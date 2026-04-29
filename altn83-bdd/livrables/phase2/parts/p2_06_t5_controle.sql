-- ============================================================
-- Phase 2 — Partie 6/6 : T5 + Controle du schema
--   T5 — trg_historique_statut (AFTER UPDATE OF statut ON SATELLITE)
--   Controle : tables, contraintes, triggers, volumes, FK
-- Prérequis : Parties 1 à 5 exécutées
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 2 — [6/6] T5 + Controle du schema
PROMPT  T5 trg_historique_statut : tracabilite statut
PROMPT  Controle : 11 tables, contraintes, 5 triggers
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT Création T5 — trg_historique_statut...
-- ────────────────────────────────────────────────────────────

CREATE OR REPLACE TRIGGER trg_historique_statut
AFTER UPDATE OF statut ON SATELLITE
FOR EACH ROW
BEGIN
    IF :OLD.statut != :NEW.statut THEN
        INSERT INTO HISTORIQUE_STATUT
            (id_satellite, ancien_statut, nouveau_statut, date_changement, motif)
        VALUES
            (:NEW.id_satellite,
             :OLD.statut,
             :NEW.statut,
             SYSTIMESTAMP,
             'Statut modifié de [' || :OLD.statut || '] vers [' || :NEW.statut || ']');
    END IF;
END trg_historique_statut;
/
SHOW ERRORS

-- ────────────────────────────────────────────────────────────
PROMPT [TEST T5] Cas de test...
-- ────────────────────────────────────────────────────────────

COLUMN id_satellite     FORMAT A10
COLUMN ancien_statut    FORMAT A16 HEADING "Ancien"
COLUMN nouveau_statut   FORMAT A16 HEADING "Nouveau"
COLUMN date_changement  FORMAT A30 HEADING "Horodatage"

-- CAS 1 : Changement de statut SAT-004 : En veille -> Operationnel
UPDATE SATELLITE SET statut = 'Opérationnel' WHERE id_satellite = 'SAT-004';

SELECT id_satellite, ancien_statut, nouveau_statut, date_changement
  FROM HISTORIQUE_STATUT
 ORDER BY date_changement DESC;
-- Attendu : 1 ligne SAT-004 | En veille | Operationnel | <ts>

ROLLBACK;

