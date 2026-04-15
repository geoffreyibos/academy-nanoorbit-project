-- ============================================================
-- DML : CENTRE_CONTROLE (2 lignes)
-- Seuls CTR-001 (Paris) et CTR-002 (Houston) sont insérés
-- dans le jeu de données initial.
-- CTR-003 (Singapour) est réservé à la Phase 4 — Ex.16 (MERGE INTO)
-- ============================================================

INSERT INTO CENTRE_CONTROLE (id_centre, nom_centre, ville, region, fuseau_horaire, statut)
VALUES ('CTR-001', 'NanoOrbit Paris HQ', 'Paris', 'Europe', 'Europe/Paris', 'Actif');

INSERT INTO CENTRE_CONTROLE (id_centre, nom_centre, ville, region, fuseau_horaire, statut)
VALUES ('CTR-002', 'NanoOrbit Houston', 'Houston', 'Amériques', 'America/Chicago', 'Actif');

COMMIT;
