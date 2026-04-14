-- ============================================================
-- Projet NanoOrbit — Phase 3 : PL/SQL & Package pkg_nanoOrbit
-- Groupe    : 06
-- Membres   : Oscar DEBEURET / Geoffrey IBOS / Hugo LEROUX
-- Date      : 2026-04-14
-- SGBD      : Oracle 23ai — NANOORBIT_ADMIN / FREEPDB1
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
SET SQLBLANKLINES ON

-- ============================================================
-- PALIER 1 — Bloc anonyme
-- ============================================================

-- Ex. 1 : comptage général (satellites, stations, missions)
-- Résultat attendu :
--   Satellites : 5
--   Stations   : 3
--   Missions   : 3
DECLARE
    v_nb_satellites  NUMBER;
    v_nb_stations    NUMBER;
    v_nb_missions    NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_nb_satellites FROM SATELLITE;
    SELECT COUNT(*) INTO v_nb_stations   FROM STATION_SOL;
    SELECT COUNT(*) INTO v_nb_missions   FROM MISSION;

    DBMS_OUTPUT.PUT_LINE('Satellites : ' || v_nb_satellites);
    DBMS_OUTPUT.PUT_LINE('Stations   : ' || v_nb_stations);
    DBMS_OUTPUT.PUT_LINE('Missions   : ' || v_nb_missions);
END;
/

-- Ex. 2 : caractéristiques de SAT-001 via SELECT INTO
-- Résultat attendu :
--   Nom          : NanoOrbit-Alpha
--   Format       : 3U
--   Statut       : Opérationnel
--   Lancement    : 15/03/2022
--   Masse (kg)   : 1.3
--   Batterie (Wh): 20
--   Orbite       : ORB-001
DECLARE
    v_nom       SATELLITE.nom_satellite%TYPE;
    v_format    SATELLITE.format_cubesat%TYPE;
    v_statut    SATELLITE.statut%TYPE;
    v_lancement SATELLITE.date_lancement%TYPE;
    v_masse     SATELLITE.masse_kg%TYPE;
    v_batterie  SATELLITE.capacite_batterie_wh%TYPE;
    v_orbite    SATELLITE.id_orbite%TYPE;
