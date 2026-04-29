-- ============================================================
-- Phase 3 — Palier 5/6 : Procédures et fonctions standalone
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 3 — [5/6] Procedures et fonctions standalone
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT Ex.12 — SELECT INTO securise : NO_DATA_FOUND / OTHERS
-- ────────────────────────────────────────────────────────────
DECLARE
    v_sat SATELLITE%ROWTYPE;
BEGIN
    SELECT * INTO v_sat FROM SATELLITE WHERE id_satellite = 'SAT-999';
    DBMS_OUTPUT.PUT_LINE(v_sat.nom_satellite || ' — ' || v_sat.statut);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Satellite introuvable.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
END;
/

-- ────────────────────────────────────────────────────────────
PROMPT Ex.13 — RAISE_APPLICATION_ERROR : validation fenetre (statut + chevauchement)
-- ────────────────────────────────────────────────────────────
DECLARE
    v_statut_sat SATELLITE.statut%TYPE;
    v_statut_sta STATION_SOL.statut%TYPE;
    v_nb_overlap NUMBER;

    v_id_sat   VARCHAR2(20) := 'SAT-001';
    v_code_sta VARCHAR2(20) := 'GS-KIR-01';
    v_debut    TIMESTAMP    := TO_TIMESTAMP('2024-02-01 10:00:00', 'YYYY-MM-DD HH24:MI:SS');
    v_duree    NUMBER       := 300;
BEGIN
    SELECT statut INTO v_statut_sat FROM SATELLITE   WHERE id_satellite = v_id_sat;
    SELECT statut INTO v_statut_sta FROM STATION_SOL WHERE code_station = v_code_sta;

    IF v_statut_sat != 'Opérationnel' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Satellite ' || v_id_sat || ' non operationnel.');
    END IF;

    IF v_statut_sta = 'Maintenance' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Station ' || v_code_sta || ' en maintenance.');
    END IF;

    SELECT COUNT(*) INTO v_nb_overlap
    FROM   FENETRE_COM
    WHERE  id_satellite = v_id_sat
    AND    datetime_debut < v_debut + NUMTODSINTERVAL(v_duree, 'SECOND')
    AND    datetime_debut + NUMTODSINTERVAL(duree_secondes, 'SECOND') > v_debut;

    IF v_nb_overlap > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Chevauchement detecte pour ' || v_id_sat || '.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Validation OK — fenetre autorisee.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'Satellite ou station introuvable.');
END;
/

-- ────────────────────────────────────────────────────────────
PROMPT Ex.14 — Procedure afficher_statut_satellite
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE PROCEDURE afficher_statut_satellite(p_id IN VARCHAR2) IS
    v_sat SATELLITE%ROWTYPE;
    v_orb ORBITE%ROWTYPE;
BEGIN
    SELECT * INTO v_sat FROM SATELLITE WHERE id_satellite = p_id;
    SELECT * INTO v_orb FROM ORBITE    WHERE id_orbite    = v_sat.id_orbite;

    DBMS_OUTPUT.PUT_LINE('=== ' || p_id || ' — ' || v_sat.nom_satellite || ' ===');
    DBMS_OUTPUT.PUT_LINE('Statut  : ' || v_sat.statut);
    DBMS_OUTPUT.PUT_LINE('Orbite  : ' || v_orb.type_orbite || ' — ' || v_orb.altitude_km || ' km');

    FOR r IN (
        SELECT i.type_instrument, i.modele
        FROM   EMBARQUEMENT e JOIN INSTRUMENT i ON e.ref_instrument = i.ref_instrument
        WHERE  e.id_satellite = p_id
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Instrument : ' || r.type_instrument || ' (' || r.modele || ')');
    END LOOP;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Satellite ' || p_id || ' introuvable.');
END;
/
SHOW ERRORS

BEGIN
    afficher_statut_satellite('SAT-001');
    afficher_statut_satellite('SAT-999');
END;
/

-- ────────────────────────────────────────────────────────────
PROMPT Ex.15 — Procedure mettre_a_jour_statut (parametre OUT)
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE PROCEDURE mettre_a_jour_statut(
    p_id            IN  VARCHAR2,
    p_statut        IN  VARCHAR2,
    p_ancien_statut OUT VARCHAR2
) IS
BEGIN
    SELECT statut INTO p_ancien_statut FROM SATELLITE WHERE id_satellite = p_id;
    UPDATE SATELLITE SET statut = p_statut WHERE id_satellite = p_id;
    DBMS_OUTPUT.PUT_LINE(p_id || ' : ' || p_ancien_statut || ' -> ' || p_statut);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Satellite ' || p_id || ' introuvable.');
END;
/
SHOW ERRORS

DECLARE
    v_ancien VARCHAR2(30);
BEGIN
    mettre_a_jour_statut('SAT-004', 'Opérationnel', v_ancien);
    DBMS_OUTPUT.PUT_LINE('Ancien statut recupere : ' || v_ancien);
    ROLLBACK;
END;
/

-- ────────────────────────────────────────────────────────────
PROMPT Ex.16 — Fonction calculer_volume_session (debit x duree / 8)
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION calculer_volume_session(p_id_fenetre IN NUMBER) RETURN NUMBER IS
    v_debit STATION_SOL.debit_max_mbps%TYPE;
    v_duree FENETRE_COM.duree_secondes%TYPE;
BEGIN
    SELECT s.debit_max_mbps, f.duree_secondes
    INTO   v_debit, v_duree
    FROM   FENETRE_COM f JOIN STATION_SOL s ON f.code_station = s.code_station
    WHERE  f.id_fenetre = p_id_fenetre;

    RETURN ROUND(v_debit * v_duree / 8, 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Fenetre ' || p_id_fenetre || ' introuvable.');
END;
/
SHOW ERRORS

BEGIN
    FOR r IN (SELECT id_fenetre, id_satellite, code_station FROM FENETRE_COM) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Fenetre ' || r.id_fenetre || ' (' || r.id_satellite || ' -> ' || r.code_station || ')' ||
            ' — volume theorique : ' || calculer_volume_session(r.id_fenetre) || ' Mo'
        );
    END LOOP;
END;
/

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Palier 5/6 termine.
PROMPT ────────────────────────────────────────────
PROMPT
