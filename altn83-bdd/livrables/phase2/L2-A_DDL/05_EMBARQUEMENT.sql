-- ============================================================
-- Table : EMBARQUEMENT
-- Description : Association satellite ↔ instrument avec attributs porteurs
-- Dépend de : SATELLITE, INSTRUMENT
-- ============================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE EMBARQUEMENT CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE EMBARQUEMENT (
    id_satellite        VARCHAR2(20)    NOT NULL,
    ref_instrument      VARCHAR2(20)    NOT NULL,
    date_integration    DATE            NOT NULL,
    etat_fonctionnement VARCHAR2(20)    NOT NULL,
    commentaire         VARCHAR2(255),

    CONSTRAINT pk_embarquement
        PRIMARY KEY (id_satellite, ref_instrument),

    CONSTRAINT fk_embarquement_satellite
        FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite),

    CONSTRAINT fk_embarquement_instrument
        FOREIGN KEY (ref_instrument) REFERENCES INSTRUMENT(ref_instrument),

    CONSTRAINT ck_embarquement_etat
        CHECK (etat_fonctionnement IN ('Nominal', 'Dégradé', 'Hors service'))
);
