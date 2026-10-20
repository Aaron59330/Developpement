# Systèmes illégaux du serveur (gangs, marché noir, drogues, braquages, territoires)

Tout se crée **en jeu**, sans redémarrer, depuis des « builders » réservés aux groupes ESX `_dev` (parfois `admin` / `superadmin`).
Point d'entrée commun : `/builders` (hub) — chaque builder a aussi sa commande.

| Besoin | Builder / script | Commande |
|---|---|---|
| Créer un gang (grades, coffre, garage, territoires, activités illégales) | `pickax_gangbuilder` | `/gangbuilder` (création), `/gangmenu` ou **F7** (menu du gang), `/gangtablet` (tablette) |
| Filières de drogue, blanchiment, braquages de commerces/banques | `pickax_worldbuilder` | `/worldbuilder` |
| Marché noir public (PNJ qui vend des objets illégaux) | `pickax_shopbuilder` (modèle « Marché noir ») | `/shopbuilder` |
| Événements illégaux (Brinks, largage, livraison illégale…) | `pickax_eventbuilder` | `/eventbuilder` |
| Dialogue du PNJ avant d'ouvrir un service | `pickax_dialog` | (automatique) |

---
## 1. Gangs (`pickax_gangbuilder`)
Un gang = une ligne `jobs2` + grades `job2_grades` ; les membres sont rattachés par `users.job2` / `users.job2_grade` (aucune écriture dans `jobs`).
**Créer un gang** : `/gangbuilder` → nouveau gang → modèle (Gang de rue, Mafia, Club de motards, Cartel, Personnalisé) → nom (20 caractères max), couleur, blip, grades et salaires → placer les points → activer.
**Points du gang** (chacun réservé à *son* gang, grade minimum vérifié côté serveur) : Garage (voitures/motos/aéronefs/bateaux), Vestiaire, Armurerie, Coffre (ox_inventory), Gestion du gang (boss), Marché noir du gang (public ou privé), Récolte, Traitement, Point de vente, Blanchiment.
**Trésorerie** : argent propre + argent sale du gang, dépôt/retrait selon grade, plafonds, journal.
**Gestion boss** : recruter (joueur le plus proche), promouvoir, exclure, salaires.
**Menu gang (F7)** : fiche du gang, menottes / escorte / fouille, tablette, quitter le gang.
**Tablette (`/gangtablet`)** : tableau de bord, territoires, quêtes journalières (3) et hebdomadaires (2) avec récompenses en argent sale + réputation, guerres entre gangs, classement, actualités.
**Guerres** : un gang du bureau en défie un autre (10/15/25 kills, 20/40/60 min, mise jusqu'à 50 000 $ sale) ; le gagnant empoche les mises + réputation.
**Réglages** : `/gangbuilder` → Paramètres (tout est modifiable en direct ; « Réinitialiser cette section » = valeurs de `config.lua`).
**Diagnostic** : `/gbcheck` (console serveur), `/gbdebug`, `/gbreset`, `/gbwho`.
Exports : `GetGangMoney`, `AddGangMoney`, `RemoveGangMoney`, `AddGangRep`, `GetPlayerGang`, `SetPlayerGang`, `GetGangMembers`.

## 2. Territoires (dans le gangbuilder)
- Créés dans le builder, onglet *Territoires* : zone circulaire (rayon 40 m par défaut), blip coloré au propriétaire, zone dessinée au sol.
- **Capture** : un seul gang présent dans la zone, 120 s par défaut, au moins `MinMembers` membres ; la présence du propriétaire bloque la capture. HUD de progression.
- **Protection** : 30 min après une capture. **Revenu** : 500 $ sale toutes les 15 min dans la trésorerie du gang propriétaire.
- Chaque zone peut surcharger durée / membres / revenu / protection.
- **Affrontements** : un gang qui fait une activité illégale (récolte, traitement, vente) sur le territoire d'un autre déclenche un conflit de 300 s : la zone clignote en rouge, chaque kill entre les deux gangs dans la zone = 1 point. Le gagnant gagne de la réputation ; l'intrus gagnant capture la zone si elle n'est pas protégée. Test staff : `/gbconflict <id territoire> <gang>`.
- **Missions colis** : un colis apparaît dans une zone (toutes les 45 min si au moins 2 gangs sont connectés, ou `/gbobjective [zone]`, arrêt `/gbobjstop`). Le premier gang qui le prend doit tenir la zone 180 s, puis le livrer à **son** coffre de gang ; si le porteur meurt le colis tombe. Récompense en argent sale + réputation.

## 3. Drogues et blanchiment (`pickax_worldbuilder`, module « Drogues & labos »)
Modèles prêts : Cannabis, Cocaïne, Méthamphétamine, Opium/Héroïne, Blanchiment d'argent, Filière personnalisée.
Points d'une filière : **Récolte** (objet, quantité, durée, outil requis, épuisement/repousse), **Laboratoire** (recettes multi-ingrédients, lots, chance de raté), **Porte/intérieur** (téléportation entrée/sortie), **Dealer** (vente, prix aléatoires, limite horaire, paiement en argent sale), **Blanchiment** (taux, min/max, limite horaire).
Options sur chaque point : accès par métier/gang/objet clé, policiers requis, chance d'alerter la police (`Config.AlertHook` pour brancher ps-dispatch/cd_dispatch).
Les items des modèles (`weed`, `weed_pooch`, `coke_pooch`…) doivent exister dans ox_inventory (ceux qui n'existent pas sont signalés en rouge).

## 4. Braquages (`pickax_worldbuilder`, module « Braquages »)
Modèles : Supérette 24/7, Banque (coffre, thermite requise), Bijouterie, Braquage personnalisé.
Déclenchement : viser le vendeur *ou* touche E ; caisses, coffres, coffre-fort, butin ; mini-jeux (ox_lib), outils requis, policiers requis, cooldown persistant, alerte police, gardes armés, mode coopératif, butin en argent sale/propre + objets avec probabilités.

## 5. Marché noir public (`pickax_shopbuilder`)
Modèle « Marché noir » : PNJ (g_m_m_chigoon_01), paiement uniquement en argent sale, produits de départ : crochet, cran d'arrêt. Ajoute tes produits (armes, munitions, outils…) avec prix, stock, réassort, licence, métiers autorisés. Peut avoir plusieurs emplacements. Le dialogue du PNJ (« Psst… approche ») s'active/désactive par boutique.
Différence avec le marché noir de **gang** : celui du gang est un point du gangbuilder (réservé au gang ou public) ; celui-ci est une boutique libre.

## 6. Événements illégaux (`pickax_eventbuilder`)
Fourgon blindé (Brinks : gardes, perçage, sacs de billets), Largage (caisses, mercenaires), Commerce à menacer, Épave, Livraison illégale, Contrôle de zone. Déclenchement automatique, manuel ou par interaction ; policiers requis, récompenses, alertes. `eventstop` (console) arrête tout.

## 7. Autres éléments dans le core (`pickax_core`)
GoFast (mission de livraison de véhicule), vente de drogue aux passants via le menu contextuel (weed/coke), armes permanentes, prise d'otage (`/otage`, `/porter`), menottes/fouille, prison (jail).

## Ordre conseillé pour monter un serveur illégal
1. Créer les filières de drogue (worldbuilder) + un blanchiment.
2. Créer 2–3 gangs (gangbuilder) avec leurs points (coffre obligatoire pour les missions colis).
3. Poser 4–6 territoires.
4. Créer un marché noir (shopbuilder) et quelques braquages.
5. Régler `Config.PoliceJobs` et `Config.AlertHook` (worldbuilder) pour que les alertes arrivent à ton dispatch.
