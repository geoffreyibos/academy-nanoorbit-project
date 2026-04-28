[CmdletBinding()]
param(
    [switch]$EnsureOracle = $true
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$apiDir = Join-Path $repoRoot "nanoorbit-local-api"
$bddDir = Join-Path $repoRoot "altn83-bdd"
$logDir = Join-Path $apiDir "logs"
$pidFile = Join-Path $logDir "server.pid"
$outLog = Join-Path $logDir "server.out.log"
$errLog = Join-Path $logDir "server.err.log"
$dockerConfig = Join-Path $apiDir ".docker-config"
$healthUrl = "http://localhost:8088/health"

function Test-HttpOk {
    param([string]$Url)

    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 3
        return $response.StatusCode -ge 200 -and $response.StatusCode -lt 300
    } catch {
        return $false
    }
}

function Get-RunningApiProcess {
    if (-not (Test-Path $pidFile)) {
        return $null
    }

    $pidValue = (Get-Content $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1).Trim()
    if (-not $pidValue) {
        return $null
    }

    try {
        return Get-Process -Id ([int]$pidValue) -ErrorAction Stop
    } catch {
        return $null
    }
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw "Node.js est requis mais introuvable dans le PATH."
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker CLI est requis mais introuvable dans le PATH."
}

New-Item -ItemType Directory -Force -Path $logDir | Out-Null
New-Item -ItemType Directory -Force -Path $dockerConfig | Out-Null

$dockerConfigFile = Join-Path $dockerConfig "config.json"
if (-not (Test-Path $dockerConfigFile)) {
    Set-Content -Path $dockerConfigFile -Value "{}" -Encoding ascii
}

if (Test-HttpOk -Url $healthUrl) {
    $health = Invoke-WebRequest -UseBasicParsing -Uri $healthUrl -TimeoutSec 3 | Select-Object -ExpandProperty Content
    Write-Host "API deja disponible sur $healthUrl"
    Write-Host $health
    exit 0
}

$runningProcess = Get-RunningApiProcess
if ($runningProcess) {
    Write-Host "Processus API detecte (PID $($runningProcess.Id)) mais health KO. Arret du processus."
    Stop-Process -Id $runningProcess.Id -Force
    Remove-Item $pidFile -ErrorAction SilentlyContinue
}

$env:DOCKER_CONFIG = $dockerConfig

if ($EnsureOracle) {
    $containerStatus = docker ps --filter "name=nanoorbit-oracle" --format "{{.Status}}"
    if (-not $containerStatus) {
        Write-Host "Demarrage du conteneur Oracle via docker compose..."
        docker compose -f (Join-Path $bddDir "docker-compose.yml") up -d | Out-Host
    } else {
        Write-Host "Conteneur Oracle detecte : $containerStatus"
    }
}

if (Test-Path $outLog) {
    Remove-Item $outLog -Force
}
if (Test-Path $errLog) {
    Remove-Item $errLog -Force
}

$process = Start-Process `
    -FilePath "node" `
    -ArgumentList "server.js" `
    -WorkingDirectory $apiDir `
    -RedirectStandardOutput $outLog `
    -RedirectStandardError $errLog `
    -WindowStyle Hidden `
    -PassThru

Set-Content -Path $pidFile -Value $process.Id -Encoding ascii

$deadline = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 1

    if ($process.HasExited) {
        $stderr = if (Test-Path $errLog) { Get-Content $errLog -Raw } else { "" }
        throw "L'API locale s'est arretee pendant le demarrage.`n$stderr"
    }

    if (Test-HttpOk -Url $healthUrl) {
        $health = Invoke-WebRequest -UseBasicParsing -Uri $healthUrl -TimeoutSec 3 | Select-Object -ExpandProperty Content
        Write-Host "API demarree sur http://localhost:8088"
        Write-Host "URL emulateur Android : http://10.0.2.2:8088"
        Write-Host "Logs : $outLog"
        Write-Host $health
        exit 0
    }
}

$stderr = if (Test-Path $errLog) { Get-Content $errLog -Raw } else { "" }
throw "Timeout pendant le demarrage de l'API locale.`n$stderr"
