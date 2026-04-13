-- ============================================================
-- run_phase2.sql
-- Script maître Phase 2 — NanoOrbit
-- Exécution complète dans l'ordre : DDL → DML → Triggers → Contrôle
--
-- Utilisation (SQL*Plus) :
--   @/chemin/vers/run_phase2.sql
--
-- Prérequis :
--   SET SERVEROUTPUT ON
--   Connexion : NANOORBIT_ADMIN sur FREEPDB1
-- ============================================================

SET SERVEROUTPUT ON
SET ECHO ON

-- ============================================================
-- ÉTAPE 1 — DDL : Création des tables
-- ============================================================
PROMPT ============================================================
PROMPT ÉTAPE 1 — DDL
PROMPT ============================================================

PROMPT --- 01 ORBITE
@@L2-A_DDL/01_ORBITE.sql

PROMPT --- 02 CENTRE_CONTROLE
@@L2-A_DDL/02_CENTRE_CONTROLE.sql

PROMPT --- 03 SATELLITE
@@L2-A_DDL/03_SATELLITE.sql

PROMPT --- 04 INSTRUMENT
@@L2-A_DDL/04_INSTRUMENT.sql

PROMPT --- 05 EMBARQUEMENT
@@L2-A_DDL/05_EMBARQUEMENT.sql

PROMPT --- 06 STATION_SOL
@@L2-A_DDL/06_STATION_SOL.sql

PROMPT --- 07 AFFECTATION_STATION
@@L2-A_DDL/07_AFFECTATION_STATION.sql

PROMPT --- 08 MISSION
@@L2-A_DDL/08_MISSION.sql

PROMPT --- 09 FENETRE_COM
@@L2-A_DDL/09_FENETRE_COM.sql

PROMPT --- 10 PARTICIPATION
@@L2-A_DDL/10_PARTICIPATION.sql

PROMPT --- 11 HISTORIQUE_STATUT
@@L2-A_DDL/11_HISTORIQUE_STATUT.sql

-- ============================================================
-- ÉTAPE 2 — DML : Insertion des données de référence
-- ============================================================
PROMPT ============================================================
PROMPT ÉTAPE 2 — DML
PROMPT ============================================================

PROMPT --- 01 ORBITE
@@L2-B_DML/01_ORBITE.sql

PROMPT --- 02 CENTRE_CONTROLE
@@L2-B_DML/02_CENTRE_CONTROLE.sql

PROMPT --- 03 SATELLITE
@@L2-B_DML/03_SATELLITE.sql

PROMPT --- 04 INSTRUMENT
@@L2-B_DML/04_INSTRUMENT.sql

PROMPT --- 05 EMBARQUEMENT
@@L2-B_DML/05_EMBARQUEMENT.sql

PROMPT --- 06 STATION_SOL
@@L2-B_DML/06_STATION_SOL.sql

PROMPT --- 07 AFFECTATION_STATION
@@L2-B_DML/07_AFFECTATION_STATION.sql

PROMPT --- 08 MISSION
@@L2-B_DML/08_MISSION.sql

PROMPT --- 09 FENETRE_COM
@@L2-B_DML/09_FENETRE_COM.sql

PROMPT --- 10 PARTICIPATION
@@L2-B_DML/10_PARTICIPATION.sql

-- ============================================================
-- ÉTAPE 3 — Triggers
-- ============================================================
PROMPT ============================================================
PROMPT ÉTAPE 3 — Triggers
PROMPT ============================================================

PROMPT --- T1 trg_valider_fenetre
@@L2-C_Triggers/T1_trg_valider_fenetre.sql

PROMPT --- T2 trg_no_chevauchement
@@L2-C_Triggers/T2_trg_no_chevauchement.sql

PROMPT --- T3 trg_volume_realise
@@L2-C_Triggers/T3_trg_volume_realise.sql

PROMPT --- T4 trg_mission_terminee
@@L2-C_Triggers/T4_trg_mission_terminee.sql

PROMPT --- T5 trg_historique_statut
@@L2-C_Triggers/T5_trg_historique_statut.sql

-- ============================================================
-- ÉTAPE 4 — Contrôle du schéma
-- ============================================================
PROMPT ============================================================
PROMPT ÉTAPE 4 — Contrôle
PROMPT ============================================================

@@L2-D_Controle/controle_schema.sql

PROMPT ============================================================
PROMPT Phase 2 terminée.
PROMPT ============================================================