BEGIN
    SELECT nom_satellite, format_cubesat, statut,
           date_lancement, masse_kg, capacite_batterie_wh, id_orbite
    INTO   v_nom, v_format, v_statut,
           v_lancement, v_masse, v_batterie, v_orbite
    FROM   SATELLITE
    WHERE  id_satellite = 'SAT-001';

    DBMS_OUTPUT.PUT_LINE('Nom          : ' || v_nom);
    DBMS_OUTPUT.PUT_LINE('Format       : ' || v_format);
    DBMS_OUTPUT.PUT_LINE('Statut       : ' || v_statut);
    DBMS_OUTPUT.PUT_LINE('Lancement    : ' || TO_CHAR(v_lancement, 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('Masse (kg)   : ' || v_masse);
    DBMS_OUTPUT.PUT_LINE('Batterie (Wh): ' || v_batterie);
    DBMS_OUTPUT.PUT_LINE('Orbite       : ' || v_orbite);
END;
/


-- ============================================================
-- PALIER 2 — Variables et types
-- ============================================================

-- Ex. 3 : %ROWTYPE — statut et capacité batterie de SAT-001
-- Résultat attendu :
--   Statut   : Opérationnel
--   Batterie : 20 Wh
DECLARE
    v_sat SATELLITE%ROWTYPE;
BEGIN
    SELECT * INTO v_sat FROM SATELLITE WHERE id_satellite = 'SAT-001';

    DBMS_OUTPUT.PUT_LINE('Statut   : ' || v_sat.statut);
    DBMS_OUTPUT.PUT_LINE('Batterie : ' || v_sat.capacite_batterie_wh || ' Wh');
END;
/

-- Ex. 4 : NVL — résolution de INS-AIS-01 (NULL → N/A)
-- Résultat attendu :
--   Modèle     : ShipTrack-V2
--   Résolution : N/A m
DECLARE
    v_modele     INSTRUMENT.modele%TYPE;
    v_resolution INSTRUMENT.resolution_m%TYPE;
BEGIN
    SELECT modele, resolution_m
    INTO   v_modele, v_resolution
    FROM   INSTRUMENT
    WHERE  ref_instrument = 'INS-AIS-01';

    DBMS_OUTPUT.PUT_LINE('Modèle     : ' || v_modele);
    DBMS_OUTPUT.PUT_LINE('Résolution : ' || NVL(TO_CHAR(v_resolution), 'N/A') || ' m');
END;
/


-- ============================================================
-- PALIER 3 — Structures de contrôle
-- ============================================================

-- Ex. 5 : IF/ELSIF — catégoriser SAT-001 selon statut et durée de vie restante
-- Résultat attendu :
--   Satellite  : SAT-001
--   Statut     : Opérationnel
--   Restant    : ~23 mois (selon date d'exécution)
--   Catégorie  : Surveillance renforcée
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
    DBMS_OUTPUT.PUT_LINE('Catégorie  : ' || v_categorie);
END;
/

-- Ex. 6 : CASE — type d'orbite et vitesse orbitale de SAT-001
-- Formule : v = 2π × (6371 + altitude) / période (km/min)
-- Résultat attendu :
--   Type    : Orbite héliosynchrone
--   Vitesse : 455,35 km/min (≈ 7,6 km/s)
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
        WHEN 'SSO' THEN 'Orbite héliosynchrone'
        WHEN 'LEO' THEN 'Orbite basse'
        WHEN 'MEO' THEN 'Orbite moyenne'
        WHEN 'GEO' THEN 'Orbite géostationnaire'
        ELSE 'Inconnue'
    END;

    DBMS_OUTPUT.PUT_LINE('Type    : ' || v_label);
    DBMS_OUTPUT.PUT_LINE('Vitesse : ' || v_vitesse || ' km/min');
END;
/

-- Ex. 7 : boucle FOR — grille des volumes pour passages de 5 à 15 min (GS-TLS-01, 150 Mbps)
-- Volume (Mo) = débit (Mbps) × durée (s) / 8
-- Résultat attendu :
--   5 min → 5625 Mo, ..., 15 min → 16875 Mo
DECLARE
    v_debit  NUMBER := 150;
    v_volume NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Durée (min) | Volume (Mo)');
    DBMS_OUTPUT.PUT_LINE('------------|------------');
    FOR i IN 5..15 LOOP
        v_volume := ROUND(v_debit * (i * 60) / 8, 1);
        DBMS_OUTPUT.PUT_LINE(LPAD(i, 11) || ' | ' || v_volume);
    END LOOP;
END;
/


-- ============================================================
-- PALIER 4 — Curseurs
-- ============================================================

-- Ex. 8 : SQL%ROWCOUNT — mise à jour de plusieurs satellites + comptage
-- Résultat attendu :
--   Satellites mis en veille : 2
--   Rollback effectué — données restaurées.
BEGIN
    UPDATE SATELLITE
    SET    statut = 'En veille'
    WHERE  statut = 'Opérationnel' AND id_orbite = 'ORB-001';

    DBMS_OUTPUT.PUT_LINE('Satellites mis en veille : ' || SQL%ROWCOUNT);

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Rollback effectué — données restaurées.');
END;
/

-- Ex. 9 : Cursor FOR Loop — satellites avec orbite, statut et instruments
-- Résultat attendu : 1 ligne par combinaison satellite/instrument
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

-- Ex. 10 : curseur explicite OPEN/FETCH/CLOSE
-- Satellites opérationnels + dernière fenêtre de communication
-- Résultat attendu : SAT-001, SAT-002, SAT-003 avec leur dernière station
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

-- Ex. 11 : curseur paramétré — fenêtres de GS-KIR-01 + volume total
-- Résultat attendu :
--   SAT-001 | 15/01/2024 09:14 | 420s | Réalisée | 1250 Mo
--   SAT-003 | 16/01/2024 08:30 | 540s | Réalisée | 1680 Mo
--   Volume total téléchargé : 2930 Mo
DECLARE
    CURSOR c_fenetres(p_station VARCHAR2) IS
        SELECT f.id_fenetre, f.id_satellite, f.datetime_debut,
               f.duree_secondes, f.statut, f.volume_donnees_mo
        FROM   FENETRE_COM f
        WHERE  f.code_station = p_station
        ORDER BY f.datetime_debut;

    v_volume_total NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Fenêtres de GS-KIR-01 ===');
    FOR r IN c_fenetres('GS-KIR-01') LOOP
        DBMS_OUTPUT.PUT_LINE(
            r.id_satellite || ' | ' || TO_CHAR(r.datetime_debut, 'DD/MM/YYYY HH24:MI') ||
            ' | ' || r.duree_secondes || 's | ' || r.statut ||
            ' | ' || NVL(TO_CHAR(r.volume_donnees_mo), 'N/A') || ' Mo'
        );
        v_volume_total := v_volume_total + NVL(r.volume_donnees_mo, 0);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Volume total téléchargé : ' || v_volume_total || ' Mo');
END;
/


-- ============================================================
-- PALIER 5 — Procédures et fonctions standalone
-- ============================================================

-- Ex. 12 : SELECT INTO sécurisé — NO_DATA_FOUND et OTHERS
-- Résultat attendu :
--   Satellite introuvable.
DECLARE
    v_sat SATELLITE%ROWTYPE;
BEGIN
    SELECT * INTO v_sat FROM SATELLITE WHERE id_satellite = 'SAT-999';
    DBMS_OUTPUT.PUT_LINE(v_sat.nom_satellite || ' — ' || v_sat.statut);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Satellite introuvable.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
END;
/

-- Ex. 13 : RAISE_APPLICATION_ERROR — validation d'une fenêtre avant insertion
-- Vérifie : satellite opérationnel, station active, absence de chevauchement
-- Résultat attendu : Validation OK — fenêtre autorisée.
DECLARE
    v_statut_sat SATELLITE.statut%TYPE;
    v_statut_sta STATION_SOL.statut%TYPE;
    v_nb_overlap NUMBER;

    v_id_sat   VARCHAR2(20) := 'SAT-001';
    v_code_sta VARCHAR2(20) := 'GS-KIR-01';
    v_debut    TIMESTAMP    := TO_TIMESTAMP('2024-02-01 10:00:00', 'YYYY-MM-DD HH24:MI:SS');
    v_duree    NUMBER       := 300;
BEGIN
    SELECT statut INTO v_statut_sat FROM SATELLITE   WHERE id_satellite = v_id_sat;
    SELECT statut INTO v_statut_sta FROM STATION_SOL WHERE code_station = v_code_sta;

    IF v_statut_sat != 'Opérationnel' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Satellite ' || v_id_sat || ' non opérationnel.');
    END IF;

    IF v_statut_sta = 'Maintenance' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Station ' || v_code_sta || ' en maintenance.');
    END IF;

    SELECT COUNT(*) INTO v_nb_overlap
    FROM   FENETRE_COM
    WHERE  id_satellite = v_id_sat
    AND    datetime_debut < v_debut + NUMTODSINTERVAL(v_duree, 'SECOND')
    AND    datetime_debut + NUMTODSINTERVAL(duree_secondes, 'SECOND') > v_debut;

    IF v_nb_overlap > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Chevauchement détecté pour ' || v_id_sat || '.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Validation OK — fenêtre autorisée.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'Satellite ou station introuvable.');
END;
/

-- Ex. 14 : procédure afficher_statut_satellite(p_id IN)
-- Résultat attendu pour SAT-001 : statut, orbite ORB-001, 2 instruments
CREATE OR REPLACE PROCEDURE afficher_statut_satellite(p_id IN VARCHAR2) IS
    v_sat SATELLITE%ROWTYPE;
    v_orb ORBITE%ROWTYPE;
BEGIN
    SELECT * INTO v_sat FROM SATELLITE WHERE id_satellite = p_id;
    SELECT * INTO v_orb FROM ORBITE    WHERE id_orbite    = v_sat.id_orbite;

    DBMS_OUTPUT.PUT_LINE('=== ' || p_id || ' — ' || v_sat.nom_satellite || ' ===');
    DBMS_OUTPUT.PUT_LINE('Statut  : ' || v_sat.statut);
    DBMS_OUTPUT.PUT_LINE('Orbite  : ' || v_orb.type_orbite || ' — ' || v_orb.altitude_km || ' km');

    FOR r IN (
        SELECT i.type_instrument, i.modele
        FROM   EMBARQUEMENT e JOIN INSTRUMENT i ON e.ref_instrument = i.ref_instrument
        WHERE  e.id_satellite = p_id
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Instrument : ' || r.type_instrument || ' (' || r.modele || ')');
    END LOOP;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Satellite ' || p_id || ' introuvable.');
END;
/
SHOW ERRORS

BEGIN
    afficher_statut_satellite('SAT-001');
    afficher_statut_satellite('SAT-999');
END;
/

-- Ex. 15 : procédure mettre_a_jour_statut(p_id IN, p_statut IN, p_ancien_statut OUT)
-- Résultat attendu :
--   SAT-004 : En veille → Opérationnel
--   Ancien statut récupéré : En veille
CREATE OR REPLACE PROCEDURE mettre_a_jour_statut(
    p_id            IN  VARCHAR2,
    p_statut        IN  VARCHAR2,
    p_ancien_statut OUT VARCHAR2
) IS
BEGIN
    SELECT statut INTO p_ancien_statut FROM SATELLITE WHERE id_satellite = p_id;
    UPDATE SATELLITE SET statut = p_statut WHERE id_satellite = p_id;
    DBMS_OUTPUT.PUT_LINE(p_id || ' : ' || p_ancien_statut || ' → ' || p_statut);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Satellite ' || p_id || ' introuvable.');
END;
/
SHOW ERRORS

DECLARE
    v_ancien VARCHAR2(30);
BEGIN
    mettre_a_jour_statut('SAT-004', 'Opérationnel', v_ancien);
    DBMS_OUTPUT.PUT_LINE('Ancien statut récupéré : ' || v_ancien);
    ROLLBACK;
END;
/

-- Ex. 16 : fonction calculer_volume_session(p_id_fenetre IN) RETURN NUMBER
-- Volume théorique = débit_max_mbps × duree_secondes / 8 (Mo)
-- Résultat attendu :
--   Fenêtre 1 (SAT-001 → GS-KIR-01) — volume théorique : 21000 Mo
CREATE OR REPLACE FUNCTION calculer_volume_session(p_id_fenetre IN NUMBER) RETURN NUMBER IS
    v_debit STATION_SOL.debit_max_mbps%TYPE;
    v_duree FENETRE_COM.duree_secondes%TYPE;
BEGIN
    SELECT s.debit_max_mbps, f.duree_secondes
    INTO   v_debit, v_duree
    FROM   FENETRE_COM f JOIN STATION_SOL s ON f.code_station = s.code_station
    WHERE  f.id_fenetre = p_id_fenetre;

    RETURN ROUND(v_debit * v_duree / 8, 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Fenêtre ' || p_id_fenetre || ' introuvable.');
END;
/
SHOW ERRORS

BEGIN
    FOR r IN (SELECT id_fenetre, id_satellite, code_station FROM FENETRE_COM) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Fenêtre ' || r.id_fenetre || ' (' || r.id_satellite || ' → ' || r.code_station || ')' ||
            ' — volume théorique : ' || calculer_volume_session(r.id_fenetre) || ' Mo'
        );
    END LOOP;
END;
/


-- ============================================================
-- PALIER 6 (BONUS) — Package pkg_nanoOrbit
-- ============================================================
-- Contient 7 sous-programmes publics :
--   planifier_fenetre       PROCEDURE  — valide + insère une fenêtre
--   cloturer_fenetre        PROCEDURE  — passe une fenêtre à 'Réalisée'
--   affecter_satellite_mission PROCEDURE — inscrit un satellite à une mission
--   mettre_en_revision      PROCEDURE  — passe un satellite à 'En veille'
--   calculer_volume_theorique FUNCTION — débit × durée / 8 (Mo)
--   statut_constellation    PROCEDURE  — vue d'ensemble de la constellation
--   stats_satellite         PROCEDURE  — stats d'un satellite

-- ============================================================
-- SPEC
-- ============================================================
CREATE OR REPLACE PACKAGE pkg_nanoOrbit AS

    PROCEDURE planifier_fenetre(
        p_id_sat    IN  VARCHAR2,
        p_code_sta  IN  VARCHAR2,
        p_debut     IN  TIMESTAMP,
        p_duree     IN  NUMBER,
        p_id_fenetre OUT NUMBER
    );

    PROCEDURE cloturer_fenetre(
        p_id_fenetre IN NUMBER,
        p_volume     IN NUMBER
    );

    PROCEDURE affecter_satellite_mission(
        p_id_sat    IN VARCHAR2,
        p_id_mission IN VARCHAR2,
        p_role      IN VARCHAR2
    );

    PROCEDURE mettre_en_revision(p_id_sat IN VARCHAR2);

    FUNCTION calculer_volume_theorique(p_id_fenetre IN NUMBER) RETURN NUMBER;

    PROCEDURE statut_constellation;

    PROCEDURE stats_satellite(p_id_sat IN VARCHAR2);

END pkg_nanoOrbit;
/
SHOW ERRORS

-- ============================================================
-- BODY
-- ============================================================
CREATE OR REPLACE PACKAGE BODY pkg_nanoOrbit AS

    -- ----------------------------------------------------------
    -- planifier_fenetre : valide les contraintes, insère la fenêtre
    -- ----------------------------------------------------------
    PROCEDURE planifier_fenetre(
        p_id_sat    IN  VARCHAR2,
        p_code_sta  IN  VARCHAR2,
        p_debut     IN  TIMESTAMP,
        p_duree     IN  NUMBER,
        p_id_fenetre OUT NUMBER
    ) IS
        v_statut_sat SATELLITE.statut%TYPE;
        v_statut_sta STATION_SOL.statut%TYPE;
        v_nb_overlap NUMBER;
    BEGIN
        SELECT statut INTO v_statut_sat FROM SATELLITE   WHERE id_satellite = p_id_sat;
        SELECT statut INTO v_statut_sta FROM STATION_SOL WHERE code_station = p_code_sta;

        IF v_statut_sat != 'Opérationnel' THEN
            RAISE_APPLICATION_ERROR(-20001, 'Satellite ' || p_id_sat || ' non opérationnel.');
        END IF;

        IF v_statut_sta = 'Maintenance' THEN
            RAISE_APPLICATION_ERROR(-20002, 'Station ' || p_code_sta || ' en maintenance.');
        END IF;

        SELECT COUNT(*) INTO v_nb_overlap
        FROM   FENETRE_COM
        WHERE  id_satellite = p_id_sat
        AND    datetime_debut < p_debut + NUMTODSINTERVAL(p_duree, 'SECOND')
        AND    datetime_debut + NUMTODSINTERVAL(duree_secondes, 'SECOND') > p_debut;

        IF v_nb_overlap > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Chevauchement détecté pour ' || p_id_sat || '.');
        END IF;

        INSERT INTO FENETRE_COM (datetime_debut, duree_secondes, elevation_max_deg,
                                 volume_donnees_mo, statut, id_satellite, code_station)
        VALUES (p_debut, p_duree, 0, NULL, 'Planifiée', p_id_sat, p_code_sta)
        RETURNING id_fenetre INTO p_id_fenetre;

        DBMS_OUTPUT.PUT_LINE('Fenêtre planifiée — id : ' || p_id_fenetre);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20004, 'Satellite ou station introuvable.');
    END planifier_fenetre;

    -- ----------------------------------------------------------
    -- cloturer_fenetre : passe la fenêtre à 'Réalisée' avec volume
    -- ----------------------------------------------------------
    PROCEDURE cloturer_fenetre(
        p_id_fenetre IN NUMBER,
        p_volume     IN NUMBER
    ) IS
        v_statut FENETRE_COM.statut%TYPE;
    BEGIN
        SELECT statut INTO v_statut FROM FENETRE_COM WHERE id_fenetre = p_id_fenetre;

        IF v_statut != 'Planifiée' THEN
            RAISE_APPLICATION_ERROR(-20005, 'La fenêtre ' || p_id_fenetre || ' n''est pas planifiée.');
        END IF;

        UPDATE FENETRE_COM
        SET    statut = 'Réalisée', volume_donnees_mo = p_volume
        WHERE  id_fenetre = p_id_fenetre;

        DBMS_OUTPUT.PUT_LINE('Fenêtre ' || p_id_fenetre || ' clôturée — ' || p_volume || ' Mo.');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20006, 'Fenêtre ' || p_id_fenetre || ' introuvable.');
    END cloturer_fenetre;

    -- ----------------------------------------------------------
    -- affecter_satellite_mission : inscrit un satellite à une mission
    -- ----------------------------------------------------------
    PROCEDURE affecter_satellite_mission(
        p_id_sat     IN VARCHAR2,
        p_id_mission IN VARCHAR2,
        p_role       IN VARCHAR2
    ) IS
        v_statut_sat SATELLITE.statut%TYPE;
        v_statut_msn MISSION.statut_mission%TYPE;
    BEGIN
        SELECT statut       INTO v_statut_sat FROM SATELLITE WHERE id_satellite = p_id_sat;
        SELECT statut_mission INTO v_statut_msn FROM MISSION   WHERE id_mission   = p_id_mission;

        IF v_statut_sat NOT IN ('Opérationnel', 'En veille') THEN
            RAISE_APPLICATION_ERROR(-20007, 'Satellite ' || p_id_sat || ' non assignable (statut : ' || v_statut_sat || ').');
        END IF;

        IF v_statut_msn = 'Terminée' THEN
            RAISE_APPLICATION_ERROR(-20008, 'Mission ' || p_id_mission || ' terminée.');
        END IF;

        INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
        VALUES (p_id_sat, p_id_mission, p_role);

        DBMS_OUTPUT.PUT_LINE(p_id_sat || ' affecté à ' || p_id_mission || ' (' || p_role || ').');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20009, p_id_sat || ' déjà inscrit à ' || p_id_mission || '.');
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010, 'Satellite ou mission introuvable.');
    END affecter_satellite_mission;

    -- ----------------------------------------------------------
    -- mettre_en_revision : passe un satellite opérationnel à 'En veille'
    -- ----------------------------------------------------------
    PROCEDURE mettre_en_revision(p_id_sat IN VARCHAR2) IS
        v_statut SATELLITE.statut%TYPE;
    BEGIN
        SELECT statut INTO v_statut FROM SATELLITE WHERE id_satellite = p_id_sat;

        IF v_statut = 'Désorbité' THEN
            RAISE_APPLICATION_ERROR(-20011, 'Satellite ' || p_id_sat || ' désorbité — révision impossible.');
        END IF;

        UPDATE SATELLITE SET statut = 'En veille' WHERE id_satellite = p_id_sat;

        DBMS_OUTPUT.PUT_LINE(p_id_sat || ' mis en révision (statut : ' || v_statut || ' → En veille).');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20012, 'Satellite ' || p_id_sat || ' introuvable.');
    END mettre_en_revision;

    -- ----------------------------------------------------------
    -- calculer_volume_theorique : débit × durée / 8 (Mo)
    -- ----------------------------------------------------------
    FUNCTION calculer_volume_theorique(p_id_fenetre IN NUMBER) RETURN NUMBER IS
        v_debit STATION_SOL.debit_max_mbps%TYPE;
        v_duree FENETRE_COM.duree_secondes%TYPE;
    BEGIN
        SELECT s.debit_max_mbps, f.duree_secondes
        INTO   v_debit, v_duree
        FROM   FENETRE_COM f JOIN STATION_SOL s ON f.code_station = s.code_station
        WHERE  f.id_fenetre = p_id_fenetre;

        RETURN ROUND(v_debit * v_duree / 8, 2);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20013, 'Fenêtre ' || p_id_fenetre || ' introuvable.');
    END calculer_volume_theorique;

    -- ----------------------------------------------------------
    -- statut_constellation : vue d'ensemble de tous les satellites
    -- ----------------------------------------------------------
    PROCEDURE statut_constellation IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('=== Constellation NanoOrbit ===');
        DBMS_OUTPUT.PUT_LINE(RPAD('Satellite', 10) || RPAD('Nom', 22) || RPAD('Statut', 16) ||
                             RPAD('Orbite', 8) || 'Instruments');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));

        FOR r IN (
            SELECT s.id_satellite, s.nom_satellite, s.statut,
                   o.type_orbite,
                   (SELECT COUNT(*) FROM EMBARQUEMENT e WHERE e.id_satellite = s.id_satellite) nb_instr
            FROM   SATELLITE s JOIN ORBITE o ON s.id_orbite = o.id_orbite
            ORDER BY s.id_satellite
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
                RPAD(r.id_satellite, 10) || RPAD(r.nom_satellite, 22) ||
                RPAD(r.statut, 16)       || RPAD(r.type_orbite, 8)   || r.nb_instr
            );
        END LOOP;
    END statut_constellation;

    -- ----------------------------------------------------------
    -- stats_satellite : nb fenêtres, volume total, missions actives
    -- ----------------------------------------------------------
    PROCEDURE stats_satellite(p_id_sat IN VARCHAR2) IS
        v_nom        SATELLITE.nom_satellite%TYPE;
        v_nb_fen     NUMBER;
        v_vol_total  NUMBER;
        v_nb_msn     NUMBER;
    BEGIN
        SELECT nom_satellite INTO v_nom FROM SATELLITE WHERE id_satellite = p_id_sat;

        SELECT COUNT(*), NVL(SUM(volume_donnees_mo), 0)
        INTO   v_nb_fen, v_vol_total
        FROM   FENETRE_COM
        WHERE  id_satellite = p_id_sat AND statut = 'Réalisée';

        SELECT COUNT(*)
        INTO   v_nb_msn
        FROM   PARTICIPATION p JOIN MISSION m ON p.id_mission = m.id_mission
        WHERE  p.id_satellite = p_id_sat AND m.statut_mission = 'Active';

        DBMS_OUTPUT.PUT_LINE('=== Stats ' || p_id_sat || ' — ' || v_nom || ' ===');
        DBMS_OUTPUT.PUT_LINE('Fenêtres réalisées : ' || v_nb_fen);
        DBMS_OUTPUT.PUT_LINE('Volume total DL    : ' || v_vol_total || ' Mo');
        DBMS_OUTPUT.PUT_LINE('Missions actives   : ' || v_nb_msn);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20014, 'Satellite ' || p_id_sat || ' introuvable.');
    END stats_satellite;

