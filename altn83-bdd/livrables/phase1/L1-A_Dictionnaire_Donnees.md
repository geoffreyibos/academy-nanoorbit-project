# L1-A — Dictionnaire des données NanoOrbit

**Module** : ALTN83 — Bases de Données Réparties  
**Projet** : NanoOrbit — CubeSat Earth Observation System  
**Phase** : Phase 1 — Conception & Architecture distribuée  
**Livrable** : L1-A — Dictionnaire des données complet

---

## Partie 1 — Tableau des attributs par entité

### Entité : ORBITE

| Attribut               | Code Oracle       | Type Oracle                                   | Obligatoire | Unique | Contraintes / Remarques                        |
| ---------------------- | ----------------- | --------------------------------------------- | ----------- | ------ | ---------------------------------------------- |
| Identifiant orbite     | `id_orbite`       | `NUMBER GENERATED ALWAYS AS IDENTITY`         | OUI         | OUI    | PK — clé technique auto-incrémentée            |
| Type d'orbite          | `type_orbite`     | `VARCHAR2(10)`                                | OUI         | NON    | CHECK IN ('LEO', 'MEO', 'SSO', 'GEO')          |
| Altitude (km)          | `altitude_km`     | `NUMBER(5)`                                   | OUI         | NON    | UNIQUE composite avec inclinaison_deg (RG-O02) |
| Inclinaison (°)        | `inclinaison_deg` | `NUMBER(5,2)`                                 | OUI         | NON    | UNIQUE composite avec altitude_km (RG-O02)     |
| Période orbitale (min) | `periode_min`     | `NUMBER(6,2)`                                 | OUI         | NON    | Durée d'une révolution complète                |
| Excentricité           | `excentricite`    | `NUMBER(6,4)`                                 | OUI         | NON    | 0 = circulaire, 1 = elliptique extrême         |
| Zone de couverture     | `zone_couverture` | `VARCHAR2(200)`                               | OUI         | NON    | Description géographique                       |

> Contrainte composite : `UNIQUE (altitude_km, inclinaison_deg)` — RG-O02

---

### Entité : SATELLITE

| Attribut                   | Code Oracle            | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                                           |
| -------------------------- | ---------------------- | --------------- | ----------- | ------ | ----------------------------------------------------------------- |
| Identifiant satellite      | `id_satellite`         | `VARCHAR2(20)`  | OUI         | OUI    | PK — format SAT-NNN, immuable après mise en orbite (RG-S01)       |
| Nom du satellite           | `nom_satellite`        | `VARCHAR2(100)` | OUI         | NON    | Nom commercial ou opérationnel                                    |
| Date de lancement          | `date_lancement`       | `DATE`          | OUI         | NON    | Date effective de mise en orbite                                  |
| Masse (kg)                 | `masse_kg`             | `NUMBER(5,2)`   | OUI         | NON    | Masse au lancement en kilogrammes                                 |
| Format CubeSat             | `format_cubesat`       | `VARCHAR2(5)`   | OUI         | NON    | CHECK IN ('1U', '3U', '6U', '12U')                                |
| Statut opérationnel        | `statut_actuel`        | `VARCHAR2(30)`  | OUI         | NON    | CHECK IN ('Opérationnel', 'En veille', 'Défaillant', 'Désorbité') |
| Durée de vie prévue (mois) | `duree_vie_mois`       | `NUMBER(4)`     | OUI         | NON    | Durée nominale de la mission                                      |
| Capacité batterie (Wh)     | `capacite_batterie_wh` | `NUMBER(6,1)`   | OUI         | NON    | Énergie stockable                                                 |
| Orbite courante            | `id_orbite`            | `NUMBER`        | OUI         | NON    | FK → ORBITE(id_orbite) — orbite actuelle du satellite (RG-S02)    |

> Note RG-S06 : un satellite au statut 'Désorbité' ne peut plus recevoir de nouvelles fenêtres ni participer à de nouvelles missions. Cette contrainte ne peut PAS être exprimée en DDL seul — elle sera implémentée par un trigger BEFORE INSERT en Phase 2.

---

### Entité : INSTRUMENT

