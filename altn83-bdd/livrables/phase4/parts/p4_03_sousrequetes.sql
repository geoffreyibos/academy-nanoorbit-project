-- ============================================================
-- Phase 4 — Partie 3/7 : Sous-requêtes avancées
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
PROMPT  Phase 4 — [3/7] Sous-requetes avancees
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT Ex.8 — Sous-requete scalaire : fenetres > moyenne, ecart affiche
PROMPT         Moyenne realisees = (1250 + 890 + 1680) / 3 = 1273,3 Mo
-- ────────────────────────────────────────────────────────────
-- Resultat attendu : FEN-003 (SAT-003, 1680 Mo, ecart +406.7 Mo)
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


-- ────────────────────────────────────────────────────────────
PROMPT Ex.9 — Sous-requete correlee : derniere fenetre realisee par satellite
-- ────────────────────────────────────────────────────────────
-- Resultat attendu : SAT-001 (KIR-01, 15/01/2024, 1250 Mo)
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
      WHERE f2.id_satellite = s.id_satellite
        AND f2.statut = 'Réalisée'
  )
ORDER BY s.id_satellite;


-- ────────────────────────────────────────────────────────────
PROMPT Ex.10 — EXISTS / NOT EXISTS
-- ────────────────────────────────────────────────────────────

PROMPT Satellites sans fenetre realisee :
-- Resultat attendu : SAT-004 (En veille), SAT-005 (Desorbite)
SELECT s.id_satellite, s.nom_satellite, s.statut
FROM SATELLITE s
WHERE NOT EXISTS (
    SELECT 1
    FROM FENETRE_COM f
    WHERE f.id_satellite = s.id_satellite
      AND f.statut = 'Réalisée'
)
ORDER BY s.id_satellite;

PROMPT Stations sans fenetre realisee :
-- Resultat attendu : GS-SGP-01 (Maintenance — trigger T1 bloque toute insertion)
SELECT st.code_station, st.nom_station, st.statut
FROM STATION_SOL st
WHERE NOT EXISTS (
    SELECT 1
    FROM FENETRE_COM f
    WHERE f.code_station = st.code_station
      AND f.statut = 'Réalisée'
);

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Partie 3/7 terminee.
PROMPT ────────────────────────────────────────────
PROMPT
