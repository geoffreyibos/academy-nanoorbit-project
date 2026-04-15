-- ============================================================
-- DML : STATION_SOL (3 lignes)
-- ============================================================

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne_m, bande_frequence, debit_max_mbps, statut)
VALUES ('GS-TLS-01', 'Toulouse Ground Station', 43.6047, 1.4442, 3.5, 'S', 150, 'Active');

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne_m, bande_frequence, debit_max_mbps, statut)
VALUES ('GS-KIR-01', 'Kiruna Arctic Station', 67.8557, 20.2253, 5.4, 'X', 400, 'Active');

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne_m, bande_frequence, debit_max_mbps, statut)
VALUES ('GS-SGP-01', 'Singapore Station', 1.3521, 103.8198, 3.0, 'S', 120, 'Maintenance');

COMMIT;
