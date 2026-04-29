[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$apiDir = Join-Path $repoRoot "nanoorbit-local-api"
$dockerConfig = Join-Path $apiDir ".docker-config"
$oracleContainer = $env:ORACLE_CONTAINER
$oracleConnect = $env:ORACLE_CONNECT

if (-not $oracleContainer) {
    $oracleContainer = "nanoorbit-oracle"
}
if (-not $oracleConnect) {
    $oracleConnect = "NANOORBIT_ADMIN/NanoOrbit2025@localhost:1521/FREEPDB1"
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker CLI est requis mais introuvable dans le PATH."
}

New-Item -ItemType Directory -Force -Path $dockerConfig | Out-Null
$dockerConfigFile = Join-Path $dockerConfig "config.json"
if (-not (Test-Path $dockerConfigFile)) {
    Set-Content -Path $dockerConfigFile -Value "{}" -Encoding ascii
}

$env:DOCKER_CONFIG = $dockerConfig

$sql = @"
SET HEADING OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET PAGESIZE 0
SET SERVEROUTPUT ON

BEGIN
    DELETE FROM FENETRE_COM WHERE id_satellite = 'SAT-TEST';
    DELETE FROM EMBARQUEMENT WHERE id_satellite = 'SAT-TEST';
    DELETE FROM PARTICIPATION WHERE id_satellite = 'SAT-TEST';
    DELETE FROM HISTORIQUE_STATUT WHERE id_satellite = 'SAT-TEST';
    DELETE FROM SATELLITE WHERE id_satellite = 'SAT-TEST';

    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('INFO - SAT-TEST etait deja absent.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('OK - SAT-TEST supprime de Oracle.');
    END IF;

    COMMIT;
END;
/
EXIT
"@

$sql | docker exec -i $oracleContainer sqlplus -s $oracleConnect

Write-Host ""
Write-Host "Satellite de test supprime cote Oracle : SAT-TEST"
Write-Host "Si l'app est hors ligne, elle peut encore l'afficher depuis le cache Room."
