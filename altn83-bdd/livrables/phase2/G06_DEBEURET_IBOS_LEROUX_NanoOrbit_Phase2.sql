-- ============================================================
-- Projet NanoOrbit — Phase 2 : Schéma Oracle & Triggers
-- Groupe    : 06
-- Membres   : Oscar DEBEURET / Geoffrey IBOS / Hugo LEROUX
-- Date      : 2026-04-14
-- SGBD      : Oracle 23ai — NANOORBIT_ADMIN / FREEPDB1
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 2 — NanoOrbit  (DDL + DML + Triggers)
PROMPT ════════════════════════════════════════════
PROMPT
PROMPT [DDL] Creation des tables...

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
-- ============================================================
-- Table : MISSION
-- Description : Missions d'observation terrestre
-- ============================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE MISSION CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE MISSION (
    id_mission      VARCHAR2(20)    NOT NULL,
    nom_mission     VARCHAR2(100)   NOT NULL,
    objectif        VARCHAR2(500)   NOT NULL,
    zone_cible      VARCHAR2(200)   NOT NULL,
    date_debut      DATE            NOT NULL,
    date_fin        DATE,
    statut_mission  VARCHAR2(20)    NOT NULL,

    CONSTRAINT pk_mission
        PRIMARY KEY (id_mission),

    CONSTRAINT ck_mission_statut
        CHECK (statut_mission IN ('Active', 'Terminée'))
);
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
-- ============================================================
-- Table : PARTICIPATION
-- Description : Association satellite ↔ mission avec rôle
-- Dépend de : SATELLITE, MISSION
-- ============================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE PARTICIPATION CASCADE CONSTRAINTS PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE PARTICIPATION (
    id_satellite    VARCHAR2(20)    NOT NULL,
    id_mission      VARCHAR2(20)    NOT NULL,
    role_satellite  VARCHAR2(100)   NOT NULL,

    CONSTRAINT pk_participation
        PRIMARY KEY (id_satellite, id_mission),

    CONSTRAINT fk_participation_satellite
        FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite),

    CONSTRAINT fk_participation_mission
        FOREIGN KEY (id_mission) REFERENCES MISSION(id_mission)
);
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
-- ============================================================
PROMPT [DML] Insertion des donnees de reference...
-- DML : ORBITE (3 lignes)
-- Identifiants format ORB-NNN conformément à l'Annexe A
-- ============================================================

INSERT INTO ORBITE (id_orbite, type_orbite, altitude_km, inclinaison_deg, periode_min, excentricite, zone_couverture)
VALUES ('ORB-001', 'SSO', 550, 97.6, 95.5, 0.0010, 'Polaire globale — Europe / Arctique');

INSERT INTO ORBITE (id_orbite, type_orbite, altitude_km, inclinaison_deg, periode_min, excentricite, zone_couverture)
VALUES ('ORB-002', 'SSO', 700, 98.2, 98.8, 0.0008, 'Polaire globale — haute latitude');

INSERT INTO ORBITE (id_orbite, type_orbite, altitude_km, inclinaison_deg, periode_min, excentricite, zone_couverture)
VALUES ('ORB-003', 'LEO', 400, 51.6, 92.6, 0.0020, 'Équatoriale — zone tropicale');

COMMIT;
-- ============================================================
-- DML : CENTRE_CONTROLE (2 lignes)
-- Seuls CTR-001 (Paris) et CTR-002 (Houston) sont insérés
-- dans le jeu de données initial.
-- CTR-003 (Singapour) est réservé à la Phase 4 — Ex.16 (MERGE INTO)
-- ============================================================

INSERT INTO CENTRE_CONTROLE (id_centre, nom_centre, ville, region, fuseau_horaire, statut)
VALUES ('CTR-001', 'NanoOrbit Paris HQ', 'Paris', 'Europe', 'Europe/Paris', 'Actif');

INSERT INTO CENTRE_CONTROLE (id_centre, nom_centre, ville, region, fuseau_horaire, statut)
VALUES ('CTR-002', 'NanoOrbit Houston', 'Houston', 'Amériques', 'America/Chicago', 'Actif');

COMMIT;
-- ============================================================
-- DML : SATELLITE (5 lignes — dont 1 Désorbité)
-- FK id_orbite → ORBITE (ORB-001, ORB-002, ORB-003)
-- SAT-005 (Désorbité) inclus pour tester le trigger T1
-- ============================================================

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse_kg, format_cubesat, statut, duree_vie_mois, capacite_batterie_wh, id_orbite)
VALUES ('SAT-001', 'NanoOrbit-Alpha', TO_DATE('2022-03-15', 'YYYY-MM-DD'), 1.30, '3U', 'Opérationnel', 60, 20, 'ORB-001');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse_kg, format_cubesat, statut, duree_vie_mois, capacite_batterie_wh, id_orbite)
VALUES ('SAT-002', 'NanoOrbit-Beta', TO_DATE('2022-03-15', 'YYYY-MM-DD'), 1.30, '3U', 'Opérationnel', 60, 20, 'ORB-001');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse_kg, format_cubesat, statut, duree_vie_mois, capacite_batterie_wh, id_orbite)
VALUES ('SAT-003', 'NanoOrbit-Gamma', TO_DATE('2023-06-10', 'YYYY-MM-DD'), 2.00, '6U', 'Opérationnel', 84, 40, 'ORB-002');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse_kg, format_cubesat, statut, duree_vie_mois, capacite_batterie_wh, id_orbite)
VALUES ('SAT-004', 'NanoOrbit-Delta', TO_DATE('2023-06-10', 'YYYY-MM-DD'), 2.00, '6U', 'En veille', 84, 40, 'ORB-002');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse_kg, format_cubesat, statut, duree_vie_mois, capacite_batterie_wh, id_orbite)
VALUES ('SAT-005', 'NanoOrbit-Epsilon', TO_DATE('2021-11-20', 'YYYY-MM-DD'), 4.50, '12U', 'Désorbité', 36, 80, 'ORB-003');

