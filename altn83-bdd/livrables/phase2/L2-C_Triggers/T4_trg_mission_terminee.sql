-- ============================================================
-- TRIGGER T4 — trg_mission_terminee
-- Niveau  : 2 (Bonus)
-- Événement : BEFORE INSERT ON PARTICIPATION
-- Règles  : RG-S06 (satellite Désorbité), RG-M04 (mission Terminée)
-- Objectif : Bloquer tout satellite Désorbité dans une mission (RG-S06)
--            et bloquer l'ajout d'un satellite dans une mission
--            dont le statut est 'Terminée' (RG-M04)
-- ============================================================

CREATE OR REPLACE TRIGGER trg_mission_terminee
    BEFORE INSERT ON PARTICIPATION
    FOR EACH ROW
DECLARE
    v_statut_satellite  SATELLITE.statut%TYPE;
    v_statut_mission    MISSION.statut_mission%TYPE;
BEGIN
    -- RG-S06 : satellite Désorbité → participation à une mission interdite
    SELECT statut
    INTO v_statut_satellite
    FROM SATELLITE
    WHERE id_satellite = :NEW.id_satellite;

    IF v_statut_satellite = 'Désorbité' THEN
        RAISE_APPLICATION_ERROR(-20005,
                                'Satellite ' || :NEW.id_satellite ||
                                ' est Désorbité — aucune participation à une mission autorisée (RG-S06)');
    END IF;

    -- RG-M04 : mission Terminée → plus de nouveaux satellites
    SELECT statut_mission
    INTO v_statut_mission
    FROM MISSION
    WHERE id_mission = :NEW.id_mission;

    IF v_statut_mission = 'Terminée' THEN
        RAISE_APPLICATION_ERROR(-20004,
                                'La mission ' || :NEW.id_mission ||
                                ' est Terminée — aucun nouveau satellite ne peut y être ajouté (RG-M04)');
    END IF;
END trg_mission_terminee;
/
SHOW ERRORS

-- ============================================================
-- CAS DE TEST T4
-- ============================================================

-- Nettoyage préalable : supprime la ligne parasite si elle existe
-- (peut rester en base suite à un run précédent sans ROLLBACK)
DELETE FROM PARTICIPATION
WHERE id_satellite = 'SAT-004'
  AND id_mission   = 'MSN-ARC-2023';
COMMIT;

-- CAS 1 : Valide — ajout de SAT-004 (En veille) à une mission Active (MSN-ARC-2023)
-- Résultat attendu : INSERT réussi, aucune erreur
INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-004', 'MSN-ARC-2023', 'Satellite de secours');
ROLLBACK;

-- CAS 2 : Erreur RG-M04 — tentative d'ajout à MSN-DEF-2022 (Terminée)
-- SAT-003 (Opérationnel) vers mission Terminée → T4 doit bloquer sur RG-M04
-- Résultat attendu : ORA-20004 — mission MSN-DEF-2022 est Terminée
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-003', 'MSN-DEF-2022', 'Imageur de remplacement');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait dû être rejeté (RG-M04)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK RG-M04 — ' || SQLERRM);
END;
/

-- CAS 3 : Erreur RG-S06 — SAT-005 (Désorbité) vers MSN-ARC-2023 (Active)
-- La mission est Active, mais le satellite est Désorbité
-- RG-S06 est vérifié en premier dans T4 → doit bloquer avant RG-M04
-- Résultat attendu : ORA-20005 — Satellite SAT-005 est Désorbité
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-005', 'MSN-ARC-2023', 'Test RG-S06 PARTICIPATION');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait dû être rejeté (RG-S06)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK RG-S06 PARTICIPATION — ' || SQLERRM);
END;
/

-- CAS 4 (bonus) : Double blocage — SAT-005 (Désorbité) vers MSN-DEF-2022 (Terminée)
-- RG-S06 est vérifié en premier → ORA-20005 prime sur RG-M04
-- Résultat attendu : ORA-20005 — Satellite SAT-005 est Désorbité
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-005', 'MSN-DEF-2022', 'Test RG-S06 + RG-M04');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait dû être rejeté');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK RG-S06+RG-M04 — ' || SQLERRM);
END;
/