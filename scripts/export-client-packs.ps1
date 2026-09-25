[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$packwiz = Join-Path $projectRoot '.tools\packwiz.exe'
$profileFile = Join-Path $projectRoot 'profiles\client-profiles.json'
$distDir = Join-Path $projectRoot 'dist'
$cacheDir = Join-Path $projectRoot '.runtime\packwiz-cache'

if (-not (Test-Path -LiteralPath $packwiz)) { throw 'Project-local Packwiz was not found.' }
if (-not (Test-Path -LiteralPath $profileFile)) { throw 'Client profile configuration was not found.' }

$config = Get-Content -LiteralPath $profileFile -Raw | ConvertFrom-Json
if ($config.schemaVersion -ne 1) { throw "Unsupported client profile schema: $($config.schemaVersion)" }

$clientFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $projectRoot 'mods') -Filter '*.pw.toml' |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName | Select-String -Pattern '^side = "client"$' -Quiet)
        } |
        ForEach-Object Name |
        Sort-Object
)

$assigned = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($tier in $config.tiers) {
    foreach ($file in $tier.add) {
        if (-not $assigned.Add([string]$file)) { throw "Client mod is assigned more than once: $file" }
        if ($file -notin $clientFiles) { throw "Profile references a missing or non-client mod: $file" }
    }
}

$unclassified = @($clientFiles | Where-Object { -not $assigned.Contains($_) })
if ($unclassified.Count -gt 0) {
    throw "Unclassified client mods: $($unclassified -join ', ')"
}

New-Item -ItemType Directory -Path $distDir -Force | Out-Null
New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
$included = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$checksums = [System.Collections.Generic.List[string]]::new()

foreach ($tier in $config.tiers) {
    foreach ($file in $tier.add) { [void]$included.Add([string]$file) }

    $workDir = Join-Path ([IO.Path]::GetTempPath()) ("vermishell-export-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $workDir | Out-Null

    try {
        Get-ChildItem -LiteralPath $projectRoot -Force |
            Where-Object { $_.Name -notin @('.git', '.tools', '.runtime', 'dist') } |
            Copy-Item -Destination $workDir -Recurse -Force

        foreach ($file in $clientFiles) {
            if (-not $included.Contains($file)) {
                $target = Join-Path $workDir (Join-Path 'mods' $file)
                $resolvedParent = (Resolve-Path -LiteralPath (Split-Path -Parent $target)).Path
                if (-not $resolvedParent.StartsWith($workDir, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Unsafe profile target: $target"
                }
                Remove-Item -LiteralPath $target -Force
            }
        }

        $packFile = Join-Path $workDir 'pack.toml'
        $packText = Get-Content -LiteralPath $packFile -Raw
        $version = [regex]::Match($packText, '(?m)^version = "([^"]+)"$').Groups[1].Value
        if (-not $version) { throw 'Could not read the pack version.' }
        $packText = [regex]::Replace($packText, '(?m)^name = ".*"$', "name = `"Vermishell - $($tier.displayName)`"")
        $packText = [regex]::Replace($packText, '(?m)^version = ".*"$', "version = `"$version-$($tier.id)`"")
        Set-Content -LiteralPath $packFile -Value $packText -NoNewline -Encoding utf8

        Push-Location $workDir
        try {
            & $packwiz refresh
            if ($LASTEXITCODE -ne 0) { throw "Packwiz refresh failed for $($tier.id)." }

            $output = Join-Path $distDir ("Vermishell-$version-$($tier.id).mrpack")
            & $packwiz --cache $cacheDir modrinth export --output $output
            if ($LASTEXITCODE -ne 0) { throw "Packwiz export failed for $($tier.id)." }
        } finally {
            Pop-Location
        }

        $hash = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant()
        $checksums.Add("$hash  $([IO.Path]::GetFileName($output))")
        Write-Host "Built $([IO.Path]::GetFileName($output))"
    } finally {
        if (Test-Path -LiteralPath $workDir) { Remove-Item -LiteralPath $workDir -Recurse -Force }
    }
}

Set-Content -LiteralPath (Join-Path $distDir 'SHA256SUMS.txt') -Value $checksums -Encoding utf8
Write-Host "Client packs are ready in $distDir"
