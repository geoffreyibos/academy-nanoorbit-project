-- ============================================================
-- Table : AFFECTATION_STATION
-- Description : Rattachement d'une station à un centre de contrôle
-- Dépend de : CENTRE_CONTROLE, STATION_SOL
-- ============================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE AFFECTATION_STATION CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE AFFECTATION_STATION (
    id_centre           VARCHAR2(20)    NOT NULL,
    code_station        VARCHAR2(20)    NOT NULL,
    date_affectation    DATE            NOT NULL,
    commentaire         VARCHAR2(255),

    CONSTRAINT pk_affectation_station
        PRIMARY KEY (id_centre, code_station),

    CONSTRAINT fk_affectation_centre
        FOREIGN KEY (id_centre) REFERENCES CENTRE_CONTROLE(id_centre),

    CONSTRAINT fk_affectation_station
        FOREIGN KEY (code_station) REFERENCES STATION_SOL(code_station)
);
