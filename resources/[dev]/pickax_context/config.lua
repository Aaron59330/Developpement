Config = {}

-- Menu contextuel du joueur : affiche, en cascade, les actions de pickax_core/players/contextMenu (moi, véhicule visé, joueur visé, passant, objet, lieu…).
-- Le contenu des actions se règle dans pickax_core/players/contextMenu/config.lua ; ici seulement l'ouverture et la présentation.

Config.Command = 'moi'             -- /moi ouvre / ferme le menu
Config.Key = 'LMENU'               -- Alt gauche (modifiable par le joueur dans les paramètres FiveM) ; '' = aucune
Config.HoldToShow = true           -- true : maintenir la touche = curseur libre ; relâcher = tout se ferme ; false : un appui active / désactive le curseur
Config.HoldControl = 19           -- numéro de la touche maintenue pour détecter son relâchement (19 = Alt gauche). Si tu changes Config.Key, mets ici le numéro de la nouvelle touche, ou nil
Config.GhostAlpha = 140          -- transparence du personnage pendant que son menu est ouvert (0 = invisible, 255 = normal)

-- Fonctionnement : maintiens la touche -> un curseur apparaît ; clic gauche sur ton personnage -> le menu « Moi » s'ouvre (et ton personnage devient
-- semi-transparent). Clic gauche sur un véhicule, un joueur, un passant ou un objet -> le menu de cet élément. Relâcher la touche ferme tout.
-- Tu peux marcher et conduire pendant ce temps.
-- /moi ouvre directement le menu « Moi » sans viser.
