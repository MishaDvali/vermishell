$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$toolsDir = Join-Path $projectRoot '.tools'
$serverDir = Join-Path $projectRoot '.runtime\server'
$packwiz = Join-Path $toolsDir 'packwiz.exe'
$installer = Join-Path $toolsDir 'packwiz-installer-bootstrap.jar'
$java = Get-ChildItem -LiteralPath (Join-Path $toolsDir 'jdk') -Recurse -Filter 'java.exe' |
    Where-Object { $_.FullName -match '\\bin\\java\.exe$' } |
    Select-Object -First 1

if (-not $java) { throw 'Project-local Java was not found.' }
if (-not (Test-Path -LiteralPath $packwiz)) { throw 'Project-local Packwiz was not found.' }
if (-not (Test-Path -LiteralPath $installer)) { throw 'Packwiz Installer bootstrap was not found.' }

& $packwiz refresh
if ($LASTEXITCODE -ne 0) { throw 'packwiz refresh failed.' }

$serve = Start-Process -FilePath $packwiz -ArgumentList @('serve') -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru
try {
    $deadline = (Get-Date).AddSeconds(30)
    do {
        try {
            Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8080/pack.toml' -TimeoutSec 2 | Out-Null
            $ready = $true
        } catch {
            Start-Sleep -Milliseconds 500
        }
    } until ($ready -or (Get-Date) -ge $deadline)

    if (-not $ready) { throw 'Timed out waiting for packwiz serve.' }
    New-Item -ItemType Directory -Path $serverDir -Force | Out-Null
    Push-Location $serverDir
    try {
        & $java.FullName -jar $installer -g -s server 'http://127.0.0.1:8080/pack.toml'
        if ($LASTEXITCODE -ne 0) { throw 'Packwiz Installer failed.' }
    } finally {
        Pop-Location
    }
} finally {
    if ($serve -and -not $serve.HasExited) { Stop-Process -Id $serve.Id }
}

