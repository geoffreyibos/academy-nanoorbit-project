-- ============================================================
-- Phase 4 — Partie 4/7 : Fonctions analytiques OVER (BONUS)
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
PROMPT  Phase 4 — [4/7] Fonctions analytiques OVER (BONUS)
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT Ex.11 — ROW_NUMBER / RANK / DENSE_RANK
PROMPT         Classement global et par type d'orbite
-- ────────────────────────────────────────────────────────────
-- Resultat attendu (global) : SAT-003 1er, SAT-001 2e, SAT-002 3e
-- Satellites sans fenetre realisee apparaissent en derniere position
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


-- ────────────────────────────────────────────────────────────
PROMPT Ex.12 — LAG / LEAD : evolution du volume entre fenetres, par station
-- ────────────────────────────────────────────────────────────
-- GS-KIR-01 : FEN-001 (SAT-001, 1250 Mo) -) FEN-003 (SAT-003, 1680 Mo) -) +34.4%
-- GS-TLS-01 : FEN-002 (SAT-002,  890 Mo) seule fenetre realisee -) evolution NULL
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


-- ────────────────────────────────────────────────────────────
PROMPT Ex.13 — SUM OVER : cumul chronologique + moyenne mobile 3 fenetres
-- ────────────────────────────────────────────────────────────
-- FEN-001 (SAT-001/KIR) : cumul 1250,  moy3 1250.0
-- FEN-002 (SAT-002/TLS) : cumul 2140,  moy3 1070.0
-- FEN-003 (SAT-003/KIR) : cumul 3820,  moy3 1273.3
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


-- ────────────────────────────────────────────────────────────
PROMPT Ex.14 — Tableau de bord constellation
PROMPT         RANK + SUM OVER + part % + comparaison a la moyenne
-- ────────────────────────────────────────────────────────────
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
PROMPT ────────────────────────────────────────────
PROMPT  Partie 4/7 terminee.
PROMPT ────────────────────────────────────────────
PROMPT
