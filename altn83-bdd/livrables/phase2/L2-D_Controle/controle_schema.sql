-- ============================================================
-- L2-D : Script de contrôle du schéma NanoOrbit
-- Vérification des tables, contraintes et triggers
-- Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- ============================================================


-- -------------------------------------------------------
-- 1. Vérification des tables créées
-- Attendu : 11 tables (10 + HISTORIQUE_STATUT)
-- -------------------------------------------------------
SELECT table_name, num_rows
FROM user_tables
WHERE table_name IN (
                     'ORBITE', 'SATELLITE', 'INSTRUMENT', 'EMBARQUEMENT',
                     'CENTRE_CONTROLE', 'STATION_SOL', 'AFFECTATION_STATION',
                     'MISSION', 'FENETRE_COM', 'PARTICIPATION', 'HISTORIQUE_STATUT'
    )
ORDER BY table_name;

-- -------------------------------------------------------
-- 2. Vérification des contraintes
-- -------------------------------------------------------
SELECT table_name, constraint_name, constraint_type, status
FROM user_constraints
WHERE table_name IN (
                     'ORBITE', 'SATELLITE', 'INSTRUMENT', 'EMBARQUEMENT',
                     'CENTRE_CONTROLE', 'STATION_SOL', 'AFFECTATION_STATION',
                     'MISSION', 'FENETRE_COM', 'PARTICIPATION', 'HISTORIQUE_STATUT'
    )
ORDER BY table_name, constraint_type;

-- -------------------------------------------------------
-- 3. Vérification des triggers
-- Attendu : 5 triggers (T1 à T5), tous ENABLED
-- -------------------------------------------------------
SELECT trigger_name, table_name, trigger_type, triggering_event, status
FROM user_triggers
WHERE table_name IN ('FENETRE_COM', 'PARTICIPATION', 'SATELLITE')
ORDER BY table_name, trigger_name;

-- -------------------------------------------------------
-- 4. Vérification du volume de données DML
-- -------------------------------------------------------
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
-- Résultat attendu :
--   AFFECTATION_STATION : 3   CENTRE_CONTROLE : 2   EMBARQUEMENT : 7
--   FENETRE_COM : 5           HISTORIQUE_STATUT : 0  INSTRUMENT : 4
--   MISSION : 3               ORBITE : 3             PARTICIPATION : 7
--   SATELLITE : 5             STATION_SOL : 3

-- -------------------------------------------------------
-- 5. Vérification de la cohérence des FK
-- -------------------------------------------------------
-- Satellites sans orbite correspondante (doit renvoyer 0)
SELECT COUNT(*) AS satellites_orphelins
FROM SATELLITE s
         LEFT JOIN ORBITE o ON s.id_orbite = o.id_orbite
WHERE o.id_orbite IS NULL;

-- Fenêtres sans satellite valide (doit renvoyer 0)
SELECT COUNT(*) AS fenetres_orphelines
FROM FENETRE_COM f
         LEFT JOIN SATELLITE s ON f.id_satellite = s.id_satellite
WHERE s.id_satellite IS NULL;

-- -------------------------------------------------------
-- 6. Test rapide trigger T1 (satellite Désorbité)
-- -------------------------------------------------------
BEGIN
    INSERT INTO FENETRE_COM
    (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, statut)
    VALUES
        ('SAT-005', 'GS-KIR-01', SYSTIMESTAMP, 300, 45.0, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('ECHEC : T1 n''a pas bloqué SAT-005 (Désorbité)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK T1 : ' || SUBSTR(SQLERRM, 1, 80));
END;
/

-- -------------------------------------------------------
-- 7. Test rapide trigger T4 — RG-M04 (mission Terminée)
-- -------------------------------------------------------
BEGIN
    -- SAT-003 (Opérationnel) vers MSN-DEF-2022 (Terminée)
    -- T4 doit bloquer via RG-M04 (ORA-20004)
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-003', 'MSN-DEF-2022', 'Imageur test');
    DBMS_OUTPUT.PUT_LINE('ECHEC : T4 n''a pas bloqué MSN-DEF-2022 (Terminée)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK T4 RG-M04 : ' || SUBSTR(SQLERRM, 1, 80));
END;
/

-- -------------------------------------------------------
-- 8. Test rapide trigger T4 — RG-S06 (satellite Désorbité)
-- -------------------------------------------------------
BEGIN
    -- SAT-005 (Désorbité) vers MSN-ARC-2023 (Active)
    -- T4 doit bloquer via RG-S06 (ORA-20005)
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-005', 'MSN-ARC-2023', 'Test RG-S06');
    DBMS_OUTPUT.PUT_LINE('ECHEC : T4 n''a pas bloqué SAT-005 (Désorbité)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK T4 RG-S06 : ' || SUBSTR(SQLERRM, 1, 80));
END;
/