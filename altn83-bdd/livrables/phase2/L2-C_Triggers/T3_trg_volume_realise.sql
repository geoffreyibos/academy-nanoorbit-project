-- ============================================================
-- TRIGGER T3 — trg_volume_realise
-- Niveau  : 1 (Obligatoire)
-- Événement : BEFORE INSERT OR UPDATE ON FENETRE_COM
-- Règle   : RG-F05
-- Objectif : Forcer volume_donnees_mo à NULL si le statut de
--            la fenêtre est différent de 'Réalisée' (correction
--            silencieuse — pas d'erreur levée)
-- ============================================================

CREATE OR REPLACE TRIGGER trg_volume_realise
BEFORE INSERT OR UPDATE ON FENETRE_COM
FOR EACH ROW
BEGIN
    -- RG-F05 : volume renseigné uniquement pour les fenêtres Réalisées
    IF :NEW.statut != 'Réalisée' THEN
        :NEW.volume_donnees_mo := NULL;
    END IF;
END trg_volume_realise;
/
SHOW ERRORS

-- ============================================================
-- CAS DE TEST T3
-- ============================================================

-- CAS 1 : Valide — fenêtre Réalisée avec volume → volume conservé
-- Résultat attendu : INSERT réussi, volume_donnees_mo = 500
INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-002', 'GS-KIR-01', TO_TIMESTAMP('2024-02-05 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 70.0, 500, 'Réalisée');

SELECT id_fenetre, statut, volume_donnees_mo
  FROM FENETRE_COM
 WHERE id_satellite = 'SAT-002'
   AND datetime_debut = TO_TIMESTAMP('2024-02-05 10:00:00', 'YYYY-MM-DD HH24:MI:SS');
-- Résultat attendu : volume_donnees_mo = 500

ROLLBACK;

-- CAS 2 : Correction silencieuse — fenêtre Planifiée avec volume fourni
-- Résultat attendu : INSERT réussi, mais volume_donnees_mo forcé à NULL
INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-002', 'GS-KIR-01', TO_TIMESTAMP('2024-02-05 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 70.0, 999, 'Planifiée');

SELECT id_fenetre, statut, volume_donnees_mo
  FROM FENETRE_COM
 WHERE id_satellite = 'SAT-002'
   AND datetime_debut = TO_TIMESTAMP('2024-02-05 10:00:00', 'YYYY-MM-DD HH24:MI:SS');
-- Résultat attendu : volume_donnees_mo = NULL (corrigé silencieusement par T3)

ROLLBACK;
