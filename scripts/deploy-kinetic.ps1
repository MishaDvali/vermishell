[CmdletBinding()]
param(
    [switch]$PrepareOnly,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$deployRoot = Join-Path $projectRoot '.runtime\kinetic-deploy'
$settingsPath = Join-Path $deployRoot 'settings.json'
$stagingDir = Join-Path $deployRoot 'staging'
$keyPath = Join-Path $deployRoot 'id_ed25519'
$knownHostsPath = Join-Path $deployRoot 'known_hosts'
$batchPath = Join-Path $deployRoot 'deploy.sftp'
$managedConfigs = @(
    'DistantHorizons.toml',
    'streamsreflowing-common.toml'
)
$configSources = @($managedConfigs | ForEach-Object { Join-Path $projectRoot "config\$_" })

function Assert-Command {
    param([Parameter(Mandatory)][string]$Name)

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command) { throw "Required command was not found: $Name" }
    $command.Source
}

function ConvertTo-SftpPath {
    param([Parameter(Mandatory)][string]$Path)

    '"' + ($Path -replace '\\', '/') + '"'
}

function Assert-SafeDeployPath {
    param([Parameter(Mandatory)][string]$Path)

    $resolvedDeployRoot = [IO.Path]::GetFullPath($deployRoot).TrimEnd('\') + '\'
    $resolvedPath = [IO.Path]::GetFullPath($Path)
    if (-not $resolvedPath.StartsWith($resolvedDeployRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify a path outside the deployment workspace: $resolvedPath"
    }
}

New-Item -ItemType Directory -Path $deployRoot -Force | Out-Null

if (-not (Test-Path -LiteralPath $settingsPath)) {
    throw @"
Missing local deployment settings: $settingsPath

Create it from scripts/deploy-kinetic.settings.example.json and fill in the
SFTP values shown by Kinetic Panel. This file is under .runtime and is ignored
by Git.
"@
}

$settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
foreach ($property in 'hostName', 'port', 'userName', 'remoteRoot') {
    if (-not $settings.$property) { throw "Deployment setting '$property' is missing in $settingsPath" }
}

if ($settings.remoteRoot -notin '.', '/') {
    throw "For safety, remoteRoot must be '.' or '/'. Found: $($settings.remoteRoot)"
}

foreach ($configSource in $configSources) {
    if (-not (Test-Path -LiteralPath $configSource)) {
        throw "Missing managed server config: $configSource"
    }
}

$sftp = Assert-Command 'sftp.exe'
Assert-Command 'ssh-keygen.exe' | Out-Null

if (-not (Test-Path -LiteralPath $keyPath)) {
    throw @"
Missing deployment key: $keyPath

Run scripts/setup-kinetic-deploy.ps1, add the printed public key under
Kinetic Panel -> Account -> SSH Keys, then run this script again.
"@
}

Assert-SafeDeployPath $stagingDir
if (Test-Path -LiteralPath $stagingDir) {
    Remove-Item -LiteralPath $stagingDir -Recurse -Force
}
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

Write-Host 'Building a clean server-only mod set from Packwiz...'
$syncScript = Join-Path $PSScriptRoot 'sync-server.ps1'
& powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $syncScript -ServerDirectory $stagingDir
if ($LASTEXITCODE -ne 0) { throw 'Packwiz server materialization failed.' }

$stagedModsDir = Join-Path $stagingDir 'mods'
$stagedMods = @(Get-ChildItem -LiteralPath $stagedModsDir -File -Filter '*.jar')
if ($stagedMods.Count -eq 0) { throw "No server mod JARs were materialized in $stagedModsDir" }

Write-Host "Prepared $($stagedMods.Count) server mod JARs."
Write-Host "Managed configs: $($managedConfigs -join ', ')"

if ($PrepareOnly) {
    Write-Host 'PrepareOnly requested; no connection to Kinetic was made.'
    return
}

if (-not $Yes) {
    $confirmation = Read-Host "Confirm Pasta is OFFLINE in Kinetic Panel, then type DEPLOY"
    if ($confirmation -cne 'DEPLOY') {
        throw 'Deployment cancelled. The server must be offline before replacing mods.'
    }
}

$remoteRoot = $settings.remoteRoot.TrimEnd('/')
if (-not $remoteRoot) { $remoteRoot = '/' }
$localModsPath = ConvertTo-SftpPath $stagedModsDir
$configUploads = @(
    for ($i = 0; $i -lt $managedConfigs.Count; $i++) {
        "put $(ConvertTo-SftpPath $configSources[$i]) config/$($managedConfigs[$i])"
    }
) -join "`n"

$batch = @"
cd $remoteRoot
-rm mods.pasta-next/*
-rmdir mods.pasta-next
mkdir mods.pasta-next
lcd $localModsPath
cd mods.pasta-next
put *.jar
cd ..
-rm mods.pasta-previous/*
-rmdir mods.pasta-previous
-rename mods mods.pasta-previous
rename mods.pasta-next mods
-mkdir config
$configUploads
bye
"@
Set-Content -LiteralPath $batchPath -Value $batch -Encoding ascii

$destination = "$($settings.userName)@$($settings.hostName)"
$arguments = @(
    '-b', $batchPath,
    '-P', [string]$settings.port,
    '-i', $keyPath,
    '-o', 'BatchMode=yes',
    '-o', 'StrictHostKeyChecking=accept-new',
    '-o', "UserKnownHostsFile=$knownHostsPath",
    $destination
)

Write-Host "Uploading Pasta to $destination..."
& $sftp @arguments
if ($LASTEXITCODE -ne 0) {
    throw "SFTP deployment failed with exit code $LASTEXITCODE. The live mods directory was left unchanged unless the output shows that the final rename already occurred."
}

Write-Host ''
Write-Host "Deployment complete: $($stagedMods.Count) mod JARs and $($managedConfigs.Count) managed configs."
Write-Host 'The former remote mods directory is available as mods.pasta-previous.'
Write-Host 'You can now start Pasta from the Kinetic Panel and inspect the console.'
