-- ============================================================
-- Phase 4 — Partie 2/7 : CTE avec WITH … AS
-- Prérequis : Partie 1 executee (vues creees)
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 50
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

COLUMN id_satellite             FORMAT A10
COLUMN nom_satellite            FORMAT A20
COLUMN nom_station              FORMAT A25
COLUMN nom_centre               FORMAT A22
COLUMN id_mission               FORMAT A14
COLUMN nom_mission              FORMAT A20
COLUMN statut_mission           FORMAT A12
COLUMN orbite                   FORMAT A14
COLUMN types_orbites            FORMAT A10
COLUMN statut                   FORMAT A14
COLUMN date_debut               FORMAT A16
COLUMN duree_fmt                FORMAT A10
COLUMN debut                    FORMAT A16
COLUMN derniere_fenetre         FORMAT A16
COLUMN code_station             FORMAT A12
COLUMN id_orbite                FORMAT A8
COLUMN id_centre                FORMAT A8
COLUMN station_la_plus_active   FORMAT A25
COLUMN satellites_operationnels FORMAT A20
COLUMN satellites_actifs        FORMAT A20
COLUMN commentaire              FORMAT A52
COLUMN libelle                  FORMAT A70
COLUMN index_name               FORMAT A32
COLUMN index_type               FORMAT A22
COLUMN table_name               FORMAT A20
COLUMN plan_table_output        FORMAT A120
COLUMN "EVOL_VS_MOIS_PREC"      FORMAT A16
COLUMN mois                     FORMAT A7
COLUMN vol_precedent_mo         HEADING "VOL_PREC_MO"  FORMAT 99999
COLUMN vol_suivant_mo           HEADING "VOL_SUIV_MO"  FORMAT 99999
COLUMN evolution_pct            HEADING "EVOL_%"       FORMAT 9999.9
COLUMN volume_total_mo          FORMAT 99999
COLUMN volume_donnees_mo        FORMAT 99999
COLUMN volume_mo                FORMAT 99999
COLUMN volume_moyen_mo          FORMAT 99999.9
COLUMN cumul_mo                 FORMAT 99999
COLUMN moy_mobile_3             FORMAT 99999.9
COLUMN moy_constellation_mo     FORMAT 99999.9
COLUMN ecart_moyenne            FORMAT 99999
COLUMN ecart_moyenne_mo         FORMAT 99999.9
COLUMN part_pct                 HEADING "PART_%"       FORMAT 999.9
COLUMN nb_instruments           FORMAT 99    HEADING "NB_INST"
COLUMN nb_fenetres              FORMAT 999
COLUMN nb_satellites            FORMAT 99    HEADING "NB_SATS"
COLUMN nb_fenetres_realisees    FORMAT 99    HEADING "NB_FEN"
COLUMN batterie_wh              FORMAT 9999
COLUMN rang                     FORMAT 999
COLUMN rang_global              FORMAT 999
COLUMN dense_rang               FORMAT 999
COLUMN rang_par_orbite          FORMAT 999
COLUMN row_num                  FORMAT 999
COLUMN type_orbite              FORMAT A6   HEADING "TYPE"
COLUMN "PART_%"                 FORMAT 999.9
COLUMN status                   FORMAT A8
COLUMN date_aff                 FORMAT A12
COLUMN ancien_statut            FORMAT A14  HEADING "ANCIEN_STATUT"
COLUMN nouveau_statut           FORMAT A14  HEADING "NOUVEAU_STATUT"
COLUMN date_chgt                FORMAT A20

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 4 — [2/7] CTE avec WITH … AS
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT Ex.5 — CTE simple : Top 3 satellites par volume telecharge
-- ────────────────────────────────────────────────────────────
-- Resultat attendu : SAT-003 (1680), SAT-001 (1250), SAT-002 (890)
WITH stats_sat AS (
    SELECT
        s.id_satellite,
        s.nom_satellite,
        COUNT(f.id_fenetre) AS nb_fenetres_realisees,
        SUM(f.volume_donnees_mo) AS volume_total_mo,
        ROUND(AVG(f.volume_donnees_mo), 1) AS volume_moyen_mo
    FROM SATELLITE s
    JOIN FENETRE_COM f ON s.id_satellite = f.id_satellite
    WHERE f.statut = 'Réalisée'
    GROUP BY s.id_satellite, s.nom_satellite
)
SELECT id_satellite, nom_satellite,
       nb_fenetres_realisees, volume_total_mo, volume_moyen_mo
