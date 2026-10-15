# Modules intégrés à pickax_core

Les anciennes ressources `pickax_builderhub`, `pickax_jobbuilder`, `pickax_gangbuilder`, `pickax_shopbuilder`, `pickax_worldbuilder`,
`pickax_hud1`, `pickax_hud2`, `pickax_speedometer`, `pickax_pause` et `pickax_connectui` vivent maintenant ici, **avec leurs scripts d'origine**.
Il n'y a plus qu'un seul `ensure pickax_core` / `restart pickax_core`.

## Comment ça marche
- `registry.lua` : liste des modules et de leurs fichiers, dans l'ordre d'origine des anciens `fxmanifest.lua`.
- `loader.lua` : exécute chaque module dans **son propre environnement Lua** (Config, GB, JB, ESX… restent privés, rien ne se mélange avec le core).
  Trois familles d'appels sont adaptées pour cohabiter dans une seule ressource :
  `SendNUIMessage` / `RegisterNUICallback` / `SetNuiFocus` (étiquetés avec le nom du module) et `LoadResourceFile` / `SaveResourceFile` (chemins du module).
- `_hub/` : FiveM n'autorise qu'une page NUI par ressource. Le hub (`index.html` + `hub.js`) affiche chaque interface dans un cadre transparent,
  redirige les messages du jeu vers le bon cadre et donne le focus clavier / souris au module actif. `shim.js` (chargé en premier par chaque page)
  préfixe les callbacks NUI (`jobbuilder:rpc`) et fixe `GetParentResourceName()`.

## Ajouter / retirer un module
1. Copie ses fichiers dans `modules/<nom>/` (sans `fxmanifest.lua`) et ajoute une entrée dans `registry.lua`.
2. Si le module a une interface : ajoute `<script src="…/_hub/shim.js"></script>` en tête de sa page, une ligne dans `UIS` de `_hub/hub.js`,
   et ses fichiers dans `files` du `fxmanifest.lua` du core (les `.lua` lus côté client y sont listés explicitement : ne jamais y mettre de script serveur).
3. Désactiver un module sans le supprimer : `setr pickax:disable_modules "gangbuilder,hud2"` dans `server.cfg`.

## Références aux anciens noms
- `exports.pickax_jobbuilder:…`, `exports.pickax_hud1:…`, etc. → `exports.pickax_core:…` (mêmes noms d'export).
- `GetResourceState('pickax_<module>')` → `GetResourceState('pickax_core')`.
- Les évènements (`jobbuilder:…`), commandes (`/jobbuilder`), tables SQL et permissions n'ont pas changé.
- Les préférences client stockées en KVP (ex. réglages du HUD) repartent de zéro : le KVP est lié au nom de la ressource.
