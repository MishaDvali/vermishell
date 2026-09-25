$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$serverDir = Join-Path $projectRoot '.runtime\server'
$packFile = Join-Path $projectRoot 'pack.toml'
$persistentJvmArgs = Join-Path $projectRoot 'user_jvm_args.txt'
$java = Get-ChildItem -LiteralPath (Join-Path $projectRoot '.tools\jdk') -Recurse -Filter 'java.exe' |
    Where-Object { $_.FullName -match '\\bin\\java\.exe$' } |
    Select-Object -First 1

if (-not $java) { throw 'Project-local Java was not found.' }
if (-not (Test-Path -LiteralPath $persistentJvmArgs)) { throw "Missing persistent JVM arguments: $persistentJvmArgs" }

$packText = Get-Content -LiteralPath $packFile -Raw
$neoForgeVersion = [regex]::Match($packText, '(?m)^neoforge = "([^"]+)"$').Groups[1].Value
if (-not $neoForgeVersion) { throw 'Could not read the NeoForge version from pack.toml.' }

& (Join-Path $PSScriptRoot 'sync-server.ps1')

$env:JAVA_HOME = Split-Path -Parent (Split-Path -Parent $java.FullName)
$env:PATH = (Join-Path $env:JAVA_HOME 'bin') + [IO.Path]::PathSeparator + $env:PATH

$neoForgeArgs = Join-Path $serverDir "libraries\net\neoforged\neoforge\$neoForgeVersion\win_args.txt"
if (-not (Test-Path -LiteralPath $neoForgeArgs)) {
    $installer = Join-Path $projectRoot ".tools\neoforge-$neoForgeVersion-installer.jar"
    if (-not (Test-Path -LiteralPath $installer)) {
        throw "NeoForge runtime arguments and installer are both missing: $neoForgeArgs"
    }

    Write-Host "NeoForge runtime files are missing; repairing $neoForgeVersion..."
    & $java.FullName -jar $installer --installServer $serverDir
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $neoForgeArgs)) {
        throw 'NeoForge runtime repair failed.'
    }
}

$runtimeJvmArgs = Join-Path $serverDir 'user_jvm_args.txt'
Copy-Item -LiteralPath $persistentJvmArgs -Destination $runtimeJvmArgs -Force

$eula = Join-Path $serverDir 'eula.txt'
if (-not (Test-Path -LiteralPath $eula) -or -not (Select-String -LiteralPath $eula -SimpleMatch 'eula=true' -Quiet)) {
    throw "Minecraft EULA has not been accepted. Review $eula and set eula=true before starting the server."
}

Push-Location $serverDir
try {
    & $java.FullName "@$runtimeJvmArgs" "@$neoForgeArgs" nogui
    if ($LASTEXITCODE -ne 0) { throw "Vermishell server exited with code $LASTEXITCODE." }
} finally {
    Pop-Location
}