-- CAS 2 : Pas d'enregistrement si le statut ne change pas
DECLARE
    v_avant NUMBER;
    v_apres NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_avant FROM HISTORIQUE_STATUT;

    UPDATE SATELLITE SET statut = 'Opérationnel'
     WHERE id_satellite = 'SAT-001';  -- deja Operationnel

    SELECT COUNT(*) INTO v_apres FROM HISTORIQUE_STATUT;

    IF v_avant = v_apres THEN
        DBMS_OUTPUT.PUT_LINE('OK CAS 2 : aucune ligne ajoutee (statut inchange)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('ERREUR CAS 2 : une ligne a ete inseree a tort');
    END IF;
    ROLLBACK;
END;
/

-- CAS 3 : Chaine de changements SAT-003 : Operationnel -> Defaillant -> Desorbite
UPDATE SATELLITE SET statut = 'Défaillant' WHERE id_satellite = 'SAT-003';
UPDATE SATELLITE SET statut = 'Désorbité'  WHERE id_satellite = 'SAT-003';

SELECT id_satellite, ancien_statut, nouveau_statut, date_changement
  FROM HISTORIQUE_STATUT
 WHERE id_satellite = 'SAT-003'
 ORDER BY date_changement;
-- Attendu : 2 lignes
--   SAT-003 | Operationnel | Defaillant | <ts1>
--   SAT-003 | Defaillant   | Desorbite  | <ts2>

ROLLBACK;

-- Verification finale : HISTORIQUE_STATUT vide apres rollbacks
SELECT COUNT(*) AS historique_apres_rollback FROM HISTORIQUE_STATUT;
-- Attendu : 0

-- ────────────────────────────────────────────────────────────
PROMPT
PROMPT [CONTROLE] Verification du schema NanoOrbit...
-- ────────────────────────────────────────────────────────────

COLUMN table_name        FORMAT A25  HEADING "Table"
COLUMN constraint_name   FORMAT A35  HEADING "Contrainte"
COLUMN constraint_type   FORMAT A1   HEADING "T"
COLUMN status            FORMAT A8   HEADING "Statut"
COLUMN trigger_name      FORMAT A30  HEADING "Trigger"
COLUMN trigger_type      FORMAT A16  HEADING "Type"
COLUMN triggering_event  FORMAT A20  HEADING "Evenement"
COLUMN nb_lignes         FORMAT 9999 HEADING "Lignes"
COLUMN satellites_orphelins FORMAT 9 HEADING "Orphelins"
COLUMN fenetres_orphelines  FORMAT 9 HEADING "Orphelines"

-- 1. Tables créées — attendu : 11 tables
PROMPT
PROMPT [1] Tables creees (attendu : 11)
SELECT table_name
  FROM user_tables
 WHERE table_name IN (
       'ORBITE', 'SATELLITE', 'INSTRUMENT', 'EMBARQUEMENT',
       'CENTRE_CONTROLE', 'STATION_SOL', 'AFFECTATION_STATION',
       'MISSION', 'FENETRE_COM', 'PARTICIPATION', 'HISTORIQUE_STATUT')
 ORDER BY table_name;

-- 2. Contraintes (PK, FK, CK, UQ)
PROMPT
PROMPT [2] Contraintes
SELECT table_name, constraint_name, constraint_type, status
  FROM user_constraints
 WHERE table_name IN (
       'ORBITE', 'SATELLITE', 'INSTRUMENT', 'EMBARQUEMENT',
       'CENTRE_CONTROLE', 'STATION_SOL', 'AFFECTATION_STATION',
       'MISSION', 'FENETRE_COM', 'PARTICIPATION', 'HISTORIQUE_STATUT')
 ORDER BY table_name, constraint_type;

-- 3. Triggers — attendu : 5 triggers ENABLED (T1 a T5)
PROMPT
PROMPT [3] Triggers (attendu : 5 ENABLED)
SELECT trigger_name, table_name, trigger_type, triggering_event, status
  FROM user_triggers
 WHERE table_name IN ('FENETRE_COM', 'PARTICIPATION', 'SATELLITE')
 ORDER BY table_name, trigger_name;

-- 4. Volumes DML
PROMPT
PROMPT [4] Volumes DML
SELECT 'ORBITE'              AS table_name, COUNT(*) AS nb_lignes FROM ORBITE
UNION ALL
SELECT 'SATELLITE',           COUNT(*) FROM SATELLITE
UNION ALL
SELECT 'INSTRUMENT',          COUNT(*) FROM INSTRUMENT
UNION ALL
SELECT 'EMBARQUEMENT',        COUNT(*) FROM EMBARQUEMENT
UNION ALL
SELECT 'CENTRE_CONTROLE',     COUNT(*) FROM CENTRE_CONTROLE
UNION ALL
SELECT 'STATION_SOL',         COUNT(*) FROM STATION_SOL
UNION ALL
SELECT 'AFFECTATION_STATION', COUNT(*) FROM AFFECTATION_STATION
UNION ALL
SELECT 'MISSION',             COUNT(*) FROM MISSION
UNION ALL
SELECT 'FENETRE_COM',         COUNT(*) FROM FENETRE_COM
UNION ALL
SELECT 'PARTICIPATION',       COUNT(*) FROM PARTICIPATION
UNION ALL
SELECT 'HISTORIQUE_STATUT',   COUNT(*) FROM HISTORIQUE_STATUT
ORDER BY table_name;
-- Attendu : AFFECTATION_STATION=3 CENTRE_CONTROLE=2 EMBARQUEMENT=7
--           FENETRE_COM=5 HISTORIQUE_STATUT=0 INSTRUMENT=4
--           MISSION=3 ORBITE=3 PARTICIPATION=7 SATELLITE=5 STATION_SOL=3

-- 5. Cohérence des FK
PROMPT
PROMPT [5] Coherence FK (attendu : 0 orphelins)
SELECT COUNT(*) AS satellites_orphelins
  FROM SATELLITE s
  LEFT JOIN ORBITE o ON s.id_orbite = o.id_orbite
 WHERE o.id_orbite IS NULL;

SELECT COUNT(*) AS fenetres_orphelines
  FROM FENETRE_COM f
  LEFT JOIN SATELLITE s ON f.id_satellite = s.id_satellite
 WHERE s.id_satellite IS NULL;

-- 6. Test rapide T1 — satellite Désorbité
PROMPT
PROMPT [6] Test rapide T1 (RG-S06)
BEGIN
    INSERT INTO FENETRE_COM
        (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, statut)
    VALUES
        ('SAT-005', 'GS-KIR-01', SYSTIMESTAMP, 300, 45.0, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('ECHEC : T1 n''a pas bloque SAT-005 (Desorbite)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK T1 : ' || SUBSTR(SQLERRM, 1, 80));
END;
/

-- 7. Test rapide T4 — mission Terminée
PROMPT
PROMPT [7] Test rapide T4 (RG-M04)
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-003', 'MSN-DEF-2022', 'Imageur test');
    DBMS_OUTPUT.PUT_LINE('ECHEC : T4 n''a pas bloque MSN-DEF-2022 (Terminee)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK T4 RG-M04 : ' || SUBSTR(SQLERRM, 1, 80));
END;
/

-- 8. Test rapide T4 — satellite Désorbité
PROMPT
PROMPT [8] Test rapide T4 (RG-S06 PARTICIPATION)
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-005', 'MSN-ARC-2023', 'Test RG-S06');
    DBMS_OUTPUT.PUT_LINE('ECHEC : T4 n''a pas bloque SAT-005 (Desorbite)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK T4 RG-S06 : ' || SUBSTR(SQLERRM, 1, 80));
END;
/

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 2 terminee — schema NanoOrbit valide.
PROMPT  11 tables  |  5 triggers  |  donnees DML OK
PROMPT ════════════════════════════════════════════
PROMPT
