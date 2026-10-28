# pickax_bourse

Bourse fictive : des titres (`Config.Stocks`) dont le prix évolue **côté serveur** (marche aléatoire avec tendance, toutes les 10 minutes, plus des actualités qui font bondir ou chuter un titre). Les joueurs achètent et vendent via `/bourse` (menus ox_lib), avec des frais de 1 %, un maximum d'actions par titre et un portefeuille persistant (plus-value affichée à la vente).

- `Config.Spots` : lieux où l'on peut passer des ordres (vide = partout).
- Les prix et les ordres sont validés uniquement par le serveur.
- Export : `exports.pickax_bourse:GetPrice('AERO')`.
- Tables créées au démarrage : `pickax_bourse_prices`, `pickax_bourse_holdings`.
