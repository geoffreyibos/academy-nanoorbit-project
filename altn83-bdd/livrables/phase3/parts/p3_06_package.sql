-- ============================================================
-- Phase 3 — Palier 6/6 : Package pkg_nanoOrbit (BONUS)
-- SPEC + BODY + scénario de validation complet
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 3 — [6/6] Package pkg_nanoOrbit (BONUS)
PROMPT   planifier_fenetre / cloturer_fenetre
PROMPT   affecter_satellite_mission / mettre_en_revision
PROMPT   calculer_volume_theorique / statut_constellation / stats_satellite
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT Compilation SPEC...
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE PACKAGE pkg_nanoOrbit AS

    PROCEDURE planifier_fenetre(
        p_id_sat    IN  VARCHAR2,
        p_code_sta  IN  VARCHAR2,
        p_debut     IN  TIMESTAMP,
        p_duree     IN  NUMBER,
        p_id_fenetre OUT NUMBER
    );

    PROCEDURE cloturer_fenetre(
        p_id_fenetre IN NUMBER,
        p_volume     IN NUMBER
    );

    PROCEDURE affecter_satellite_mission(
        p_id_sat     IN VARCHAR2,
        p_id_mission IN VARCHAR2,
        p_role       IN VARCHAR2
    );

    PROCEDURE mettre_en_revision(p_id_sat IN VARCHAR2);

    FUNCTION calculer_volume_theorique(p_id_fenetre IN NUMBER) RETURN NUMBER;

    PROCEDURE statut_constellation;

    PROCEDURE stats_satellite(p_id_sat IN VARCHAR2);

END pkg_nanoOrbit;
/
SHOW ERRORS

-- ────────────────────────────────────────────────────────────
PROMPT Compilation BODY...
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE PACKAGE BODY pkg_nanoOrbit AS

    PROCEDURE planifier_fenetre(
        p_id_sat    IN  VARCHAR2,
        p_code_sta  IN  VARCHAR2,
        p_debut     IN  TIMESTAMP,
        p_duree     IN  NUMBER,
        p_id_fenetre OUT NUMBER
    ) IS
        v_statut_sat SATELLITE.statut%TYPE;
        v_statut_sta STATION_SOL.statut%TYPE;
        v_nb_overlap NUMBER;
    BEGIN
        SELECT statut INTO v_statut_sat FROM SATELLITE   WHERE id_satellite = p_id_sat;
        SELECT statut INTO v_statut_sta FROM STATION_SOL WHERE code_station = p_code_sta;

        IF v_statut_sat != 'Opérationnel' THEN
            RAISE_APPLICATION_ERROR(-20001, 'Satellite ' || p_id_sat || ' non operationnel.');
        END IF;

        IF v_statut_sta = 'Maintenance' THEN
            RAISE_APPLICATION_ERROR(-20002, 'Station ' || p_code_sta || ' en maintenance.');
        END IF;

        SELECT COUNT(*) INTO v_nb_overlap
        FROM   FENETRE_COM
        WHERE  id_satellite = p_id_sat
        AND    datetime_debut < p_debut + NUMTODSINTERVAL(p_duree, 'SECOND')
        AND    datetime_debut + NUMTODSINTERVAL(duree_secondes, 'SECOND') > p_debut;

        IF v_nb_overlap > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Chevauchement detecte pour ' || p_id_sat || '.');
        END IF;

        INSERT INTO FENETRE_COM (datetime_debut, duree_secondes, elevation_max_deg,
                                 volume_donnees_mo, statut, id_satellite, code_station)
        VALUES (p_debut, p_duree, 0, NULL, 'Planifiée', p_id_sat, p_code_sta)
        RETURNING id_fenetre INTO p_id_fenetre;

        DBMS_OUTPUT.PUT_LINE('Fenetre planifiee — id : ' || p_id_fenetre);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20004, 'Satellite ou station introuvable.');
    END planifier_fenetre;

    PROCEDURE cloturer_fenetre(
        p_id_fenetre IN NUMBER,
        p_volume     IN NUMBER
    ) IS
        v_statut FENETRE_COM.statut%TYPE;
    BEGIN
        SELECT statut INTO v_statut FROM FENETRE_COM WHERE id_fenetre = p_id_fenetre;

        IF v_statut != 'Planifiée' THEN
            RAISE_APPLICATION_ERROR(-20005, 'La fenetre ' || p_id_fenetre || ' n''est pas planifiee.');
        END IF;

        UPDATE FENETRE_COM
        SET    statut = 'Réalisée', volume_donnees_mo = p_volume
        WHERE  id_fenetre = p_id_fenetre;

        DBMS_OUTPUT.PUT_LINE('Fenetre ' || p_id_fenetre || ' cloturee — ' || p_volume || ' Mo.');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20006, 'Fenetre ' || p_id_fenetre || ' introuvable.');
    END cloturer_fenetre;

    PROCEDURE affecter_satellite_mission(
        p_id_sat     IN VARCHAR2,
        p_id_mission IN VARCHAR2,
        p_role       IN VARCHAR2
    ) IS
        v_statut_sat SATELLITE.statut%TYPE;
        v_statut_msn MISSION.statut_mission%TYPE;
    BEGIN
        SELECT statut        INTO v_statut_sat FROM SATELLITE WHERE id_satellite = p_id_sat;
        SELECT statut_mission INTO v_statut_msn FROM MISSION   WHERE id_mission   = p_id_mission;

        IF v_statut_sat NOT IN ('Opérationnel', 'En veille') THEN
            RAISE_APPLICATION_ERROR(-20007, 'Satellite ' || p_id_sat || ' non assignable (statut : ' || v_statut_sat || ').');
        END IF;

        IF v_statut_msn = 'Terminée' THEN
            RAISE_APPLICATION_ERROR(-20008, 'Mission ' || p_id_mission || ' terminee.');
        END IF;

        INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
        VALUES (p_id_sat, p_id_mission, p_role);

        DBMS_OUTPUT.PUT_LINE(p_id_sat || ' affecte a ' || p_id_mission || ' (' || p_role || ').');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20009, p_id_sat || ' deja inscrit a ' || p_id_mission || '.');
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010, 'Satellite ou mission introuvable.');
    END affecter_satellite_mission;

    PROCEDURE mettre_en_revision(p_id_sat IN VARCHAR2) IS
        v_statut SATELLITE.statut%TYPE;
    BEGIN
        SELECT statut INTO v_statut FROM SATELLITE WHERE id_satellite = p_id_sat;

        IF v_statut = 'Désorbité' THEN
            RAISE_APPLICATION_ERROR(-20011, 'Satellite ' || p_id_sat || ' desorbite — revision impossible.');
        END IF;

        UPDATE SATELLITE SET statut = 'En veille' WHERE id_satellite = p_id_sat;

        DBMS_OUTPUT.PUT_LINE(p_id_sat || ' mis en revision (statut : ' || v_statut || ' -> En veille).');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20012, 'Satellite ' || p_id_sat || ' introuvable.');
    END mettre_en_revision;

    FUNCTION calculer_volume_theorique(p_id_fenetre IN NUMBER) RETURN NUMBER IS
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
            RAISE_APPLICATION_ERROR(-20013, 'Fenetre ' || p_id_fenetre || ' introuvable.');
    END calculer_volume_theorique;

    PROCEDURE statut_constellation IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('=== Constellation NanoOrbit ===');
        DBMS_OUTPUT.PUT_LINE(RPAD('Satellite', 10) || RPAD('Nom', 22) || RPAD('Statut', 16) ||
                             RPAD('Orbite', 8) || 'Instruments');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));

        FOR r IN (
            SELECT s.id_satellite, s.nom_satellite, s.statut,
                   o.type_orbite,
                   (SELECT COUNT(*) FROM EMBARQUEMENT e WHERE e.id_satellite = s.id_satellite) nb_instr
            FROM   SATELLITE s JOIN ORBITE o ON s.id_orbite = o.id_orbite
            ORDER BY s.id_satellite
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
                RPAD(r.id_satellite, 10) || RPAD(r.nom_satellite, 22) ||
                RPAD(r.statut, 16)       || RPAD(r.type_orbite, 8)   || r.nb_instr
            );
        END LOOP;
    END statut_constellation;

    PROCEDURE stats_satellite(p_id_sat IN VARCHAR2) IS
        v_nom        SATELLITE.nom_satellite%TYPE;
        v_nb_fen     NUMBER;
        v_vol_total  NUMBER;
        v_nb_msn     NUMBER;
    BEGIN
        SELECT nom_satellite INTO v_nom FROM SATELLITE WHERE id_satellite = p_id_sat;

        SELECT COUNT(*), NVL(SUM(volume_donnees_mo), 0)
        INTO   v_nb_fen, v_vol_total
        FROM   FENETRE_COM
        WHERE  id_satellite = p_id_sat AND statut = 'Réalisée';

        SELECT COUNT(*)
        INTO   v_nb_msn
        FROM   PARTICIPATION p JOIN MISSION m ON p.id_mission = m.id_mission
        WHERE  p.id_satellite = p_id_sat AND m.statut_mission = 'Active';

        DBMS_OUTPUT.PUT_LINE('=== Stats ' || p_id_sat || ' — ' || v_nom || ' ===');
        DBMS_OUTPUT.PUT_LINE('Fenetres realisees : ' || v_nb_fen);
        DBMS_OUTPUT.PUT_LINE('Volume total DL    : ' || v_vol_total || ' Mo');
        DBMS_OUTPUT.PUT_LINE('Missions actives   : ' || v_nb_msn);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20014, 'Satellite ' || p_id_sat || ' introuvable.');
    END stats_satellite;

