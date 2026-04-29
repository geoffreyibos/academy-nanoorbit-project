-- ============================================================
-- Phase 4 — Partie 1/7 : Vues (CREATE VIEW + vue matérialisée)
-- Prérequis : Phase 2 et Phase 3 exécutées
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
PROMPT  Phase 4 — [1/7] Vues (CREATE VIEW)
PROMPT ════════════════════════════════════════════
PROMPT

-- Nettoyage idempotent : suppression des objets Phase 4
BEGIN EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_volumes_mensuels'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_stats_missions';            EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_fenetres_detail';           EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW v_satellites_operationnels';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_fenetre_satellite';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_fenetre_station';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_fenetre_mois';           EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_participation_mission';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_satellite_statut';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_satellite_statut_orbite'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ────────────────────────────────────────────────────────────
PROMPT V1 — v_satellites_operationnels
PROMPT      Satellites operationnels : orbite, nb instruments, batterie
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_satellites_operationnels AS
SELECT
    s.id_satellite,
    s.nom_satellite,
    o.type_orbite || ' ' || o.altitude_km || ' km' AS orbite,
    o.periode_min AS periode_min,
    COUNT(e.ref_instrument) AS nb_instruments,
    s.capacite_batterie_wh AS batterie_wh,
    s.statut
FROM SATELLITE s
JOIN ORBITE o ON s.id_orbite = o.id_orbite
LEFT JOIN EMBARQUEMENT e ON s.id_satellite = e.id_satellite
WHERE s.statut = 'Opérationnel'
GROUP BY s.id_satellite, s.nom_satellite, o.type_orbite, o.altitude_km,
         o.periode_min, s.capacite_batterie_wh, s.statut;
/
SHOW ERRORS

SELECT id_satellite, nom_satellite, orbite, nb_instruments, batterie_wh
FROM v_satellites_operationnels
ORDER BY id_satellite;


-- ────────────────────────────────────────────────────────────
PROMPT V2 — v_fenetres_detail
PROMPT      Fenetres avec satellite, station, centre, duree formatee, volume
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_fenetres_detail AS
SELECT
    f.id_fenetre,
    s.nom_satellite,
    s.id_satellite,
    st.nom_station,
    st.code_station,
    c.nom_centre,
    TO_CHAR(f.datetime_debut, 'DD/MM/YYYY HH24:MI') AS date_debut,
    FLOOR(f.duree_secondes / 60) || 'min ' || MOD(f.duree_secondes, 60) || 's' AS duree_fmt,
    f.duree_secondes,
    f.elevation_max_deg,
    f.volume_donnees_mo,
    f.statut
FROM FENETRE_COM f
JOIN SATELLITE s ON f.id_satellite = s.id_satellite
JOIN STATION_SOL st ON f.code_station = st.code_station
JOIN AFFECTATION_STATION a ON st.code_station = a.code_station
JOIN CENTRE_CONTROLE c ON a.id_centre = c.id_centre;
/
SHOW ERRORS

SELECT id_fenetre, nom_satellite, nom_station, nom_centre,
       date_debut, duree_fmt, volume_donnees_mo, statut
FROM v_fenetres_detail
ORDER BY id_fenetre;


-- ────────────────────────────────────────────────────────────
PROMPT V3 — v_stats_missions
PROMPT      Par mission : nb satellites, types orbites, volume total
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_stats_missions AS
SELECT
    m.id_mission,
    m.nom_mission,
    m.statut_mission,
    COUNT(DISTINCT p.id_satellite) AS nb_satellites,
    LISTAGG(DISTINCT o.type_orbite, ', ')
        WITHIN GROUP (ORDER BY o.type_orbite) AS types_orbites,
    NVL(SUM(f.volume_donnees_mo), 0) AS volume_total_mo
FROM MISSION m
LEFT JOIN PARTICIPATION p ON m.id_mission = p.id_mission
LEFT JOIN SATELLITE s ON p.id_satellite = s.id_satellite
LEFT JOIN ORBITE o ON s.id_orbite = o.id_orbite
LEFT JOIN FENETRE_COM f ON s.id_satellite = f.id_satellite
                       AND f.statut = 'Réalisée'
GROUP BY m.id_mission, m.nom_mission, m.statut_mission;
/
SHOW ERRORS

SELECT id_mission, nom_mission, statut_mission, nb_satellites,
       types_orbites, volume_total_mo
FROM v_stats_missions
ORDER BY id_mission;


-- ────────────────────────────────────────────────────────────
PROMPT V4 — mv_volumes_mensuels (bonus)
PROMPT      Vue materialisee : volumes par mois / centre / type orbite
-- ────────────────────────────────────────────────────────────
CREATE MATERIALIZED VIEW mv_volumes_mensuels
REFRESH ON DEMAND
AS
SELECT
    TRUNC(f.datetime_debut, 'MM') AS mois,
    c.id_centre,
    c.nom_centre,
    o.type_orbite,
    COUNT(*) AS nb_fenetres,
    SUM(f.volume_donnees_mo) AS volume_total_mo,
    ROUND(AVG(f.volume_donnees_mo), 1) AS volume_moyen_mo
FROM FENETRE_COM f
JOIN SATELLITE s ON f.id_satellite = s.id_satellite
JOIN ORBITE o ON s.id_orbite = o.id_orbite
JOIN STATION_SOL st ON f.code_station = st.code_station
JOIN AFFECTATION_STATION a ON st.code_station = a.code_station
JOIN CENTRE_CONTROLE c ON a.id_centre = c.id_centre
WHERE f.statut = 'Réalisée'
GROUP BY TRUNC(f.datetime_debut, 'MM'), c.id_centre, c.nom_centre, o.type_orbite;

SELECT TO_CHAR(mois, 'MM/YYYY') AS mois, nom_centre, type_orbite,
       nb_fenetres, volume_total_mo, volume_moyen_mo
FROM mv_volumes_mensuels;

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Partie 1/7 terminee.
PROMPT ────────────────────────────────────────────
PROMPT
