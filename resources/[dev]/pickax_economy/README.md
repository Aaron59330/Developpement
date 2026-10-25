# pickax_economy — économie dynamique

Les prix suivent l'offre et la demande : les **ventes** des joueurs font baisser le prix d'un marché, les **achats** le font monter ; tout revient à la normale tout seul (10 % de la pression disparaît toutes les 5 min). Des événements aléatoires de **pénurie / surplus** (±10 à 25 %, 2 à 6 h) font bouger les marchés actifs.

Brancher un marché depuis n'importe quel script (serveur) :
```lua
local price = exports.pickax_economy:Price('crop:wheat', 14)          -- prix de base × multiplicateur
exports.pickax_economy:Record('crop:wheat', 12, 'sell')              -- le joueur vend 12 → le prix baisse
exports.pickax_economy:Record('shop:alimentation', 3, 'buy')         -- le joueur achète 3 → le prix monte
```
Déjà branchés : **boutiques du Shop Builder** (clé `shop:<catégorie>`, ±30 % max, achats) et **récoltes du fermier** (`crop:<culture>`, ±40 %, ventes au marché).
Réglages : `config.lua` (bornes par type de marché, vitesse de retour, événements). Supervision, événements manuels et remise à zéro : `/aerotools` → onglet **Économie**.
Si la ressource est arrêtée, tous les prix reviennent à leur valeur normale. Table créée automatiquement : `pickax_economy`.
