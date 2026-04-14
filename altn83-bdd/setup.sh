#!/usr/bin/env bash
# ============================================================
# setup.sh — NanoOrbit Phase 2 : setup complet
#
# Ce script :
#   1. Démarre le conteneur Oracle 23ai via Docker Compose
#   2. Attend que la base soit prête
#   3. Crée l'utilisateur NANOORBIT_ADMIN
#   4. Exécute tous les scripts Phase 2 dans l'ordre
#
# Prérequis : Docker + Docker Compose installés et lancés
# Usage     : bash setup.sh
# ============================================================

set -e

CONTAINER="nanoorbit-oracle"
SYS_PASS="Oracle2025"
APP_USER="NANOORBIT_ADMIN"
APP_PASS="NanoOrbit2025"
PDB="FREEPDB1"

# Chemin des scripts à l'intérieur du conteneur
# (monté via le volume ./livrables → /opt/oracle/livrables)
SCRIPTS_DIR="/opt/oracle/livrables/phase2"

# ============================================================
# 1. Démarrage du conteneur
# ============================================================
echo ""
echo "=== 1/4 Démarrage du conteneur Oracle 23ai ==="
docker compose up -d

# ============================================================
# 2. Attente que la base soit prête
# ============================================================
echo ""
echo "=== 2/4 Attente de la base de données ==="
echo "(Première initialisation : 2-3 minutes environ)"

until docker inspect --format='{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null | grep -q "healthy"; do
    echo "  ... en attente ($(date +%H:%M:%S))"
    sleep 15
done

echo "  Base prête."

# ============================================================
# 3. Création de l'utilisateur NANOORBIT_ADMIN
# ============================================================
echo ""
echo "=== 3/4 Création de l'utilisateur $APP_USER ==="

docker exec -i "$CONTAINER" sqlplus -s "sys/$SYS_PASS@localhost:1521/$PDB as sysdba" << SQL
SET SERVEROUTPUT ON

BEGIN
    EXECUTE IMMEDIATE 'DROP USER NANOORBIT_ADMIN CASCADE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE USER NANOORBIT_ADMIN
    IDENTIFIED BY NanoOrbit2025
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON USERS;

GRANT CREATE SESSION   TO NANOORBIT_ADMIN;
GRANT CREATE TABLE     TO NANOORBIT_ADMIN;
GRANT CREATE SEQUENCE  TO NANOORBIT_ADMIN;
GRANT CREATE TRIGGER   TO NANOORBIT_ADMIN;
GRANT CREATE PROCEDURE TO NANOORBIT_ADMIN;
GRANT CREATE VIEW      TO NANOORBIT_ADMIN;
GRANT CREATE TYPE      TO NANOORBIT_ADMIN;

PROMPT Utilisateur NANOORBIT_ADMIN créé.
EXIT;
SQL

echo "  Utilisateur créé."

# ============================================================
# 4. Exécution de la Phase 2
# ============================================================
echo ""
echo "=== 4/4 Exécution des scripts Phase 2 ==="

docker exec -i "$CONTAINER" sqlplus -s "$APP_USER/$APP_PASS@localhost:1521/$PDB" << SQL
SET SERVEROUTPUT ON
SET ECHO ON

PROMPT ============================================================
PROMPT ÉTAPE 1 — DDL
PROMPT ============================================================
@$SCRIPTS_DIR/L2-A_DDL/01_ORBITE.sql
@$SCRIPTS_DIR/L2-A_DDL/02_CENTRE_CONTROLE.sql
@$SCRIPTS_DIR/L2-A_DDL/03_SATELLITE.sql
@$SCRIPTS_DIR/L2-A_DDL/04_INSTRUMENT.sql
@$SCRIPTS_DIR/L2-A_DDL/05_EMBARQUEMENT.sql
@$SCRIPTS_DIR/L2-A_DDL/06_STATION_SOL.sql
@$SCRIPTS_DIR/L2-A_DDL/07_AFFECTATION_STATION.sql
@$SCRIPTS_DIR/L2-A_DDL/08_MISSION.sql
@$SCRIPTS_DIR/L2-A_DDL/09_FENETRE_COM.sql
@$SCRIPTS_DIR/L2-A_DDL/10_PARTICIPATION.sql
@$SCRIPTS_DIR/L2-A_DDL/11_HISTORIQUE_STATUT.sql

PROMPT ============================================================
PROMPT ÉTAPE 2 — DML
PROMPT ============================================================
@$SCRIPTS_DIR/L2-B_DML/01_ORBITE.sql
@$SCRIPTS_DIR/L2-B_DML/02_CENTRE_CONTROLE.sql
@$SCRIPTS_DIR/L2-B_DML/03_SATELLITE.sql
@$SCRIPTS_DIR/L2-B_DML/04_INSTRUMENT.sql
@$SCRIPTS_DIR/L2-B_DML/05_EMBARQUEMENT.sql
@$SCRIPTS_DIR/L2-B_DML/06_STATION_SOL.sql
@$SCRIPTS_DIR/L2-B_DML/07_AFFECTATION_STATION.sql
@$SCRIPTS_DIR/L2-B_DML/08_MISSION.sql
@$SCRIPTS_DIR/L2-B_DML/09_FENETRE_COM.sql
@$SCRIPTS_DIR/L2-B_DML/10_PARTICIPATION.sql

PROMPT ============================================================
PROMPT ÉTAPE 3 — Triggers
PROMPT ============================================================
@$SCRIPTS_DIR/L2-C_Triggers/T1_trg_valider_fenetre.sql
@$SCRIPTS_DIR/L2-C_Triggers/T2_trg_no_chevauchement.sql
@$SCRIPTS_DIR/L2-C_Triggers/T3_trg_volume_realise.sql
@$SCRIPTS_DIR/L2-C_Triggers/T4_trg_mission_terminee.sql
@$SCRIPTS_DIR/L2-C_Triggers/T5_trg_historique_statut.sql

PROMPT ============================================================
PROMPT ÉTAPE 4 — Contrôle
PROMPT ============================================================
@$SCRIPTS_DIR/L2-D_Controle/controle_schema.sql

EXIT;
SQL

# ============================================================
# Résumé
# ============================================================
echo ""
echo "============================================================"
echo "Phase 2 déployée avec succès."
echo ""
echo "Connexion directe :"
echo "  docker exec -it $CONTAINER sqlplus $APP_USER/$APP_PASS@localhost:1521/$PDB"
echo ""
echo "Arrêter le conteneur :"
echo "  docker compose down"
echo ""
echo "Tout supprimer (données incluses) :"
echo "  docker compose down -v"
echo "============================================================"
