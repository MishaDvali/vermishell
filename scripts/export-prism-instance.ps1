[CmdletBinding()]
param(
    [string]$OutputDirectory,
    [string]$PublishedOutputPath
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$bootstrap = Join-Path $projectRoot '.tools\packwiz-installer-bootstrap.jar'
$packUrl = 'https://raw.githubusercontent.com/MishaDvali/vermishell/main/pack.toml'
$runtimeExportRoot = Join-Path $projectRoot '.runtime\prism-export'

if (-not $OutputDirectory) { $OutputDirectory = Join-Path $projectRoot 'dist\main' }
if (-not $PublishedOutputPath) { $PublishedOutputPath = Join-Path $projectRoot 'prism\Pasta-Prism.zip' }
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$PublishedOutputPath = [IO.Path]::GetFullPath($PublishedOutputPath)
if (-not (Test-Path -LiteralPath $bootstrap -PathType Leaf)) {
    throw 'Packwiz Installer bootstrap was not found in Pasta/.tools.'
}

$packText = Get-Content -LiteralPath (Join-Path $projectRoot 'pack.toml') -Raw
$version = [regex]::Match($packText, '(?m)^version = "([^"]+)"$').Groups[1].Value
if (-not $version) { throw 'Could not read the pack version.' }

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $runtimeExportRoot -Force | Out-Null
$staging = Join-Path $runtimeExportRoot ([guid]::NewGuid().ToString('N'))
$minecraftDirectory = Join-Path $staging 'minecraft'
$output = Join-Path $OutputDirectory 'Pasta-Prism.zip'

try {
    New-Item -ItemType Directory -Path $minecraftDirectory -Force | Out-Null

    $instanceConfig = @(
        '[General]',
        'ConfigVersion=1.3',
        'InstanceType=OneSix',
        'name=Pasta',
        'OverrideCommands=true',
        ('PreLaunchCommand=\"$INST_JAVA\" -jar packwiz-installer-bootstrap.jar ' + $packUrl)
    )
    Set-Content -LiteralPath (Join-Path $staging 'instance.cfg') -Value $instanceConfig -Encoding utf8

    $componentManifest = [ordered]@{
        components = @(
            [ordered]@{
                cachedName = 'Minecraft'
                cachedVersion = '1.21.1'
                important = $true
                uid = 'net.minecraft'
                version = '1.21.1'
            },
            [ordered]@{
                cachedName = 'NeoForge'
                cachedVersion = '21.1.251'
                uid = 'net.neoforged'
                version = '21.1.251'
            }
        )
        formatVersion = 1
    }
    $componentManifest | ConvertTo-Json -Depth 6 |
        Set-Content -LiteralPath (Join-Path $staging 'mmc-pack.json') -Encoding utf8

    Copy-Item -LiteralPath $bootstrap -Destination (Join-Path $minecraftDirectory 'packwiz-installer-bootstrap.jar')
    $instructions = @(
        'Pasta for Prism Launcher',
        '',
        'Import this ZIP through Add Instance -> Import.',
        'Packwiz will install the client pack on first launch and update it before every later launch.',
        'Keep an Internet connection available while updating.'
    )
    Set-Content -LiteralPath (Join-Path $minecraftDirectory 'PASTA-README.txt') -Value $instructions -Encoding utf8

    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $output -CompressionLevel Optimal -Force
    New-Item -ItemType Directory -Path (Split-Path -Parent $PublishedOutputPath) -Force | Out-Null
    if (-not $output.Equals($PublishedOutputPath, [StringComparison]::OrdinalIgnoreCase)) {
        Copy-Item -LiteralPath $output -Destination $PublishedOutputPath -Force
    }
} finally {
    if (Test-Path -LiteralPath $staging) {
        Remove-Item -LiteralPath $staging -Recurse -Force
    }
}

$releaseFiles = @(Get-ChildItem -LiteralPath $OutputDirectory -File | Where-Object Extension -In '.mrpack', '.zip' | Sort-Object Name)
$checksums = foreach ($file in $releaseFiles) {
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $($file.Name)"
}
Set-Content -LiteralPath (Join-Path $OutputDirectory 'SHA256SUMS.txt') -Value $checksums -Encoding utf8

Write-Host "Prism auto-updating instance: $output"
Write-Host "Stable GitHub artifact: $PublishedOutputPath"
