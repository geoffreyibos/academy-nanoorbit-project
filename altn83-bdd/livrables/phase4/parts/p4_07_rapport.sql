-- ============================================================
-- Phase 4 — Partie 7/7 : Rapport de pilotage final
-- CTE + analytiques + vue matérialisée combinés
-- Prérequis : toutes les parties precedentes executees
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
PROMPT  Phase 4 — [7/7] Rapport de pilotage NanoOrbit
PROMPT  Rang centres · Part % · Evolution LAG · Satellites rattaches
PROMPT ════════════════════════════════════════════
PROMPT

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
PROMPT  Phase 4 — terminee.
PROMPT ════════════════════════════════════════════
PROMPT
