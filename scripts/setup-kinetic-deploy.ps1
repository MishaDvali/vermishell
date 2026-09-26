[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$deployRoot = Join-Path $projectRoot '.runtime\kinetic-deploy'
$keyPath = Join-Path $deployRoot 'id_ed25519'
$publicKeyPath = "$keyPath.pub"
$sshKeygen = (Get-Command 'ssh-keygen.exe' -ErrorAction Stop).Source

New-Item -ItemType Directory -Path $deployRoot -Force | Out-Null

if (-not (Test-Path -LiteralPath $keyPath)) {
    $arguments = @(
        '-q',
        '-t', 'ed25519',
        '-N', '""',
        '-C', 'pasta-kinetic-deploy',
        '-f', ('"' + $keyPath + '"')
    )
    $process = Start-Process -FilePath $sshKeygen -ArgumentList $arguments -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -ne 0) { throw "ssh-keygen failed with exit code $($process.ExitCode)." }
}

if (-not (Test-Path -LiteralPath $publicKeyPath)) {
    throw "Public key was not created: $publicKeyPath"
}

Write-Host 'Deployment key ready. Add this public key in:'
Write-Host 'Kinetic Panel -> Account -> SSH Keys'
Write-Host ''
Get-Content -Raw -LiteralPath $publicKeyPath
Write-Host ''
Write-Host 'After Kinetic confirms the key, run scripts/deploy-kinetic.ps1.'
