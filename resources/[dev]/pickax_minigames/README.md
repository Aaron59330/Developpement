# pickax_minigames — Mini-jeux Builder

Crée en jeu des mini-jeux complets (lobby, compte à rebours, scores, récompenses, classements) via une interface style Apple.
Commande : `/minigames` (ou bouton « Mini-jeux Builder » du menu admin / du panel `/builders`).

## Types fournis
| Type | Moteur | Principe |
|---|---|---|
| Basket | shoot | maintiens **E**, relâche dans la zone verte ; panier 2 / 3 points |
| Football | shoot | tirs au but, zones du but à points |
| Tennis | rally | une machine envoie des balles, renvoie-les avec **E** vers les zones |
| Boxe | fight | duel, rounds, PV, K.O. (dégâts décidés par le serveur) |
| Paintball / Laser game | tag | touches validées par le serveur (aucun vrai dégât), équipes ou solo |
| Course | race | checkpoints, tours, à pied / vélo / voiture, classement au temps |

## Utilisation
1. `/minigames` → **Nouveau mini-jeu** → choisis un type (ou un modèle).
2. Onglet **Emplacements** : place-toi sur le terrain puis « Ma position » / « Point visé » pour chaque point.
3. Règle **Règles**, **Récompenses**, **Réglages**, enregistre, active.
4. Les joueurs entrent dans le marker du lobby (**E**), rejoignent, la partie démarre quand le minimum est atteint.
5. **F9** (réglable) pour quitter une partie.

## Sécurité
Scores, touches, coups, checkpoints et gains sont validés côté serveur (distances, cadence, limites). Les mises sont remboursées si la partie n'a pas démarré.
Tables SQL créées automatiquement : `minigames_defs`, `minigames_stats`, `minigames_logs`.

## Ajouter un type
Ajoute une entrée dans `Config.Types` (`config.lua`) en réutilisant un moteur existant (`shoot`, `rally`, `fight`, `tag`, `race`) : champs, emplacements et modèles apparaissent automatiquement dans le builder.
