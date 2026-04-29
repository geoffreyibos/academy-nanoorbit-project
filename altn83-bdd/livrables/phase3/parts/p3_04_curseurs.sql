-- ============================================================
-- Phase 3 — Palier 4/6 : Curseurs (implicite, FOR, explicite, paramétré)
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 3 — [4/6] Curseurs
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT Ex.8 — SQL%ROWCOUNT : UPDATE satellites + rollback
-- ────────────────────────────────────────────────────────────
BEGIN
    UPDATE SATELLITE
    SET    statut = 'En veille'
    WHERE  statut = 'Opérationnel' AND id_orbite = 'ORB-001';

    DBMS_OUTPUT.PUT_LINE('Satellites mis en veille : ' || SQL%ROWCOUNT);

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Rollback effectue — donnees restaurees.');
END;
/

-- ────────────────────────────────────────────────────────────
PROMPT Ex.9 — Cursor FOR Loop : satellites / orbite / instruments
-- ────────────────────────────────────────────────────────────
BEGIN
    FOR r IN (
        SELECT s.id_satellite, s.statut,
               o.type_orbite, o.altitude_km,
               i.type_instrument
        FROM   SATELLITE s
        JOIN   ORBITE o          ON s.id_orbite      = o.id_orbite
        LEFT JOIN EMBARQUEMENT e ON s.id_satellite   = e.id_satellite
        LEFT JOIN INSTRUMENT i   ON e.ref_instrument = i.ref_instrument
        ORDER BY s.id_satellite
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            r.id_satellite || ' | ' || r.statut || ' | ' ||
            r.type_orbite || ' ' || r.altitude_km || ' km | ' ||
            NVL(r.type_instrument, 'Aucun instrument')
        );
    END LOOP;
END;
/

-- ────────────────────────────────────────────────────────────
PROMPT Ex.10 — Curseur explicite OPEN/FETCH/CLOSE : derniere fenetre par satellite
-- ────────────────────────────────────────────────────────────
DECLARE
    CURSOR c_sat IS
        SELECT s.id_satellite,
               f.code_station, f.datetime_debut, f.volume_donnees_mo
        FROM   SATELLITE s
        JOIN   FENETRE_COM f ON s.id_satellite = f.id_satellite
        WHERE  s.statut = 'Opérationnel'
        AND    f.datetime_debut = (
            SELECT MAX(f2.datetime_debut)
            FROM   FENETRE_COM f2
            WHERE  f2.id_satellite = s.id_satellite
        )
        ORDER BY s.id_satellite;

    v_row c_sat%ROWTYPE;
BEGIN
    OPEN c_sat;
    LOOP
        FETCH c_sat INTO v_row;
        EXIT WHEN c_sat%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(
            v_row.id_satellite || ' — ' || v_row.code_station ||
            ' le ' || TO_CHAR(v_row.datetime_debut, 'DD/MM/YYYY HH24:MI') ||
            ' — ' || NVL(TO_CHAR(v_row.volume_donnees_mo), 'N/A') || ' Mo'
        );
    END LOOP;
    CLOSE c_sat;
END;
/

-- ────────────────────────────────────────────────────────────
PROMPT Ex.11 — Curseur parametre : fenetres GS-KIR-01 + volume total
-- ────────────────────────────────────────────────────────────
DECLARE
    CURSOR c_fenetres(p_station VARCHAR2) IS
        SELECT f.id_fenetre, f.id_satellite, f.datetime_debut,
               f.duree_secondes, f.statut, f.volume_donnees_mo
        FROM   FENETRE_COM f
        WHERE  f.code_station = p_station
        ORDER BY f.datetime_debut;

    v_volume_total NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Fenetres de GS-KIR-01 ===');
    FOR r IN c_fenetres('GS-KIR-01') LOOP
        DBMS_OUTPUT.PUT_LINE(
            r.id_satellite || ' | ' || TO_CHAR(r.datetime_debut, 'DD/MM/YYYY HH24:MI') ||
            ' | ' || r.duree_secondes || 's | ' || r.statut ||
            ' | ' || NVL(TO_CHAR(r.volume_donnees_mo), 'N/A') || ' Mo'
        );
        v_volume_total := v_volume_total + NVL(r.volume_donnees_mo, 0);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Volume total telecharge : ' || v_volume_total || ' Mo');
END;
/

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Palier 4/6 termine.
PROMPT ────────────────────────────────────────────
PROMPT
