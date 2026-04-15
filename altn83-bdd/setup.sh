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

echo "  Base prête. Stabilisation (15s)..."
sleep 15

# ============================================================
# 3. Création de l'utilisateur NANOORBIT_ADMIN
# ============================================================
echo ""
echo "=== 3/4 Création de l'utilisateur $APP_USER ==="


# L'image gvenzl crée automatiquement APP_USER avec des privilèges de base.
# On ajoute ici les privilèges supplémentaires nécessaires.
docker exec -i "$CONTAINER" sqlplus -s "sys/$SYS_PASS@localhost:1521/$PDB as sysdba" << SQL
GRANT CREATE TABLE     TO NANOORBIT_ADMIN;
GRANT CREATE SEQUENCE  TO NANOORBIT_ADMIN;
GRANT CREATE TRIGGER   TO NANOORBIT_ADMIN;
GRANT CREATE PROCEDURE TO NANOORBIT_ADMIN;
GRANT CREATE VIEW      TO NANOORBIT_ADMIN;
GRANT CREATE TYPE      TO NANOORBIT_ADMIN;
GRANT UNLIMITED TABLESPACE TO NANOORBIT_ADMIN;
PROMPT Privileges accordes a NANOORBIT_ADMIN.
EXIT;
SQL

echo "  Utilisateur créé."

# ============================================================
# 4. Exécution de la Phase 2
# ============================================================
echo ""
echo "=== 4/4 Exécution des scripts Phase 2 ==="

# On appelle sqlplus directement avec le fichier maître (@@).
# Passer des @file dans un heredoc casse le buffer multi-lignes
# de SQL*Plus — les CREATE TABLE perdent leurs contraintes.
if ! docker exec "$CONTAINER" bash -c \
    "cd $SCRIPTS_DIR && sqlplus $APP_USER/$APP_PASS@localhost:1521/$PDB @run_phase2.sql"; then
    echo ""
    echo "============================================================"
    echo "ERREUR : L'exécution SQL a échoué."
    echo "Consultez la sortie ci-dessus pour identifier le problème."
    echo "============================================================"
    exit 1
fi

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
