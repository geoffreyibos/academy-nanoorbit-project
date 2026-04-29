-- ============================================================
-- Projet NanoOrbit — Phase 4 : Exploitation avancée & Optimisation
-- Groupe    : 06
-- Membres   : Oscar DEBEURET / Geoffrey IBOS / Hugo LEROUX
-- Date      : 2026-04-27
-- SGBD      : Oracle 23ai — NANOORBIT_ADMIN / FREEPDB1
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 50
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

-- Formatage des colonnes (valable pour toute la session SQL*Plus)
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
PROMPT  Phase 4 — NanoOrbit  (Vues · CTE · Analytiques · MERGE · Index)
PROMPT ════════════════════════════════════════════
PROMPT

-- ============================================================
-- Nettoyage idempotent : suppression des objets Phase 4
-- avant recréation (pour exécutions répétées)
-- ============================================================
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

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  [PARTIE 1] Vues (CREATE VIEW)
PROMPT ════════════════════════════════════════════


-- ============================================================
PROMPT
PROMPT V1 — v_satellites_operationnels
PROMPT      Satellites opérationnels : orbite, nb instruments, batterie
-- ============================================================
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

-- Test V1 — résultat attendu : SAT-001 (2 inst.), SAT-002 (1), SAT-003 (2)
SELECT id_satellite, nom_satellite, orbite, nb_instruments, batterie_wh
FROM v_satellites_operationnels
ORDER BY id_satellite;


-- ============================================================
PROMPT
PROMPT V2 — v_fenetres_detail
PROMPT      Fenêtres avec satellite, station, centre, durée formatée, volume
-- ============================================================
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

-- Test V2 — résultat attendu : 5 fenêtres (3 réalisées, 2 planifiées)
SELECT id_fenetre, nom_satellite, nom_station, nom_centre,
       date_debut, duree_fmt, volume_donnees_mo, statut
FROM v_fenetres_detail
ORDER BY id_fenetre;


-- ============================================================
PROMPT
PROMPT V3 — v_stats_missions
PROMPT      Par mission : nb satellites, types orbites, volume total
-- ============================================================
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

-- Test V3
-- MSN-ARC-2023  : 3 satellites (SAT-001/002/003), SSO, volume 1250+1680=2930 Mo
-- MSN-DEF-2022  : 2 satellites (SAT-001/005), SSO+LEO, volume 1250 Mo
-- MSN-COAST-2024: 2 satellites (SAT-003/004), SSO, volume 1680 Mo
SELECT id_mission, nom_mission, statut_mission, nb_satellites,
       types_orbites, volume_total_mo
FROM v_stats_missions
ORDER BY id_mission;


-- ============================================================
PROMPT
PROMPT V4 — mv_volumes_mensuels (bonus)
PROMPT      Vue matérialisée : volumes par mois / centre / type orbite
-- ============================================================
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

-- Test V4 — résultat attendu : 1 ligne (janv. 2024, CTR-001, SSO)
SELECT TO_CHAR(mois, 'MM/YYYY') AS mois, nom_centre, type_orbite,
       nb_fenetres, volume_total_mo, volume_moyen_mo
FROM mv_volumes_mensuels;


PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  [PARTIE 2] CTE avec WITH … AS
PROMPT ════════════════════════════════════════════


-- ============================================================
PROMPT
PROMPT Ex.5 — CTE simple : Top 3 satellites par volume téléchargé
-- ============================================================
-- Résultat attendu : SAT-003 (1680), SAT-001 (1250), SAT-002 (890)
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


-- ============================================================
PROMPT
PROMPT Ex.6 — CTE multiples : Analyse comparative par centre de contrôle
-- ============================================================
-- Note : les fenêtres du jeu de référence datent de janvier 2024.
-- Le filtre porte sur toutes les données disponibles (sans restriction de mois).
-- CTR-002 (Houston) n'apparaît pas : GS-SGP-01 est en Maintenance, aucune fenêtre réalisée.
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


