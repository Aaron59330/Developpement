# pickax_casino

Casino complet : **caisse** (achat / rachat de jetons), **machines à sous**, **blackjack**, **roulette européenne**.

## Mise en place
1. Démarre la ressource (elle fait partie de `[dev]`, déjà lancée par `ensure [dev]`). Les tables SQL se créent seules.
2. Place les postes en jeu (staff, là où tu te tiens) :
   - `/casinoadd cashier`
   - `/casinoadd slots bronze|silver|gold`
   - `/casinoadd blackjack classic|vip`
   - `/casinoadd roulette classic|vip`
3. `/casinolist` liste les postes, `/casinodel <numéro>` en supprime un.
4. `/casinortp` affiche le taux de retour théorique des machines, `/casinostats` le bénéfice de la maison.

## Règles
- 1 jeton = `Config.ChipBuyPrice` $ ; rachat à `Config.ChipSellPrice` (0.95 = la caisse garde 5 %).
- Machines : 3 rouleaux, 5 lignes (3 horizontales + 2 diagonales), mise répartie sur les lignes, retour ≈ 95 %.
- Blackjack : sabot de 6 jeux, blackjack 3 pour 2, le croupier tire jusqu'à 17, doubler sur les 2 premières cartes.
- Roulette : un seul zéro, plein 35 pour 1, chances simples 1 pour 1, douzaines et colonnes 2 pour 1 (retour 97,3 %).

## Sécurité
Tirages, cartes et gains sont calculés côté serveur (`server/games.lua`). Le client n'envoie que sa mise. Vérification de la distance au poste, une action à la fois par joueur, débit atomique en base.

## Réglages
Tout est dans `config.lua` (prix, limites, rouleaux, gains, tables) et modifiable depuis le panel : *Gestion Base → Tous les réglages des scripts*.
