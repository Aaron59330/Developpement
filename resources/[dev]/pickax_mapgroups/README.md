# pickax_mapgroups

Plusieurs lieux portant **exactement le même nom** (deux garages, trois banques…) apparaissent comme **un seul blip** sur la carte, nommé « Garage (2) », posé sur le lieu le plus proche de toi.

Pour choisir un lieu : ouvre la carte, sélectionne le blip et « Définir un point de passage » dessus : une liste des lieux (avec la distance et la rue) s'ouvre ; ton choix déplace le point de passage sur ce lieu.

- Les builders (jobs, gangs, boutiques, monde, drogues) regroupent leurs blips automatiquement (`client/bb_map.lua`, fonctions `BB.BlipsBegin` / `BB.BlipsEnd`).
- Sans cette ressource, le blip regroupé reste affiché (« Garage (2) ») mais sans la liste.
- Un seul nom différent (même d'une majuscule) suffit à garder deux blips séparés.
- Dépendance : `ox_lib`. À démarrer avec les builders (déjà couvert par `ensure [dev]`).