COMMIT;
-- ============================================================
-- DML : INSTRUMENT (4 lignes)
-- resolution_m NULL pour INS-AIS-01 (capteur non optique)
-- ============================================================

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution_m, consommation_w, masse_kg)
VALUES ('INS-CAM-01', 'Caméra optique', 'PlanetScope-Mini', 3, 2.5, 0.4);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution_m, consommation_w, masse_kg)
VALUES ('INS-IR-01', 'Infrarouge', 'FLIR-Lepton-3', 160, 1.2, 0.15);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution_m, consommation_w, masse_kg)
VALUES ('INS-AIS-01', 'Récepteur AIS', 'ShipTrack-V2', NULL, 0.8, 0.12);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution_m, consommation_w, masse_kg)
VALUES ('INS-SPEC-01', 'Spectromètre', 'HyperSpec-Nano', 30, 3.1, 0.6);

COMMIT;
-- ============================================================
-- DML : EMBARQUEMENT (7 lignes)
-- PK composite (id_satellite, ref_instrument)
-- commentaire renseigné conformément à l'Annexe A
-- ============================================================

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement, commentaire)
VALUES ('SAT-001', 'INS-CAM-01', TO_DATE('2022-03-15', 'YYYY-MM-DD'), 'Nominal',
        'Imageur principal Alpha — utilisé dans MSN-DEF-2022 et MSN-ARC-2023');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement, commentaire)
VALUES ('SAT-001', 'INS-IR-01', TO_DATE('2022-03-15', 'YYYY-MM-DD'), 'Nominal',
        'Détection thermique complémentaire');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement, commentaire)
VALUES ('SAT-002', 'INS-CAM-01', TO_DATE('2022-03-15', 'YYYY-MM-DD'), 'Nominal',
        'Imageur secondaire — même modèle que SAT-001 (achat en lot)');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement, commentaire)
VALUES ('SAT-003', 'INS-CAM-01', TO_DATE('2023-06-10', 'YYYY-MM-DD'), 'Nominal',
        'Caméra haute résolution — 6U offre plus d''espace');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement, commentaire)
VALUES ('SAT-003', 'INS-SPEC-01', TO_DATE('2023-06-10', 'YYYY-MM-DD'), 'Nominal',
        'Spectromètre — mission surveillance qualité de l''air');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement, commentaire)
VALUES ('SAT-004', 'INS-IR-01', TO_DATE('2023-06-10', 'YYYY-MM-DD'), 'Dégradé',
        'Résolution réduite — satellite en veille depuis anomalie thermique');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement, commentaire)
VALUES ('SAT-005', 'INS-AIS-01', TO_DATE('2021-11-20', 'YYYY-MM-DD'), 'Hors service',
        'SAT-005 désorbité — instrument non récupérable');

COMMIT;
-- ============================================================
-- DML : STATION_SOL (3 lignes)
-- ============================================================

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne_m, bande_frequence, debit_max_mbps, statut)
VALUES ('GS-TLS-01', 'Toulouse Ground Station', 43.6047, 1.4442, 3.5, 'S', 150, 'Active');

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne_m, bande_frequence, debit_max_mbps, statut)
VALUES ('GS-KIR-01', 'Kiruna Arctic Station', 67.8557, 20.2253, 5.4, 'X', 400, 'Active');

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne_m, bande_frequence, debit_max_mbps, statut)
VALUES ('GS-SGP-01', 'Singapore Station', 1.3521, 103.8198, 3.0, 'S', 120, 'Maintenance');

COMMIT;
-- ============================================================
-- DML : AFFECTATION_STATION (3 lignes)
-- FK id_centre → CENTRE_CONTROLE (CTR-001, CTR-002)
-- CTR-001 (Paris) supervise GS-TLS-01 et GS-KIR-01 (missions polaires SSO)
-- CTR-002 (Houston) supervise GS-SGP-01 (couverture zone Asie-Pacifique)
-- Date d'affectation de GS-SGP-01 : 2023-03-15 (per Annexe A)
-- ============================================================

INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation, commentaire)
VALUES ('CTR-001', 'GS-TLS-01', TO_DATE('2022-01-10', 'YYYY-MM-DD'),
        'Paris HQ supervise la station de Toulouse — proximité géographique');

INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation, commentaire)
VALUES ('CTR-001', 'GS-KIR-01', TO_DATE('2022-01-10', 'YYYY-MM-DD'),
        'Paris HQ supervise également Kiruna — missions polaires SSO');

INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation, commentaire)
VALUES ('CTR-002', 'GS-SGP-01', TO_DATE('2023-03-15', 'YYYY-MM-DD'),
        'Houston supervise Singapour — couverture zone Asie-Pacifique');

COMMIT;
-- ============================================================
-- DML : MISSION (3 lignes)
-- date_fin NULL pour les missions encore actives
-- ============================================================

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-ARC-2023', 'ArcticWatch 2023',
        'Surveillance de la fonte des glaces et dynamique des banquises arctiques',
        'Arctique / Groenland',
        TO_DATE('2023-01-01', 'YYYY-MM-DD'), NULL, 'Active');

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-DEF-2022', 'DeforestAlert',
        'Détection et cartographie de la déforestation en temps quasi-réel',
        'Amazonie / Congo',
        TO_DATE('2022-06-01', 'YYYY-MM-DD'), TO_DATE('2023-05-31', 'YYYY-MM-DD'), 'Terminée');

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_cible, date_debut, date_fin, statut_mission)
VALUES ('MSN-COAST-2024', 'CoastGuard 2024',
        'Surveillance de l''évolution du trait de côte et détection d''érosion côtière',
        'Méditerranée / Atlantique',
        TO_DATE('2024-03-01', 'YYYY-MM-DD'), NULL, 'Active');

COMMIT;
-- ============================================================
-- DML : FENETRE_COM (5 lignes)
-- id_fenetre omis — GENERATED ALWAYS AS IDENTITY
-- volume_donnees_mo NULL pour les fenêtres 'Planifiée'
-- ============================================================

INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-001', 'GS-KIR-01', TO_TIMESTAMP('2024-01-15 09:14:00', 'YYYY-MM-DD HH24:MI:SS'), 420, 82.3, 1250, 'Réalisée');

INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-002', 'GS-TLS-01', TO_TIMESTAMP('2024-01-15 11:52:00', 'YYYY-MM-DD HH24:MI:SS'), 310, 67.1, 890, 'Réalisée');

INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-003', 'GS-KIR-01', TO_TIMESTAMP('2024-01-16 08:30:00', 'YYYY-MM-DD HH24:MI:SS'), 540, 88.9, 1680, 'Réalisée');

INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-001', 'GS-TLS-01', TO_TIMESTAMP('2024-01-20 14:22:00', 'YYYY-MM-DD HH24:MI:SS'), 380, 71.4, NULL, 'Planifiée');

INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-003', 'GS-TLS-01', TO_TIMESTAMP('2024-01-21 07:45:00', 'YYYY-MM-DD HH24:MI:SS'), 290, 59.8, NULL, 'Planifiée');

COMMIT;
-- ============================================================
-- DML : PARTICIPATION (7 lignes)
-- ============================================================

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-001', 'MSN-ARC-2023', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-002', 'MSN-ARC-2023', 'Imageur secondaire');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-003', 'MSN-ARC-2023', 'Satellite de relais');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-001', 'MSN-DEF-2022', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-005', 'MSN-DEF-2022', 'Imageur secondaire');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-003', 'MSN-COAST-2024', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-004', 'MSN-COAST-2024', 'Satellite de secours');

COMMIT;
-- ============================================================
PROMPT
PROMPT [T1] trg_valider_fenetre...
-- TRIGGER T1 — trg_valider_fenetre
-- Niveau  : 1 (Obligatoire)
-- Événement : BEFORE INSERT ON FENETRE_COM
-- Règles  : RG-S06, RG-G03
-- Objectif : Bloquer la création d'une fenêtre si le satellite
--            est Désorbité ou si la station est en Maintenance
-- ============================================================

CREATE OR REPLACE TRIGGER trg_valider_fenetre
BEFORE INSERT ON FENETRE_COM
FOR EACH ROW
DECLARE
    v_statut_satellite  SATELLITE.statut%TYPE;
    v_statut_station    STATION_SOL.statut%TYPE;
BEGIN
    -- RG-S06 : satellite Désorbité → fenêtre interdite
    SELECT statut
      INTO v_statut_satellite
      FROM SATELLITE
     WHERE id_satellite = :NEW.id_satellite;

    IF v_statut_satellite = 'Désorbité' THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Satellite ' || :NEW.id_satellite ||
            ' est Désorbité — aucune nouvelle fenêtre de communication autorisée (RG-S06)');
    END IF;

    -- RG-G03 : station en Maintenance → fenêtre interdite
    SELECT statut
      INTO v_statut_station
      FROM STATION_SOL
     WHERE code_station = :NEW.code_station;

    IF v_statut_station = 'Maintenance' THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Station ' || :NEW.code_station ||
            ' est en Maintenance — planification de fenêtre impossible (RG-G03)');
    END IF;
END trg_valider_fenetre;
/
SHOW ERRORS

-- ============================================================
PROMPT [TEST T1] Validation des contraintes...
-- CAS DE TEST T1
-- ============================================================

-- Nettoyage : réinitialisation de FENETRE_COM à l'état DML de référence
-- (idempotent — supprime les lignes de test résiduelles des runs précédents)
DECLARE
    v_rows NUMBER;