END pkg_nanoOrbit;
/
SHOW ERRORS

-- ============================================================
-- Scénario de validation du package
-- ============================================================
DECLARE
    v_id_fenetre NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- 1. Vue d''ensemble de la constellation ---');
    pkg_nanoOrbit.statut_constellation;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- 2. Stats SAT-001 avant opérations ---');
    pkg_nanoOrbit.stats_satellite('SAT-001');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- 3. Planification d''une fenêtre (SAT-001 / GS-TLS-01) ---');
    pkg_nanoOrbit.planifier_fenetre(
        'SAT-001', 'GS-TLS-01',
        TO_TIMESTAMP('2025-06-01 08:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        300,
        v_id_fenetre
    );
    DBMS_OUTPUT.PUT_LINE('  Volume théorique : ' || pkg_nanoOrbit.calculer_volume_theorique(v_id_fenetre) || ' Mo');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- 4. Clôture de la fenêtre ---');
    pkg_nanoOrbit.cloturer_fenetre(v_id_fenetre, 1500);

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- 5. Affectation SAT-004 → MSN-ARC-2023 ---');
    pkg_nanoOrbit.affecter_satellite_mission('SAT-004', 'MSN-ARC-2023', 'Imagerie secondaire');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- 6. Mise en révision de SAT-002 ---');
    pkg_nanoOrbit.mettre_en_revision('SAT-002');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- 7. Vue d''ensemble après opérations ---');
    pkg_nanoOrbit.statut_constellation;

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Rollback effectué — données restaurées.');
END;
/
