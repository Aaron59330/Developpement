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
