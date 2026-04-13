-- ============================================================
-- Table : STATION_SOL
-- Description : Stations de réception au sol
-- Dépend de : CENTRE_CONTROLE
-- ============================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE STATION_SOL CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE STATION_SOL (
    code_station        VARCHAR2(20)    NOT NULL,
    nom_station         VARCHAR2(100)   NOT NULL,
    latitude            NUMBER(9,6)     NOT NULL,
    longitude           NUMBER(9,6)     NOT NULL,
    diametre_antenne_m  NUMBER(4,1)     NOT NULL,
    bande_frequence     VARCHAR2(10)    NOT NULL,
    debit_max_mbps      NUMBER(6,1)     NOT NULL,
    statut              VARCHAR2(20)    NOT NULL,

    CONSTRAINT pk_station_sol
        PRIMARY KEY (code_station),

    CONSTRAINT ck_station_bande
        CHECK (bande_frequence IN ('UHF', 'S', 'X', 'Ka')),

    CONSTRAINT ck_station_statut
        CHECK (statut IN ('Active', 'Maintenance', 'Inactive'))
);
