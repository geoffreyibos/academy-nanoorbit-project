-- ============================================================
-- Phase 2 — Partie 4/6 : T2 — trg_no_chevauchement
-- Règles : RG-F02 (chevauchement satellite) + RG-F03 (station)
-- Compound Trigger : BEFORE STATEMENT / BEFORE EACH ROW / AFTER STATEMENT
-- Prérequis : Parties 1, 2 et 3 exécutées
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
SET SQLBLANKLINES ON
SET FEEDBACK OFF
SET VERIFY OFF

PROMPT
PROMPT ════════════════════════════════════════════
PROMPT  Phase 2 — [4/6] T2 — trg_no_chevauchement
PROMPT  RG-F02 : un satellite = un contact a la fois
PROMPT  RG-F03 : une station = une fenetre a la fois
PROMPT  Compound Trigger — evite ORA-04091 (table mutante)
PROMPT ════════════════════════════════════════════
PROMPT

CREATE OR REPLACE TRIGGER trg_no_chevauchement
    FOR INSERT OR UPDATE ON FENETRE_COM
    COMPOUND TRIGGER

    -- --------------------------------------------------------
    -- Zone de stockage partagee entre les phases du trigger
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
    -- Reinitialisation avant chaque instruction DML
    -- --------------------------------------------------------
    BEFORE STATEMENT IS
    BEGIN
        g_idx := 0;
        g_rows.DELETE;
    END BEFORE STATEMENT;

    -- --------------------------------------------------------
    -- Collecte des nouvelles valeurs ligne par ligne
    -- (la table est mutante ici -> pas de SELECT sur FENETRE_COM)
    -- id_fenetre non stocke : GENERATED ALWAYS AS IDENTITY,
    -- sa valeur est NULL ici -> inutilisable pour l'exclusion.
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
    -- Verification des chevauchements apres stabilisation.
    -- La nouvelle ligne est deja presente -> on l'exclut via sa
    -- cle naturelle (id_satellite, code_station, datetime_debut).
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

            -- RG-F02 : un satellite ne peut communiquer qu'avec une station a la fois
            SELECT COUNT(*) INTO v_count
            FROM FENETRE_COM
            WHERE id_satellite = g_rows(i).id_satellite
              AND NOT (code_station  = g_rows(i).code_station
                   AND datetime_debut = g_rows(i).datetime_debut)
              AND g_rows(i).datetime_debut < datetime_debut + NUMTODSINTERVAL(duree_secondes, 'SECOND')
              AND v_fin > datetime_debut;

            IF v_count > 0 THEN
                v_msg := 'Chevauchement pour le satellite ' || g_rows(i).id_satellite
                    || ' — un seul contact a la fois (RG-F02)';
            END IF;

            -- RG-F03 : une station ne peut traiter qu'un satellite a la fois
            IF v_msg IS NULL THEN
                SELECT COUNT(*) INTO v_count
                FROM FENETRE_COM
                WHERE code_station = g_rows(i).code_station
                  AND NOT (id_satellite   = g_rows(i).id_satellite
                       AND datetime_debut = g_rows(i).datetime_debut)
                  AND g_rows(i).datetime_debut < datetime_debut + NUMTODSINTERVAL(duree_secondes, 'SECOND')
                  AND v_fin > datetime_debut;

                IF v_count > 0 THEN
                    v_msg := 'Chevauchement pour la station ' || g_rows(i).code_station
                        || ' — une seule fenetre a la fois (RG-F03)';
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

-- ────────────────────────────────────────────────────────────
PROMPT [TEST T2] Cas de test...
-- ────────────────────────────────────────────────────────────

-- CAS 1 : Valide — SAT-002 sur plage libre (Jan 15 14:00, aucun chevauchement)
BEGIN
    INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
    VALUES ('SAT-002', 'GS-KIR-01', TO_TIMESTAMP('2024-01-15 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 55.0, NULL, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('OK CAS 1 : INSERT reussi (plage libre, aucun chevauchement)');
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN ROLLBACK; DBMS_OUTPUT.PUT_LINE('ERREUR inattendue CAS 1 : ' || SQLERRM);
END;
/

-- CAS 2 : Erreur RG-F02 — chevauchement satellite
-- SAT-001 a deja une fenetre le 2024-01-15 09:14:00 (420s -> fin 09:21:00)
-- Nouvelle fenetre a 09:15:00 sur autre station -> meme satellite, chevauche
BEGIN
    INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
    VALUES ('SAT-001', 'GS-TLS-01', TO_TIMESTAMP('2024-01-15 09:15:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 60.0, NULL, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait du etre rejete (RG-F02)');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('OK RG-F02 — ' || SQLERRM);
END;
/

-- CAS 3 : Erreur RG-F03 — chevauchement station
-- GS-KIR-01 occupee le 2024-01-15 09:14:00 (SAT-001, 420s -> fin 09:21:00)
-- Nouvelle fenetre a 09:14:00 meme station autre satellite -> chevauche
BEGIN
    INSERT INTO FENETRE_COM (id_satellite, code_station, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut)
    VALUES ('SAT-002', 'GS-KIR-01', TO_TIMESTAMP('2024-01-15 09:14:00', 'YYYY-MM-DD HH24:MI:SS'), 300, 50.0, NULL, 'Planifiée');
    DBMS_OUTPUT.PUT_LINE('ERREUR : INSERT aurait du etre rejete (RG-F03)');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('OK RG-F03 — ' || SQLERRM);
END;
/

PROMPT
PROMPT ────────────────────────────────────────────
PROMPT  Partie 4/6 terminee — T2 valide.
PROMPT ────────────────────────────────────────────
PROMPT
