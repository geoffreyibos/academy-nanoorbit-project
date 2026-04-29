-- ============================================================
-- Phase 3 — Palier 1/6 : Blocs anonymes
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 3 — [1/6] Blocs anonymes
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT Ex.1 — Comptage general (satellites, stations, missions)
-- ────────────────────────────────────────────────────────────
DECLARE
    v_nb_satellites  NUMBER;
    v_nb_stations    NUMBER;
    v_nb_missions    NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_nb_satellites FROM SATELLITE;
    SELECT COUNT(*) INTO v_nb_stations   FROM STATION_SOL;
    SELECT COUNT(*) INTO v_nb_missions   FROM MISSION;

    DBMS_OUTPUT.PUT_LINE('Satellites : ' || v_nb_satellites);
    DBMS_OUTPUT.PUT_LINE('Stations   : ' || v_nb_stations);
    DBMS_OUTPUT.PUT_LINE('Missions   : ' || v_nb_missions);
END;
/

-- ────────────────────────────────────────────────────────────
PROMPT Ex.2 — Caracteristiques de SAT-001 (SELECT INTO)
-- ────────────────────────────────────────────────────────────
DECLARE
    v_nom       SATELLITE.nom_satellite%TYPE;
    v_format    SATELLITE.format_cubesat%TYPE;
    v_statut    SATELLITE.statut%TYPE;
    v_lancement SATELLITE.date_lancement%TYPE;
    v_masse     SATELLITE.masse_kg%TYPE;
    v_batterie  SATELLITE.capacite_batterie_wh%TYPE;
    v_orbite    SATELLITE.id_orbite%TYPE;
BEGIN
    SELECT nom_satellite, format_cubesat, statut,
           date_lancement, masse_kg, capacite_batterie_wh, id_orbite
    INTO   v_nom, v_format, v_statut,
           v_lancement, v_masse, v_batterie, v_orbite
    FROM   SATELLITE
    WHERE  id_satellite = 'SAT-001';

    DBMS_OUTPUT.PUT_LINE('Nom          : ' || v_nom);
    DBMS_OUTPUT.PUT_LINE('Format       : ' || v_format);
    DBMS_OUTPUT.PUT_LINE('Statut       : ' || v_statut);
    DBMS_OUTPUT.PUT_LINE('Lancement    : ' || TO_CHAR(v_lancement, 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('Masse (kg)   : ' || v_masse);
    DBMS_OUTPUT.PUT_LINE('Batterie (Wh): ' || v_batterie);
    DBMS_OUTPUT.PUT_LINE('Orbite       : ' || v_orbite);
END;
/

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Palier 1/6 termine.
PROMPT ────────────────────────────────────────────
PROMPT