| Attribut             | Code Oracle       | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                                    |
| -------------------- | ----------------- | --------------- | ----------- | ------ | ---------------------------------------------------------- |
| Référence instrument | `id_instrument`   | `VARCHAR2(20)`  | OUI         | OUI    | PK — référence constructeur (ex : INS-CAM-01)              |
| Type d'instrument    | `type_instrument` | `VARCHAR2(50)`  | OUI         | NON    | Caméra optique / Infrarouge / Récepteur AIS / Spectromètre |
| Modèle               | `modele`          | `VARCHAR2(100)` | OUI         | NON    | Désignation commerciale                                    |
| Résolution (m)       | `resolution_m`    | `NUMBER(6,1)`   | NON         | NON    | NULL si non applicable (ex : capteurs AIS)                 |
| Consommation (W)     | `consommation_w`  | `NUMBER(5,2)`   | OUI         | NON    | Puissance consommée en fonctionnement                      |
| Masse (kg)           | `masse_kg`        | `NUMBER(5,3)`   | OUI         | NON    | Masse de l'instrument                                      |

---

### Entité-association : EMBARQUEMENT _(SATELLITE ↔ INSTRUMENT)_

> Entité-association porteuse d'attributs propres à chaque couple (satellite, instrument) — RG-S04

| Attribut               | Code Oracle           | Type Oracle    | Obligatoire | Unique | Contraintes / Remarques                          |
| ---------------------- | --------------------- | -------------- | ----------- | ------ | ------------------------------------------------ |
| Identifiant satellite  | `id_satellite`        | `VARCHAR2(20)` | OUI         | NON    | PK composite + FK → SATELLITE(id_satellite)      |
| Référence instrument   | `id_instrument`       | `VARCHAR2(20)` | OUI         | NON    | PK composite + FK → INSTRUMENT(id_instrument)    |
| Date d'intégration     | `date_integration`    | `DATE`         | OUI         | NON    | Date de montage de l'instrument sur le satellite |
| État de fonctionnement | `etat_fonctionnement` | `VARCHAR2(20)` | OUI         | NON    | CHECK IN ('Nominal', 'Dégradé', 'Hors service')  |

> PK composite : `(id_satellite, id_instrument)`

---

### Entité : CENTRE_CONTROLE

| Attribut            | Code Oracle      | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                            |
| ------------------- | ---------------- | --------------- | ----------- | ------ | -------------------------------------------------- |
| Identifiant centre  | `id_centre`      | `VARCHAR2(20)`  | OUI         | OUI    | PK — format CTR-NNN                                |
| Nom du centre       | `nom_centre`     | `VARCHAR2(100)` | OUI         | NON    | Nom opérationnel                                   |
| Ville               | `ville`          | `VARCHAR2(50)`  | OUI         | NON    | Ville d'implantation                               |
| Région géographique | `region`         | `VARCHAR2(50)`  | OUI         | NON    | CHECK IN ('Europe', 'Amériques', 'Asie-Pacifique') |
| Fuseau horaire      | `fuseau_horaire` | `VARCHAR2(50)`  | OUI         | NON    | Identifiant IANA (ex : Europe/Paris)               |
| Statut              | `statut`         | `VARCHAR2(20)`  | OUI         | NON    | CHECK IN ('Actif', 'Inactif')                      |

---

### Entité : STATION_SOL

| Attribut             | Code Oracle          | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                                 |
| -------------------- | -------------------- | --------------- | ----------- | ------ | ------------------------------------------------------- |
| Code station         | `code_station`       | `VARCHAR2(20)`  | OUI         | OUI    | PK — format GS-XXX-NN (RG-G01)                          |
| Nom de la station    | `nom_station`        | `VARCHAR2(100)` | OUI         | NON    | Nom opérationnel                                        |
| Latitude (°)         | `latitude`           | `NUMBER(9,6)`   | OUI         | NON    | Coordonnée Nord/Sud (RG-G01)                            |
| Longitude (°)        | `longitude`          | `NUMBER(9,6)`   | OUI         | NON    | Coordonnée Est/Ouest (RG-G01)                           |
| Diamètre antenne (m) | `diametre_antenne_m` | `NUMBER(4,1)`   | OUI         | NON    | Taille de l'antenne principale                          |
| Bande de fréquence   | `bande_frequence`    | `VARCHAR2(10)`  | OUI         | NON    | CHECK IN ('UHF', 'S', 'X', 'Ka')                        |
| Débit max (Mbps)     | `debit_max_mbps`     | `NUMBER(6,1)`   | OUI         | NON    | Débit descendant maximal                                |
| Statut               | `statut`             | `VARCHAR2(20)`  | OUI         | NON    | CHECK IN ('Active', 'Maintenance', 'Inactive') (RG-G03) |

---

### Association : AFFECTATION_STATION _(STATION_SOL ↔ CENTRE_CONTROLE)_

> Chaque station est rattachée à exactement un centre de contrôle (RG-G04). Un centre peut superviser plusieurs stations.

