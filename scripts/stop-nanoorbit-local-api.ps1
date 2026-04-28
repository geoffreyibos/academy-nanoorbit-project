[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $repoRoot "nanoorbit-local-api\\logs\\server.pid"

if (-not (Test-Path $pidFile)) {
    Write-Host "Aucun PID d'API locale trouve."
    exit 0
}

$pidValue = (Get-Content $pidFile | Select-Object -First 1).Trim()
if (-not $pidValue) {
    Remove-Item $pidFile -ErrorAction SilentlyContinue
    Write-Host "PID vide, rien a arreter."
    exit 0
}

try {
    $process = Get-Process -Id ([int]$pidValue) -ErrorAction Stop
    Stop-Process -Id $process.Id -Force
    Write-Host "API locale arretee (PID $($process.Id))."
} catch {
    Write-Host "Le processus $pidValue n'est plus actif."
}

Remove-Item $pidFile -ErrorAction SilentlyContinue
