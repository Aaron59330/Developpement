Config = {}

-- Menu contextuel du joueur : affiche, en cascade, les actions de pickax_core/players/contextMenu (moi, véhicule visé, joueur visé, passant, objet, lieu…).
-- Le contenu des actions se règle dans pickax_core/players/contextMenu/config.lua ; ici seulement l'ouverture et la présentation.

Config.Command = 'moi'             -- /moi ouvre / ferme le menu
Config.Key = 'LMENU'               -- Alt gauche (modifiable par le joueur dans les paramètres FiveM) ; '' = aucune
Config.HoldToShow = true           -- true : le menu reste affiché tant que la touche est maintenue (relâcher = fermer) ; false : appui = ouvrir / fermer
Config.OffsetPx = 70               -- décalage du menu à droite du personnage (pixels)
