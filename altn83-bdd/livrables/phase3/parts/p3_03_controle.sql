-- ============================================================
-- Phase 3 — Palier 3/6 : Structures de contrôle (IF, CASE, LOOP)
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 3 — [3/6] Structures de controle
PROMPT ════════════════════════════════════════════
PROMPT

-- ────────────────────────────────────────────────────────────
PROMPT Ex.5 — IF/ELSIF : categorisation de SAT-001 par duree de vie
-- ────────────────────────────────────────────────────────────
DECLARE
    v_sat          SATELLITE%ROWTYPE;
    v_mois_ecoules NUMBER;
    v_restant      NUMBER;
    v_categorie    VARCHAR2(50);
BEGIN
    SELECT * INTO v_sat FROM SATELLITE WHERE id_satellite = 'SAT-001';

    v_mois_ecoules := MONTHS_BETWEEN(SYSDATE, v_sat.date_lancement);
    v_restant      := v_sat.duree_vie_mois - v_mois_ecoules;

    IF v_sat.statut = 'Désorbité' THEN
        v_categorie := 'Hors service';
    ELSIF v_sat.statut = 'Défaillant' THEN
        v_categorie := 'En anomalie';
    ELSIF v_restant < 6 THEN
        v_categorie := 'Fin de vie imminente';
    ELSIF v_restant < 18 THEN
        v_categorie := 'Surveillance renforcée';
    ELSE
        v_categorie := 'Nominal';
    END IF;

    DBMS_OUTPUT.PUT_LINE('Satellite  : ' || v_sat.id_satellite);
    DBMS_OUTPUT.PUT_LINE('Statut     : ' || v_sat.statut);
    DBMS_OUTPUT.PUT_LINE('Restant    : ' || ROUND(v_restant) || ' mois');
    DBMS_OUTPUT.PUT_LINE('Categorie  : ' || v_categorie);
END;
/

-- ────────────────────────────────────────────────────────────
PROMPT Ex.6 — CASE : type d'orbite et vitesse orbitale de SAT-001
-- ────────────────────────────────────────────────────────────
DECLARE
    v_type_orbite ORBITE.type_orbite%TYPE;
    v_altitude    ORBITE.altitude_km%TYPE;
    v_periode     ORBITE.periode_min%TYPE;
    v_vitesse     NUMBER;
    v_label       VARCHAR2(30);
BEGIN
    SELECT o.type_orbite, o.altitude_km, o.periode_min
    INTO   v_type_orbite, v_altitude, v_periode
    FROM   SATELLITE s JOIN ORBITE o ON s.id_orbite = o.id_orbite
    WHERE  s.id_satellite = 'SAT-001';

    v_vitesse := ROUND(2 * 3.14159 * (6371 + v_altitude) / v_periode, 2);

    v_label := CASE v_type_orbite
        WHEN 'SSO' THEN 'Orbite heliosynchrone'
        WHEN 'LEO' THEN 'Orbite basse'
        WHEN 'MEO' THEN 'Orbite moyenne'
        WHEN 'GEO' THEN 'Orbite geostationnaire'
        ELSE 'Inconnue'
    END;

    DBMS_OUTPUT.PUT_LINE('Type    : ' || v_label);
    DBMS_OUTPUT.PUT_LINE('Vitesse : ' || v_vitesse || ' km/min');
END;
/

-- ────────────────────────────────────────────────────────────
PROMPT Ex.7 — FOR loop : grille volumes (5 a 15 min, 150 Mbps)
-- ────────────────────────────────────────────────────────────
DECLARE
    v_debit  NUMBER := 150;
    v_volume NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Duree (min) | Volume (Mo)');
    DBMS_OUTPUT.PUT_LINE('------------|------------');
    FOR i IN 5..15 LOOP
        v_volume := ROUND(v_debit * (i * 60) / 8, 1);
        DBMS_OUTPUT.PUT_LINE(LPAD(i, 11) || ' | ' || v_volume);
    END LOOP;
END;
/

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Palier 3/6 termine.
PROMPT ────────────────────────────────────────────
PROMPT
