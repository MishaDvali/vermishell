[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$InstanceDirectory,
    [string]$InstanceName = 'Pasta'
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$bootstrapSource = Join-Path $projectRoot '.tools\packwiz-installer-bootstrap.jar'
$packUrl = 'https://raw.githubusercontent.com/MishaDvali/vermishell/main/pack.toml'

if (Get-Process -Name 'prismlauncher' -ErrorAction SilentlyContinue) {
    throw 'Close Prism Launcher before running this setup so it does not overwrite instance.cfg.'
}
if (-not (Test-Path -LiteralPath $bootstrapSource -PathType Leaf)) {
    throw 'Packwiz Installer bootstrap was not found in Pasta/.tools.'
}

$instanceDirectory = [IO.Path]::GetFullPath($InstanceDirectory)
$instanceConfig = Join-Path $instanceDirectory 'instance.cfg'
$minecraftDirectory = Join-Path $instanceDirectory 'minecraft'
if (-not (Test-Path -LiteralPath $instanceConfig -PathType Leaf)) {
    throw "Prism instance.cfg not found: $instanceConfig"
}
if (-not (Test-Path -LiteralPath $minecraftDirectory -PathType Container)) {
    throw "Prism Minecraft directory not found: $minecraftDirectory"
}

$destination = Join-Path $minecraftDirectory 'packwiz-installer-bootstrap.jar'
Copy-Item -LiteralPath $bootstrapSource -Destination $destination -Force

$command = '"$INST_JAVA" -jar packwiz-installer-bootstrap.jar ' + $packUrl
$escapedCommand = $command.Replace('"', '\"')
$settings = [Collections.Generic.List[string]]::new()
$settings.AddRange([string[]](Get-Content -LiteralPath $instanceConfig))

function Set-PrismSetting {
    param([string]$Key, [string]$Value)

    for ($i = 0; $i -lt $settings.Count; $i++) {
        if ($settings[$i].StartsWith("$Key=", [StringComparison]::Ordinal)) {
            $settings[$i] = "$Key=$Value"
            return
        }
    }
    $settings.Add("$Key=$Value")
}

$backup = "$instanceConfig.pasta-backup"
if (-not (Test-Path -LiteralPath $backup)) {
    Copy-Item -LiteralPath $instanceConfig -Destination $backup
}
Set-PrismSetting -Key 'name' -Value $InstanceName
Set-PrismSetting -Key 'OverrideCommands' -Value 'true'
Set-PrismSetting -Key 'PreLaunchCommand' -Value $escapedCommand
Set-Content -LiteralPath $instanceConfig -Value $settings -Encoding utf8

$instructions = @(
    "Packwiz Installer is configured for the Prism instance '$InstanceName'.",
    '',
    'Prism custom commands were configured automatically.',
    'The effective pre-launch command is:',
    '',
    $command,
    '',
    'Launch once while online. Packwiz will download and update the managed mods and config before Minecraft starts.'
)
$instructionsPath = Join-Path $minecraftDirectory 'PASTA-AUTO-UPDATE.txt'
Set-Content -LiteralPath $instructionsPath -Value $instructions -Encoding utf8

Write-Host "Copied: $destination"
Write-Host "Configured: $instanceConfig"
Write-Host "Backup: $backup"
Write-Host "Instructions: $instructionsPath"
Write-Host ''
Write-Host 'Prism pre-launch command:'
Write-Host $command