| Attribut           | Code Oracle        | Type Oracle    | Obligatoire | Unique | Contraintes / Remarques                        |
| ------------------ | ------------------ | -------------- | ----------- | ------ | ---------------------------------------------- |
| Identifiant centre | `id_centre`        | `VARCHAR2(20)` | OUI         | NON    | PK composite + FK → CENTRE_CONTROLE(id_centre) |
| Code station       | `code_station`     | `VARCHAR2(20)` | OUI         | NON    | PK composite + FK → STATION_SOL(code_station)  |
| Date d'affectation | `date_affectation` | `DATE`         | OUI         | NON    | Date de rattachement de la station au centre   |

> PK composite : `(id_centre, code_station)`

---

### Entité : MISSION

| Attribut                | Code Oracle      | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                              |
| ----------------------- | ---------------- | --------------- | ----------- | ------ | ---------------------------------------------------- |
| Identifiant mission     | `id_mission`     | `VARCHAR2(20)`  | OUI         | OUI    | PK — format MSN-XXX-AAAA (RG-M01)                    |
| Nom de la mission       | `nom_mission`    | `VARCHAR2(100)` | OUI         | NON    | Intitulé descriptif                                  |
| Objectif                | `objectif`       | `VARCHAR2(500)` | OUI         | NON    | Description de l'objectif scientifique               |
| Zone géographique cible | `zone_cible`     | `VARCHAR2(200)` | OUI         | NON    | Région d'intérêt principal                           |
| Date de début           | `date_debut`     | `DATE`          | OUI         | NON    | NOT NULL — démarrage effectif de la mission (RG-M01) |
| Date de fin             | `date_fin`       | `DATE`          | NON         | NON    | NULL si mission à durée indéterminée (RG-M01)        |
| Statut mission          | `statut_mission` | `VARCHAR2(20)`  | OUI         | NON    | CHECK IN ('Active', 'Terminée')                      |

> Note RG-M04 : une mission au statut 'Terminée' ne peut plus accueillir de nouveaux satellites. Cette contrainte nécessite un trigger BEFORE INSERT sur PARTICIPATION.

---

### Entité : FENETRE_COM

| Attribut               | Code Oracle         | Type Oracle                           | Obligatoire | Unique | Contraintes / Remarques                          |
| ---------------------- | ------------------- | ------------------------------------- | ----------- | ------ | ------------------------------------------------ |
| Identifiant fenêtre    | `id_fenetre`        | `NUMBER GENERATED ALWAYS AS IDENTITY` | OUI         | OUI    | PK — clé technique auto-incrémentée              |
| Identifiant satellite  | `id_satellite`      | `VARCHAR2(20)`                        | OUI         | NON    | FK NOT NULL → SATELLITE(id_satellite) (RG-F01)   |
| Code station           | `code_station`      | `VARCHAR2(20)`                        | OUI         | NON    | FK NOT NULL → STATION_SOL(code_station) (RG-F01) |
| Date/heure de début    | `datetime_debut`    | `TIMESTAMP`                           | OUI         | NON    | Début du passage du satellite                    |
| Durée (secondes)       | `duree_secondes`    | `NUMBER(4)`                           | OUI         | NON    | CHECK BETWEEN 1 AND 900 (RG-F04)                 |
| Élévation max (°)      | `elevation_max_deg` | `NUMBER(5,2)`                         | OUI         | NON    | Angle d'élévation maximal du passage             |
| Volume de données (Mo) | `volume_donnees_mo` | `NUMBER(8,1)`                         | NON         | NON    | NULL si statut ≠ 'Réalisée' (RG-F05)             |
| Statut                 | `statut`            | `VARCHAR2(20)`                        | OUI         | NON    | CHECK IN ('Planifiée', 'Réalisée')               |

> Notes :
>
> - RG-F02 : pas de chevauchement temporel pour un même satellite → Trigger BEFORE INSERT OR UPDATE
> - RG-F03 : pas de chevauchement temporel pour une même station → Trigger BEFORE INSERT OR UPDATE
> - RG-F05 : `volume_donnees_mo` doit rester NULL si statut ≠ 'Réalisée' → Trigger BEFORE INSERT OR UPDATE

---

### Entité-association : PARTICIPATION _(SATELLITE ↔ MISSION)_

> Entité-association porteuse du rôle du satellite dans la mission — RG-M03