-- ============================================================
PROMPT
PROMPT Ex.7 — CTE récursive : Hiérarchie Centre → Station → Fenêtres
PROMPT         avec indentation LPAD et clause CYCLE (Oracle 11g+)
-- ============================================================
-- Structure : CTR-001 (Paris)
--               ├─ GS-TLS-01 [Active]
--               │     └─ FEN-002 · SAT-002 · 15/01/2024 ...
--               │     └─ FEN-004 · SAT-001 · 20/01/2024 ...
--               ├─ GS-KIR-01 [Active]
--               │     └─ FEN-001 · SAT-001 ...
--               └─ ...
WITH hier (niveau, id_noeud, libelle, cle_tri) AS (
    -- Ancre : centres de contrôle (niveau 0)
    SELECT
        0,
        id_centre,
        CAST(nom_centre AS VARCHAR2(300)),
        CAST(id_centre AS VARCHAR2(300))
    FROM CENTRE_CONTROLE

    UNION ALL

    -- Récursion niveau 1 : stations rattachées au centre
    SELECT
        h.niveau + 1,
        a.code_station,
        CAST(LPAD(' ', 4) || '├─ ' || st.nom_station ||
             ' [' || st.statut || ']' AS VARCHAR2(300)),
        h.cle_tri || '|' || a.code_station
    FROM hier h
    JOIN AFFECTATION_STATION a ON h.id_noeud = a.id_centre
    JOIN STATION_SOL st ON a.code_station = st.code_station
    WHERE h.niveau = 0

    UNION ALL

    -- Récursion niveau 2 : fenêtres de la station
    SELECT
        h.niveau + 1,
        TO_CHAR(f.id_fenetre),
        CAST(LPAD(' ', 8) || '└─ FEN-' || LPAD(f.id_fenetre, 3, '0') ||
             ' · ' || f.id_satellite ||
             ' · ' || TO_CHAR(f.datetime_debut, 'DD/MM/YYYY HH24:MI') ||
             CASE WHEN f.volume_donnees_mo IS NOT NULL
                  THEN ' (' || f.volume_donnees_mo || ' Mo)'
                  ELSE ' (planifiée)'
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
PROMPT ════════════════════════════════════════════
PROMPT  [PARTIE 3] Sous-requêtes avancées
PROMPT ════════════════════════════════════════════


-- ============================================================
PROMPT
PROMPT Ex.8 — Sous-requête scalaire : fenêtres > moyenne, écart affiché
-- ============================================================
-- Moyenne réalisées = (1250 + 890 + 1680) / 3 = 1273.3 Mo
-- Résultat attendu : FEN-003 (SAT-003, 1680 Mo, écart +406.7 Mo)
SELECT
    f.id_fenetre,
    f.id_satellite,
    f.code_station,
    f.volume_donnees_mo,
    ROUND(
        f.volume_donnees_mo -
        (SELECT AVG(volume_donnees_mo) FROM FENETRE_COM WHERE statut = 'Réalisée'),
        1
    ) AS ecart_moyenne_mo
FROM FENETRE_COM f
WHERE f.statut = 'Réalisée'
  AND f.volume_donnees_mo >
      (SELECT AVG(volume_donnees_mo) FROM FENETRE_COM WHERE statut = 'Réalisée')
ORDER BY f.volume_donnees_mo DESC;


-- ============================================================
PROMPT
PROMPT Ex.9 — Sous-requête corrélée : dernière fenêtre réalisée par satellite
-- ============================================================
-- Résultat attendu : SAT-001 (KIR-01, 15/01/2024, 1250 Mo)
--                   SAT-002 (TLS-01, 15/01/2024,  890 Mo)
--                   SAT-003 (KIR-01, 16/01/2024, 1680 Mo)
SELECT
    s.id_satellite,
    s.nom_satellite,
    f.code_station,
    TO_CHAR(f.datetime_debut, 'DD/MM/YYYY HH24:MI') AS derniere_fenetre,
    f.volume_donnees_mo AS volume_mo
FROM SATELLITE s
JOIN FENETRE_COM f ON s.id_satellite = f.id_satellite
WHERE f.statut = 'Réalisée'
  AND f.datetime_debut = (
      SELECT MAX(f2.datetime_debut)
      FROM FENETRE_COM f2
      WHERE f2.id_satellite = s.id_satellite   -- corrélation
        AND f2.statut = 'Réalisée'
  )
ORDER BY s.id_satellite;


-- ============================================================
PROMPT
PROMPT Ex.10 — EXISTS / NOT EXISTS
-- ============================================================

-- Satellites sans aucune fenêtre réalisée
-- Résultat attendu : SAT-004 (En veille), SAT-005 (Désorbité)
-- SAT-004 est en veille, aucune fenêtre planifiée ou réalisée
-- SAT-005 est désorbité, le trigger T1 bloque toute insertion
PROMPT Satellites sans fenetre realisee :
SELECT s.id_satellite, s.nom_satellite, s.statut
FROM SATELLITE s
WHERE NOT EXISTS (
    SELECT 1
    FROM FENETRE_COM f
    WHERE f.id_satellite = s.id_satellite
      AND f.statut = 'Réalisée'
)
ORDER BY s.id_satellite;

-- Stations sans aucune fenêtre réalisée (toutes périodes confondues)
-- Résultat attendu : GS-SGP-01 (en Maintenance)
-- Raison : GS-SGP-01 est en Maintenance depuis la création du schéma ;
--          le trigger T1 (trg_valider_fenetre) bloque toute nouvelle fenêtre.
PROMPT Stations sans fenetre realisee :
SELECT st.code_station, st.nom_station, st.statut
FROM STATION_SOL st
WHERE NOT EXISTS (
    SELECT 1
    FROM FENETRE_COM f
    WHERE f.code_station = st.code_station
      AND f.statut = 'Réalisée'
);


PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  [PARTIE 4 — BONUS] Fonctions analytiques OVER
PROMPT ════════════════════════════════════════════


-- ============================================================
PROMPT
PROMPT Ex.11 — ROW_NUMBER / RANK / DENSE_RANK
PROMPT         Classement global et par type orbite
-- ============================================================
-- Résultat attendu (global) : SAT-003 1er, SAT-001 2e, SAT-002 3e
-- Satellites sans fenêtre réalisée (SAT-004, SAT-005) apparaissent en dernière position
SELECT
    s.id_satellite,
    s.nom_satellite,
    o.type_orbite,
    NVL(SUM(f.volume_donnees_mo), 0) AS volume_total_mo,
    ROW_NUMBER() OVER (ORDER BY SUM(f.volume_donnees_mo) DESC NULLS LAST) AS row_num,
    RANK()       OVER (ORDER BY SUM(f.volume_donnees_mo) DESC NULLS LAST) AS rang_global,
    DENSE_RANK() OVER (ORDER BY SUM(f.volume_donnees_mo) DESC NULLS LAST) AS dense_rang,
    RANK() OVER (
        PARTITION BY o.type_orbite
        ORDER BY SUM(f.volume_donnees_mo) DESC NULLS LAST
    ) AS rang_par_orbite
FROM SATELLITE s
JOIN ORBITE o ON s.id_orbite = o.id_orbite
LEFT JOIN FENETRE_COM f ON s.id_satellite = f.id_satellite
                       AND f.statut = 'Réalisée'
GROUP BY s.id_satellite, s.nom_satellite, o.type_orbite
ORDER BY rang_global NULLS LAST;


-- ============================================================
PROMPT
PROMPT Ex.12 — LAG / LEAD : evolution du volume entre fenetres, par station
-- ============================================================
-- GS-KIR-01 : FEN-001 (SAT-001, 1250 Mo) → FEN-003 (SAT-003, 1680 Mo) → +34.4%
-- GS-TLS-01 : FEN-002 (SAT-002,  890 Mo) seule fenêtre réalisée → évolution NULL
SELECT
    st.nom_station,
    f.id_fenetre,
    TO_CHAR(f.datetime_debut, 'DD/MM/YYYY HH24:MI') AS debut,
    f.id_satellite,
    f.volume_donnees_mo AS volume_mo,
    LAG(f.volume_donnees_mo)
        OVER (PARTITION BY f.code_station ORDER BY f.datetime_debut) AS vol_precedent_mo,
    LEAD(f.volume_donnees_mo)
        OVER (PARTITION BY f.code_station ORDER BY f.datetime_debut) AS vol_suivant_mo,
    CASE
        WHEN LAG(f.volume_donnees_mo)
                 OVER (PARTITION BY f.code_station ORDER BY f.datetime_debut) IS NOT NULL
        THEN ROUND(
                (f.volume_donnees_mo
                 - LAG(f.volume_donnees_mo)
                       OVER (PARTITION BY f.code_station ORDER BY f.datetime_debut))
                / LAG(f.volume_donnees_mo)
                      OVER (PARTITION BY f.code_station ORDER BY f.datetime_debut)
                * 100,
                1)
        ELSE NULL
    END AS evolution_pct
FROM FENETRE_COM f
JOIN STATION_SOL st ON f.code_station = st.code_station
WHERE f.statut = 'Réalisée'
ORDER BY f.code_station, f.datetime_debut;


-- ============================================================
PROMPT
PROMPT Ex.13 — SUM OVER : cumul chronologique + moyenne mobile 3 fenêtres
-- ============================================================
-- Résultat attendu (CTR-001) :
--   FEN-001 (SAT-001/KIR) : cumul 1250,  moy3 1250.0
--   FEN-002 (SAT-002/TLS) : cumul 2140,  moy3 1070.0
--   FEN-003 (SAT-003/KIR) : cumul 3820,  moy3 1273.3
SELECT
    c.nom_centre,
    f.id_fenetre,
    f.id_satellite,
    f.code_station,
    TO_CHAR(f.datetime_debut, 'DD/MM/YYYY HH24:MI') AS debut,
    f.volume_donnees_mo AS volume_mo,
    SUM(f.volume_donnees_mo) OVER (
        PARTITION BY a.id_centre
        ORDER BY f.datetime_debut
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumul_mo,
    ROUND(AVG(f.volume_donnees_mo) OVER (
        PARTITION BY a.id_centre
        ORDER BY f.datetime_debut
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 1) AS moy_mobile_3
FROM FENETRE_COM f
JOIN STATION_SOL st ON f.code_station = st.code_station
JOIN AFFECTATION_STATION a ON st.code_station = a.code_station
JOIN CENTRE_CONTROLE c ON a.id_centre = c.id_centre
WHERE f.statut = 'Réalisée'
ORDER BY a.id_centre, f.datetime_debut;


-- ============================================================
PROMPT
PROMPT Ex.14 — Tableau de bord constellation
PROMPT         RANK + SUM OVER + part % + comparaison à la moyenne
-- ============================================================
WITH volumes AS (
    SELECT
        s.id_satellite,
        s.nom_satellite,
        o.type_orbite,
        NVL(SUM(f.volume_donnees_mo), 0) AS vol_total
    FROM SATELLITE s
    JOIN ORBITE o ON s.id_orbite = o.id_orbite
    LEFT JOIN FENETRE_COM f ON s.id_satellite = f.id_satellite
                           AND f.statut = 'Réalisée'
    GROUP BY s.id_satellite, s.nom_satellite, o.type_orbite
),
total_constellation AS (
    SELECT SUM(vol_total) AS total FROM volumes WHERE vol_total > 0
)
SELECT
    v.id_satellite,
    v.nom_satellite,
    v.type_orbite,
    v.vol_total AS volume_mo,
    RANK() OVER (ORDER BY v.vol_total DESC NULLS LAST) AS rang,
    CASE WHEN t.total > 0
         THEN ROUND(v.vol_total / t.total * 100, 1)
         ELSE 0
    END AS part_pct,
    SUM(v.vol_total) OVER (
        ORDER BY v.vol_total DESC NULLS LAST
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumul_mo,
    ROUND(AVG(v.vol_total) OVER (), 1) AS moy_constellation_mo,
    ROUND(v.vol_total - AVG(v.vol_total) OVER (), 1) AS ecart_moyenne
FROM volumes v, total_constellation t
ORDER BY rang NULLS LAST;


PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  [PARTIE 5 — BONUS] MERGE INTO
PROMPT ════════════════════════════════════════════


-- ============================================================
PROMPT
PROMPT Ex.15 — MERGE INTO SATELLITE
PROMPT         Synchronisation de statuts depuis un système IoT externe
-- ============================================================
-- Source IoT : mises à jour de 3 satellites existants + 1 nouveau (SAT-006)
-- SAT-001 : Opérationnel → Opérationnel (inchangé)
-- SAT-002 : Opérationnel → En veille (déclenche T5 → HISTORIQUE_STATUT)
-- SAT-003 : Opérationnel → Opérationnel (inchangé)
-- SAT-006 : nouveau → inséré avec statut "En veille"

SAVEPOINT avant_merge_iot;

MERGE INTO SATELLITE tgt
USING (
    SELECT 'SAT-001' AS id_satellite, 'Opérationnel' AS statut, 'ORB-001' AS id_orbite FROM DUAL
    UNION ALL
    SELECT 'SAT-002', 'En veille',    'ORB-001' FROM DUAL
    UNION ALL
    SELECT 'SAT-003', 'Opérationnel', 'ORB-002' FROM DUAL
    UNION ALL
    SELECT 'SAT-006', 'En veille',    'ORB-003' FROM DUAL  -- nouveau satellite
) src
ON (tgt.id_satellite = src.id_satellite)
WHEN MATCHED THEN
    UPDATE SET tgt.statut    = src.statut,
               tgt.id_orbite = src.id_orbite
WHEN NOT MATCHED THEN
    INSERT (id_satellite, nom_satellite, date_lancement, masse_kg,
            format_cubesat, statut, duree_vie_mois, capacite_batterie_wh, id_orbite)
    VALUES (src.id_satellite,
            'NanoOrbit-IoT-' || src.id_satellite,
            SYSDATE, 1.30, '3U', src.statut, 48, 20, src.id_orbite);

-- Vérification post-MERGE
PROMPT Etat post-MERGE (statuts satellites) :
SELECT id_satellite, nom_satellite, statut, id_orbite
FROM SATELLITE
ORDER BY id_satellite;

PROMPT Historique statut genere par T5 :
SELECT id_satellite, ancien_statut, nouveau_statut,
       TO_CHAR(date_changement, 'DD/MM/YYYY HH24:MI:SS') AS date_chgt
FROM HISTORIQUE_STATUT
ORDER BY id_historique DESC
FETCH FIRST 5 ROWS ONLY;

-- On conserve les modifications (SAT-002 en veille est réaliste)
COMMIT;


-- ============================================================
PROMPT
PROMPT Ex.16 — MERGE INTO AFFECTATION_STATION
PROMPT         Intégration de CTR-003 (Singapour) — fichier de config révisé
-- ============================================================
-- Scénario : le fichier de configuration NanoOrbit 2026 transfère
-- GS-SGP-01 de CTR-002 (Houston) vers le nouveau centre CTR-003 (Singapour).
-- CTR-001 voit ses dates d'affectation mises à jour (renouvellement contrat).

-- Étape 1 : Insertion de CTR-003 si absent (idempotent)
BEGIN
    INSERT INTO CENTRE_CONTROLE
        (id_centre, nom_centre, ville, region, fuseau_horaire, statut)
    VALUES
        ('CTR-003', 'NanoOrbit Singapore', 'Singapour',
         'Asie-Pacifique', 'Asia/Singapore', 'Actif');
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN NULL;  -- déjà inséré lors d'une exécution précédente
END;
/

-- Étape 2 : Supprimer l'ancienne affectation CTR-002 / GS-SGP-01 (transfert)
BEGIN
    DELETE FROM AFFECTATION_STATION
    WHERE id_centre = 'CTR-002' AND code_station = 'GS-SGP-01';
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN NULL;  -- déjà supprimée lors d'une exécution précédente
END;
/

-- Étape 3 : MERGE — mise à jour CTR-001 + nouvelle association CTR-003/GS-SGP-01
MERGE INTO AFFECTATION_STATION tgt
USING (
    -- Associations CTR-001 : renouvellement de contrat 2026
    SELECT 'CTR-001' AS id_centre, 'GS-TLS-01' AS code_station,
           DATE '2026-01-01' AS date_aff, 'Renouvellement contrat 2026' AS cmt
    FROM DUAL
    UNION ALL
    SELECT 'CTR-001', 'GS-KIR-01',
           DATE '2026-01-01', 'Renouvellement contrat 2026'
    FROM DUAL
    UNION ALL
    -- Nouvelle association : CTR-003 prend en charge GS-SGP-01
    SELECT 'CTR-003', 'GS-SGP-01',
           DATE '2026-04-01', 'Transfert vers NanoOrbit Singapore — ouverture centre Asie-Pacifique'
    FROM DUAL
) src
ON (tgt.id_centre = src.id_centre AND tgt.code_station = src.code_station)
WHEN MATCHED THEN
    UPDATE SET tgt.date_affectation = src.date_aff,
               tgt.commentaire      = src.cmt
WHEN NOT MATCHED THEN
    INSERT (id_centre, code_station, date_affectation, commentaire)
    VALUES (src.id_centre, src.code_station, src.date_aff, src.cmt);

COMMIT;

-- Vérification post-MERGE
PROMPT Affectations stations apres MERGE :
SELECT a.id_centre, c.nom_centre, a.code_station,
       TO_CHAR(a.date_affectation, 'DD/MM/YYYY') AS date_aff,
       a.commentaire
FROM AFFECTATION_STATION a
JOIN CENTRE_CONTROLE c ON a.id_centre = c.id_centre
ORDER BY a.id_centre, a.code_station;


PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  [PARTIE 6 — BONUS] Index et EXPLAIN PLAN
PROMPT ════════════════════════════════════════════


-- ============================================================
PROMPT
PROMPT Ex.17 — Index stratégiques
-- ============================================================

-- Index sur FK de FENETRE_COM (évite les full scans lors des jointures)
CREATE INDEX idx_fenetre_satellite ON FENETRE_COM(id_satellite);
CREATE INDEX idx_fenetre_station ON FENETRE_COM(code_station);

-- Index sur FK de PARTICIPATION (jointure mission → participation fréquente)
CREATE INDEX idx_participation_mission ON PARTICIPATION(id_mission);

-- Index sur statut de SATELLITE (filtrage WHERE statut = '...' très fréquent)
CREATE INDEX idx_satellite_statut ON SATELLITE(statut);

-- Index composite (statut + orbite) pour les requêtes analytiques par type
CREATE INDEX idx_satellite_statut_orbite ON SATELLITE(statut, id_orbite);

-- Index fonctionnel sur TRUNC(datetime_debut, 'MM') pour les agrégats mensuels
CREATE INDEX idx_fenetre_mois ON FENETRE_COM(TRUNC(datetime_debut, 'MM'));

PROMPT Index crees :
SELECT index_name, index_type, table_name, status
FROM user_indexes
WHERE table_name IN ('FENETRE_COM', 'SATELLITE', 'PARTICIPATION')
  AND index_name LIKE 'IDX_%'
ORDER BY table_name, index_name;


-- ============================================================
PROMPT
PROMPT Ex.18 — EXPLAIN PLAN : requête de reporting mensuel (4 tables)
-- ============================================================
-- Requête : volumes téléchargés par mois, centre et type d'orbite
-- Avant création des index → TABLE ACCESS FULL probable sur FENETRE_COM et SATELLITE
-- Après création des index ci-dessus → INDEX RANGE SCAN attendu

EXPLAIN PLAN SET STATEMENT_ID = 'REPORT_MENSUEL' FOR
SELECT
    c.nom_centre,
    o.type_orbite,
    TRUNC(f.datetime_debut, 'MM') AS mois,
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
GROUP BY c.nom_centre, o.type_orbite, TRUNC(f.datetime_debut, 'MM')
ORDER BY mois, c.nom_centre;

-- Lecture du plan
-- Points à identifier : TABLE ACCESS FULL vs INDEX RANGE SCAN,
-- HASH JOIN vs NESTED LOOPS, coût (Cost) de chaque étape
SELECT plan_table_output
FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'REPORT_MENSUEL', 'TYPICAL'));


-- ============================================================
PROMPT
PROMPT Ex.19 — Index invisible / visible : impact sur idx_satellite_statut
-- ============================================================
-- Étape 1 : rendre l'index invisible → Oracle ignore cet index (= TABLE ACCESS FULL)
ALTER INDEX idx_satellite_statut INVISIBLE;

EXPLAIN PLAN SET STATEMENT_ID = 'STATUT_INVISIBLE' FOR
SELECT id_satellite, nom_satellite, statut
FROM SATELLITE
WHERE statut = 'Opérationnel';

PROMPT Plan avec idx_satellite_statut INVISIBLE (TABLE ACCESS FULL attendu) :
SELECT plan_table_output
FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'STATUT_INVISIBLE', 'TYPICAL'));

-- Étape 2 : rendre l'index visible → Oracle peut utiliser INDEX RANGE SCAN
ALTER INDEX idx_satellite_statut VISIBLE;

EXPLAIN PLAN SET STATEMENT_ID = 'STATUT_VISIBLE' FOR
SELECT id_satellite, nom_satellite, statut
FROM SATELLITE
WHERE statut = 'Opérationnel';

PROMPT Plan avec idx_satellite_statut VISIBLE (INDEX RANGE SCAN attendu) :
SELECT plan_table_output
FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'STATUT_VISIBLE', 'TYPICAL'));

