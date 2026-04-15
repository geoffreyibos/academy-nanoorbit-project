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
