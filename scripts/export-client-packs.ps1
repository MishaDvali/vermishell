[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$packwiz = Join-Path $projectRoot '.tools\packwiz.exe'
$distDir = Join-Path $projectRoot 'dist'
$mainDir = Join-Path $distDir 'main'
$legacyDir = Join-Path $distDir 'legacy'
$cacheDir = Join-Path $projectRoot '.runtime\packwiz-cache'

if (-not (Test-Path -LiteralPath $packwiz)) { throw 'Project-local Packwiz was not found.' }

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

New-Item -ItemType Directory -Path $distDir -Force | Out-Null
New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null

# Preserve the former multi-edition exports as the first emergency snapshot.
$rootExports = @(Get-ChildItem -LiteralPath $distDir -File -ErrorAction SilentlyContinue)
if ($rootExports.Count) {
    $archive = Get-NextLegacyDirectory
    New-Item -ItemType Directory -Path $archive | Out-Null
    $rootExports | Move-Item -Destination $archive
}

# Every later export archives the previous main release under the next number.
if (Test-Path -LiteralPath $mainDir) {
    $currentFiles = @(Get-ChildItem -LiteralPath $mainDir -Force -ErrorAction SilentlyContinue)
    if ($currentFiles.Count) {
        $archive = Get-NextLegacyDirectory
        Move-Item -LiteralPath $mainDir -Destination $archive
    } else {
        Remove-Item -LiteralPath $mainDir -Force
    }
}
New-Item -ItemType Directory -Path $mainDir | Out-Null

& $packwiz refresh
if ($LASTEXITCODE -ne 0) { throw 'packwiz refresh failed.' }

$packText = Get-Content -LiteralPath (Join-Path $projectRoot 'pack.toml') -Raw
$version = [regex]::Match($packText, '(?m)^version = "([^"]+)"$').Groups[1].Value
if (-not $version) { throw 'Could not read the pack version.' }

$output = Join-Path $mainDir "Pasta-$version.mrpack"
Push-Location $projectRoot
try {
    & $packwiz --cache $cacheDir modrinth export --output $output
    if ($LASTEXITCODE -ne 0) { throw 'Packwiz Modrinth export failed.' }
} finally {
    Pop-Location
}

& (Join-Path $PSScriptRoot 'export-prism-instance.ps1') -OutputDirectory $mainDir
if ($LASTEXITCODE -ne 0) { throw 'Prism instance export failed.' }

# Keep the ordinary launcher folder in lockstep with every exported release.
# This prevents TLauncher/manual-install files from silently remaining on an
# older pack version when only the main export command is run.
& (Join-Path $PSScriptRoot 'materialize-client-folders.ps1') -PacksDirectory $mainDir
if ($LASTEXITCODE -ne 0) { throw 'Client folder materialization failed.' }

$prismInstructions = @(
    'Pasta automatic updates for Prism Launcher',
    '',
    '1. Close Prism Launcher.',
    '2. Run scripts/setup-prism-auto-update.ps1 once for the instance folder.',
    'The script copies Packwiz Installer and configures the pre-launch command:',
    '',
    '"$INST_JAVA" -jar packwiz-installer-bootstrap.jar https://raw.githubusercontent.com/MishaDvali/vermishell/main/pack.toml',
    '',
    'The GitHub main branch is the update source, so changes only reach players after they are committed and pushed.'
)
Set-Content -LiteralPath (Join-Path $mainDir 'PRISM-AUTO-UPDATE.txt') -Value $prismInstructions -Encoding utf8

Write-Host "Main client pack: $output"
Write-Host "Prism import: $(Join-Path $mainDir 'Pasta-Prism.zip')"
Write-Host "Manual launcher folder: $(Join-Path $projectRoot '.runtime\client-folders\main')"
Write-Host "Previous releases: $legacyDir"
