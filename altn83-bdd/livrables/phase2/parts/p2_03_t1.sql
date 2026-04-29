-- ============================================================
-- Phase 2 — Partie 3/6 : T1 — trg_valider_fenetre
-- Regles : RG-S06 (satellite Desorbite) + RG-G03 (station Maintenance)
-- Prérequis : Parties 1 et 2 executees
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 2 — [3/6] T1 — trg_valider_fenetre
PROMPT  RG-S06 : satellite Desorbite -> fenetre interdite
PROMPT  RG-G03 : station en Maintenance -> fenetre interdite
PROMPT ════════════════════════════════════════════
PROMPT

CREATE OR REPLACE TRIGGER trg_valider_fenetre
BEFORE INSERT ON FENETRE_COM
FOR EACH ROW
DECLARE
    v_statut_satellite  SATELLITE.statut%TYPE;
    v_statut_station    STATION_SOL.statut%TYPE;
BEGIN
    SELECT statut INTO v_statut_satellite
    FROM SATELLITE WHERE id_satellite = :NEW.id_satellite;

    IF v_statut_satellite = 'Désorbité' THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Satellite ' || :NEW.id_satellite ||
            ' est Désorbité — aucune nouvelle fenêtre autorisée (RG-S06)');
    END IF;

    SELECT statut INTO v_statut_station
    FROM STATION_SOL WHERE code_station = :NEW.code_station;

    IF v_statut_station = 'Maintenance' THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Station ' || :NEW.code_station ||
            ' est en Maintenance — planification impossible (RG-G03)');
    END IF;
END trg_valider_fenetre;
/
SHOW ERRORS

-- ────────────────────────────────────────────────────────────
PROMPT [TEST T1] Cas de test...
-- ────────────────────────────────────────────────────────────

-- Nettoyage idempotent des lignes de test residuelles
DECLARE
    v_rows NUMBER;
BEGIN
    DELETE FROM FENETRE_COM
     WHERE NOT (id_satellite = 'SAT-001' AND code_station = 'GS-KIR-01'
                AND datetime_debut = TO_TIMESTAMP('2024-01-15 09:14:00', 'YYYY-MM-DD HH24:MI:SS'))
       AND NOT (id_satellite = 'SAT-002' AND code_station = 'GS-TLS-01'
                AND datetime_debut = TO_TIMESTAMP('2024-01-15 11:52:00', 'YYYY-MM-DD HH24:MI:SS'))
       AND NOT (id_satellite = 'SAT-003' AND code_station = 'GS-KIR-01'
                AND datetime_debut = TO_TIMESTAMP('2024-01-16 08:30:00', 'YYYY-MM-DD HH24:MI:SS'))
       AND NOT (id_satellite = 'SAT-001' AND code_station = 'GS-TLS-01'
                AND datetime_debut = TO_TIMESTAMP('2024-01-20 14:22:00', 'YYYY-MM-DD HH24:MI:SS'))
       AND NOT (id_satellite = 'SAT-003' AND code_station = 'GS-TLS-01'
                AND datetime_debut = TO_TIMESTAMP('2024-01-21 07:45:00', 'YYYY-MM-DD HH24:MI:SS'));
    v_rows := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Nettoyage T1 : ' || v_rows || ' ligne(s) resid(s) supprimee(s)');
END;
/

-- CAS 1 : Valide — SAT-001 (Operationnel) + GS-KIR-01 (Active)
BEGIN
    INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
    VALUES ('SAT-001', 'GS-KIR-01', TO_TIMESTAMP('2024-02-01 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 75.0, NULL, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('OK CAS 1 : INSERT reussi (satellite Operationnel, station Active)');
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERREUR inattendue CAS 1 : ' || SQLERRM);
END;
/

-- CAS 2 : Erreur RG-S06 — SAT-005 (Desorbite)
BEGIN
    INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
    VALUES ('SAT-005', 'GS-KIR-01', TO_TIMESTAMP('2024-02-01 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 60.0, NULL, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait du etre rejete (RG-S06)');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('OK RG-S06 — ' || SQLERRM);
END;
/

-- CAS 3 : Erreur RG-G03 — GS-SGP-01 (Maintenance)
BEGIN
    INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
    VALUES ('SAT-001', 'GS-SGP-01', TO_TIMESTAMP('2024-02-01 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 45.0, NULL, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait du etre rejete (RG-G03)');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('OK RG-G03 — ' || SQLERRM);
END;
/

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Partie 3/6 terminee — T1 valide.
PROMPT ────────────────────────────────────────────
PROMPT
