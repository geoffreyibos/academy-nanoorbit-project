# L1-C — MLD NanoOrbit

**Module** : ALTN83 — Bases de Données Réparties  
**Projet** : NanoOrbit — CubeSat Earth Observation System  
**Phase** : Phase 1 — Conception & Architecture distribuée  
**Livrable** : L1-C — Modèle Logique de Données (MLD)

---

**Notation** : `PK` = clé primaire · `FK` = clé étrangère · `#attr` = référence vers une autre table

---

## Schéma relationnel

```
ORBITE              (id_orbite PK, type_orbite, altitude_km, inclinaison_deg, periode_min, excentricite, zone_couverture)
SATELLITE           (id_satellite PK, nom_satellite, date_lancement, masse_kg, format_cubesat, statut_actuel, duree_vie_mois, capacite_batterie_wh, #id_orbite)
INSTRUMENT          (id_instrument PK, type_instrument, modele, resolution_m, consommation_w, masse_kg)
EMBARQUEMENT        (id_satellite PK FK, id_instrument PK FK, date_integration, etat_fonctionnement)
CENTRE_CONTROLE     (id_centre PK, nom_centre, ville, region, fuseau_horaire, statut)
STATION_SOL         (code_station PK, nom_station, latitude, longitude, diametre_antenne_m, bande_frequence, debit_max_mbps, statut)
AFFECTATION_STATION (code_station PK FK, id_centre PK FK, date_affectation)
MISSION             (id_mission PK, nom_mission, objectif, zone_cible, date_debut, date_fin, statut_mission)
FENETRE_COM         (id_fenetre PK, datetime_debut, duree_secondes, elevation_max_deg, volume_donnees_mo, statut, #id_satellite, #code_station)
PARTICIPATION       (id_satellite PK FK, id_mission PK FK, role_satellite)
```

---

## Notes de transformation

- **EST_SUR** (0,N — 1,1) : absorbée par FK `#id_orbite` dans SATELLITE.
- **FENETRE_COM** : clé technique `id_fenetre` ajoutée au MLD (justifié en L1-D).
- **AFFECTATION_STATION** : table distincte car elle porte l'attribut `date_affectation`.
