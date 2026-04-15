-- ============================================================
-- DML : AFFECTATION_STATION (3 lignes)
-- FK id_centre → CENTRE_CONTROLE (CTR-001, CTR-002)
-- CTR-001 (Paris) supervise GS-TLS-01 et GS-KIR-01 (missions polaires SSO)
-- CTR-002 (Houston) supervise GS-SGP-01 (couverture zone Asie-Pacifique)
-- Date d'affectation de GS-SGP-01 : 2023-03-15 (per Annexe A)
-- ============================================================

INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation, commentaire)
VALUES ('CTR-001', 'GS-TLS-01', TO_DATE('2022-01-10', 'YYYY-MM-DD'),
        'Paris HQ supervise la station de Toulouse — proximité géographique');

INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation, commentaire)
VALUES ('CTR-001', 'GS-KIR-01', TO_DATE('2022-01-10', 'YYYY-MM-DD'),
        'Paris HQ supervise également Kiruna — missions polaires SSO');

INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation, commentaire)
VALUES ('CTR-002', 'GS-SGP-01', TO_DATE('2023-03-15', 'YYYY-MM-DD'),
        'Houston supervise Singapour — couverture zone Asie-Pacifique');

COMMIT;
