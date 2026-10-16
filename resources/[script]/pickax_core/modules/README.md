# Modules intégrés à pickax_core

Seuls les modules **sans interface NUI** sont intégrés ici (aujourd'hui : `connectui`, l'écran de connexion). Chaque module est exécuté par
`loader.lua` (côté serveur) dans son propre environnement Lua : ses variables globales restent privées, sa logique ne change pas.

Les modules avec interface (builders, HUD, compteur, menu pause, CarPlay) restent des ressources séparées dans `resources/[dev]/` :
une ressource FiveM ne peut avoir qu'une seule page NUI, et le regroupement par cadres (iframes) n'a pas fonctionné en jeu.

Ajouter un module serveur : dossier `modules/<nom>/` + une ligne dans `registry.lua`. Désactiver : `set pickax:disable_modules "connectui"`.
