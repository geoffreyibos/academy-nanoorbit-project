-- ============================================================
-- Phase 2 — Partie 1/6 : DDL — Création des 11 tables
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 2 — [1/6] DDL — Creation des tables
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT ORBITE — catalogue des orbites disponibles
-- ────────────────────────────────────────────────────────────
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
    CONSTRAINT pk_orbite                    PRIMARY KEY (id_orbite),
    CONSTRAINT ck_orbite_type               CHECK (type_orbite IN ('LEO', 'MEO', 'SSO', 'GEO')),
    CONSTRAINT uq_orbite_altitude_inclinaison UNIQUE (altitude_km, inclinaison_deg)
);

-- ────────────────────────────────────────────────────────────
PROMPT CENTRE_CONTROLE — centres opérationnels (Paris, Houston, Singapour)
-- ────────────────────────────────────────────────────────────
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
    CONSTRAINT pk_centre_controle PRIMARY KEY (id_centre),
    CONSTRAINT ck_centre_region   CHECK (region IN ('Europe', 'Amériques', 'Asie-Pacifique')),
    CONSTRAINT ck_centre_statut   CHECK (statut IN ('Actif', 'Inactif'))
);

-- ────────────────────────────────────────────────────────────
PROMPT SATELLITE — CubeSats de la constellation NanoOrbit
PROMPT   FK id_orbite -> ORBITE : tout satellite doit avoir une orbite connue (RG-S02)
PROMPT   RG-S06 (satellite Desorbite) : non exprimable en CHECK — traite par T1 et T4
-- ────────────────────────────────────────────────────────────
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE SATELLITE CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE SATELLITE (
    id_satellite         VARCHAR2(20)    NOT NULL,
    nom_satellite        VARCHAR2(100)   NOT NULL,
    date_lancement       DATE            NOT NULL,
    masse_kg             NUMBER(5,2)     NOT NULL,
    format_cubesat       VARCHAR2(5)     NOT NULL,
    statut               VARCHAR2(30)    NOT NULL,
    duree_vie_mois       NUMBER(4)       NOT NULL,
    capacite_batterie_wh NUMBER(6,1)     NOT NULL,
    id_orbite            VARCHAR2(10)    NOT NULL,
    CONSTRAINT pk_satellite         PRIMARY KEY (id_satellite),
    CONSTRAINT fk_satellite_orbite  FOREIGN KEY (id_orbite) REFERENCES ORBITE(id_orbite),
    CONSTRAINT ck_satellite_format  CHECK (format_cubesat IN ('1U', '3U', '6U', '12U')),
    CONSTRAINT ck_satellite_statut  CHECK (statut IN ('Opérationnel', 'En veille', 'Défaillant', 'Désorbité'))
);

-- ────────────────────────────────────────────────────────────
PROMPT INSTRUMENT — catalogue global des instruments embarquables
-- ────────────────────────────────────────────────────────────
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE INSTRUMENT CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE INSTRUMENT (
    ref_instrument   VARCHAR2(20)    NOT NULL,
    type_instrument  VARCHAR2(50)    NOT NULL,
    modele           VARCHAR2(100)   NOT NULL,
    resolution_m     NUMBER(6,1),
    consommation_w   NUMBER(5,2)     NOT NULL,
    masse_kg         NUMBER(5,3)     NOT NULL,
    CONSTRAINT pk_instrument PRIMARY KEY (ref_instrument)
);

-- ────────────────────────────────────────────────────────────
PROMPT EMBARQUEMENT — association satellite <-> instrument (PK composite)
-- ────────────────────────────────────────────────────────────
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
    CONSTRAINT pk_embarquement              PRIMARY KEY (id_satellite, ref_instrument),
    CONSTRAINT fk_embarquement_satellite    FOREIGN KEY (id_satellite)   REFERENCES SATELLITE(id_satellite),
    CONSTRAINT fk_embarquement_instrument   FOREIGN KEY (ref_instrument) REFERENCES INSTRUMENT(ref_instrument),
    CONSTRAINT ck_embarquement_etat         CHECK (etat_fonctionnement IN ('Nominal', 'Dégradé', 'Hors service'))
);

-- ────────────────────────────────────────────────────────────
PROMPT STATION_SOL — stations de reception au sol
-- ────────────────────────────────────────────────────────────
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE STATION_SOL CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE STATION_SOL (
    code_station       VARCHAR2(20)    NOT NULL,
    nom_station        VARCHAR2(100)   NOT NULL,
    latitude           NUMBER(9,6)     NOT NULL,
    longitude          NUMBER(9,6)     NOT NULL,
    diametre_antenne_m NUMBER(4,1)     NOT NULL,
    bande_frequence    VARCHAR2(10)    NOT NULL,
    debit_max_mbps     NUMBER(6,1)     NOT NULL,
    statut             VARCHAR2(20)    NOT NULL,
    CONSTRAINT pk_station_sol    PRIMARY KEY (code_station),
    CONSTRAINT ck_station_bande  CHECK (bande_frequence IN ('UHF', 'S', 'X', 'Ka')),
    CONSTRAINT ck_station_statut CHECK (statut IN ('Active', 'Maintenance', 'Inactive'))
);

