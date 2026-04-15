-- ============================================================
-- run_phase2.sql — Script maître Phase 2 NanoOrbit
-- Appelé directement par sqlplus (pas via heredoc)
-- Chemins résolus relativement à ce fichier (@@)
-- ============================================================

WHENEVER SQLERROR EXIT FAILURE

SET SQLBLANKLINES ON
SET LINESIZE 150
SET PAGESIZE 100
SET SERVEROUTPUT ON
SET ECHO ON

COLUMN id_satellite     FORMAT A20
COLUMN ancien_statut    FORMAT A20
COLUMN nouveau_statut   FORMAT A20
COLUMN date_changement  FORMAT A35

-- ============================================================
-- ÉTAPE 1 — DDL
-- ============================================================
PROMPT ============================================================
PROMPT ETAPE 1 - DDL
PROMPT ============================================================

@@L2-A_DDL/01_ORBITE.sql
@@L2-A_DDL/02_CENTRE_CONTROLE.sql
@@L2-A_DDL/03_SATELLITE.sql
@@L2-A_DDL/04_INSTRUMENT.sql
@@L2-A_DDL/05_EMBARQUEMENT.sql
@@L2-A_DDL/06_STATION_SOL.sql
@@L2-A_DDL/07_AFFECTATION_STATION.sql
@@L2-A_DDL/08_MISSION.sql
@@L2-A_DDL/09_FENETRE_COM.sql
@@L2-A_DDL/10_PARTICIPATION.sql
@@L2-A_DDL/11_HISTORIQUE_STATUT.sql

-- Vérification DDL
PROMPT --- Tables créées après DDL :
SELECT table_name FROM user_tables ORDER BY table_name;

-- ============================================================
-- ÉTAPE 2 — DML
-- ============================================================
PROMPT ============================================================
PROMPT ETAPE 2 - DML
PROMPT ============================================================

@@L2-B_DML/01_ORBITE.sql
@@L2-B_DML/02_CENTRE_CONTROLE.sql
@@L2-B_DML/03_SATELLITE.sql
@@L2-B_DML/04_INSTRUMENT.sql
@@L2-B_DML/05_EMBARQUEMENT.sql
@@L2-B_DML/06_STATION_SOL.sql
@@L2-B_DML/07_AFFECTATION_STATION.sql
@@L2-B_DML/08_MISSION.sql
@@L2-B_DML/09_FENETRE_COM.sql
@@L2-B_DML/10_PARTICIPATION.sql

-- ============================================================
-- ÉTAPE 3 — Triggers
-- ============================================================
PROMPT ============================================================
PROMPT ETAPE 3 - Triggers
PROMPT ============================================================

@@L2-C_Triggers/T1_trg_valider_fenetre.sql
@@L2-C_Triggers/T2_trg_no_chevauchement.sql
@@L2-C_Triggers/T3_trg_volume_realise.sql
@@L2-C_Triggers/T4_trg_mission_terminee.sql
@@L2-C_Triggers/T5_trg_historique_statut.sql

-- ============================================================
-- ÉTAPE 4 — Contrôle
-- ============================================================
PROMPT ============================================================
PROMPT ETAPE 4 - Controle
PROMPT ============================================================

@@L2-D_Controle/controle_schema.sql

PROMPT ============================================================
PROMPT Phase 2 terminee.
PROMPT ============================================================

EXIT;
