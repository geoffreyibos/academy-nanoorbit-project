# L1-C — MLD NanoOrbit

**Module** : ALTN83 — Bases de Données Réparties  
**Projet** : NanoOrbit — CubeSat Earth Observation System  
**Groupe** : 06 — Oscar DEBEURET / Geoffrey IBOS / Hugo LEROUX  
**Phase** : Phase 1 — Conception & Architecture distribuée  
**Livrable** : L1-C — Modèle Logique de Données (MLD)

---

**Notation** : `PK` = clé primaire · `FK` = clé étrangère · `#attr` = référence vers une autre table

---

## Schéma relationnel

```
ORBITE (id_orbite PK, type_orbite, altitude_km, inclinaison_deg, periode_min, excentricite, zone_couverture)
SATELLITE (id_satellite PK, nom_satellite, date_lancement, masse_kg, format_cubesat, statut, duree_vie_mois, capacite_batterie_wh, #id_orbite)
INSTRUMENT (ref_instrument PK, type_instrument, modele, resolution_m, consommation_w, masse_kg)
EMBARQUEMENT (id_satellite PK FK, ref_instrument PK FK, date_integration, etat_fonctionnement, commentaire)
CENTRE_CONTROLE (id_centre PK, nom_centre, ville, region, fuseau_horaire, statut)
STATION_SOL (code_station PK, nom_station, latitude, longitude, diametre_antenne_m, bande_frequence, debit_max_mbps, statut, #id_centre)
MISSION (id_mission PK, nom_mission, objectif, zone_cible, date_debut, date_fin, statut_mission)
FENETRE_COM (id_fenetre PK, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut, #id_satellite, #code_station)
PARTICIPATION (id_satellite PK FK, id_mission PK FK, role_satellite)
```

## Notes de transformation

- **EST_SUR** (1,1 côté SATELLITE) : absorbée par FK `#id_orbite` dans SATELLITE — la cardinalité 1,1 impose une FK directe plutôt qu'une table de jointure.
- **EMBARQUEMENT** : table distincte car elle porte trois attributs propres (`date_integration`, `etat_fonctionnement`, `commentaire`) qui caractérisent le couple SATELLITE × INSTRUMENT.
- **FENETRE_COM** : entité autonome issue de la transformation du MCD — les deux associations CONCERNE et RECOIT sont absorbées par les FK `#id_satellite` et `#code_station` portées directement par la table (cardinalités 1,N côté FENETRE_COM dans les deux cas).
- **AFFECTATION_STATION** (1,1 côté STATION_SOL) : absorbée par FK `#id_centre` dans STATION_SOL — la cardinalité 1,1 permet cette absorption ; l'attribut `date_affectation` est déplacé dans STATION_SOL en conséquence.
- **PARTICIPATION** : table distincte car l'association est de type N,N entre SATELLITE et MISSION, avec l'attribut `role_satellite`.