-- ────────────────────────────────────────────────────────────
PROMPT AFFECTATION_STATION — rattachement station <-> centre de controle
-- ────────────────────────────────────────────────────────────
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE AFFECTATION_STATION CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE AFFECTATION_STATION (
    id_centre        VARCHAR2(20)    NOT NULL,
    code_station     VARCHAR2(20)    NOT NULL,
    date_affectation DATE            NOT NULL,
    commentaire      VARCHAR2(255),
    CONSTRAINT pk_affectation_station PRIMARY KEY (id_centre, code_station),
    CONSTRAINT fk_affectation_centre  FOREIGN KEY (id_centre)    REFERENCES CENTRE_CONTROLE(id_centre),
    CONSTRAINT fk_affectation_station FOREIGN KEY (code_station) REFERENCES STATION_SOL(code_station)
);

-- ────────────────────────────────────────────────────────────
PROMPT MISSION — missions d'observation terrestre
-- ────────────────────────────────────────────────────────────
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE MISSION CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE MISSION (
    id_mission     VARCHAR2(20)    NOT NULL,
    nom_mission    VARCHAR2(100)   NOT NULL,
    objectif       VARCHAR2(500)   NOT NULL,
    zone_cible     VARCHAR2(200)   NOT NULL,
    date_debut     DATE            NOT NULL,
    date_fin       DATE,
    statut_mission VARCHAR2(20)    NOT NULL,
    CONSTRAINT pk_mission        PRIMARY KEY (id_mission),
    CONSTRAINT ck_mission_statut CHECK (statut_mission IN ('Active', 'Terminée'))
);

-- ────────────────────────────────────────────────────────────
PROMPT FENETRE_COM — fenetres de communication satellite <-> station
PROMPT   RG-F02 (chevauchement) : non exprimable en CHECK — traite par T2 (Compound Trigger)
PROMPT   id_fenetre : GENERATED ALWAYS AS IDENTITY
-- ────────────────────────────────────────────────────────────
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE FENETRE_COM CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE FENETRE_COM (
    id_fenetre        NUMBER          GENERATED ALWAYS AS IDENTITY,
    id_satellite      VARCHAR2(20)    NOT NULL,
    code_station      VARCHAR2(20)    NOT NULL,
    datetime_debut    TIMESTAMP       NOT NULL,
    duree_secondes    NUMBER(4)       NOT NULL,
    elevation_max_deg NUMBER(5,2)     NOT NULL,
    volume_donnees_mo NUMBER(8,1),
    statut            VARCHAR2(20)    NOT NULL,
    CONSTRAINT pk_fenetre_com      PRIMARY KEY (id_fenetre),
    CONSTRAINT fk_fenetre_satellite FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite),
    CONSTRAINT fk_fenetre_station   FOREIGN KEY (code_station) REFERENCES STATION_SOL(code_station),
    CONSTRAINT ck_fenetre_duree     CHECK (duree_secondes BETWEEN 1 AND 900),
    CONSTRAINT ck_fenetre_statut    CHECK (statut IN ('Planifiée', 'Réalisée'))
);

-- ────────────────────────────────────────────────────────────
PROMPT PARTICIPATION — association satellite <-> mission avec role
-- ────────────────────────────────────────────────────────────
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE PARTICIPATION CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE PARTICIPATION (
    id_satellite   VARCHAR2(20)    NOT NULL,
    id_mission     VARCHAR2(20)    NOT NULL,
    role_satellite VARCHAR2(100)   NOT NULL,
    CONSTRAINT pk_participation          PRIMARY KEY (id_satellite, id_mission),
    CONSTRAINT fk_participation_satellite FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite),
    CONSTRAINT fk_participation_mission   FOREIGN KEY (id_mission)   REFERENCES MISSION(id_mission)
);

-- ────────────────────────────────────────────────────────────
PROMPT HISTORIQUE_STATUT — tracabilite des changements de statut (alimente par T5)
-- ────────────────────────────────────────────────────────────
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
    CONSTRAINT pk_historique_statut   PRIMARY KEY (id_historique),
    CONSTRAINT fk_historique_satellite FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite)
);

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Partie 1/6 terminee — 11 tables creees.
PROMPT ────────────────────────────────────────────
PROMPT
