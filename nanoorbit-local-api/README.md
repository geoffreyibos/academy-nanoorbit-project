# NanoOrbit Local API

Backend local minimal pour l'application Android.

Il interroge Oracle dans le conteneur Docker `nanoorbit-oracle` via `docker exec` + `sqlplus` et expose :

- `GET /health`
- `GET /satellites`
- `GET /satellites/{id}/instruments`
- `GET /satellites/{id}/detail`
- `GET /fenetres`
- `GET /stations`

## Lancement

1. Vérifier que le conteneur Oracle est démarré
2. Depuis ce dossier, lancer :

```powershell
npm start
```

Le serveur écoute sur `http://localhost:8088`.

## Lancement recommandé sur Windows

Depuis la racine du dépôt :

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-nanoorbit-local-api.ps1
```

Ce script :

- démarre Oracle via `docker compose` si nécessaire
- démarre l'API locale en arrière-plan
- force `DOCKER_CONFIG` vers `nanoorbit-local-api/.docker-config`
- vérifie `GET /health` avant de rendre la main

Pour arrêter l'API :

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\stop-nanoorbit-local-api.ps1
```
