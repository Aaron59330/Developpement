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
| Padel / Volley-ball | rally | comme le tennis, autre balle et autre rythme |
| Fléchettes | shoot | jauge de précision, anneaux de la cible en zones à points |
| Bowling | bowling | 10 frames, quilles placées automatiquement, strike / spare bonifiés |
| Combat libre | fight | comme la boxe, plus de vie et de dégâts |
| Karting / Auto / Moto / Quad / Bateau | race | courses avec véhicule par défaut (modifiable) |

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

## Progression (tout est modifiable en jeu : builder → bouton ✨ « Progression »)
- **XP et niveaux** : XP par partie / victoire / point, bonus de série de victoires, courbe de niveaux, titres.
- **Coins boutique** : palier d'XP répétable (ex : 5 coins tous les 2000 XP) + récompenses par niveau (argent et coins), crédités via `pickax_core` (`BoutiqueGrantCoins`). Hors-ligne, ils sont mis en attente et remis à la connexion.
- **Défis** quotidiens (3) et hebdo (2) tirés dans une liste que tu édites ; **succès** à débloquer.
- **Mini-jeu de la semaine** (gains et XP multipliés), **saisons** avec récompenses du podium, annonces des records.
- Profil joueur : `/mgprofil` ou onglet « Mon profil » du lobby.
- Tables : `minigames_players`, `minigames_settings`, `minigames_pending`.

## Interface
Même identité que les autres builders (World / Event) : barre latérale, onglets, cartes, toasts, confirmations, dock de sons (`bb-ui.js`), éditeur commun **Blip & Marker** (`BBMap` + `client/bb_map.lua`), aide « E » activable par marker, barre de progression commune (attente avant le départ) et **mode placement** (Entrée = enregistrer ta position, ← → = cible, Retour = menu).

## Props et armes
- Onglet **Props** : obstacles, abris, rampes, ballons, décor (catalogue + modèle libre, bouton **Tester**). Mode « seulement pendant la partie » ou « toujours visible » près du lobby.
- Armes : une quinzaine de marqueurs (pistolets, SMG, fusils, sniper, pompe) + armes laser ; champ libre `WEAPON_…` possible. Paintball : teinte d'arme par équipe et **éclaboussures de peinture** à l'impact (visibles par tous les joueurs de la partie).

## Pré-placement automatique
Au premier démarrage, 10 mini-jeux sont créés et activés (basket ×2, tirs au but, fléchettes, bowling, tennis, ring de boxe, paintball, laser game, sprint), une seule fois. Les terrains sont **calculés autour d'une ancre** (lieu connu de GTA V + cap) : positions **approximatives**, à retoucher dans le builder (Emplacements / Props, mode placement). `Config.PresetGames` (liste et ancres), `/mgseed` (admin) pour recréer les manquants, `Config.AutoSeed = false` pour désactiver.