| Attribut              | Code Oracle      | Type Oracle     | Obligatoire | Unique | Contraintes / Remarques                                                          |
| --------------------- | ---------------- | --------------- | ----------- | ------ | -------------------------------------------------------------------------------- |
| Identifiant satellite | `id_satellite`   | `VARCHAR2(20)`  | OUI         | NON    | PK composite + FK → SATELLITE(id_satellite)                                      |
| Identifiant mission   | `id_mission`     | `VARCHAR2(20)`  | OUI         | NON    | PK composite + FK → MISSION(id_mission)                                          |
| Rôle du satellite     | `role_satellite` | `VARCHAR2(100)` | OUI         | NON    | Ex : 'Imageur principal', 'Satellite de relais', 'Satellite de secours' (RG-M03) |

> PK composite : `(id_satellite, id_mission)`

---

## Partie 2 — Classification des règles de gestion

### Catégorie 1 — Structure relationnelle (PK, FK, UNIQUE)

_Ces règles s'expriment directement dans la structure du MCD/MLD par des clés primaires, étrangères ou contraintes d'unicité._

| Code   | Règle (résumé)                                                    | Mécanisme Oracle                                                          |
| ------ | ----------------------------------------------------------------- | ------------------------------------------------------------------------- |
| RG-S01 | Identifiant satellite unique, immuable                            | PK `id_satellite` dans SATELLITE                                          |
| RG-S02 | Satellite sur une orbite courante (FK vers ORBITE)                | FK `id_orbite` dans SATELLITE → ORBITE                                    |
| RG-S03 | Association N-N satellite ↔ instrument                            | PK composite dans EMBARQUEMENT                                            |
| RG-S04 | Attributs propres à l'embarquement (date, état)                   | Entité-association EMBARQUEMENT avec attributs                            |
| RG-S05 | Association N-N satellite ↔ mission                               | PK composite dans PARTICIPATION                                           |
| RG-O01 | Orbite = entité indépendante, plusieurs satellites possibles      | Entité ORBITE + FK depuis SATELLITE                                       |
| RG-O02 | Unicité de la combinaison altitude + inclinaison                  | `UNIQUE (altitude_km, inclinaison_deg)` dans ORBITE                       |
| RG-O03 | Orbite peut exister sans satellite affecté                        | FK nullable côté SATELLITE (pas de `NOT NULL` sur `id_orbite`)            |
| RG-I01 | Instrument référencé dans un catalogue global indépendant         | Entité INSTRUMENT indépendante, PK `id_instrument`                        |
| RG-I02 | Instrument partageable entre plusieurs satellites                 | Association N-N via EMBARQUEMENT                                          |
| RG-G01 | Station identifiée par code unique, localisée (lat/long)          | PK `code_station` + `NOT NULL` `latitude`, `longitude`                    |
| RG-G02 | Station communique avec plusieurs satellites                      | Association N-N via FENETRE_COM                                           |
| RG-G04 | Chaque station rattachée à exactement un centre de contrôle       | Table AFFECTATION_STATION + FK vers CENTRE_CONTROLE et STATION_SOL        |
| RG-F01 | Fenêtre implique obligatoirement 1 satellite + 1 station          | FK `NOT NULL` `id_satellite` et `code_station` dans FENETRE_COM           |
| RG-M01 | Mission : date de début obligatoire, fin facultative              | `NOT NULL` `date_debut`, nullable `date_fin` dans MISSION                 |
| RG-M02 | Mission mobilise ≥ 1 satellite, satellite dans plusieurs missions | Association N-N via PARTICIPATION                                         |
| RG-M03 | Rôle du satellite dans chaque mission                             | Attribut `role_satellite` dans PARTICIPATION                              |

---

### Catégorie 2 — Contrainte simple (CHECK, NOT NULL)

_Ces règles s'expriment par des contraintes statiques Oracle directement dans le DDL._

