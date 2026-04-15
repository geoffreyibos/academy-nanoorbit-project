-- ============================================================
-- DML : MISSION (3 lignes)
-- date_fin NULL pour les missions encore actives
-- ============================================================

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-ARC-2023', 'ArcticWatch 2023',
        'Surveillance de la fonte des glaces et dynamique des banquises arctiques',
        'Arctique / Groenland',
        TO_DATE('2023-01-01', 'YYYY-MM-DD'), NULL, 'Active');

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-DEF-2022', 'DeforestAlert',
        'Détection et cartographie de la déforestation en temps quasi-réel',
        'Amazonie / Congo',
        TO_DATE('2022-06-01', 'YYYY-MM-DD'), TO_DATE('2023-05-31', 'YYYY-MM-DD'), 'Terminée');

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-COAST-2024', 'CoastGuard 2024',
        'Surveillance de l''évolution du trait de côte et détection d''érosion côtière',
        'Méditerranée / Atlantique',
        TO_DATE('2024-03-01', 'YYYY-MM-DD'), NULL, 'Active');

COMMIT;
