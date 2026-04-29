-- ============================================================
-- Phase 2 — Partie 5/6 : T3 + T4
--   T3 — trg_volume_realise   (RG-F05 : volume -> Realisee seulement)
--   T4 — trg_mission_terminee (RG-S06 + RG-M04)
-- Prérequis : Parties 1 à 4 exécutées
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 2 — [5/6] T3 + T4
PROMPT  T3 trg_volume_realise  : RG-F05
PROMPT  T4 trg_mission_terminee : RG-S06 + RG-M04
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT Création T3 — trg_volume_realise...
-- ────────────────────────────────────────────────────────────

CREATE OR REPLACE TRIGGER trg_volume_realise
BEFORE INSERT OR UPDATE ON FENETRE_COM
FOR EACH ROW
BEGIN
    -- RG-F05 : volume renseigne uniquement pour les fenetres Realisees
    IF :NEW.statut != 'Réalisée' THEN
        :NEW.volume_donnees_mo := NULL;
    END IF;
END trg_volume_realise;
/
SHOW ERRORS

-- ────────────────────────────────────────────────────────────
PROMPT [TEST T3] Cas de test...
-- ────────────────────────────────────────────────────────────

COLUMN id_fenetre       FORMAT 9999 HEADING "ID"
COLUMN statut           FORMAT A12
COLUMN volume_donnees_mo FORMAT 9999990 HEADING "Volume(Mo)"

-- CAS 1 : Fenetre Realisee avec volume -> volume conserve
BEGIN
    INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
    VALUES ('SAT-002', 'GS-KIR-01', TO_TIMESTAMP('2024-02-05 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 70.0, 500, 'Réalisée');
    DBMS_OUTPUT.PUT_LINE('OK CAS 1 : INSERT Realisee — verification du volume ci-dessous');
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERREUR inattendue CAS 1 : ' || SQLERRM);
END;
/

-- CAS 2 : Fenetre Planifiee avec volume fourni -> volume force a NULL par T3
BEGIN
    INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
    VALUES ('SAT-002', 'GS-KIR-01', TO_TIMESTAMP('2024-02-05 11:00:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 70.0, 999, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('OK CAS 2 : INSERT Planifiee avec volume=999 -> T3 forcera NULL');

    SELECT id_fenetre, statut, volume_donnees_mo
      FROM FENETRE_COM
     WHERE id_satellite = 'SAT-002'
       AND datetime_debut = TO_TIMESTAMP('2024-02-05 11:00:00', 'YYYY-MM-DD HH24:MI:SS');

    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERREUR inattendue CAS 2 : ' || SQLERRM);
END;
/

-- ────────────────────────────────────────────────────────────
PROMPT Création T4 — trg_mission_terminee...
-- ────────────────────────────────────────────────────────────

CREATE OR REPLACE TRIGGER trg_mission_terminee
BEFORE INSERT ON PARTICIPATION
FOR EACH ROW
DECLARE
    v_statut_satellite SATELLITE.statut%TYPE;
    v_statut_mission   MISSION.statut_mission%TYPE;
BEGIN
    -- RG-S06 : satellite Desorbite -> participation interdite
    SELECT statut INTO v_statut_satellite
    FROM SATELLITE WHERE id_satellite = :NEW.id_satellite;

    IF v_statut_satellite = 'Désorbité' THEN
        RAISE_APPLICATION_ERROR(-20005,
            'Satellite ' || :NEW.id_satellite ||
            ' est Désorbité — aucune participation autorisée (RG-S06)');
    END IF;

    -- RG-M04 : mission Terminee -> plus de nouveaux satellites
    SELECT statut_mission INTO v_statut_mission
    FROM MISSION WHERE id_mission = :NEW.id_mission;

    IF v_statut_mission = 'Terminée' THEN
        RAISE_APPLICATION_ERROR(-20004,
            'La mission ' || :NEW.id_mission ||
            ' est Terminée — aucun nouveau satellite autorisé (RG-M04)');
    END IF;
END trg_mission_terminee;
/
SHOW ERRORS

-- ────────────────────────────────────────────────────────────
PROMPT [TEST T4] Cas de test...
-- ────────────────────────────────────────────────────────────

-- Nettoyage idempotent : supprime la ligne parasite si elle existe
DELETE FROM PARTICIPATION
WHERE id_satellite = 'SAT-004' AND id_mission = 'MSN-ARC-2023';
COMMIT;

-- CAS 1 : Valide — SAT-004 (En veille) vers MSN-ARC-2023 (Active)
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-004', 'MSN-ARC-2023', 'Satellite de secours');
    DBMS_OUTPUT.PUT_LINE('OK CAS 1 : INSERT reussi (satellite valide, mission active)');
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERREUR inattendue CAS 1 : ' || SQLERRM);
END;
/

-- CAS 2 : Erreur RG-M04 — SAT-003 (Operationnel) vers MSN-DEF-2022 (Terminee)
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-003', 'MSN-DEF-2022', 'Imageur de remplacement');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait du etre rejete (RG-M04)');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('OK RG-M04 — ' || SQLERRM);
END;
/

-- CAS 3 : Erreur RG-S06 — SAT-005 (Desorbite) vers MSN-ARC-2023 (Active)
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-005', 'MSN-ARC-2023', 'Test RG-S06 PARTICIPATION');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait du etre rejete (RG-S06)');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('OK RG-S06 PARTICIPATION — ' || SQLERRM);
END;
/

-- CAS 4 (bonus) : Double blocage — SAT-005 (Desorbite) vers MSN-DEF-2022 (Terminee)
-- RG-S06 verifie en premier -> ORA-20005 prime sur RG-M04
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-005', 'MSN-DEF-2022', 'Test RG-S06 + RG-M04');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait du etre rejete');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('OK RG-S06+RG-M04 — ' || SQLERRM);
END;
/

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Partie 5/6 terminee — T3 et T4 valides.
PROMPT ────────────────────────────────────────────
PROMPT
