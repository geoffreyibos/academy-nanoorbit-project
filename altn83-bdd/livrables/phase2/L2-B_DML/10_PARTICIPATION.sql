-- ============================================================
-- DML : PARTICIPATION (7 lignes)
-- ============================================================

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