END pkg_nanoOrbit;
/
SHOW ERRORS

-- ────────────────────────────────────────────────────────────
PROMPT [SCENARIO] Validation du package
-- ────────────────────────────────────────────────────────────
DECLARE
    v_id_fenetre NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- 1. Vue d''ensemble de la constellation ---');
    pkg_nanoOrbit.statut_constellation;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- 2. Stats SAT-001 avant operations ---');
    pkg_nanoOrbit.stats_satellite('SAT-001');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- 3. Planification d''une fenetre (SAT-001 / GS-TLS-01) ---');
    pkg_nanoOrbit.planifier_fenetre(
        'SAT-001', 'GS-TLS-01',
        TO_TIMESTAMP('2025-06-01 08:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        300,
        v_id_fenetre
    );
    DBMS_OUTPUT.PUT_LINE('  Volume theorique : ' || pkg_nanoOrbit.calculer_volume_theorique(v_id_fenetre) || ' Mo');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- 4. Cloture de la fenetre ---');
    pkg_nanoOrbit.cloturer_fenetre(v_id_fenetre, 1500);

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- 5. Affectation SAT-004 -> MSN-ARC-2023 ---');
    pkg_nanoOrbit.affecter_satellite_mission('SAT-004', 'MSN-ARC-2023', 'Imagerie secondaire');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- 6. Mise en revision de SAT-002 ---');
    pkg_nanoOrbit.mettre_en_revision('SAT-002');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- 7. Vue d''ensemble apres operations ---');
    pkg_nanoOrbit.statut_constellation;

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Rollback effectue — donnees restaurees.');
END;
/

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 3 — terminee.
PROMPT ════════════════════════════════════════════
PROMPT
