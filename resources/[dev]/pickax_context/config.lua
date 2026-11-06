Config = {}

-- Menu contextuel du joueur : affiche, en cascade, les actions de pickax_core/players/contextMenu (moi, véhicule visé, joueur visé, passant, objet, lieu…).
-- Le contenu des actions se règle dans pickax_core/players/contextMenu/config.lua ; ici seulement l'ouverture et la présentation.

Config.Command = 'moi'             -- /moi ouvre / ferme le menu
Config.Key = 'LMENU'               -- Alt gauche (modifiable par le joueur dans les paramètres FiveM) ; '' = aucune
Config.HoldToShow = true           -- true : maintenir la touche = curseur libre ; relâcher = tout se ferme ; false : un appui active / désactive le curseur
Config.HoverMs = 150               -- durée (ms) pendant laquelle le curseur doit rester sur le personnage pour ouvrir son menu
Config.GhostAlpha = 140           -- transparence du personnage pendant que son menu est ouvert (0 = invisible, 255 = normal)

-- Fonctionnement : maintiens la touche -> un curseur apparaît ; place-le sur ton personnage -> le menu « Moi » s'ouvre (et ton personnage devient
-- semi-transparent). Clique sur un véhicule, un joueur, un passant ou un objet -> le menu de cet élément. Tu peux marcher et conduire pendant ce temps.
-- /moi ouvre directement le menu « Moi » sans viser.
