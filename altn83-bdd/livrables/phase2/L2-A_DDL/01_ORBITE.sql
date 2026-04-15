-- ============================================================
-- Table : ORBITE
-- Description : Catalogue des orbites disponibles
-- ============================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE ORBITE CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE ORBITE (
    id_orbite       VARCHAR2(10)    NOT NULL,
    type_orbite     VARCHAR2(10)    NOT NULL,
    altitude_km     NUMBER(5)       NOT NULL,
    inclinaison_deg NUMBER(5,2)     NOT NULL,
    periode_min     NUMBER(6,2)     NOT NULL,
    excentricite    NUMBER(6,4)     NOT NULL,
    zone_couverture VARCHAR2(200)   NOT NULL,

    CONSTRAINT pk_orbite
        PRIMARY KEY (id_orbite),

    CONSTRAINT ck_orbite_type
        CHECK (type_orbite IN ('LEO', 'MEO', 'SSO', 'GEO')),

    CONSTRAINT uq_orbite_altitude_inclinaison
        UNIQUE (altitude_km, inclinaison_deg)
);
