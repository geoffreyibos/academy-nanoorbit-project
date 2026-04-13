-- ============================================================
-- DML : FENETRE_COM (5 lignes)
-- id_fenetre omis — GENERATED ALWAYS AS IDENTITY
-- volume_donnees_mo NULL pour les fenêtres 'Planifiée'
-- ============================================================

INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-001', 'GS-KIR-01', TO_TIMESTAMP('2024-01-15 09:14:00', 'YYYY-MM-DD HH24:MI:SS'), 420, 82.3, 1250, 'Réalisée');

INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-002', 'GS-TLS-01', TO_TIMESTAMP('2024-01-15 11:52:00', 'YYYY-MM-DD HH24:MI:SS'), 310, 67.1, 890, 'Réalisée');

INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-003', 'GS-KIR-01', TO_TIMESTAMP('2024-01-16 08:30:00', 'YYYY-MM-DD HH24:MI:SS'), 540, 88.9, 1680, 'Réalisée');

INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-001', 'GS-TLS-01', TO_TIMESTAMP('2024-01-20 14:22:00', 'YYYY-MM-DD HH24:MI:SS'), 380, 71.4, NULL, 'Planifiée');

INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-003', 'GS-TLS-01', TO_TIMESTAMP('2024-01-21 07:45:00', 'YYYY-MM-DD HH24:MI:SS'), 290, 59.8, NULL, 'Planifiée');

COMMIT;
