# pickax_creator

Écrans plein format dans le style doré (verre sombre, lecteur de musique) :

| Écran | Ouvert par | Remplace |
|---|---|---|
| Enregistrement du Personnage (identité) | `esx_identity` | formulaire carte d'identité |
| Apparence / Coiffure (skin) | `pickax_core/esx/skinchanger` (`SkinChanger()`) | menu RageUI de création |
| Point d'apparition (carte) | `esx_identity` (`Config.Destinations`) | menu « Destination » |
| Message de bienvenue | `esx_identity`, après l'arrivée | – |
| Gestionnaire d'animations | `pickax_core/players/menuemote` (touche K / `/emoteui`) | menu RageUI des emotes |

Si `pickax_creator` n'est pas démarré, chaque système garde son ancien menu.

## À fournir
- `html/music/*.mp3` + déclaration dans `config.lua` (`Config.Music.Tracks`) pour le lecteur.
- `html/map.png` : image de la carte de Los Santos (réglage des bornes dans `Config.Map`).
- `html/places/<nom>.webp` : photos des points d'apparition (champ `image` dans `Config.Destinations.Spots` d'esx_identity).
- `Config.Scene.Studio` : lieu de la scène de création (un vestiaire / boutique) ; vide = là où se trouve le joueur.

Ordre de démarrage : `ensure pickax_creator` avant `esx_identity` et `pickax_core`.
