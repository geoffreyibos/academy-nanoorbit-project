-- ============================================================
-- Table : INSTRUMENT
-- Description : Catalogue global des instruments embarquables
-- ============================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE INSTRUMENT CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE INSTRUMENT (
    ref_instrument      VARCHAR2(20)    NOT NULL,
    type_instrument     VARCHAR2(50)    NOT NULL,
    modele              VARCHAR2(100)   NOT NULL,
    resolution_m        NUMBER(6,1),
    consommation_w      NUMBER(5,2)     NOT NULL,
    masse_kg            NUMBER(5,3)     NOT NULL,

    CONSTRAINT pk_instrument
        PRIMARY KEY (ref_instrument)
);
