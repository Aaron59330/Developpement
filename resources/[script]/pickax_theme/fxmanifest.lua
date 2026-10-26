fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_theme'
description 'Thème général Pickax : couleur, nom et logo communs à toutes les interfaces (réglés dans pickax_core/config.lua)'
version '1.0.0'

-- Pas de script : ressource de données.
--  • theme.js  : valeurs de secours + application automatique aux interfaces NUI (couleur, nom, logo)
--  • logo/     : logo du serveur (logo/logo.png par défaut, remplaçable)
--  • theme.lua : inclus par les autres ressources ('@pickax_theme/theme.lua') pour lire la même couleur côté Lua
files { 'theme.js', 'theme.lua', 'theme_live.json', 'hx.css', 'logo/*' }

-- [AERO] protection de la base : cette ressource ne démarre pas sans pickax_guard (licence valide)
dependency 'pickax_guard'
