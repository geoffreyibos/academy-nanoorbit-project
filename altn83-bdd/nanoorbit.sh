#!/usr/bin/env bash
# nanoorbit.sh — Interface CLI interactive NanoOrbit
# Usage : bash nanoorbit.sh

# ── Configuration ─────────────────────────────────────────────────────────────
CONTAINER="nanoorbit-oracle"
SYS_PASS="Oracle2025"
APP_USER="NANOORBIT_ADMIN"
APP_PASS="NanoOrbit2025"
PDB="FREEPDB1"
SCRIPTS_DIR="/opt/oracle/livrables"
COMPOSE_FILE="$(dirname "$0")/docker-compose.yml"

# ── Couleurs & styles ──────────────────────────────────────────────────────────
R='\033[0;31m'   G='\033[0;32m'   Y='\033[1;33m'
B='\033[0;34m'   C='\033[0;36m'   M='\033[0;35m'
W='\033[1;37m'   DIM='\033[2m'    BOLD='\033[1m'
RST='\033[0m'

# ── Utilitaires ───────────────────────────────────────────────────────────────
clear_screen()  { clear; }
press_enter()   { echo -e "\n${DIM}  Appuyez sur Entrée pour continuer...${RST}"; read -r; }

line_thin()  { echo -e "${DIM}  ────────────────────────────────────────────────────${RST}"; }
line_thick() { echo -e "${B}  ════════════════════════════════════════════════════${RST}"; }

header() {
    clear_screen
    echo
    echo -e "${B}  ╔══════════════════════════════════════════════════╗${RST}"
    echo -e "${B}  ║${RST}  ${BOLD}${W}🛰  NanoOrbit — Oracle 23ai / ALTN83${RST}             ${B}║${RST}"
    echo -e "${B}  ╠══════════════════════════════════════════════════╣${RST}"
    printf  "  ${B}║${RST}  "
    container_status_inline
    printf  "  ${B}║${RST}\n"
    echo -e "${B}  ╚══════════════════════════════════════════════════╝${RST}"
    echo
}

container_status_inline() {
    local exists running health
    exists=$(docker ps -a --filter "name=^${CONTAINER}$" --format "{{.Names}}" 2>/dev/null)
    if [ -z "$exists" ]; then
        printf "${R}●${RST} Conteneur : ${R}inexistant${RST}%-26s" " "
        return
    fi
    running=$(docker inspect --format='{{.State.Running}}' "$CONTAINER" 2>/dev/null)
    health=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null)
    if [ "$running" = "true" ]; then
        if [ "$health" = "healthy" ]; then
            printf "${G}●${RST} Conteneur : ${G}en ligne${RST} ${DIM}(healthy)${RST}%-15s" " "
        else
            printf "${Y}●${RST} Conteneur : ${Y}démarrage${RST} ${DIM}($health)${RST}%-12s" " "
        fi
    else
        printf "${R}●${RST} Conteneur : ${R}arrêté${RST}%-28s" " "
    fi
}

step_msg()    { echo -e "\n  ${BOLD}${C}▶${RST} $1"; }
ok_msg()      { echo -e "  ${G}✓${RST}  $1"; }
warn_msg()    { echo -e "  ${Y}⚠${RST}  $1"; }
fail_msg()    { echo -e "  ${R}✗${RST}  $1"; }
info_msg()    { echo -e "  ${DIM}   $1${RST}"; }

confirm() {
    echo -e "\n  ${Y}?${RST}  $1 ${DIM}[o/N]${RST} "
    read -r -p "    → " ans
    [[ "$ans" =~ ^[oOyY]$ ]]
}

# ── Fonctions métier ───────────────────────────────────────────────────────────

wait_healthy() {
    step_msg "Attente Oracle (peut prendre 2-3 min au premier démarrage)..."
    local dots=0
    while true; do
        local s
        s=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || echo "starting")
        if [ "$s" = "healthy" ]; then break; fi
        printf "\r  ${Y}…${RST}  $(date +%H:%M:%S) — statut : %-12s" "$s"
        sleep 10
        (( dots++ ))
    done
    printf "\r%-60s\r" " "
    ok_msg "Base prête"
    sleep 5
}

