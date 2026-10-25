# pickax_auction — hôtel des ventes (enchères entre joueurs)

`/encheres` (ou une touche E devant un lieu de `Config.Spots`).

- **Vendre** des objets ox_inventory ou des véhicules rangés au garage : prix de départ, achat immédiat optionnel, durée 1 / 6 / 24 / 72 h. Frais de mise en vente (2 %, min. 25 $) et taxe à la vente (5 %) réglables dans `config.lua`.
- **Enchérir** en liquide ou par banque : l'argent est retiré tout de suite et **rendu automatiquement** (même hors ligne) si on est surenchéri. Une enchère dans les 2 dernières minutes prolonge la vente.
- **Mise en dépôt** : l'objet quitte l'inventaire, le véhicule passe au propriétaire `auction:<id>` (invisible dans le garage). À la fin : le gagnant reçoit l'objet dans **Réclamations** (ou le véhicule dans son garage), le vendeur est payé sur sa banque ; sans enchère, tout revient au vendeur. Annulable tant qu'aucune enchère n'est placée.
- Protections : une seule clôture possible par enchère, comparaison de l'enchère précédente côté SQL (pas de double gagnant), limite d'enchères actives par joueur, armes / argent / téléphone / papiers interdits par défaut.
- Tables créées automatiquement : `pickax_auctions`, `pickax_auction_claims`. Webhook Discord optionnel (`Config.Webhook`).
