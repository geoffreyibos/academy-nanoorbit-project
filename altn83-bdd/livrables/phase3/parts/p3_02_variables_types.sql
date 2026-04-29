-- ============================================================
-- Phase 3 — Palier 2/6 : Variables et types (%TYPE, %ROWTYPE, NVL)
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 3 — [2/6] Variables et types
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT Ex.3 — %ROWTYPE : statut et batterie de SAT-001
-- ────────────────────────────────────────────────────────────
DECLARE
    v_sat SATELLITE%ROWTYPE;
BEGIN
    SELECT * INTO v_sat FROM SATELLITE WHERE id_satellite = 'SAT-001';

    DBMS_OUTPUT.PUT_LINE('Statut   : ' || v_sat.statut);
    DBMS_OUTPUT.PUT_LINE('Batterie : ' || v_sat.capacite_batterie_wh || ' Wh');
END;
/

-- ────────────────────────────────────────────────────────────
PROMPT Ex.4 — NVL : resolution de INS-AIS-01 (NULL -) N/A)
-- ────────────────────────────────────────────────────────────
DECLARE
    v_modele     INSTRUMENT.modele%TYPE;
    v_resolution INSTRUMENT.resolution_m%TYPE;
BEGIN
    SELECT modele, resolution_m
    INTO   v_modele, v_resolution
    FROM   INSTRUMENT
    WHERE  ref_instrument = 'INS-AIS-01';

    DBMS_OUTPUT.PUT_LINE('Modele     : ' || v_modele);
    DBMS_OUTPUT.PUT_LINE('Resolution : ' || NVL(TO_CHAR(v_resolution), 'N/A') || ' m');
END;
/

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Palier 2/6 termine.
PROMPT ────────────────────────────────────────────
PROMPT
