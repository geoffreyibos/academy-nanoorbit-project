-- ============================================================
-- Table : PARTICIPATION
-- Description : Association satellite ↔ mission avec rôle
-- Dépend de : SATELLITE, MISSION
-- ============================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE PARTICIPATION CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE PARTICIPATION (
    id_satellite    VARCHAR2(20)    NOT NULL,
    id_mission      VARCHAR2(20)    NOT NULL,
    role_satellite  VARCHAR2(100)   NOT NULL,

    CONSTRAINT pk_participation
        PRIMARY KEY (id_satellite, id_mission),

    CONSTRAINT fk_participation_satellite
        FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite),

    CONSTRAINT fk_participation_mission
        FOREIGN KEY (id_mission) REFERENCES MISSION(id_mission)
);
