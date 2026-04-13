-- ============================================================
-- DML : SATELLITE (5 lignes — dont 1 Désorbité)
-- FK id_orbite → ORBITE (ORB-001, ORB-002, ORB-003)
-- SAT-005 (Désorbité) inclus pour tester le trigger T1
-- ============================================================

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse_kg, format_cubesat, statut, duree_vie_mois, capacite_batterie_wh, id_orbite)
VALUES ('SAT-001', 'NanoOrbit-Alpha', TO_DATE('2022-03-15', 'YYYY-MM-DD'), 1.30, '3U', 'Opérationnel', 60, 20, 'ORB-001');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse_kg, format_cubesat, statut, duree_vie_mois, capacite_batterie_wh, id_orbite)
VALUES ('SAT-002', 'NanoOrbit-Beta', TO_DATE('2022-03-15', 'YYYY-MM-DD'), 1.30, '3U', 'Opérationnel', 60, 20, 'ORB-001');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse_kg, format_cubesat, statut, duree_vie_mois, capacite_batterie_wh, id_orbite)
VALUES ('SAT-003', 'NanoOrbit-Gamma', TO_DATE('2023-06-10', 'YYYY-MM-DD'), 2.00, '6U', 'Opérationnel', 84, 40, 'ORB-002');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse_kg, format_cubesat, statut, duree_vie_mois, capacite_batterie_wh, id_orbite)
VALUES ('SAT-004', 'NanoOrbit-Delta', TO_DATE('2023-06-10', 'YYYY-MM-DD'), 2.00, '6U', 'En veille', 84, 40, 'ORB-002');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse_kg, format_cubesat, statut, duree_vie_mois, capacite_batterie_wh, id_orbite)
VALUES ('SAT-005', 'NanoOrbit-Epsilon', TO_DATE('2021-11-20', 'YYYY-MM-DD'), 4.50, '12U', 'Désorbité', 36, 80, 'ORB-003');

COMMIT;
