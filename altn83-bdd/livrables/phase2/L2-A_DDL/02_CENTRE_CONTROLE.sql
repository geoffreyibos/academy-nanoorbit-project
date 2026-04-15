-- ============================================================
-- Table : CENTRE_CONTROLE
-- Description : Centres de contrôle opérationnels (Paris, Houston, Singapour)
-- ============================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE CENTRE_CONTROLE CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE CENTRE_CONTROLE (
    id_centre       VARCHAR2(20)    NOT NULL,
    nom_centre      VARCHAR2(100)   NOT NULL,
    ville           VARCHAR2(50)    NOT NULL,
    region          VARCHAR2(50)    NOT NULL,
    fuseau_horaire  VARCHAR2(50)    NOT NULL,
    statut          VARCHAR2(20)    NOT NULL,

    CONSTRAINT pk_centre_controle
        PRIMARY KEY (id_centre),

    CONSTRAINT ck_centre_region
        CHECK (region IN ('Europe', 'Amériques', 'Asie-Pacifique')),

    CONSTRAINT ck_centre_statut
        CHECK (statut IN ('Actif', 'Inactif'))
);
