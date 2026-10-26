# pickax_carnet — le carnet du joueur

Touche **F3** (ou `/carnet`). Un seul écran pour que chaque joueur sache toujours quoi faire, avec des **récompenses versées automatiquement** (compte bancaire + notification).

## Ce que voit le joueur
- **Série de connexion** : récompense chaque jour (500 → 3 500 $ sur 7 jours, le cycle recommence). On peut manquer 1 jour sans perdre sa série.
- **3 objectifs du jour** (facile / moyen / difficile), choisis selon ce que le joueur peut faire (métier, gang) et qui ne changent pas s'il se reconnecte. Les 3 terminés = bonus « journée parfaite ».
- **Objectif de la semaine** : un gros objectif perso.
- **Défi de la ville** : une activité tirée chaque semaine que TOUS les joueurs font avancer ensemble. Réussi = **gains +15 % pendant 3 h pour tout le serveur** (via `pickax_economy`) + une récompense pour chaque participant (même hors ligne : payé à la reconnexion).
- **Lieux du jour** : visiter des endroits connus de la ville (détecté automatiquement).

## Ce qui fait avancer les objectifs
| Métrique | Source |
|---|---|
| `playtime`, `social`, `visit` | boucle serveur (1 fois par minute : temps de jeu, joueurs côte à côte, lieux proches) |
| `distance` | client (km parcourus), plafonné côté serveur, téléportations ignorées |
| `job_task`, `earn` | Job Builder : métiers actifs (`AJ.pay`) et événements aléatoires de métier |
| `purchase` | Shop Builder : articles achetés |
| `minigame` | Mini-jeux : parties terminées |
| `sell` | Builder Illégal : marchandises vendues (objectif réservé aux membres d'un gang) |

Une autre ressource peut alimenter le carnet : `exports.pickax_carnet:Report(src, 'job_task', 1)` (src = id serveur ou identifiant du joueur ; métriques déjà utilisées dans `Config.Goals`).

## Réglages
- `config.lua` : récompenses, série, catalogue d'objectifs (`Config.Goals`), lieux (`Config.Places`), défis de la ville (`Config.Community`), heure de reset (`ResetHour`, `UtcOffset`).
- **Panel web → Réglages → Carnet** : activer / désactiver le carnet et multiplier toutes les récompenses. Le type d'économie du serveur (réaliste / équilibré / abusé) s'applique aussi aux récompenses.
- Tables créées automatiquement : `carnet_players`, `carnet_state`.
- `/carnetreset` (groupe admin) remet à zéro le carnet du joueur qui tape la commande (tests).

## Installation
`ensure pickax_carnet` (déjà inclus si tu utilises `ensure [dev]`). Dépend de `oxmysql` et `es_extended` ; `pickax_economy`, `pickax_settings` et `pickax_gangbuilder` sont facultatifs.

## Tests hors jeu
`lua5.4 tools/tests/carnet_test.lua` (56 vérifications : calendrier, série, objectifs, récompenses sans doublon, défi de la ville, anti-triche distance, réglages du panel).
