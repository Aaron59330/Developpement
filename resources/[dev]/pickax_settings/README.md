# pickax_settings

Réglages du serveur modifiables depuis le panel web (**Réglages du serveur**). Démarré avec `ensure [dev]`.

## Principes (optimisation)
- **Aucun changement de comportement tant qu'un réglage n'est pas modifié** : les valeurs d'origine de chaque ressource restent.
- **Aucune boucle par image** : chaque ressource lit les valeurs une fois puis les met en cache ; un changement déclenche un événement unique (`pickax_settings:changed` : valeurs, surcharges).
- Les fonctions optionnelles (annonces, redémarrages, maintenance) ne consomment rien si elles sont désactivées.
- Les valeurs sont validées (type, min/max, liste d'options) côté panel ET côté serveur.

## Réglages fournis (`config.lua`)
Serveur : mode maintenance, annonces automatiques, redémarrages programmés. Interface : position des notifications, boussole, HUD (faim/soif, vie, armure, cartes du haut). Voix : distances. Économie : bonus de gains le week-end.

## Ajouter un réglage
1. Ajoute une ligne dans `Settings.Schema` (`config.lua`) : le panel affiche le formulaire tout seul.
2. Dans la ressource concernée :
```lua
AddEventHandler('pickax_settings:changed', function(all, overrides)
    if overrides.mon_reglage ~= nil then MaConfig.valeur = all.mon_reglage end   -- n'agit que si le réglage a été modifié
end)
```
(côté serveur ou client). Valeur ponctuelle : `exports.pickax_settings:Get('mon_reglage')`.


## Catégories de réglages (panel web → Réglages du serveur)
| Catégorie | Ce qu'on règle | Appliqué par |
|---|---|---|
| Serveur | maintenance, annonces automatiques, redémarrages programmés | pickax_settings |
| Monde & PNJ | PNJ et circulation (3 densités), police PNJ, niveau de recherche, bateaux / trains / camions-poubelles | pickax_core (`utils/npc`) et pickax_settings |
| Météo & heure | météo fixe ou dynamique, panne de courant, heure figée | pickax_core (`system/vsync`) |
| Joueurs & combat | tir ami, dégâts d'armes et de mêlée, coups critiques, tir en véhicule, régénération de la vie, endurance, caméra d'inactivité | pickax_settings (client) |
| Nouveaux joueurs | message de bienvenue, argent bonus à la création du personnage | pickax_settings (serveur) |
| Interface | notifications, boussole, HUD, cartes d'information, viseur | pickax_notify, pickax_compass, pickax_hud1, pickax_hud2 |
| Voix | distances (chuchoter / normal / crier) | pma-voice |
| Économie | bonus de gains du week-end | pickax_economy |
| Carnet | activer, multiplicateur des récompenses | pickax_carnet |
| Gangs | territoires (capture, protection, revenus, racket), affrontements, guerre de zone déclarée, zones de tribut, missions colis, guerres entre gangs | pickax_gangbuilder (`panelsettings.lua`) |
| Drogues & labos | laboratoire interactif (qualité, rendement, anti-triche), rendu 3D et caméra du labo, intoxication, vente de drogue aux PNJ | pickax_jobbuilder, pickax_illegalbuilder (`panelsettings.lua`) |
| Discord | statut affiché sur le profil Discord | pickax_core (`utils/discord`) |
| Performance | mode performance des interfaces | pickax_theme, pickax_compass, pickax_hud1 |

Un réglage ne change rien tant qu'il n'est pas modifié : les valeurs d'origine de la base restent en vigueur. Remis à sa valeur par défaut, l'effet précédent est annulé.
Chaque réglage a une `section` (sous-titre dans le panel). Pour en ajouter un : une ligne dans `config.lua`, puis un consommateur qui écoute `pickax_settings:changed` (ou lit `exports.pickax_settings:Get`).
Tests hors jeu : `lua5.4 tools/tests/settings_test.lua` et `lua5.4 tools/tests/vsync_settings_test.lua`.

Les builders (gangs, jobs, illégal) appliquent leurs réglages via un fichier `panelsettings.lua` (liste `clé du réglage → chemin dans le config.lua`) : ajouter un réglage = une ligne dans `Settings.Schema` + une ligne dans ce fichier. Test : `ROOT=. lua tools/tests/panelsettings_test.lua` (vérifie aussi que chaque défaut du schéma est égal à la valeur du config.lua).

## Activité du serveur et alertes Discord
- **Activité** : les ressources comptent leurs événements avec `exports.pickax_settings:Count('clé', n, 'Libellé')` (ventes de rue et chez les dealers, saisies, fabrications et accidents de labo, événements de gangs…). Les compteurs du jour et des 7 derniers jours (14 jours conservés) sont envoyés au panel avec chaque synchronisation : **panel web → Statistiques → Activité du serveur**.
- **Discord** (panel → *Réglages du serveur → Discord → Alertes Discord*) : colle l'URL d'un webhook, choisis les catégories (gangs : guerres, territoires, tributs, raids de QG, saisons · police : saisies · laboratoires : accidents graves) et, si tu veux, un **résumé quotidien** à l'heure de ton choix. `exports.pickax_settings:Discord('gangs', 'Titre', 'Texte', couleur)` pour tes propres scripts.
- L'adresse du webhook est un réglage **secret** (`secret = true` dans `Settings.Schema`) : elle n'est **jamais envoyée aux joueurs** (seulement conservée côté serveur). Seules les URL `https://discord.com/api/webhooks/…` sont acceptées ; envoi limité à un message toutes les 1,3 s.
- Tests : `ROOT=. lua tools/tests/activity_test.lua` (13 vérifications) ; panel : `node tools/selftest2.js`.

## Mode de jeu : facile / difficile
Un seul réglage (panel → *Réglages du serveur* → carte **Mode de jeu**, ou `game_mode`) règle la difficulté de toute la base.
- **Difficile** (défaut, comportement actuel) : systèmes complets : table de traitement interactive avec accidents, catalyseur et niveaux de laborantin, intoxication, tablettes obligatoires, pureté, réputation et quartiers pour la vente de rue, raids de QG, guerres de zone, affrontements, racket.
- **Facile** : fabrication au labo avec la simple barre de progression, ni accident ni intoxication, aucune tablette exigée, vente de rue plus facile (85 % d'acceptation, moins d'alertes), captures de territoires rapides (60 s, sans défenseurs requis), ni raids, ni guerres de zone, ni affrontements.
- Principe : un réglage peut avoir `easy = valeur` dans `Settings.Schema` (20 réglages aujourd'hui). Valeur active = **réglage modifié par le client** → sinon valeur `easy` si le mode est facile → sinon valeur par défaut. Un réglage modifié à la main passe donc toujours avant le mode ; repasser en difficile restaure les valeurs d'origine. La carte du panel liste exactement ce que change le mode facile.
- Ajouter un système au mode : `easy = …` sur sa ligne du schéma + la ligne correspondante dans le `panelsettings.lua` de la ressource. Test : `ROOT=. lua tools/tests/modes_test.lua` (82 vérifications : types, bornes, application réelle sur les configs, restauration).
