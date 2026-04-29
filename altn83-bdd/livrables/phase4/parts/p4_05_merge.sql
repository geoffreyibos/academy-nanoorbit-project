-- ============================================================
-- Phase 4 — Partie 5/7 : MERGE INTO (BONUS)
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
PROMPT  Phase 4 — [5/7] MERGE INTO (BONUS)
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT Ex.15 — MERGE INTO SATELLITE
PROMPT         Synchronisation de statuts depuis un systeme IoT externe
-- ────────────────────────────────────────────────────────────
-- SAT-001 : Operationnel -) Operationnel (inchange)
-- SAT-002 : Operationnel -) En veille (declenche T5 -) HISTORIQUE_STATUT)
-- SAT-003 : Operationnel -) Operationnel (inchange)
-- SAT-006 : nouveau      -) insere avec statut "En veille"

SAVEPOINT avant_merge_iot;

MERGE INTO SATELLITE tgt
USING (
    SELECT 'SAT-001' AS id_satellite, 'Opérationnel' AS statut, 'ORB-001' AS id_orbite FROM DUAL
    UNION ALL
    SELECT 'SAT-002', 'En veille',    'ORB-001' FROM DUAL
    UNION ALL
    SELECT 'SAT-003', 'Opérationnel', 'ORB-002' FROM DUAL
    UNION ALL
    SELECT 'SAT-006', 'En veille',    'ORB-003' FROM DUAL
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

COMMIT;


-- ────────────────────────────────────────────────────────────
PROMPT Ex.16 — MERGE INTO AFFECTATION_STATION
PROMPT         Integration de CTR-003 (Singapour) — fichier de config revise
-- ────────────────────────────────────────────────────────────
-- GS-SGP-01 transferee de CTR-002 (Houston) vers CTR-003 (Singapour).
-- CTR-001 : dates d'affectation mises a jour (renouvellement contrat 2026).

BEGIN
    INSERT INTO CENTRE_CONTROLE
        (id_centre, nom_centre, ville, region, fuseau_horaire, statut)
    VALUES
        ('CTR-003', 'NanoOrbit Singapore', 'Singapour',
         'Asie-Pacifique', 'Asia/Singapore', 'Actif');
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

BEGIN
    DELETE FROM AFFECTATION_STATION
    WHERE id_centre = 'CTR-002' AND code_station = 'GS-SGP-01';
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

MERGE INTO AFFECTATION_STATION tgt
USING (
    SELECT 'CTR-001' AS id_centre, 'GS-TLS-01' AS code_station,
           DATE '2026-01-01' AS date_aff, 'Renouvellement contrat 2026' AS cmt
    FROM DUAL
    UNION ALL
    SELECT 'CTR-001', 'GS-KIR-01',
           DATE '2026-01-01', 'Renouvellement contrat 2026'
    FROM DUAL
    UNION ALL
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

PROMPT Affectations stations apres MERGE :
SELECT a.id_centre, c.nom_centre, a.code_station,
       TO_CHAR(a.date_affectation, 'DD/MM/YYYY') AS date_aff,
       a.commentaire
FROM AFFECTATION_STATION a
JOIN CENTRE_CONTROLE c ON a.id_centre = c.id_centre
ORDER BY a.id_centre, a.code_station;

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Partie 5/7 terminee.
PROMPT ────────────────────────────────────────────
PROMPT
