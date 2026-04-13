-- ============================================================
-- Table : MISSION
-- Description : Missions d'observation terrestre
-- ============================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE MISSION CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE MISSION (
    id_mission      VARCHAR2(20)    NOT NULL,
    nom_mission     VARCHAR2(100)   NOT NULL,
    objectif        VARCHAR2(500)   NOT NULL,
    zone_cible      VARCHAR2(200)   NOT NULL,
    date_debut      DATE            NOT NULL,
    date_fin        DATE,
    statut_mission  VARCHAR2(20)    NOT NULL,

    CONSTRAINT pk_mission
        PRIMARY KEY (id_mission),

    CONSTRAINT ck_mission_statut
        CHECK (statut_mission IN ('Active', 'Terminée'))
);
