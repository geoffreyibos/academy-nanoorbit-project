# NanoOrbit Ground Control

Projet Android Studio complet pour le sujet `ALTN82_NanoOrbit_GroundControl_Projet.pdf`, limité volontairement à la partie mobile dans `altn82-android`.

## Stack retenue

- Kotlin + Jetpack Compose + Material 3
- Architecture MVVM avec `NanoOrbitViewModel`
- Repository cache-first
- Room pour le cache local
- Interface Retrofit `NanoOrbitApi` + implémentation mock `MockNanoOrbitApi`
- Navigation Compose
- osmdroid pour la carte OpenStreetMap
- WorkManager pour le bonus notifications locales

## Structure principale

- `app/src/main/java/com/efrei/nanoorbit/data/models`
  Modèles Kotlin cohérents avec le MLD NanoOrbit + `MockData.kt` aligné sur les CSV ALTN83.
- `app/src/main/java/com/efrei/nanoorbit/data/api`
  Interface REST `GET /satellites`, `GET /satellites/{id}/instruments`, `GET /fenetres`.
- `app/src/main/java/com/efrei/nanoorbit/data/db`
  Cache Room avec `SatelliteEntity` et `FenetreEntity`.
- `app/src/main/java/com/efrei/nanoorbit/data/repository`
  Stratégie cache-first + validations client.
- `app/src/main/java/com/efrei/nanoorbit/ui`
  Dashboard, détail, planning, carte, navigation et composants réutilisables.
- `app/src/main/java/com/efrei/nanoorbit/viewmodel`
  État central de l’application via `StateFlow`.

## Synergies explicites avec ALTN83

1. Modèles de données
   `Models.kt` reprend les entités Oracle importantes (`SATELLITE`, `ORBITE`, `INSTRUMENT`, `MISSION`, `FENETRE_COM`, `STATION_SOL`) et les enums miroir des `CHECK`.

2. Règle RG-F04
   La validation client de la durée `[1..900]` est implémentée dans `NanoOrbitRepository.validateFenetreCreation()` et utilisée dans `PlanningScreen`.

3. Continuité hors-ligne Q3
   `NanoOrbitRepository` applique une stratégie cache-first avec Room, affichage d’une bannière hors-ligne et âge du cache dans le dashboard.

## Fonctionnalités couvertes

- Dashboard avec recherche temps réel, filtre statut, compteur, gestion des satellites désorbités
- DetailScreen avec statut, télémétrie, instruments, missions actives et dialogue d’anomalie
- PlanningScreen avec filtre station, tri chronologique, indicateurs agrégés et validation client
- MapScreen avec stations au sol, OSM, géolocalisation opérateur et distance jusqu’aux stations
- Notifications locales pour les fenêtres imminentes via WorkManager

## Ouverture dans Android Studio

1. Ouvrir le dossier `altn82-android/starter`
2. Laisser Android Studio synchroniser Gradle
3. Lancer sur un émulateur ou un appareil API 26+

## Limites de la livraison

- La partie `altn83-bdd` n’a pas été modifiée
- Le réseau est simulé côté Android via `MockNanoOrbitApi`
- Je n’ai pas pu exécuter une compilation locale ici car `gradle` et `gradle-wrapper.jar` n’étaient pas disponibles dans l’environnement du terminal
