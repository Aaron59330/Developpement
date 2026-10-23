# pickax_heists — Braquage Doomsday · Acte II : « Le problème Bogdan »

Reproduit l'enchaînement de la mission de GTA Online : **3 préparatifs, 4 mises en place, puis le finale en 2 équipes** (sous-marin / air).

| Type | Mission | Prérequis |
|---|---|---|
| Préparatif | Cartes d'accès (fourgon antiémeute) | — |
| Mise en place | Avenger (hangar de l'aéroport) | Cartes d'accès |
| Préparatif | Renseignements ULP | — |
| Mise en place | Sauver l'agent de l'ULP (2 équipes : assaut / couverture) | Renseignements ULP |
| Préparatif | Camion antiémeute (RCV) | — |
| Préparatif | Strombergs | Sauver l'agent |
| Préparatif | Calculateurs de torpilles | Strombergs |
| Mise en place | Reconnaissance du sous-marin | Torpilles, Avenger, RCV |
| **Finale** | Le problème Bogdan | Tout le reste |

Finale — **équipe sous-marin** : Stromberg → sous-marin → éliminer le passage → trouver et interroger le contact → salle de contrôle → photo de la table de renseignements → brancher Clifford → rejoindre l'Avenger.
**Équipe aérienne** : Avenger → survoler le sous-marin → éliminer les hélicoptères ennemis → récupérer l'équipe → livrer l'Avenger.
Défi Élite : moins de 15 min, sans mort (+10 % de gain).

## Installation
1. `ensure pickax_heists` (déjà couvert par `ensure [dev]`). Dépend de `es_extended`, `oxmysql`, `ox_lib`. La table `pk_heists` se crée toute seule.
2. **Calibre les coordonnées** (obligatoire) : va à l'endroit voulu en jeu, tape `/heistpos` → la position est copiée ; colle-la dans `config.lua` (tableau `Config.Board`) ou `missions/bogdan.lua` (`coords` / `spawn`). Toutes les positions actuelles sont des **repères approximatifs**.
3. Règle le gain dans `config.lua` : `PayoutMultiplier` (0.02 = 2 % du montant GTA : 1 282 500 $ → ≈ 25 650 $).

## Utilisation
- Aller au tableau de planification (`Config.Board`), `E` → créer l'équipe → inviter les joueurs (ID, à moins de 30 m) → choisir les missions.
- Chef : lance les missions ; tous les membres reçoivent l'objectif (HUD en haut à droite).
- `/heistreset <id>` (admin) : remet à zéro la progression d'un joueur.

## Limites à connaître
- L'**intérieur du sous-marin** (cellule, salle de contrôle) n'existe pas dans la carte de base de FiveM : il faut un MLO. Sans MLO, les étapes « contact » et « salle de contrôle » se jouent aux coordonnées configurées (à placer sur ton MLO, ou à l'extérieur d'un bateau).
- Les ennemis/véhicules sont générés par chaque joueur pour sa propre part (pas de synchronisation entre membres).
- Le chef de braquage est le seul à lancer/annuler ; un joueur qui part sort de l'équipe.