FROM stats_sat
ORDER BY volume_total_mo DESC
FETCH FIRST 3 ROWS ONLY;


-- ────────────────────────────────────────────────────────────
PROMPT Ex.6 — CTE multiples : Analyse comparative par centre de controle
-- ────────────────────────────────────────────────────────────
-- CTR-002 (Houston) n'apparait pas : GS-SGP-01 en Maintenance, aucune fenetre realisee.
WITH fenetres_par_centre AS (
    SELECT
        a.id_centre,
        c.nom_centre,
        f.id_fenetre,
        f.code_station,
        f.volume_donnees_mo
    FROM FENETRE_COM f
    JOIN STATION_SOL st ON f.code_station = st.code_station
    JOIN AFFECTATION_STATION a ON st.code_station = a.code_station
    JOIN CENTRE_CONTROLE c ON a.id_centre = c.id_centre
    WHERE f.statut = 'Réalisée'
),
stats_centre AS (
    SELECT
        id_centre,
        nom_centre,
        COUNT(id_fenetre) AS nb_fenetres,
        SUM(volume_donnees_mo) AS volume_total_mo
    FROM fenetres_par_centre
    GROUP BY id_centre, nom_centre
),
stations_rang AS (
    SELECT
        a.id_centre,
        st.nom_station,
        COUNT(f.id_fenetre) AS nb_fenetres_sta,
        RANK() OVER (
            PARTITION BY a.id_centre
            ORDER BY COUNT(f.id_fenetre) DESC
        ) AS rang
    FROM STATION_SOL st
    JOIN AFFECTATION_STATION a ON st.code_station = a.code_station
    LEFT JOIN FENETRE_COM f ON st.code_station = f.code_station
                           AND f.statut = 'Réalisée'
    GROUP BY a.id_centre, st.nom_station
)
SELECT
    sc.nom_centre,
    sc.nb_fenetres,
    sc.volume_total_mo,
    sr.nom_station AS station_la_plus_active
FROM stats_centre sc
LEFT JOIN stations_rang sr ON sc.id_centre = sr.id_centre AND sr.rang = 1
ORDER BY sc.volume_total_mo DESC NULLS LAST;


-- ────────────────────────────────────────────────────────────
PROMPT Ex.7 — CTE recursive : Hierarchie Centre -) Station -) Fenetres
PROMPT         (Oracle exige exactement 2 branches UNION ALL — erreur attendue)
-- ────────────────────────────────────────────────────────────
-- ORA-32041 : UNION ALL recursif limité à 2 branches sous Oracle.
-- La CTE ci-dessous en a 3 (ancre + niveau 1 + niveau 2) — erreur documentée.
WITH hier (niveau, id_noeud, libelle, cle_tri) AS (
    SELECT
        0,
        id_centre,
        CAST(nom_centre AS VARCHAR2(300)),
        CAST(id_centre AS VARCHAR2(300))
    FROM CENTRE_CONTROLE

    UNION ALL

    SELECT
        h.niveau + 1,
        a.code_station,
        CAST(LPAD(' ', 4) || 'r- ' || st.nom_station ||
             ' [' || st.statut || ']' AS VARCHAR2(300)),
        h.cle_tri || '|' || a.code_station
    FROM hier h
    JOIN AFFECTATION_STATION a ON h.id_noeud = a.id_centre
    JOIN STATION_SOL st ON a.code_station = st.code_station
    WHERE h.niveau = 0

    UNION ALL

    SELECT
        h.niveau + 1,
        TO_CHAR(f.id_fenetre),
        CAST(LPAD(' ', 8) || 'L- FEN-' || LPAD(f.id_fenetre, 3, '0') ||
             ' · ' || f.id_satellite ||
             ' · ' || TO_CHAR(f.datetime_debut, 'DD/MM/YYYY HH24:MI') ||
             CASE WHEN f.volume_donnees_mo IS NOT NULL
                  THEN ' (' || f.volume_donnees_mo || ' Mo)'
                  ELSE ' (planifiee)'
             END AS VARCHAR2(300)),
        h.cle_tri || '|' || TO_CHAR(f.id_fenetre)
    FROM hier h
    JOIN FENETRE_COM f ON h.id_noeud = f.code_station
    WHERE h.niveau = 1
)
CYCLE id_noeud SET is_cycle TO '1' DEFAULT '0'
SELECT libelle
FROM hier
WHERE is_cycle = '0'
ORDER BY cle_tri;

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Partie 2/7 terminee.
PROMPT ────────────────────────────────────────────
PROMPT
