-- ============================================================
-- Table : SATELLITE
-- Description : CubeSats de la constellation NanoOrbit
-- Dépend de : ORBITE
-- ============================================================
--
-- Q1 — Pourquoi ne peut-on pas créer SATELLITE avant ORBITE ?
-- SATELLITE porte une FK id_orbite → ORBITE(id_orbite). Oracle
-- refuse de créer une FK vers une table inexistante. Cela traduit
-- la règle RG-S02 : tout satellite est obligatoirement affecté
-- à une orbite connue du référentiel.
--
-- Q2 — RG-S06 (satellite Désorbité : plus de fenêtre ni de mission)
-- peut-elle être vérifiée au niveau DDL seul ?
-- Non. Un CHECK ne peut pas interroger une autre table, et une FK
-- ne peut pas conditionner les INSERT selon une valeur de colonne.
-- Solution : trigger BEFORE INSERT sur FENETRE_COM (T1) et
-- BEFORE INSERT sur PARTICIPATION (T4) qui vérifient le statut
-- du satellite via SELECT … INTO avant d'autoriser l'opération.
--
-- Q4 — Quel type Oracle pour format_cubesat (1U, 3U, 6U, 12U) ?
-- VARCHAR2(5) avec une contrainte CHECK IN ('1U','3U','6U','12U').
-- Un CHAR(2/3) fonctionnerait aussi mais VARCHAR2 est plus souple
-- si le format évolue (ex. '12U' fait 3 caractères). Un type
-- NUMBER serait inadapté car la valeur est alphanumérique.
-- ============================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE SATELLITE CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE SATELLITE (
    id_satellite        VARCHAR2(20)    NOT NULL,
    nom_satellite       VARCHAR2(100)   NOT NULL,
    date_lancement      DATE            NOT NULL,
    masse_kg            NUMBER(5,2)     NOT NULL,
    format_cubesat      VARCHAR2(5)     NOT NULL,
    statut              VARCHAR2(30)    NOT NULL,
    duree_vie_mois      NUMBER(4)       NOT NULL,
    capacite_batterie_wh NUMBER(6,1)   NOT NULL,
    id_orbite           VARCHAR2(10)    NOT NULL,

    CONSTRAINT pk_satellite
        PRIMARY KEY (id_satellite),

    CONSTRAINT fk_satellite_orbite
        FOREIGN KEY (id_orbite) REFERENCES ORBITE(id_orbite),

    CONSTRAINT ck_satellite_format
        CHECK (format_cubesat IN ('1U', '3U', '6U', '12U')),

    CONSTRAINT ck_satellite_statut
        CHECK (statut IN ('Opérationnel', 'En veille', 'Défaillant', 'Désorbité'))
);
