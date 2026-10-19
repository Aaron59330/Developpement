fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_pause'
description 'Menu pause Pickax : remplace la carte GTA à ÉCHAP par un menu stylé (joueur, serveur, raccourcis)'
version '1.0.0'

shared_scripts { '@pickax_theme/theme.lua', 'config.lua' }
server_script 'server.lua'
client_script 'client.lua'

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js', 'html/logo.png' }

dependencies { 'es_extended' }
