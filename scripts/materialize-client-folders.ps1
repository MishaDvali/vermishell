[CmdletBinding()]
param(
    [string]$PacksDirectory,
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

if (-not $PacksDirectory) { $PacksDirectory = Join-Path $projectRoot 'dist' }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $projectRoot '.runtime\client-folders' }

$PacksDirectory = [IO.Path]::GetFullPath($PacksDirectory)
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$runtimeRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot '.runtime'))
$cacheDirectory = Join-Path $runtimeRoot 'client-download-cache'

if (-not $OutputDirectory.StartsWith($runtimeRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputDirectory must stay inside Vermishell/.runtime.'
}
if (-not (Test-Path -LiteralPath $PacksDirectory)) { throw "Pack directory not found: $PacksDirectory" }

Add-Type -AssemblyName System.IO.Compression.FileSystem
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $cacheDirectory -Force | Out-Null

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

$packs = @(Get-ChildItem -LiteralPath $PacksDirectory -Filter '*.mrpack' | Sort-Object Name)
if ($packs.Count -eq 0) { throw "No .mrpack files found in $PacksDirectory" }

foreach ($pack in $packs) {
    $archive = [IO.Compression.ZipFile]::OpenRead($pack.FullName)
    try {
        $manifestEntry = $archive.GetEntry('modrinth.index.json')
        if (-not $manifestEntry) { throw "Missing modrinth.index.json in $($pack.Name)" }

        $reader = [IO.StreamReader]::new($manifestEntry.Open())
        try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }

        $profileId = [string]$manifest.versionId
        $targetRoot = [IO.Path]::GetFullPath((Join-Path $OutputDirectory $profileId))
        if (-not $targetRoot.StartsWith($OutputDirectory + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Unsafe profile path: $profileId"
        }
        if (Test-Path -LiteralPath $targetRoot) { Remove-Item -LiteralPath $targetRoot -Recurse -Force }
        New-Item -ItemType Directory -Path $targetRoot | Out-Null

        $position = 0
        foreach ($file in $manifest.files) {
            $position++
            $relative = ([string]$file.path).Replace('/', [IO.Path]::DirectorySeparatorChar)
            $target = [IO.Path]::GetFullPath((Join-Path $targetRoot $relative))
            if (-not $target.StartsWith($targetRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
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
            Write-Progress -Activity "Materializing $($manifest.name)" -Status "$position / $($manifest.files.Count)" -PercentComplete (($position / $manifest.files.Count) * 100)
        }
        Write-Progress -Activity "Materializing $($manifest.name)" -Completed

        Expand-OverrideFiles -Archive $archive -Prefix 'overrides/' -Destination $targetRoot
        Expand-OverrideFiles -Archive $archive -Prefix 'client-overrides/' -Destination $targetRoot

        $instructions = @(
            "Vermishell client files: $($manifest.name)",
            '',
            'Requires a legitimate Minecraft: Java Edition installation.',
            "Minecraft: $($manifest.dependencies.minecraft)",
            "NeoForge: $($manifest.dependencies.neoforge)",
            '',
            "Copy this folder's contents into a clean instance configured for the versions above.",
            'Do not mix it into an existing modded instance.'
        )
        Set-Content -LiteralPath (Join-Path $targetRoot 'INSTALL.txt') -Value $instructions -Encoding utf8
        Write-Host "Created $targetRoot"
    } finally {
        $archive.Dispose()
    }
}

Write-Host "Client folders are ready in $OutputDirectory"
