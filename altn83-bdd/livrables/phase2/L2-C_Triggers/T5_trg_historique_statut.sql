-- ============================================================
-- TRIGGER T5 — trg_historique_statut
-- Niveau  : 2 (Bonus)
-- Événement : AFTER UPDATE OF statut ON SATELLITE
-- Règle   : RG-S06 (traçabilité)
-- Objectif : Enregistrer tout changement de statut d'un satellite
--            dans la table HISTORIQUE_STATUT avec horodatage
-- Prérequis : Table HISTORIQUE_STATUT créée (11_HISTORIQUE_STATUT.sql)
-- ============================================================

CREATE OR REPLACE TRIGGER trg_historique_statut
AFTER UPDATE OF statut ON SATELLITE
FOR EACH ROW
BEGIN
    -- N'enregistrer que les vrais changements de statut
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

-- ============================================================
-- CAS DE TEST T5
-- ============================================================

-- CAS 1 : Valide — changement de statut SAT-004 : En veille → Opérationnel
-- Résultat attendu : UPDATE réussi + 1 ligne dans HISTORIQUE_STATUT
UPDATE SATELLITE
   SET statut = 'Opérationnel'
 WHERE id_satellite = 'SAT-004';

SELECT id_satellite, ancien_statut, nouveau_statut, date_changement
  FROM HISTORIQUE_STATUT
 ORDER BY date_changement DESC;
-- Résultat attendu :
--   SAT-004 | En veille | Opérationnel | <timestamp>

ROLLBACK;

-- CAS 2 : Pas d'enregistrement si le statut ne change pas
-- Résultat attendu : UPDATE réussi, HISTORIQUE_STATUT inchangé (0 nouvelle ligne)
DECLARE
    v_count_avant NUMBER;
    v_count_apres NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count_avant FROM HISTORIQUE_STATUT;

    UPDATE SATELLITE
       SET statut = 'Opérationnel'  -- même valeur que l'actuelle
     WHERE id_satellite = 'SAT-001';

    SELECT COUNT(*) INTO v_count_apres FROM HISTORIQUE_STATUT;

    IF v_count_avant = v_count_apres THEN
        DBMS_OUTPUT.PUT_LINE('OK : Aucune ligne ajoutée (statut inchangé)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('ERREUR : Une ligne a été insérée à tort');
    END IF;
    ROLLBACK;
END;
/

-- CAS 3 : Chaîne de changements — SAT-003 : Opérationnel → Défaillant → Désorbité
-- Résultat attendu : 2 lignes dans HISTORIQUE_STATUT pour SAT-003
UPDATE SATELLITE SET statut = 'Défaillant' WHERE id_satellite = 'SAT-003';
UPDATE SATELLITE SET statut = 'Désorbité'  WHERE id_satellite = 'SAT-003';

SELECT id_satellite, ancien_statut, nouveau_statut, date_changement
  FROM HISTORIQUE_STATUT
 WHERE id_satellite = 'SAT-003'
 ORDER BY date_changement;
-- Résultat attendu :
--   SAT-003 | Opérationnel | Défaillant  | <ts1>
--   SAT-003 | Défaillant   | Désorbité   | <ts2>

ROLLBACK;

-- Vérification finale du contenu HISTORIQUE_STATUT après les tests
-- (doit être vide car tous les tests ont été rollback-és)
SELECT * FROM HISTORIQUE_STATUT ORDER BY date_changement DESC;
