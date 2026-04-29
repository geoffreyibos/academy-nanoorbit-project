-- ============================================================
-- Phase 2 — Partie 2/6 : DML — Données de référence
-- Prérequis : Partie 1 executee (tables creees)
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 2 — [2/6] DML — Donnees de reference
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT ORBITE — 3 orbites (2 SSO polaires, 1 LEO equatoriale)
-- ────────────────────────────────────────────────────────────
INSERT INTO ORBITE (id_orbite, type_orbite, altitude_km, inclinaison_deg, periode_min, excentricite, zone_couverture)
VALUES ('ORB-001', 'SSO', 550, 97.6, 95.5, 0.0010, 'Polaire globale — Europe / Arctique');

INSERT INTO ORBITE (id_orbite, type_orbite, altitude_km, inclinaison_deg, periode_min, excentricite, zone_couverture)
VALUES ('ORB-002', 'SSO', 700, 98.2, 98.8, 0.0008, 'Polaire globale — haute latitude');

INSERT INTO ORBITE (id_orbite, type_orbite, altitude_km, inclinaison_deg, periode_min, excentricite, zone_couverture)
VALUES ('ORB-003', 'LEO', 400, 51.6, 92.6, 0.0020, 'Équatoriale — zone tropicale');

COMMIT;

-- ────────────────────────────────────────────────────────────
PROMPT CENTRE_CONTROLE — 2 centres (CTR-003 Singapour reserve pour Phase 4)
-- ────────────────────────────────────────────────────────────
INSERT INTO CENTRE_CONTROLE (id_centre, nom_centre, ville, region, fuseau_horaire, statut)
VALUES ('CTR-001', 'NanoOrbit Paris HQ', 'Paris', 'Europe', 'Europe/Paris', 'Actif');

INSERT INTO CENTRE_CONTROLE (id_centre, nom_centre, ville, region, fuseau_horaire, statut)
VALUES ('CTR-002', 'NanoOrbit Houston', 'Houston', 'Amériques', 'America/Chicago', 'Actif');

COMMIT;

-- ────────────────────────────────────────────────────────────
PROMPT SATELLITE — 5 satellites (4 actifs/veille, 1 Desorbite pour tester T1)
-- ────────────────────────────────────────────────────────────
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

-- ────────────────────────────────────────────────────────────
PROMPT INSTRUMENT — 4 instruments (resolution_m NULL pour INS-AIS-01)
-- ────────────────────────────────────────────────────────────
INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution_m, consommation_w, masse_kg)
VALUES ('INS-CAM-01', 'Caméra optique', 'PlanetScope-Mini', 3, 2.5, 0.4);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution_m, consommation_w, masse_kg)
VALUES ('INS-IR-01', 'Infrarouge', 'FLIR-Lepton-3', 160, 1.2, 0.15);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution_m, consommation_w, masse_kg)
VALUES ('INS-AIS-01', 'Récepteur AIS', 'ShipTrack-V2', NULL, 0.8, 0.12);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution_m, consommation_w, masse_kg)
VALUES ('INS-SPEC-01', 'Spectromètre', 'HyperSpec-Nano', 30, 3.1, 0.6);

COMMIT;

-- ────────────────────────────────────────────────────────────
PROMPT EMBARQUEMENT — 7 lignes (PK composite id_satellite + ref_instrument)
-- ────────────────────────────────────────────────────────────
INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement, commentaire)
VALUES ('SAT-001', 'INS-CAM-01', TO_DATE('2022-03-15', 'YYYY-MM-DD'), 'Nominal',
        'Imageur principal Alpha');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement, commentaire)
VALUES ('SAT-001', 'INS-IR-01', TO_DATE('2022-03-15', 'YYYY-MM-DD'), 'Nominal',
        'Détection thermique complémentaire');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement, commentaire)
VALUES ('SAT-002', 'INS-CAM-01', TO_DATE('2022-03-15', 'YYYY-MM-DD'), 'Nominal',
        'Imageur secondaire — même modèle que SAT-001');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement, commentaire)
VALUES ('SAT-003', 'INS-CAM-01', TO_DATE('2023-06-10', 'YYYY-MM-DD'), 'Nominal',
        'Caméra haute résolution — 6U');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement, commentaire)
VALUES ('SAT-003', 'INS-SPEC-01', TO_DATE('2023-06-10', 'YYYY-MM-DD'), 'Nominal',
        'Spectromètre — surveillance qualité de l''air');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement, commentaire)