grant_privileges() {
    step_msg "Octroi des privilèges à $APP_USER..."
    docker exec -i "$CONTAINER" sqlplus -s \
        "sys/$SYS_PASS@localhost:1521/$PDB as sysdba" << SQL
GRANT CREATE TABLE, CREATE SEQUENCE, CREATE TRIGGER, CREATE PROCEDURE,
      CREATE VIEW, CREATE MATERIALIZED VIEW, CREATE TYPE,
      UNLIMITED TABLESPACE TO NANOORBIT_ADMIN;
EXIT;
SQL
    ok_msg "Privilèges accordés"
}

run_script() {
    local label="$1" phase="$2"
    local script="$SCRIPTS_DIR/$phase/G06_DEBEURET_IBOS_LEROUX_NanoOrbit_$(echo "$phase" | tr '[:lower:]' '[:upper:]' | sed 's/PHASE/Phase/').sql"
    step_msg "Exécution $label..."
    line_thin
    docker exec "$CONTAINER" bash -c \
        "sqlplus -S $APP_USER/$APP_PASS@localhost:1521/$PDB @$script"
    local rc=$?
    line_thin
    if [ $rc -eq 0 ]; then
        ok_msg "$label terminée avec succès"
    else
        fail_msg "$label — erreur (code $rc)"
    fi
    return $rc
}

# ── Actions du menu ────────────────────────────────────────────────────────────

action_start() {
    header
    step_msg "Démarrage du conteneur Oracle 23ai..."
    docker compose -f "$COMPOSE_FILE" up -d --quiet-pull 2>&1 | grep -v "^$" || true
    ok_msg "Conteneur lancé"
    wait_healthy
    press_enter
}

action_stop() {
    header
    if confirm "Arrêter le conteneur (données conservées) ?"; then
        step_msg "Arrêt en cours..."
        docker compose -f "$COMPOSE_FILE" stop
        ok_msg "Conteneur arrêté"
    else
        warn_msg "Annulé"
    fi
    press_enter
}

action_reset() {
    header
    warn_msg "Cette opération ${BOLD}supprime toutes les données Oracle${RST} (volume -v)."
    if confirm "Confirmer le reset complet ?"; then
        step_msg "Suppression du conteneur et du volume..."
        docker compose -f "$COMPOSE_FILE" down -v
        ok_msg "Reset effectué — relancez 'Déploiement complet' pour réinitialiser"
    else
        warn_msg "Annulé"
    fi
    press_enter
}

action_deploy_all() {
    header
    step_msg "Déploiement complet : Phase 2 + Phase 3 + Phase 4"
    line_thin

    # Démarrage si besoin
    local running
    running=$(docker inspect --format='{{.State.Running}}' "$CONTAINER" 2>/dev/null)
    if [ "$running" != "true" ]; then
        step_msg "Démarrage du conteneur..."
        docker compose -f "$COMPOSE_FILE" up -d --quiet-pull 2>&1 | grep -v "^$" || true
        wait_healthy
    fi

    grant_privileges

    run_script "Phase 2 (DDL + DML + Triggers)"                   "phase2" || { press_enter; return; }
    run_script "Phase 3 (PL/SQL + Package)"                        "phase3" || { press_enter; return; }
    run_script "Phase 4 (Vues + CTE + Analytiques + MERGE + Index)" "phase4" \
        || warn_msg "Phase 4 terminée avec avertissements"

    echo
    echo -e "  ${G}${BOLD}╔══════════════════════════════════════╗${RST}"
    echo -e "  ${G}${BOLD}║  Déploiement complet réussi ✓        ║${RST}"
    echo -e "  ${G}${BOLD}╚══════════════════════════════════════╝${RST}"
    press_enter
}

