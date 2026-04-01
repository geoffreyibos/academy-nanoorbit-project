# L1-D — Note de modélisation NanoOrbit

**Module** : ALTN83 — Bases de Données Réparties  
**Projet** : NanoOrbit — CubeSat Earth Observation System  
**Phase** : Phase 1 — Conception & Architecture distribuée  
**Livrable** : L1-D — Note de modélisation

---

## Partie 1 — Choix de modélisation

### Choix 1 — FENETRE_COM comme entité-association

On aurait pu modéliser FENETRE_COM comme une simple entité avec deux FK. On a préféré en faire une entité-association car les attributs qu'elle porte (`datetime_debut`, `duree_secondes`, `elevation_max_deg`, etc.) n'ont de sens que pour le couple (satellite, station) — ils décrivent l'événement de communication en lui-même, pas le satellite ni la station pris séparément.

La clé technique `id_fenetre` n'apparaît qu'au MLD (pas au MCD) : elle est ajoutée uniquement pour simplifier le référencement dans les triggers de chevauchement temporel.

---

### Choix 2 — Pas de lien direct SATELLITE ↔ CENTRE_CONTROLE

On aurait pu mettre une FK `id_centre` dans SATELLITE pour indiquer quel centre pilote quel satellite. On ne l'a pas fait car un satellite en orbite basse (LEO/SSO) passe au-dessus de plusieurs régions et peut communiquer avec des stations rattachées à des centres différents. Le rattachement centre ↔ satellite passe donc par les stations, via FENETRE_COM et AFFECTATION_STATION.

---

### Choix 3 — AFFECTATION_STATION comme table distincte

RG-G04 impose qu'une station appartienne à un seul centre — on aurait pu simplement mettre `#id_centre` dans STATION_SOL et supprimer la table. On a gardé AFFECTATION_STATION séparée parce qu'elle porte `date_affectation`, qui permet de tracer les changements de rattachement dans le temps.

---

## Partie 2 — Architecture distribuée

### Contexte

Trois nœuds, un par centre de contrôle :

| Nœud | Ville | Région | Station |
|---|---|---|---|
| CTR-001 | Paris | Europe | GS-TLS-01 |
| CTR-002 | Houston | Amériques | GS-KIR-01 |
| CTR-003 | Singapour | Asie-Pacifique | GS-SGP-01 |

---

### Q1 — Données globales vs locales

- **Globales** (partagées entre tous les centres) : ORBITE, INSTRUMENT, SATELLITE, MISSION, EMBARQUEMENT, PARTICIPATION
- **Locales** (propres à chaque centre) : CENTRE_CONTROLE, STATION_SOL, AFFECTATION_STATION, FENETRE_COM

Les données de catalogue (orbites, instruments) et les données de mission sont globales car elles sont consultées par tous les opérateurs. Les données opérationnelles du quotidien (passages, stations) sont locales car chaque centre ne gère que ses propres équipements.

---

### Q2 — Fragmentation

Les données locales sont fragmentées **horizontalement par région** :

- STATION_SOL et AFFECTATION_STATION → stockées sur le nœud du centre auquel la station est rattachée
- FENETRE_COM → fragmentée par `code_station`, donc naturellement distribuée sur le nœud qui gère cette station
- CENTRE_CONTROLE → chaque nœud héberge uniquement sa propre ligne

Les données globales sont **répliquées** sur les 3 nœuds (voir Q3).

---

### Q3 — Réplication

Les tables globales sont répliquées en **réplication asynchrone** sur les 3 nœuds. Paris est désigné nœud maître pour les écritures. Les lectures sont satisfaites localement, ce qui réduit la latence pour les opérations courantes (consultation du catalogue, affichage des missions).

Les mises à jour critiques comme le changement de statut d'un satellite ('Désorbité') doivent être propagées rapidement sur tous les nœuds pour éviter des incohérences opérationnelles.

---

### Q4 — Problèmes de cohérence anticipés

Trois situations peuvent poser problème :

1. **Statut satellite** : si un satellite passe à 'Désorbité' sur Paris mais que Houston n'a pas encore reçu la mise à jour, Houston pourrait planifier une fenêtre invalide. → Propagation synchrone du statut avant tout INSERT dans FENETRE_COM.

2. **Chevauchement temporel inter-sites** : deux centres pourraient planifier en même temps une fenêtre pour le même satellite. → La vérification de chevauchement doit s'appuyer sur une vue consolidée de FENETRE_COM, pas seulement les données locales.

3. **Mission terminée** : si Paris clôture une mission mais que Singapour n'a pas encore synchronisé, Singapour peut encore ajouter des satellites à cette mission. → Le statut de MISSION doit être vérifié sur la version répliquée à jour.