BEGIN
    DELETE FROM FENETRE_COM
     WHERE NOT (id_satellite = 'SAT-001' AND code_station = 'GS-KIR-01'
                AND datetime_debut = TO_TIMESTAMP('2024-01-15 09:14:00', 'YYYY-MM-DD HH24:MI:SS'))
       AND NOT (id_satellite = 'SAT-002' AND code_station = 'GS-TLS-01'
                AND datetime_debut = TO_TIMESTAMP('2024-01-15 11:52:00', 'YYYY-MM-DD HH24:MI:SS'))
       AND NOT (id_satellite = 'SAT-003' AND code_station = 'GS-KIR-01'
                AND datetime_debut = TO_TIMESTAMP('2024-01-16 08:30:00', 'YYYY-MM-DD HH24:MI:SS'))
       AND NOT (id_satellite = 'SAT-001' AND code_station = 'GS-TLS-01'
                AND datetime_debut = TO_TIMESTAMP('2024-01-20 14:22:00', 'YYYY-MM-DD HH24:MI:SS'))
       AND NOT (id_satellite = 'SAT-003' AND code_station = 'GS-TLS-01'
                AND datetime_debut = TO_TIMESTAMP('2024-01-21 07:45:00', 'YYYY-MM-DD HH24:MI:SS'));
    v_rows := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Nettoyage T1 : ' || v_rows || ' ligne(s) résiduelle(s) supprimée(s) de FENETRE_COM');
END;
/

