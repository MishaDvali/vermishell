[CmdletBinding()]
param(
    [string]$PacksDirectory,
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

if (-not $PacksDirectory) { $PacksDirectory = Join-Path $projectRoot 'dist\main' }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $projectRoot '.runtime\client-folders' }

$PacksDirectory = [IO.Path]::GetFullPath($PacksDirectory)
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$runtimeRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot '.runtime'))
$mainDir = Join-Path $OutputDirectory 'main'
$legacyDir = Join-Path $OutputDirectory 'legacy'
$cacheDirectory = Join-Path $runtimeRoot 'client-download-cache'

if (-not $OutputDirectory.StartsWith($runtimeRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputDirectory must stay inside Pasta/.runtime.'
}
if (-not (Test-Path -LiteralPath $PacksDirectory)) { throw "Pack directory not found: $PacksDirectory" }

$packs = @(Get-ChildItem -LiteralPath $PacksDirectory -Filter '*.mrpack')
if ($packs.Count -ne 1) { throw "Expected exactly one main .mrpack in $PacksDirectory; found $($packs.Count)." }
$pack = $packs[0]

function Get-NextLegacyDirectory {
    New-Item -ItemType Directory -Path $legacyDir -Force | Out-Null
    $numbers = @(
        Get-ChildItem -LiteralPath $legacyDir -Directory -ErrorAction SilentlyContinue |
            Where-Object Name -Match '^\d{4}$' |
            ForEach-Object { [int]$_.Name }
    )
    $next = if ($numbers.Count) { [int](($numbers | Measure-Object -Maximum).Maximum) + 1 } else { 1 }
    Join-Path $legacyDir ('{0:D4}' -f [int]$next)
}

function Test-DownloadedFile {
    param([string]$Path, $Hashes)

    if ($Hashes.sha512) {
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA512).Hash.Equals(
            [string]$Hashes.sha512,
            [StringComparison]::OrdinalIgnoreCase
        )
    }
    if ($Hashes.sha1) {
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA1).Hash.Equals(
            [string]$Hashes.sha1,
            [StringComparison]::OrdinalIgnoreCase
        )
    }
    throw "No supported hash was supplied for $Path"
}

function Expand-OverrideFiles {
    param($Archive, [string]$Prefix, [string]$Destination)

    foreach ($entry in $Archive.Entries) {
        if (-not $entry.FullName.StartsWith($Prefix, [StringComparison]::OrdinalIgnoreCase)) { continue }
        $relative = $entry.FullName.Substring($Prefix.Length)
        if (-not $relative -or $relative.EndsWith('/')) { continue }

        $target = [IO.Path]::GetFullPath((Join-Path $Destination $relative))
        if (-not $target.StartsWith($Destination + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Unsafe override path: $relative"
        }

        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        $sourceStream = $entry.Open()
        $targetStream = [IO.File]::Create($target)
        try { $sourceStream.CopyTo($targetStream) } finally {
            $targetStream.Dispose()
            $sourceStream.Dispose()
        }
    }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $cacheDirectory -Force | Out-Null

if (Test-Path -LiteralPath $mainDir) {
    $mainContents = @(Get-ChildItem -LiteralPath $mainDir -Force -ErrorAction SilentlyContinue)
    if ($mainContents.Count) {
        Move-Item -LiteralPath $mainDir -Destination (Get-NextLegacyDirectory)
    } else {
        Remove-Item -LiteralPath $mainDir -Force
    }
}
New-Item -ItemType Directory -Path $mainDir | Out-Null

$archive = [IO.Compression.ZipFile]::OpenRead($pack.FullName)
try {
    $manifestEntry = $archive.GetEntry('modrinth.index.json')
    if (-not $manifestEntry) { throw "Missing modrinth.index.json in $($pack.Name)" }

    $reader = [IO.StreamReader]::new($manifestEntry.Open())
    try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }

    $position = 0
    foreach ($file in $manifest.files) {
        if ($file.env -and [string]$file.env.client -eq 'unsupported') { continue }

        $position++
        $relative = ([string]$file.path).Replace('/', [IO.Path]::DirectorySeparatorChar)
        $target = [IO.Path]::GetFullPath((Join-Path $mainDir $relative))
        if (-not $target.StartsWith($mainDir + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Unsafe manifest path: $relative"
        }

        $cacheKey = if ($file.hashes.sha512) { [string]$file.hashes.sha512 } else { [string]$file.hashes.sha1 }
        $cacheFile = Join-Path $cacheDirectory $cacheKey
        if (-not (Test-Path -LiteralPath $cacheFile) -or -not (Test-DownloadedFile -Path $cacheFile -Hashes $file.hashes)) {
            $partial = "$cacheFile.partial"
            Invoke-WebRequest -UseBasicParsing -Uri ([string]$file.downloads[0]) -OutFile $partial
            if (-not (Test-DownloadedFile -Path $partial -Hashes $file.hashes)) {
                Remove-Item -LiteralPath $partial -Force
                throw "Hash verification failed for $relative"
            }
            Move-Item -LiteralPath $partial -Destination $cacheFile -Force
        }

        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        Copy-Item -LiteralPath $cacheFile -Destination $target -Force
        Write-Progress -Activity "Materializing $($manifest.name)" -Status "$position files" -PercentComplete (($position / $manifest.files.Count) * 100)
    }
    Write-Progress -Activity "Materializing $($manifest.name)" -Completed

    Expand-OverrideFiles -Archive $archive -Prefix 'overrides/' -Destination $mainDir
    Expand-OverrideFiles -Archive $archive -Prefix 'client-overrides/' -Destination $mainDir

    $instructions = @(
        "Pasta client files: $($manifest.versionId)",
        '',
        'Minecraft 1.21.1 / NeoForge 21.1.251',
        'This is the current complete client release.',
        'Prefer the Prism + Packwiz setup documented in README.md for automatic updates.'
    )
    Set-Content -LiteralPath (Join-Path $mainDir 'INSTALL.txt') -Value $instructions -Encoding utf8
} finally {
    $archive.Dispose()
}

Write-Host "Main client folder: $mainDir"
Write-Host "Previous folders: $legacyDir"
