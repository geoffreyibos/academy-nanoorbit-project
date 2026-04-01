# L1-B — MCD MERISE NanoOrbit

**Module** : ALTN83 — Bases de Données Réparties  
**Projet** : NanoOrbit — CubeSat Earth Observation System  
**Phase** : Phase 1 — Conception & Architecture distribuée  
**Livrable** : L1-B — Modèle Conceptuel de Données (MCD)

---

## Diagramme

![MCD](L1-B_MCD.svg)

## Justification des cardinalités

| Association         | Entité A    | Card. A | Card. B | Entité B        | Justification                                                                                                               |
| ------------------- | ----------- | ------- | ------- | --------------- | --------------------------------------------------------------------------------------------------------------------------- |
| EST_SUR             | ORBITE      | `0,N`   | `1,1`   | SATELLITE       | Une orbite peut exister sans satellite affecté (RG-O03) ; un satellite est sur exactement une orbite courante (RG-S02)      |
| EMBARQUEMENT        | SATELLITE   | `1,N`   | `0,N`   | INSTRUMENT      | Un satellite embarque au moins 1 instrument (RG-S03/S04) ; un instrument peut être en catalogue sans être embarqué (RG-I01) |
| FENETRE_COM         | SATELLITE   | `0,N`   | `0,N`   | STATION_SOL     | Un satellite peut n'avoir aucune fenêtre planifiée ; une station peut n'avoir aucun passage à couvrir                       |
| PARTICIPATION       | SATELLITE   | `0,N`   | `1,N`   | MISSION         | Un satellite peut exister sans mission ; une mission mobilise au moins 1 satellite (RG-M02)                                 |
| AFFECTATION_STATION | STATION_SOL | `1,1`   | `1,N`   | CENTRE_CONTROLE | Chaque station est rattachée à exactement 1 centre (RG-G04) ; un centre supervise au moins 1 station                        |

---

## Choix de modélisation

### FENETRE_COM : entité-association

FENETRE_COM est une **entité-association** entre SATELLITE et STATION_SOL qui porte 5 attributs propres au couple (horodatage, durée, élévation, volume, statut). Ces attributs ne peuvent appartenir ni à SATELLITE ni à STATION_SOL seuls.

### Absence de lien direct SATELLITE ↔ CENTRE_CONTROLE

Aucune association directe n'existe entre SATELLITE et CENTRE_CONTROLE. Le lien est indirect : `SATELLITE → FENETRE_COM → STATION_SOL → AFFECTATION_STATION → CENTRE_CONTROLE`. Cette architecture reflète la logique opérationnelle : c'est la station sol, et non le satellite, qui est sous la responsabilité d'un centre.

### AFFECTATION_STATION : entité-association

Même si RG-G04 établisse une contrainte simple (1 station = 1 centre), l'association porte l'attribut `date_affectation`. Elle est donc modélisée comme une **entité-association** à part entière, et non comme une simple FK dans STATION_SOL.
