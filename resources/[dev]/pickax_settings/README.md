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
| Discord | statut affiché sur le profil Discord | pickax_core (`utils/discord`) |
| Performance | mode performance des interfaces | pickax_theme, pickax_compass, pickax_hud1 |

Un réglage ne change rien tant qu'il n'est pas modifié : les valeurs d'origine de la base restent en vigueur. Remis à sa valeur par défaut, l'effet précédent est annulé.
Chaque réglage a une `section` (sous-titre dans le panel). Pour en ajouter un : une ligne dans `config.lua`, puis un consommateur qui écoute `pickax_settings:changed` (ou lit `exports.pickax_settings:Get`).
Tests hors jeu : `lua5.4 tools/tests/settings_test.lua` et `lua5.4 tools/tests/vsync_settings_test.lua`.
