fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_theme'
description 'Thème général Pickax : la couleur principale de TOUTES les interfaces se règle en une ligne dans theme.js'
version '1.0.0'

-- Pas de script : ressource de données.
--  • theme.js  : la config (couleur principale) + application automatique aux interfaces NUI
--  • theme.lua : inclus par les autres ressources ('@pickax_theme/theme.lua') pour lire la même couleur côté Lua
files { 'theme.js', 'theme.lua' }
