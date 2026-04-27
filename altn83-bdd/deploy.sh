#!/usr/bin/env bash
# deploy.sh — NanoOrbit : déploiement complet (Phase 2 + Phase 3)
# Usage : bash deploy.sh

set -e

CONTAINER="nanoorbit-oracle"
SYS_PASS="Oracle2025"
APP_USER="NANOORBIT_ADMIN"
APP_PASS="NanoOrbit2025"
PDB="FREEPDB1"
SCRIPTS_DIR="/opt/oracle/livrables"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

step()  { echo -e "\n${BOLD}${BLUE}[$1/5]${RESET} $2"; }
ok()    { echo -e "  ${GREEN}✓${RESET} $1"; }
wait()  { echo -e "  ${YELLOW}…${RESET} $1"; }
fail()  { echo -e "\n${RED}✗ ERREUR : $1${RESET}\n"; exit 1; }

echo -e "\n${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║     NanoOrbit — Déploiement complet      ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"

# ── 1. Démarrage ──────────────────────────────────────────────
step 1 "Démarrage du conteneur Oracle 23ai"
docker compose up -d --quiet-pull 2>&1 | grep -v "^$" || true
ok "Conteneur démarré"

# ── 2. Attente healthy ────────────────────────────────────────
step 2 "Attente de la base de données  (2-3 min à la première init)"
while true; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || echo "starting")
    if [ "$STATUS" = "healthy" ]; then break; fi
    wait "$(date +%H:%M:%S) — statut : $STATUS"
    sleep 15
done
ok "Base prête — stabilisation 15s..."
sleep 15

# ── 3. Privilèges ─────────────────────────────────────────────
step 3 "Octroi des privilèges à $APP_USER"
docker exec -i "$CONTAINER" sqlplus -s "sys/$SYS_PASS@localhost:1521/$PDB as sysdba" << SQL
GRANT CREATE TABLE, CREATE SEQUENCE, CREATE TRIGGER, CREATE PROCEDURE,
      CREATE VIEW, CREATE TYPE, UNLIMITED TABLESPACE TO NANOORBIT_ADMIN;
EXIT;
SQL
ok "Privilèges accordés"

# ── 4. Phase 2 ────────────────────────────────────────────────
step 4 "Phase 2 — DDL + DML + Triggers"
echo -e "  ${YELLOW}──────────────────────────────────────────${RESET}"
docker exec "$CONTAINER" bash -c \
    "sqlplus -S $APP_USER/$APP_PASS@localhost:1521/$PDB @$SCRIPTS_DIR/phase2/G06_DEBEURET_IBOS_LEROUX_NanoOrbit_Phase2.sql" \
    || fail "Phase 2 échouée — consultez la sortie ci-dessus."
echo -e "  ${YELLOW}──────────────────────────────────────────${RESET}"
ok "Phase 2 terminée"

# ── 5. Phase 3 ────────────────────────────────────────────────
step 5 "Phase 3 — PL/SQL + Package pkg_nanoOrbit"
echo -e "  ${YELLOW}──────────────────────────────────────────${RESET}"
docker exec "$CONTAINER" bash -c \
    "sqlplus -S $APP_USER/$APP_PASS@localhost:1521/$PDB @$SCRIPTS_DIR/phase3/G06_DEBEURET_IBOS_LEROUX_NanoOrbit_Phase3.sql" \
    || fail "Phase 3 échouée — consultez la sortie ci-dessus."
echo -e "  ${YELLOW}──────────────────────────────────────────${RESET}"
ok "Phase 3 terminée"

# ── Résumé ────────────────────────────────────────────────────
echo -e "\n${BOLD}${GREEN}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║   Déploiement réussi — Phases 2 & 3     ║${RESET}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════╝${RESET}"
echo -e "\n  Connexion :  ${BOLD}docker exec -it $CONTAINER sqlplus $APP_USER/$APP_PASS@localhost:1521/$PDB${RESET}"
echo -e "  Arrêter  :  docker compose down"
echo -e "  Reset    :  docker compose down -v\n"