| Code   | Règle (résumé)                                                     | Mécanisme Oracle                                                              |
| ------ | ------------------------------------------------------------------ | ----------------------------------------------------------------------------- |
| RG-F04 | Durée fenêtre : entre 1 s et 900 s maximum                         | `CHECK (duree_secondes BETWEEN 1 AND 900)` dans FENETRE_COM                   |
| —      | Valeurs admises pour `statut_actuel` (SATELLITE)                   | `CHECK (statut_actuel IN ('Opérationnel', 'En veille', 'Défaillant', 'Désorbité'))` |
| —      | Valeurs admises pour `format_cubesat` (SATELLITE)                  | `CHECK (format_cubesat IN ('1U', '3U', '6U', '12U'))`                         |
| —      | Valeurs admises pour `etat_fonctionnement` (EMBARQUEMENT)          | `CHECK (etat_fonctionnement IN ('Nominal', 'Dégradé', 'Hors service'))`       |
| —      | Valeurs admises pour `statut` (STATION_SOL)                        | `CHECK (statut IN ('Active', 'Maintenance', 'Inactive'))`                     |
| —      | Valeurs admises pour `bande_frequence` (STATION_SOL)               | `CHECK (bande_frequence IN ('UHF', 'S', 'X', 'Ka'))`                         |
| —      | Valeurs admises pour `statut_mission` (MISSION)                    | `CHECK (statut_mission IN ('Active', 'Terminée'))`                            |
| —      | Valeurs admises pour `statut` (FENETRE_COM)                        | `CHECK (statut IN ('Planifiée', 'Réalisée'))`                                 |
| —      | Valeurs admises pour `type_orbite` (ORBITE)                        | `CHECK (type_orbite IN ('LEO', 'MEO', 'SSO', 'GEO'))`                        |
| —      | Valeurs admises pour `statut` (CENTRE_CONTROLE)                    | `CHECK (statut IN ('Actif', 'Inactif'))`                                      |
| —      | Tous les attributs NOT NULL sauf `date_fin` et `volume_donnees_mo` | `NOT NULL` sur tous les champs obligatoires (cf. tableaux)                    |

---

### Catégorie 3 — Mécanisme procédural (Trigger / Procédure PL/SQL)

_Ces règles NE PEUVENT PAS être exprimées par des contraintes DDL statiques. Elles seront implémentées par des triggers en Phase 2 ou des procédures en Phase 3._

| Code   | Règle (résumé)                                                 | Mécanisme Oracle                                                          | Phase        |
| ------ | -------------------------------------------------------------- | ------------------------------------------------------------------------- | ------------ |
| RG-S06 | Satellite 'Désorbité' : plus de fenêtre ni de mission possible | Trigger `BEFORE INSERT` sur FENETRE_COM et PARTICIPATION                  | Phase 2 — T1 |
| RG-I03 | Instrument non embarqué simultanément sur deux satellites      | Trigger `BEFORE INSERT` sur EMBARQUEMENT (vérification unicité active)    | Phase 2      |
| RG-I04 | Instrument 'Hors service' > 30 jours → satellite à signaler    | Procédure PL/SQL (inspection périodique)                                  | Phase 3      |
| RG-G03 | Station en 'Maintenance' : pas de nouvelle fenêtre planifiable | Trigger `BEFORE INSERT` sur FENETRE_COM                                   | Phase 2 — T1 |
| RG-F02 | Pas de chevauchement temporel pour un même satellite           | Trigger `BEFORE INSERT OR UPDATE` sur FENETRE_COM                         | Phase 2 — T2 |
| RG-F03 | Pas de chevauchement temporel pour une même station            | Trigger `BEFORE INSERT OR UPDATE` sur FENETRE_COM                         | Phase 2 — T2 |
| RG-F05 | `volume_donnees_mo` NULL si statut ≠ 'Réalisée'                | Trigger `BEFORE INSERT OR UPDATE` sur FENETRE_COM                         | Phase 2 — T3 |
| RG-M04 | Mission 'Terminée' : plus de nouveaux satellites               | Trigger `BEFORE INSERT` sur PARTICIPATION                                 | Phase 2 — T4 |

---

## Récapitulatif : nombre d'attributs par entité

| Entité / Association  | Nombre d'attributs | PK                   | FK              | Attributs porteurs                          |
| --------------------- | ------------------ | -------------------- | --------------- | ------------------------------------------- |
| ORBITE                | 7                  | 1 (simple)           | —               | —                                           |
| SATELLITE             | 9                  | 1 (simple)           | 1 (`id_orbite`) | —                                           |
| INSTRUMENT            | 6                  | 1 (simple)           | —               | —                                           |
| EMBARQUEMENT          | 4                  | 1 (composite 2 cols) | 2               | `date_integration`, `etat_fonctionnement`   |
| CENTRE_CONTROLE       | 6                  | 1 (simple)           | —               | —                                           |
| STATION_SOL           | 8                  | 1 (simple)           | —               | —                                           |
| AFFECTATION_STATION   | 3                  | 1 (composite 2 cols) | 2               | `date_affectation`                          |
| MISSION               | 7                  | 1 (simple)           | —               | —                                           |
| FENETRE_COM           | 8                  | 1 (simple)           | 2               | —                                           |
| PARTICIPATION         | 3                  | 1 (composite 2 cols) | 2               | `role_satellite`                            |
| **TOTAL**             | **61**             | **10 tables**        | **9 FK**        |                                             |
