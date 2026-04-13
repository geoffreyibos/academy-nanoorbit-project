-- ============================================================
-- DML : INSTRUMENT (4 lignes)
-- resolution_m NULL pour INS-AIS-01 (capteur non optique)
-- ============================================================

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution_m, consommation_w, masse_kg)
VALUES ('INS-CAM-01', 'Caméra optique', 'PlanetScope-Mini', 3, 2.5, 0.4);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution_m, consommation_w, masse_kg)
VALUES ('INS-IR-01', 'Infrarouge', 'FLIR-Lepton-3', 160, 1.2, 0.15);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution_m, consommation_w, masse_kg)
VALUES ('INS-AIS-01', 'Récepteur AIS', 'ShipTrack-V2', NULL, 0.8, 0.12);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution_m, consommation_w, masse_kg)
VALUES ('INS-SPEC-01', 'Spectromètre', 'HyperSpec-Nano', 30, 3.1, 0.6);

COMMIT;
