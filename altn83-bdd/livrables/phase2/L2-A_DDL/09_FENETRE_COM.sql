-- ============================================================
-- Table : FENETRE_COM
-- Description : Fenêtres de communication satellite ↔ station sol
-- Dépend de : SATELLITE, STATION_SOL
-- ============================================================
--
-- Q3 — Comment implémenter RG-F02 (pas de chevauchement de
-- fenêtres pour un même satellite) ?
-- Cette contrainte n'est PAS exprimable en CHECK : un CHECK ne
-- peut pas comparer une ligne avec les autres lignes de la table.
-- Solution : trigger COMPOUND BEFORE INSERT OR UPDATE (T2) qui,
-- en phase AFTER STATEMENT, fait un SELECT COUNT(*) sur
-- FENETRE_COM pour détecter tout intervalle [debut, debut+duree]
-- qui chevauche la nouvelle fenêtre sur le même satellite ou la
-- même station. Un Compound Trigger est nécessaire pour éviter
-- l'erreur ORA-04091 (table mutante).
-- ============================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE FENETRE_COM CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE FENETRE_COM (
    id_fenetre          NUMBER          GENERATED ALWAYS AS IDENTITY,
    id_satellite        VARCHAR2(20)    NOT NULL,
    code_station        VARCHAR2(20)    NOT NULL,
    datetime_debut      TIMESTAMP       NOT NULL,
    duree_secondes      NUMBER(4)       NOT NULL,
    elevation_max_deg   NUMBER(5,2)     NOT NULL,
    volume_donnees_mo   NUMBER(8,1),
    statut              VARCHAR2(20)    NOT NULL,

    CONSTRAINT pk_fenetre_com
        PRIMARY KEY (id_fenetre),

    CONSTRAINT fk_fenetre_satellite
        FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite),

    CONSTRAINT fk_fenetre_station
        FOREIGN KEY (code_station) REFERENCES STATION_SOL(code_station),

    CONSTRAINT ck_fenetre_duree
        CHECK (duree_secondes BETWEEN 1 AND 900),

    CONSTRAINT ck_fenetre_statut
        CHECK (statut IN ('Planifiée', 'Réalisée'))
);
