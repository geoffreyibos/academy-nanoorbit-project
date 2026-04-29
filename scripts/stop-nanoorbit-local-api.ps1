[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $repoRoot "nanoorbit-local-api\\logs\\server.pid"

function Get-ApiProcessesByCommandLine {
    Get-CimInstance Win32_Process -Filter "name = 'node.exe'" |
        Where-Object {
            $_.CommandLine -match "server\.js" -and
            $_.CommandLine -like "*nanoorbit-local-api*"
        } |
        ForEach-Object {
            Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue
        }
}

function Get-ApiPortOwner {
    try {
        $connection = Get-NetTCPConnection -LocalPort 8088 -State Listen -ErrorAction Stop |
            Select-Object -First 1
        if ($connection) {
            return Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
        }
    } catch {
        return $null
    }
    return $null
}

$processes = @()

if (Test-Path $pidFile) {
    $pidValue = (Get-Content $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1).Trim()
    if ($pidValue) {
        try {
            $processes += Get-Process -Id ([int]$pidValue) -ErrorAction Stop
        } catch {
            Write-Host "Le processus du PID $pidValue n'est plus actif."
        }
    }
}

$processes += @(Get-ApiProcessesByCommandLine)

$portOwner = Get-ApiPortOwner
if ($portOwner -and $portOwner.ProcessName -like "node*") {
    $processes += $portOwner
}

$processes = @($processes | Where-Object { $_ } | Sort-Object Id -Unique)

if ($processes.Count -eq 0) {
    Write-Host "Aucun processus d'API locale trouve."
    Remove-Item $pidFile -ErrorAction SilentlyContinue
    exit 0
}

foreach ($process in $processes) {
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    Write-Host "API locale arretee (PID $($process.Id))."
}

Remove-Item $pidFile -ErrorAction SilentlyContinue
