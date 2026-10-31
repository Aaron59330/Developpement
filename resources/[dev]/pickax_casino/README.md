# pickax_casino

Casino complet : **caisse** (achat / rachat de jetons), **machines à sous**, **blackjack**, **roulette européenne**.

## Mise en place
1. La ressource fait partie de `[dev]` (déjà lancée par `ensure [dev]`) et dépend de `pickax_worldbuilder`. Les tables SQL se créent seules.
2. Ouvre le **World Builder** (`/worldbuilder`) → **Nouveau module → Casinos** → modèle « Casino complet » (1 caisse, 3 machines, 2 blackjack, 2 roulettes) ou « Caisse seule ».
3. Onglet **Emplacements** : place chaque poste (position, PNJ, blip, repère au sol) et choisis sa gamme (Bronze / Argent / Or, Classique / VIP).
4. Onglet **Jetons & limites** : compte utilisé, prix d'achat, rachat, limites. Active le module.
5. `/casinortp` affiche le taux de retour théorique des machines, `/casinostats` le bénéfice de la maison (staff).

## Règles
- 1 jeton = `Config.ChipBuyPrice` $ ; rachat à `Config.ChipSellPrice` (0.95 = la caisse garde 5 %).
- Machines : 3 rouleaux, 5 lignes (3 horizontales + 2 diagonales), mise répartie sur les lignes, retour ≈ 95 %.
- Blackjack : sabot de 6 jeux, blackjack 3 pour 2, le croupier tire jusqu'à 17, doubler sur les 2 premières cartes.
- Roulette : un seul zéro, plein 35 pour 1, chances simples 1 pour 1, douzaines et colonnes 2 pour 1 (retour 97,3 %).

## Sécurité
Tirages, cartes et gains sont calculés côté serveur (`server/games.lua`). Le client n'envoie que sa mise. Vérification de la distance au poste, une action à la fois par joueur, débit atomique en base.

## Réglages
Règles des jeux (rouleaux, gains, limites de mise par gamme) : `config.lua`, modifiable depuis le panel (*Gestion Base → Tous les réglages des scripts*). Prix des jetons et emplacements : World Builder. Les valeurs de `config.lua` servent de défaut.
