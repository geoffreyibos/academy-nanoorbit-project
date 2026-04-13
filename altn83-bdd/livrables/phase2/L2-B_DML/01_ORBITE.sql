-- ============================================================
-- DML : ORBITE (3 lignes)
-- Identifiants format ORB-NNN conformément à l'Annexe A
-- ============================================================

INSERT INTO ORBITE (id_orbite, type_orbite, altitude_km, inclinaison_deg, periode_min, excentricite, zone_couverture)
VALUES ('ORB-001', 'SSO', 550, 97.6, 95.5, 0.0010, 'Polaire globale — Europe / Arctique');

INSERT INTO ORBITE (id_orbite, type_orbite, altitude_km, inclinaison_deg, periode_min, excentricite, zone_couverture)
VALUES ('ORB-002', 'SSO', 700, 98.2, 98.8, 0.0008, 'Polaire globale — haute latitude');

INSERT INTO ORBITE (id_orbite, type_orbite, altitude_km, inclinaison_deg, periode_min, excentricite, zone_couverture)
VALUES ('ORB-003', 'LEO', 400, 51.6, 92.6, 0.0020, 'Équatoriale — zone tropicale');

COMMIT;
