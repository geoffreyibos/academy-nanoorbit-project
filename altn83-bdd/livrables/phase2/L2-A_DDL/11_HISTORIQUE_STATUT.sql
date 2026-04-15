-- ============================================================
-- Table : HISTORIQUE_STATUT
-- Description : Traçabilité des changements de statut des satellites
-- Dépend de : SATELLITE
-- Créée après SATELLITE — alimentée exclusivement par le trigger T5
-- Aucun INSERT manuel dans le DML (L2-B)
-- ============================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE HISTORIQUE_STATUT CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE HISTORIQUE_STATUT (
    id_historique   NUMBER          GENERATED ALWAYS AS IDENTITY,
    id_satellite    VARCHAR2(20)    NOT NULL,
    ancien_statut   VARCHAR2(30)    NOT NULL,
    nouveau_statut  VARCHAR2(30)    NOT NULL,
    date_changement TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    motif           VARCHAR2(500),

    CONSTRAINT pk_historique_statut
        PRIMARY KEY (id_historique),

    CONSTRAINT fk_historique_satellite
        FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite)
);