-- Note : sur un jeu de 5 lignes, Oracle peut choisir TABLE ACCESS FULL même avec index
-- (coût du full scan < coût d'accès à l'index pour très petites tables).
-- Ce comportement est normal — l'effet est visible sur des tables de plusieurs milliers de lignes.


PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  [RAPPORT DE PILOTAGE] Tableau de bord opérationnel NanoOrbit
PROMPT ════════════════════════════════════════════
PROMPT  Rang centres par volume · Part % · Evolution LAG · Satellites rattachés
PROMPT

-- ============================================================
-- Rapport final : CTE + fonctions analytiques + vue matérialisée
-- Combine : RANK des centres, part % du volume, évolution mensuelle (LAG),
-- et liste des satellites actifs rattachés à chaque centre
-- ============================================================
WITH volumes_centre_mois AS (
    SELECT
        a.id_centre,
        c.nom_centre,
        TRUNC(f.datetime_debut, 'MM') AS mois,
        SUM(f.volume_donnees_mo) AS vol_mois
    FROM FENETRE_COM f
    JOIN STATION_SOL st ON f.code_station = st.code_station
    JOIN AFFECTATION_STATION a ON st.code_station = a.code_station
    JOIN CENTRE_CONTROLE c ON a.id_centre = c.id_centre
    WHERE f.statut = 'Réalisée'
    GROUP BY a.id_centre, c.nom_centre, TRUNC(f.datetime_debut, 'MM')
),
total_par_mois AS (
    SELECT mois, SUM(vol_mois) AS total_mois
    FROM volumes_centre_mois
    GROUP BY mois
),
rapport_analytique AS (
    SELECT
        vcm.nom_centre,
        TO_CHAR(vcm.mois, 'MM/YYYY') AS mois,
        vcm.vol_mois,
        RANK() OVER (PARTITION BY vcm.mois ORDER BY vcm.vol_mois DESC) AS rang,
        ROUND(vcm.vol_mois / tpm.total_mois * 100, 1) AS part_pct,
        LAG(vcm.vol_mois) OVER (
            PARTITION BY vcm.id_centre ORDER BY vcm.mois
        ) AS vol_mois_prec,
        CASE
            WHEN LAG(vcm.vol_mois) OVER (PARTITION BY vcm.id_centre ORDER BY vcm.mois) IS NOT NULL
            THEN ROUND(
                    (vcm.vol_mois
                     - LAG(vcm.vol_mois) OVER (PARTITION BY vcm.id_centre ORDER BY vcm.mois))
                    / LAG(vcm.vol_mois) OVER (PARTITION BY vcm.id_centre ORDER BY vcm.mois)
                    * 100, 1)
            ELSE NULL
        END AS evolution_pct,
        vcm.id_centre
    FROM volumes_centre_mois vcm
    JOIN total_par_mois tpm ON vcm.mois = tpm.mois
),
satellites_par_centre AS (
    SELECT DISTINCT a.id_centre, f.id_satellite
    FROM FENETRE_COM f
    JOIN STATION_SOL st ON f.code_station = st.code_station
    JOIN AFFECTATION_STATION a ON st.code_station = a.code_station
    JOIN SATELLITE s ON f.id_satellite = s.id_satellite
    WHERE s.statut = 'Opérationnel'
),
sats_concat AS (
    SELECT
        id_centre,
        LISTAGG(id_satellite, ', ') WITHIN GROUP (ORDER BY id_satellite) AS satellites_actifs
    FROM satellites_par_centre
    GROUP BY id_centre
)
SELECT
    ra.mois,
    ra.rang,
    ra.nom_centre,
    ra.vol_mois AS volume_mo,
    ra.part_pct AS "PART_%",
    NVL(TO_CHAR(ra.evolution_pct) || '%', 'N/A') AS "EVOL_VS_MOIS_PREC",
    NVL(sc.satellites_actifs, '—') AS satellites_operationnels
FROM rapport_analytique ra
LEFT JOIN sats_concat sc ON ra.id_centre = sc.id_centre
ORDER BY ra.mois, ra.rang;

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 4 terminee.
PROMPT ════════════════════════════════════════════
PROMPT