action_phase2() {
    header

    local -a parts=(
        "p2_01_ddl|[1/6] DDL — Creation des 11 tables"
        "p2_02_dml|[2/6] DML — Donnees de reference"
        "p2_03_t1|[3/6] T1 — trg_valider_fenetre (RG-S06 + RG-G03)"
        "p2_04_t2|[4/6] T2 — trg_no_chevauchement (RG-F02 + RG-F03)"
        "p2_05_t3_t4|[5/6] T3 + T4 — volume_realise + mission_terminee"
        "p2_06_t5_controle|[6/6] T5 — historique_statut + controle schema"
    )
    local total=${#parts[@]}
    local i=0

    for entry in "${parts[@]}"; do
        (( i++ ))
        local file="${entry%%|*}"
        local label="${entry#*|}"

        echo
        echo -e "  ${B}════════════════════════════════════════════════════${RST}"
        echo -e "  ${BOLD}${W}  Phase 2 — $label${RST}"
        echo -e "  ${B}════════════════════════════════════════════════════${RST}"
        line_thin
        docker exec "$CONTAINER" bash -c \
            "sqlplus -S $APP_USER/$APP_PASS@localhost:1521/$PDB @$SCRIPTS_DIR/phase2/parts/$file.sql"
        line_thin

        if [ $i -lt $total ]; then
            local next_label="${parts[$i]#*|}"
            echo -e "\n  ${DIM}  Suivant → $next_label${RST}"
            press_enter
            clear_screen
            header
        fi
    done

    echo
    ok_msg "Phase 2 — tous les paliers exécutés"
    press_enter
}

action_phase3() {
    header

    local -a parts=(
        "p3_01_blocs_anonymes|[1/6] Blocs anonymes (Ex.1 à 2)"
        "p3_02_variables_types|[2/6] Variables et types — %TYPE, %ROWTYPE, NVL (Ex.3 à 4)"
        "p3_03_controle|[3/6] Structures de contrôle — IF, CASE, LOOP (Ex.5 à 7)"
        "p3_04_curseurs|[4/6] Curseurs — implicite, FOR, explicite, paramétré (Ex.8 à 11)"
        "p3_05_procedures|[5/6] Procédures et fonctions standalone (Ex.12 à 16)"
        "p3_06_package|[6/6] Package pkg_nanoOrbit + scénario de validation (BONUS)"
    )
    local total=${#parts[@]}
    local i=0

    for entry in "${parts[@]}"; do
        (( i++ ))
        local file="${entry%%|*}"
        local label="${entry#*|}"

        echo
        echo -e "  ${B}════════════════════════════════════════════════════${RST}"
        echo -e "  ${BOLD}${W}  Phase 3 — $label${RST}"
        echo -e "  ${B}════════════════════════════════════════════════════${RST}"
        line_thin
        docker exec "$CONTAINER" bash -c \
            "sqlplus -S $APP_USER/$APP_PASS@localhost:1521/$PDB @$SCRIPTS_DIR/phase3/parts/$file.sql"
        line_thin

        if [ $i -lt $total ]; then
            local next_label="${parts[$i]#*|}"
            echo -e "\n  ${DIM}  Suivant → $next_label${RST}"
            press_enter
            clear_screen
            header
        fi
    done

    echo
    ok_msg "Phase 3 — tous les paliers exécutés"
    press_enter
}

action_phase4() {
    header

    local -a parts=(
        "p4_01_vues|[1/7] Vues — CREATE VIEW (V1 à V4)"
        "p4_02_cte|[2/7] CTE avec WITH … AS (Ex.5 à 7)"
        "p4_03_sousrequetes|[3/7] Sous-requêtes avancées (Ex.8 à 10)"
        "p4_04_analytiques|[4/7] Fonctions analytiques OVER (Ex.11 à 14)"
        "p4_05_merge|[5/7] MERGE INTO (Ex.15 à 16)"
        "p4_06_index|[6/7] Index et EXPLAIN PLAN (Ex.17 à 19)"
        "p4_07_rapport|[7/7] Rapport de pilotage final"
    )
    local total=${#parts[@]}
    local i=0

    for entry in "${parts[@]}"; do
        (( i++ ))
        local file="${entry%%|*}"
        local label="${entry#*|}"

        echo
        echo -e "  ${B}════════════════════════════════════════════════════${RST}"
        echo -e "  ${BOLD}${W}  Phase 4 — $label${RST}"
        echo -e "  ${B}════════════════════════════════════════════════════${RST}"
        line_thin
        docker exec "$CONTAINER" bash -c \
            "sqlplus -S $APP_USER/$APP_PASS@localhost:1521/$PDB @$SCRIPTS_DIR/phase4/parts/$file.sql"
        line_thin

        if [ $i -lt $total ]; then
            local next_label="${parts[$i]#*|}"
            echo -e "\n  ${DIM}  Suivant → $next_label${RST}"
            press_enter
            clear_screen
            header
        fi
    done

    echo
    ok_msg "Phase 4 — toutes les parties exécutées"
    press_enter
}

action_connect() {
    header
    step_msg "Ouverture de SQL*Plus interactif..."
    info_msg "Connexion : $APP_USER @ $PDB"
    info_msg "Tapez EXIT; pour revenir au menu"
    line_thin
    docker exec -it "$CONTAINER" \
        sqlplus "$APP_USER/$APP_PASS@localhost:1521/$PDB"
    line_thin
    press_enter
}

action_logs() {
    header
    step_msg "Logs du conteneur (50 dernières lignes)"
    line_thin
    docker logs --tail 50 "$CONTAINER" 2>&1
    line_thin
    press_enter
}

action_status() {
    header
    step_msg "Détail du conteneur"
    line_thin
    local exists
    exists=$(docker ps -a --filter "name=^${CONTAINER}$" --format "{{.Names}}" 2>/dev/null)
    if [ -z "$exists" ]; then
        warn_msg "Le conteneur n'existe pas. Lancez 'Démarrer' ou 'Déploiement complet'."
    else
        local state image created ports health
        state=$(docker inspect --format='{{.State.Status}}'        "$CONTAINER")
        health=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || echo "n/a")
        image=$(docker inspect --format='{{.Config.Image}}'        "$CONTAINER")
        created=$(docker inspect --format='{{.Created}}'           "$CONTAINER" | cut -c1-19 | tr 'T' ' ')
        ports=$(docker port "$CONTAINER" 2>/dev/null | tr '\n' ' ')
        info_msg "Image    : ${W}$image${RST}"
        info_msg "État     : ${W}$state${RST} / health: ${W}$health${RST}"
        info_msg "Créé     : ${W}$created${RST}"
        info_msg "Ports    : ${W}$ports${RST}"
        echo
        step_msg "Tables NANOORBIT_ADMIN"
        line_thin
        docker exec "$CONTAINER" bash -c \
            "sqlplus -S $APP_USER/$APP_PASS@localhost:1521/$PDB <<'SQL'
SET PAGESIZE 40
SET LINESIZE 80
SET FEEDBACK OFF
SELECT TABLE_NAME, NUM_ROWS
FROM USER_TABLES
ORDER BY TABLE_NAME;
EXIT;
SQL" 2>/dev/null || warn_msg "Base non disponible"
    fi
    line_thin
    press_enter
}

# ── Menu principal ─────────────────────────────────────────────────────────────

menu() {
    while true; do
        header
        echo -e "  ${BOLD}${W}Conteneur${RST}                         ${BOLD}${W}Scripts — phases${RST}"
        line_thin

        echo -e "  ${C}1${RST}  Démarrer le conteneur          ${C}4${RST}  Phase 2 interactive ${DIM}(palier par palier)${RST}"
        echo -e "  ${C}2${RST}  Arrêter le conteneur           ${C}5${RST}  Phase 3 interactive ${DIM}(palier par palier)${RST}"
        echo -e "  ${C}3${RST}  Reset complet ${DIM}(down -v)${RST}        ${C}6${RST}  Phase 4 interactive ${DIM}(partie par partie)${RST}"
        echo -e "                                 ${C}7${RST}  Déploiement complet ${DIM}(2 + 3 + 4)${RST}"
        echo
        echo -e "  ${BOLD}${W}Oracle${RST}"
        line_thin
        echo -e "  ${C}8${RST}  Connexion SQL*Plus interactive"
        echo -e "  ${C}9${RST}  Statut & tables du schéma"
        echo -e "  ${C}0${RST}  Logs du conteneur"
        echo
        line_thin
        echo -e "  ${R}q${RST}  Quitter"
        echo
        read -r -p "  Choix → " choice
        case "$choice" in
            1) action_start      ;;
            2) action_stop       ;;
            3) action_reset      ;;
            4) action_phase2     ;;
            5) action_phase3     ;;
            6) action_phase4     ;;
            7) action_deploy_all ;;
            8) action_connect    ;;
            9) action_status     ;;
            0) action_logs       ;;
            q|Q) clear_screen; echo -e "  ${DIM}À bientôt.${RST}\n"; exit 0 ;;
            *) warn_msg "Option invalide"; sleep 1 ;;
        esac
    done
}

# ── Point d'entrée ─────────────────────────────────────────────────────────────
cd "$(dirname "$0")" || exit 1
menu