-- CAS 1 : Valide — SAT-001 (Opérationnel) vers GS-KIR-01 (Active)
-- Résultat attendu : INSERT réussi, aucune erreur
BEGIN
    INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
    VALUES ('SAT-001', 'GS-KIR-01', TO_TIMESTAMP('2024-02-01 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 75.0, NULL, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('OK CAS 1 : INSERT réussi (satellite Opérationnel, station Active)');
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERREUR inattendue CAS 1 : ' || SQLERRM);
END;
/

-- CAS 2 : Erreur RG-S06 — SAT-005 (Désorbité)
-- Résultat attendu : ORA-20001 — Satellite SAT-005 est Désorbité
BEGIN
    INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
    VALUES ('SAT-005', 'GS-KIR-01', TO_TIMESTAMP('2024-02-01 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 60.0, NULL, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait dû être rejeté (RG-S06)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK RG-S06 — ' || SQLERRM);
END;
/

-- CAS 3 : Erreur RG-G03 — GS-SGP-01 (Maintenance)
-- Résultat attendu : ORA-20002 — Station GS-SGP-01 est en Maintenance
BEGIN
    INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
    VALUES ('SAT-001', 'GS-SGP-01', TO_TIMESTAMP('2024-02-01 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 45.0, NULL, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait dû être rejeté (RG-G03)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK RG-G03 — ' || SQLERRM);
END;
/

-- ============================================================
PROMPT
PROMPT [T2] trg_no_chevauchement...
-- TRIGGER T2 — trg_no_chevauchement (CORRIGÉ)
-- Niveau  : 1 (Obligatoire)
-- Événement : FOR INSERT OR UPDATE ON FENETRE_COM (Compound Trigger)
-- Règles  : RG-F02 (chevauchement satellite), RG-F03 (chevauchement station)
-- ============================================================

CREATE OR REPLACE TRIGGER trg_no_chevauchement
    FOR INSERT OR UPDATE ON FENETRE_COM
    COMPOUND TRIGGER

    -- --------------------------------------------------------
    -- Zone de stockage partagée entre les phases du trigger
    -- --------------------------------------------------------
    TYPE t_rec IS RECORD (
                             id_satellite    FENETRE_COM.id_satellite%TYPE,
                             code_station    FENETRE_COM.code_station%TYPE,
                             datetime_debut  FENETRE_COM.datetime_debut%TYPE,
                             duree_secondes  FENETRE_COM.duree_secondes%TYPE
                         );
    TYPE t_tab IS TABLE OF t_rec INDEX BY PLS_INTEGER;
    g_rows t_tab;
    g_idx  PLS_INTEGER := 0;

    -- --------------------------------------------------------
    -- Réinitialisation avant chaque instruction DML
    -- --------------------------------------------------------
BEFORE STATEMENT IS
BEGIN
    g_idx := 0;
    g_rows.DELETE;
END BEFORE STATEMENT;

    -- --------------------------------------------------------
    -- Collecte des nouvelles valeurs ligne par ligne
    -- (la table est mutante ici → pas de SELECT sur FENETRE_COM)
    -- id_fenetre non stocké : GENERATED ALWAYS AS IDENTITY,
    -- sa valeur est NULL ici → inutilisable pour l'exclusion.
    -- --------------------------------------------------------
    BEFORE EACH ROW IS
    BEGIN
        g_idx := g_idx + 1;
        g_rows(g_idx).id_satellite   := :NEW.id_satellite;
        g_rows(g_idx).code_station   := :NEW.code_station;
        g_rows(g_idx).datetime_debut := :NEW.datetime_debut;
        g_rows(g_idx).duree_secondes := :NEW.duree_secondes;
    END BEFORE EACH ROW;

    -- --------------------------------------------------------
    -- Vérification des chevauchements après stabilisation de la table.
    -- La nouvelle ligne est déjà présente → on l'exclut via sa clé
    -- naturelle (id_satellite, code_station, datetime_debut) qui est
    -- toujours non-NULL et unique, contrairement à id_fenetre qui
    -- vaut NULL dans BEFORE EACH ROW.
    -- --------------------------------------------------------
    AFTER STATEMENT IS
        v_fin   TIMESTAMP;
        v_count NUMBER;
        v_msg   VARCHAR2(500);
    BEGIN
        FOR i IN 1 .. g_idx LOOP
                v_fin := g_rows(i).datetime_debut
                    + NUMTODSINTERVAL(g_rows(i).duree_secondes, 'SECOND');
                v_msg := NULL;

                -- RG-F02 : un satellite ne peut communiquer qu'avec une station à la fois
                SELECT COUNT(*) INTO v_count
                FROM FENETRE_COM
                WHERE id_satellite = g_rows(i).id_satellite
                  -- Exclusion via clé naturelle (évite le piège NULL != NULL)
                  AND NOT (    code_station   = g_rows(i).code_station
                    AND datetime_debut = g_rows(i).datetime_debut)
                  AND g_rows(i).datetime_debut < datetime_debut + NUMTODSINTERVAL(duree_secondes, 'SECOND')
                  AND v_fin > datetime_debut;

                IF v_count > 0 THEN
                    v_msg := 'Chevauchement pour le satellite ' || g_rows(i).id_satellite
                        || ' — un seul contact à la fois (RG-F02)';
                END IF;

                -- RG-F03 : une station ne peut traiter qu'un satellite à la fois
                IF v_msg IS NULL THEN
                    SELECT COUNT(*) INTO v_count
                    FROM FENETRE_COM
                    WHERE code_station = g_rows(i).code_station
                      -- Exclusion via clé naturelle
                      AND NOT (    id_satellite   = g_rows(i).id_satellite
                        AND datetime_debut = g_rows(i).datetime_debut)
                      AND g_rows(i).datetime_debut < datetime_debut + NUMTODSINTERVAL(duree_secondes, 'SECOND')
                      AND v_fin > datetime_debut;

                    IF v_count > 0 THEN
                        v_msg := 'Chevauchement pour la station ' || g_rows(i).code_station
                            || ' — une seule fenêtre à la fois (RG-F03)';
                    END IF;
                END IF;

                IF v_msg IS NOT NULL THEN
                    RAISE_APPLICATION_ERROR(-20003, v_msg);
                END IF;
            END LOOP;
    END AFTER STATEMENT;

    END trg_no_chevauchement;
/
SHOW ERRORS

-- ============================================================
PROMPT [TEST T2] Validation des contraintes...
-- CAS DE TEST T2
-- ============================================================

-- CAS 1 : Valide — SAT-002 sur plage libre (Jan 15 14:00, aucune fenêtre ce créneau)
-- Résultat attendu : INSERT réussi
INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-002', 'GS-KIR-01', TO_TIMESTAMP('2024-01-15 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 55.0, NULL, 'Planifiée');
ROLLBACK;

-- CAS 2 : Erreur RG-F02 — chevauchement satellite
-- SAT-001 a déjà une fenêtre le 2024-01-15 09:14:00 (420s → fin 09:21:00)
-- Nouvelle fenêtre à 09:15:00 sur une autre station → même satellite, chevauche
-- Résultat attendu : ORA-20003 — Chevauchement satellite SAT-001
BEGIN
    INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
    VALUES ('SAT-001', 'GS-TLS-01', TO_TIMESTAMP('2024-01-15 09:15:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 60.0, NULL, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait dû être rejeté (RG-F02)');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('OK RG-F02 — ' || SQLERRM);
END;
/

-- CAS 3 : Erreur RG-F03 — chevauchement station
-- GS-KIR-01 occupée le 2024-01-15 09:14:00 (SAT-001, 420s → fin 09:21:00)
-- Nouvelle fenêtre à 09:14:00 sur la même station → même station, chevauche
-- Résultat attendu : ORA-20003 — Chevauchement station GS-KIR-01
BEGIN
    INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
    VALUES ('SAT-002', 'GS-KIR-01', TO_TIMESTAMP('2024-01-15 09:14:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 50.0, NULL, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait dû être rejeté (RG-F03)');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('OK RG-F03 — ' || SQLERRM);
END;
/

-- ============================================================
PROMPT
PROMPT [T3] trg_volume_realise...
-- TRIGGER T3 — trg_volume_realise
-- Niveau  : 1 (Obligatoire)
-- Événement : BEFORE INSERT OR UPDATE ON FENETRE_COM
-- Règle   : RG-F05
-- Objectif : Forcer volume_donnees_mo à NULL si le statut de
--            la fenêtre est différent de 'Réalisée' (correction
--            silencieuse — pas d'erreur levée)
-- ============================================================

CREATE OR REPLACE TRIGGER trg_volume_realise
BEFORE INSERT OR UPDATE ON FENETRE_COM
FOR EACH ROW
BEGIN
    -- RG-F05 : volume renseigné uniquement pour les fenêtres Réalisées
    IF :NEW.statut != 'Réalisée' THEN
        :NEW.volume_donnees_mo := NULL;
    END IF;
END trg_volume_realise;
/
SHOW ERRORS

-- ============================================================
PROMPT [TEST T3] Validation des contraintes...
-- CAS DE TEST T3
-- ============================================================

-- CAS 1 : Valide — fenêtre Réalisée avec volume → volume conservé
-- Résultat attendu : INSERT réussi, volume_donnees_mo = 500
INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-002', 'GS-KIR-01', TO_TIMESTAMP('2024-02-05 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 70.0, 500, 'Réalisée');

SELECT id_fenetre, statut, volume_donnees_mo
  FROM FENETRE_COM
 WHERE id_satellite = 'SAT-002'
   AND datetime_debut = TO_TIMESTAMP('2024-02-05 10:00:00', 'YYYY-MM-DD HH24:MI:SS');
-- Résultat attendu : volume_donnees_mo = 500

ROLLBACK;

-- CAS 2 : Correction silencieuse — fenêtre Planifiée avec volume fourni
-- Résultat attendu : INSERT réussi, mais volume_donnees_mo forcé à NULL
INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
VALUES ('SAT-002', 'GS-KIR-01', TO_TIMESTAMP('2024-02-05 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 70.0, 999, 'Planifiée');

SELECT id_fenetre, statut, volume_donnees_mo
  FROM FENETRE_COM
 WHERE id_satellite = 'SAT-002'
   AND datetime_debut = TO_TIMESTAMP('2024-02-05 10:00:00', 'YYYY-MM-DD HH24:MI:SS');
-- Résultat attendu : volume_donnees_mo = NULL (corrigé silencieusement par T3)

ROLLBACK;
-- ============================================================
PROMPT
PROMPT [T4] trg_mission_terminee...
-- TRIGGER T4 — trg_mission_terminee
-- Niveau  : 2 (Bonus)
-- Événement : BEFORE INSERT ON PARTICIPATION
-- Règles  : RG-S06 (satellite Désorbité), RG-M04 (mission Terminée)
-- Objectif : Bloquer tout satellite Désorbité dans une mission (RG-S06)
--            et bloquer l'ajout d'un satellite dans une mission
--            dont le statut est 'Terminée' (RG-M04)
-- ============================================================

CREATE OR REPLACE TRIGGER trg_mission_terminee
    BEFORE INSERT ON PARTICIPATION
    FOR EACH ROW
DECLARE
    v_statut_satellite  SATELLITE.statut%TYPE;
    v_statut_mission    MISSION.statut_mission%TYPE;
BEGIN
    -- RG-S06 : satellite Désorbité → participation à une mission interdite
    SELECT statut
    INTO v_statut_satellite
    FROM SATELLITE
    WHERE id_satellite = :NEW.id_satellite;

    IF v_statut_satellite = 'Désorbité' THEN
        RAISE_APPLICATION_ERROR(-20005,
                                'Satellite ' || :NEW.id_satellite ||
                                ' est Désorbité — aucune participation à une mission autorisée (RG-S06)');
    END IF;

    -- RG-M04 : mission Terminée → plus de nouveaux satellites
    SELECT statut_mission
    INTO v_statut_mission
    FROM MISSION
    WHERE id_mission = :NEW.id_mission;

    IF v_statut_mission = 'Terminée' THEN
        RAISE_APPLICATION_ERROR(-20004,
                                'La mission ' || :NEW.id_mission ||
                                ' est Terminée — aucun nouveau satellite ne peut y être ajouté (RG-M04)');
    END IF;
END trg_mission_terminee;
/
SHOW ERRORS

-- ============================================================
PROMPT [TEST T4] Validation des contraintes...
-- CAS DE TEST T4
-- ============================================================

-- Nettoyage préalable : supprime la ligne parasite si elle existe
-- (peut rester en base suite à un run précédent sans ROLLBACK)
DELETE FROM PARTICIPATION
WHERE id_satellite = 'SAT-004'
  AND id_mission   = 'MSN-ARC-2023';
COMMIT;

-- CAS 1 : Valide — ajout de SAT-004 (En veille) à une mission Active (MSN-ARC-2023)
-- Résultat attendu : INSERT réussi, aucune erreur
INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-004', 'MSN-ARC-2023', 'Satellite de secours');
ROLLBACK;

-- CAS 2 : Erreur RG-M04 — tentative d'ajout à MSN-DEF-2022 (Terminée)
-- SAT-003 (Opérationnel) vers mission Terminée → T4 doit bloquer sur RG-M04
-- Résultat attendu : ORA-20004 — mission MSN-DEF-2022 est Terminée
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-003', 'MSN-DEF-2022', 'Imageur de remplacement');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait dû être rejeté (RG-M04)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK RG-M04 — ' || SQLERRM);
END;
/

-- CAS 3 : Erreur RG-S06 — SAT-005 (Désorbité) vers MSN-ARC-2023 (Active)
-- La mission est Active, mais le satellite est Désorbité
-- RG-S06 est vérifié en premier dans T4 → doit bloquer avant RG-M04
-- Résultat attendu : ORA-20005 — Satellite SAT-005 est Désorbité
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-005', 'MSN-ARC-2023', 'Test RG-S06 PARTICIPATION');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait dû être rejeté (RG-S06)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK RG-S06 PARTICIPATION — ' || SQLERRM);
END;
/

-- CAS 4 (bonus) : Double blocage — SAT-005 (Désorbité) vers MSN-DEF-2022 (Terminée)
-- RG-S06 est vérifié en premier → ORA-20005 prime sur RG-M04
-- Résultat attendu : ORA-20005 — Satellite SAT-005 est Désorbité
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-005', 'MSN-DEF-2022', 'Test RG-S06 + RG-M04');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait dû être rejeté');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK RG-S06+RG-M04 — ' || SQLERRM);
END;
/

-- ============================================================
PROMPT
PROMPT [T5] trg_historique_statut...
-- TRIGGER T5 — trg_historique_statut
-- Niveau  : 2 (Bonus)
-- Événement : AFTER UPDATE OF statut ON SATELLITE
-- Règle   : RG-S06 (traçabilité)
-- Objectif : Enregistrer tout changement de statut d'un satellite
--            dans la table HISTORIQUE_STATUT avec horodatage
-- Prérequis : Table HISTORIQUE_STATUT créée (11_HISTORIQUE_STATUT.sql)
-- ============================================================

CREATE OR REPLACE TRIGGER trg_historique_statut
AFTER UPDATE OF statut ON SATELLITE
FOR EACH ROW
BEGIN
    -- N'enregistrer que les vrais changements de statut
    IF :OLD.statut != :NEW.statut THEN
        INSERT INTO HISTORIQUE_STATUT
            (id_satellite, ancien_statut, nouveau_statut, date_changement, motif)
        VALUES
            (:NEW.id_satellite,
             :OLD.statut,
             :NEW.statut,
             SYSTIMESTAMP,
             'Statut modifié de [' || :OLD.statut || '] vers [' || :NEW.statut || ']');
    END IF;
END trg_historique_statut;
/
SHOW ERRORS

-- ============================================================
PROMPT [TEST T5] Validation des contraintes...
-- CAS DE TEST T5
-- ============================================================

-- CAS 1 : Valide — changement de statut SAT-004 : En veille → Opérationnel
-- Résultat attendu : UPDATE réussi + 1 ligne dans HISTORIQUE_STATUT
UPDATE SATELLITE
   SET statut = 'Opérationnel'
 WHERE id_satellite = 'SAT-004';

SELECT id_satellite, ancien_statut, nouveau_statut, date_changement
  FROM HISTORIQUE_STATUT
 ORDER BY date_changement DESC;
-- Résultat attendu :
--   SAT-004 | En veille | Opérationnel | <timestamp>

ROLLBACK;

-- CAS 2 : Pas d'enregistrement si le statut ne change pas
-- Résultat attendu : UPDATE réussi, HISTORIQUE_STATUT inchangé (0 nouvelle ligne)
DECLARE
    v_count_avant NUMBER;
    v_count_apres NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count_avant FROM HISTORIQUE_STATUT;

    UPDATE SATELLITE
       SET statut = 'Opérationnel'  -- même valeur que l'actuelle
     WHERE id_satellite = 'SAT-001';

    SELECT COUNT(*) INTO v_count_apres FROM HISTORIQUE_STATUT;

    IF v_count_avant = v_count_apres THEN
        DBMS_OUTPUT.PUT_LINE('OK : Aucune ligne ajoutée (statut inchangé)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('ERREUR : Une ligne a été insérée à tort');
    END IF;
    ROLLBACK;
END;
/

-- CAS 3 : Chaîne de changements — SAT-003 : Opérationnel → Défaillant → Désorbité
-- Résultat attendu : 2 lignes dans HISTORIQUE_STATUT pour SAT-003
UPDATE SATELLITE SET statut = 'Défaillant' WHERE id_satellite = 'SAT-003';
UPDATE SATELLITE SET statut = 'Désorbité'  WHERE id_satellite = 'SAT-003';

SELECT id_satellite, ancien_statut, nouveau_statut, date_changement
  FROM HISTORIQUE_STATUT
 WHERE id_satellite = 'SAT-003'
 ORDER BY date_changement;
-- Résultat attendu :
--   SAT-003 | Opérationnel | Défaillant  | <ts1>
--   SAT-003 | Défaillant   | Désorbité   | <ts2>

ROLLBACK;

-- Vérification finale du contenu HISTORIQUE_STATUT après les tests
-- (doit être vide car tous les tests ont été rollback-és)
SELECT * FROM HISTORIQUE_STATUT ORDER BY date_changement DESC;
-- ============================================================
PROMPT
PROMPT [CONTROLE] Verification du schema...
-- L2-D : Script de contrôle du schéma NanoOrbit
-- Vérification des tables, contraintes et triggers
-- Schéma : NANOORBIT_ADMIN sur FREEPDB1
-- ============================================================

COLUMN table_name       FORMAT A25
COLUMN constraint_name  FORMAT A35
COLUMN constraint_type  FORMAT A1  HEADING "T"
COLUMN status           FORMAT A8
COLUMN trigger_name     FORMAT A30
COLUMN trigger_type     FORMAT A16
COLUMN triggering_event FORMAT A20

-- -------------------------------------------------------
-- 1. Vérification des tables créées
-- Attendu : 11 tables (10 + HISTORIQUE_STATUT)
-- -------------------------------------------------------
SELECT table_name
FROM user_tables
WHERE table_name IN (
                     'ORBITE', 'SATELLITE', 'INSTRUMENT', 'EMBARQUEMENT',
                     'CENTRE_CONTROLE', 'STATION_SOL', 'AFFECTATION_STATION',
                     'MISSION', 'FENETRE_COM', 'PARTICIPATION', 'HISTORIQUE_STATUT'
    )
ORDER BY table_name;

-- -------------------------------------------------------
-- 2. Vérification des contraintes
-- -------------------------------------------------------
SELECT table_name, constraint_name, constraint_type, status
FROM user_constraints
WHERE table_name IN (
                     'ORBITE', 'SATELLITE', 'INSTRUMENT', 'EMBARQUEMENT',
                     'CENTRE_CONTROLE', 'STATION_SOL', 'AFFECTATION_STATION',
                     'MISSION', 'FENETRE_COM', 'PARTICIPATION', 'HISTORIQUE_STATUT'
    )
ORDER BY table_name, constraint_type;

-- -------------------------------------------------------
-- 3. Vérification des triggers
-- Attendu : 5 triggers (T1 à T5), tous ENABLED
-- -------------------------------------------------------
SELECT trigger_name, table_name, trigger_type, triggering_event, status
FROM user_triggers
WHERE table_name IN ('FENETRE_COM', 'PARTICIPATION', 'SATELLITE')
ORDER BY table_name, trigger_name;

-- -------------------------------------------------------
-- 4. Vérification du volume de données DML
-- -------------------------------------------------------
SELECT 'ORBITE'              AS table_name, COUNT(*) AS nb_lignes FROM ORBITE
UNION ALL
SELECT 'SATELLITE',           COUNT(*) FROM SATELLITE
UNION ALL
SELECT 'INSTRUMENT',          COUNT(*) FROM INSTRUMENT
UNION ALL
SELECT 'EMBARQUEMENT',        COUNT(*) FROM EMBARQUEMENT
UNION ALL
SELECT 'CENTRE_CONTROLE',     COUNT(*) FROM CENTRE_CONTROLE
UNION ALL
SELECT 'STATION_SOL',         COUNT(*) FROM STATION_SOL
UNION ALL
SELECT 'AFFECTATION_STATION', COUNT(*) FROM AFFECTATION_STATION
UNION ALL
SELECT 'MISSION',             COUNT(*) FROM MISSION
UNION ALL
SELECT 'FENETRE_COM',         COUNT(*) FROM FENETRE_COM
UNION ALL
SELECT 'PARTICIPATION',       COUNT(*) FROM PARTICIPATION
UNION ALL
SELECT 'HISTORIQUE_STATUT',   COUNT(*) FROM HISTORIQUE_STATUT
ORDER BY table_name;
-- Résultat attendu :
--   AFFECTATION_STATION : 3   CENTRE_CONTROLE : 2   EMBARQUEMENT : 7
--   FENETRE_COM : 5           HISTORIQUE_STATUT : 0  INSTRUMENT : 4
--   MISSION : 3               ORBITE : 3             PARTICIPATION : 7
--   SATELLITE : 5             STATION_SOL : 3

-- -------------------------------------------------------
-- 5. Vérification de la cohérence des FK
-- -------------------------------------------------------
-- Satellites sans orbite correspondante (doit renvoyer 0)
SELECT COUNT(*) AS satellites_orphelins
FROM SATELLITE s
         LEFT JOIN ORBITE o ON s.id_orbite = o.id_orbite
WHERE o.id_orbite IS NULL;

-- Fenêtres sans satellite valide (doit renvoyer 0)
SELECT COUNT(*) AS fenetres_orphelines
FROM FENETRE_COM f
         LEFT JOIN SATELLITE s ON f.id_satellite = s.id_satellite
WHERE s.id_satellite IS NULL;

-- -------------------------------------------------------
-- 6. Test rapide trigger T1 (satellite Désorbité)
-- -------------------------------------------------------
BEGIN
    INSERT INTO FENETRE_COM
    (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, statut)
    VALUES
        ('SAT-005', 'GS-KIR-01', SYSTIMESTAMP, 300, 45.0, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('ECHEC : T1 n''a pas bloqué SAT-005 (Désorbité)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK T1 : ' || SUBSTR(SQLERRM, 1, 80));
END;
/

-- -------------------------------------------------------
-- 7. Test rapide trigger T4 — RG-M04 (mission Terminée)
-- -------------------------------------------------------
BEGIN
    -- SAT-003 (Opérationnel) vers MSN-DEF-2022 (Terminée)
    -- T4 doit bloquer via RG-M04 (ORA-20004)
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-003', 'MSN-DEF-2022', 'Imageur test');
    DBMS_OUTPUT.PUT_LINE('ECHEC : T4 n''a pas bloqué MSN-DEF-2022 (Terminée)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK T4 RG-M04 : ' || SUBSTR(SQLERRM, 1, 80));
END;
/

-- -------------------------------------------------------
-- 8. Test rapide trigger T4 — RG-S06 (satellite Désorbité)
-- -------------------------------------------------------
BEGIN
    -- SAT-005 (Désorbité) vers MSN-ARC-2023 (Active)
    -- T4 doit bloquer via RG-S06 (ORA-20005)
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-005', 'MSN-ARC-2023', 'Test RG-S06');
    DBMS_OUTPUT.PUT_LINE('ECHEC : T4 n''a pas bloqué SAT-005 (Désorbité)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK T4 RG-S06 : ' || SUBSTR(SQLERRM, 1, 80));
END;
/