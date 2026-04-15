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

### Q1 — Tables strictement locales

Les tables **STATION_SOL**, **AFFECTATION_STATION** et **FENETRE_COM** sont strictement locales à chaque centre de contrôle.

Une station sol est un équipement physique ancré dans une région : Paris n'a aucune raison d'accéder aux données opérationnelles de la station de Singapour. Les fenêtres de communication sont planifiées et exécutées par le centre qui gère la station concernée : ce sont des données de production locale, pas des données partagées. Les partager en temps réel n'apporterait rien et créerait inutilement du trafic réseau inter-sites.

---

### Q2 — Tables globales et synchronisation

Les tables **ORBITE**, **INSTRUMENT**, **SATELLITE**, **MISSION**, **EMBARQUEMENT** et **PARTICIPATION** doivent être accessibles depuis tous les centres.

Ces tables contiennent les données de référence du système : la configuration des satellites, le catalogue des instruments, les missions en cours. Un opérateur à Houston doit pouvoir consulter l'état d'un satellite géré depuis Paris, ou vérifier qu'une mission est encore active avant d'y inscrire un satellite.

On propose une **réplication en lecture** sur les 3 nœuds, avec un nœud maître (Paris) qui centralise les écritures. Les mises à jour sont propagées de façon asynchrone. Pour les changements critiques comme le passage d'un satellite à 'Désorbité', la propagation doit être synchrone pour éviter des insertions invalides sur les autres sites.

---

### Q3 — Continuité de service pour Singapour

Si le serveur central est indisponible, Singapour doit pouvoir continuer à planifier des fenêtres pour ses stations locales.

On propose une **fragmentation horizontale** : chaque centre héberge localement ses tables STATION_SOL, AFFECTATION_STATION et FENETRE_COM. La planification d'une fenêtre n'a besoin que des données locales (la station, ses créneaux déjà occupés) et d'une copie locale de SATELLITE (répliquée). Singapour peut donc fonctionner en mode dégradé en s'appuyant sur sa réplique locale de SATELLITE et ses propres tables FENETRE_COM, sans dépendre du nœud central.

La réconciliation avec les autres sites se fait à la reconnexion.

---

### Q4 — Risques de cohérence

**Scénario 1 — Statut satellite incohérent**  
Paris met à jour le statut de SAT-003 à 'Désorbité'. Quelques secondes plus tard, avant que la réplication soit arrivée à Houston, un opérateur houston insère une nouvelle fenêtre de communication pour ce satellite. Le trigger `trg_valider_fenetre` vérifie le statut localement — mais la copie locale de SATELLITE n'est pas encore à jour. La fenêtre est créée, ce qui est une erreur opérationnelle.

**Scénario 2 — Chevauchement temporel inter-sites**  
SAT-002 passe au-dessus de deux stations en même temps (trajectoire en limite de zone). Paris planifie une fenêtre sur GS-TLS-01 et Singapour planifie en parallèle une fenêtre sur GS-SGP-01 pour le même satellite, au même créneau. Chaque trigger de chevauchement ne vérifie que la table FENETRE_COM locale — le chevauchement n'est pas détecté. Le satellite se retrouve avec deux fenêtres simultanées, ce qui est physiquement impossible.
