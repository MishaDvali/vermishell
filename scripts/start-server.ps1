$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$serverDir = Join-Path $projectRoot '.runtime\server'
$java = Get-ChildItem -LiteralPath (Join-Path $projectRoot '.tools\jdk') -Recurse -Filter 'java.exe' |
    Where-Object { $_.FullName -match '\\bin\\java\.exe$' } |
    Select-Object -First 1

if (-not $java) { throw 'Project-local Java was not found.' }

& (Join-Path $PSScriptRoot 'sync-server.ps1')

$env:JAVA_HOME = Split-Path -Parent (Split-Path -Parent $java.FullName)
$env:PATH = (Join-Path $env:JAVA_HOME 'bin') + [IO.Path]::PathSeparator + $env:PATH

$eula = Join-Path $serverDir 'eula.txt'
if (-not (Test-Path -LiteralPath $eula) -or -not (Select-String -LiteralPath $eula -SimpleMatch 'eula=true' -Quiet)) {
    throw "Minecraft EULA has not been accepted. Review $eula and set eula=true before starting the server."
}

Push-Location $serverDir
try {
    & '.\run.bat' nogui
} finally {
    Pop-Location
}

