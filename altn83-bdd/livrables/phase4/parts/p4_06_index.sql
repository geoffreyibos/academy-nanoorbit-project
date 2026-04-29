-- ============================================================
-- Phase 4 — Partie 6/7 : Index et EXPLAIN PLAN (BONUS)
-- Prérequis : Partie 1 executee (DROP init + vues creees)
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
PROMPT  Phase 4 — [6/7] Index et EXPLAIN PLAN (BONUS)
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT Ex.17 — Index strategiques
-- ────────────────────────────────────────────────────────────

-- FK de FENETRE_COM (evite les full scans lors des jointures)
CREATE INDEX idx_fenetre_satellite ON FENETRE_COM(id_satellite);
CREATE INDEX idx_fenetre_station   ON FENETRE_COM(code_station);

-- FK de PARTICIPATION (jointure mission -) participation frequente)
CREATE INDEX idx_participation_mission ON PARTICIPATION(id_mission);

-- Statut de SATELLITE (filtrage WHERE statut = '...' tres frequent)
CREATE INDEX idx_satellite_statut ON SATELLITE(statut);

-- Composite (statut + orbite) pour les requetes analytiques par type
CREATE INDEX idx_satellite_statut_orbite ON SATELLITE(statut, id_orbite);

-- Fonctionnel sur TRUNC(datetime_debut, 'MM') pour les agregats mensuels
CREATE INDEX idx_fenetre_mois ON FENETRE_COM(TRUNC(datetime_debut, 'MM'));

PROMPT Index crees :
SELECT index_name, index_type, table_name, status
FROM user_indexes
WHERE table_name IN ('FENETRE_COM', 'SATELLITE', 'PARTICIPATION')
  AND index_name LIKE 'IDX_%'
ORDER BY table_name, index_name;


-- ────────────────────────────────────────────────────────────
PROMPT Ex.18 — EXPLAIN PLAN : requete de reporting mensuel (4 tables)
-- ────────────────────────────────────────────────────────────
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

SELECT plan_table_output
FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'REPORT_MENSUEL', 'TYPICAL'));


-- ────────────────────────────────────────────────────────────
PROMPT Ex.19 — Index invisible / visible : impact sur idx_satellite_statut
-- ────────────────────────────────────────────────────────────

ALTER INDEX idx_satellite_statut INVISIBLE;

EXPLAIN PLAN SET STATEMENT_ID = 'STATUT_INVISIBLE' FOR
SELECT id_satellite, nom_satellite, statut
FROM SATELLITE
WHERE statut = 'Opérationnel';

PROMPT Plan avec idx_satellite_statut INVISIBLE (TABLE ACCESS FULL attendu) :
SELECT plan_table_output
FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'STATUT_INVISIBLE', 'TYPICAL'));

ALTER INDEX idx_satellite_statut VISIBLE;

EXPLAIN PLAN SET STATEMENT_ID = 'STATUT_VISIBLE' FOR
SELECT id_satellite, nom_satellite, statut
FROM SATELLITE
WHERE statut = 'Opérationnel';

PROMPT Plan avec idx_satellite_statut VISIBLE (INDEX RANGE SCAN attendu) :
SELECT plan_table_output
FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'STATUT_VISIBLE', 'TYPICAL'));

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Partie 6/7 terminee.
PROMPT ────────────────────────────────────────────
PROMPT