VALUES ('SAT-004', 'INS-IR-01', TO_DATE('2023-06-10', 'YYYY-MM-DD'), 'Dégradé',
        'Résolution réduite — satellite en veille');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement, commentaire)
VALUES ('SAT-005', 'INS-AIS-01', TO_DATE('2021-11-20', 'YYYY-MM-DD'), 'Hors service',
        'SAT-005 désorbité — instrument non récupérable');

COMMIT;

-- ────────────────────────────────────────────────────────────
PROMPT STATION_SOL — 3 stations (GS-SGP-01 en Maintenance pour tester T1)
-- ────────────────────────────────────────────────────────────
INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne_m, bande_frequence, debit_max_mbps, statut)
VALUES ('GS-TLS-01', 'Toulouse Ground Station', 43.6047, 1.4442, 3.5, 'S', 150, 'Active');

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne_m, bande_frequence, debit_max_mbps, statut)
VALUES ('GS-KIR-01', 'Kiruna Arctic Station', 67.8557, 20.2253, 5.4, 'X', 400, 'Active');

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne_m, bande_frequence, debit_max_mbps, statut)
VALUES ('GS-SGP-01', 'Singapore Station', 1.3521, 103.8198, 3.0, 'S', 120, 'Maintenance');

COMMIT;

-- ────────────────────────────────────────────────────────────
PROMPT AFFECTATION_STATION — CTR-001 supervise TLS+KIR, CTR-002 supervise SGP
-- ────────────────────────────────────────────────────────────
INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation, commentaire)
VALUES ('CTR-001', 'GS-TLS-01', TO_DATE('2022-01-10', 'YYYY-MM-DD'),
        'Paris HQ supervise Toulouse');

INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation, commentaire)
VALUES ('CTR-001', 'GS-KIR-01', TO_DATE('2022-01-10', 'YYYY-MM-DD'),
        'Paris HQ supervise Kiruna — missions polaires SSO');

INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation, commentaire)
VALUES ('CTR-002', 'GS-SGP-01', TO_DATE('2023-03-15', 'YYYY-MM-DD'),
        'Houston supervise Singapour — zone Asie-Pacifique');

COMMIT;

-- ────────────────────────────────────────────────────────────
PROMPT MISSION — 3 missions (2 actives, 1 terminee pour tester T4)
-- ────────────────────────────────────────────────────────────
INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-ARC-2023', 'ArcticWatch 2023',
        'Surveillance de la fonte des glaces et dynamique des banquises arctiques',
        'Arctique / Groenland', TO_DATE('2023-01-01', 'YYYY-MM-DD'), NULL, 'Active');

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-DEF-2022', 'DeforestAlert',
        'Détection et cartographie de la déforestation en temps quasi-réel',
        'Amazonie / Congo',
        TO_DATE('2022-06-01', 'YYYY-MM-DD'), TO_DATE('2023-05-31', 'YYYY-MM-DD'), 'Terminée');

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-COAST-2024', 'CoastGuard 2024',
        'Surveillance de l''évolution du trait de côte et détection d''érosion côtière',
        'Méditerranée / Atlantique', TO_DATE('2024-03-01', 'YYYY-MM-DD'), NULL, 'Active');

COMMIT;

-- ────────────────────────────────────────────────────────────
PROMPT FENETRE_COM — 5 fenetres (3 realisees, 2 planifiees)
PROMPT   id_fenetre omis — GENERATED ALWAYS AS IDENTITY
-- ────────────────────────────────────────────────────────────
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

-- ────────────────────────────────────────────────────────────
PROMPT PARTICIPATION — 7 lignes (SAT-005 insere en Phase 2 avant T4)
-- ────────────────────────────────────────────────────────────
INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-001', 'MSN-ARC-2023', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-002', 'MSN-ARC-2023', 'Imageur secondaire');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-003', 'MSN-ARC-2023', 'Satellite de relais');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-001', 'MSN-DEF-2022', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-005', 'MSN-DEF-2022', 'Imageur secondaire');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-003', 'MSN-COAST-2024', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-004', 'MSN-COAST-2024', 'Satellite de secours');

COMMIT;

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Partie 2/6 terminee — donnees inserees.
PROMPT ────────────────────────────────────────────
PROMPT
