fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_connectui'
description 'Écran de connexion : carte d\'accueil (joueurs en connexion, temps d\'attente, boutons Jouer / Discord / Boutique). Textes et liens dans config.lua.'
version '1.0.0'

shared_scripts { '@pickax_theme/theme.lua', 'config.lua' }
server_script 'server.lua'

dependency 'pickax_theme'
