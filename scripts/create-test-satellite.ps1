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

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM SATELLITE
     WHERE id_satellite = 'SAT-TEST';

    IF v_count = 0 THEN
        INSERT INTO SATELLITE (
            id_satellite,
            nom_satellite,
            date_lancement,
            masse_kg,
            format_cubesat,
            statut,
            duree_vie_mois,
            capacite_batterie_wh,
            id_orbite
        ) VALUES (
            'SAT-TEST',
            'NanoOrbit-Test Offline',
            TO_DATE('2026-04-29', 'YYYY-MM-DD'),
            1.50,
            '3U',
            UNISTR('Op\00E9rationnel'),
            60,
            24,
            'ORB-001'
        );

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('OK - SAT-TEST cree dans Oracle.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('INFO - SAT-TEST existe deja.');
    END IF;
END;
/
EXIT
"@

$sql | docker exec -i $oracleContainer sqlplus -s $oracleConnect

Write-Host ""
Write-Host "Satellite de test pret : SAT-TEST"
Write-Host "Dans l'app Android : relance/refresh les satellites pendant que l'API est disponible pour le mettre en cache."
