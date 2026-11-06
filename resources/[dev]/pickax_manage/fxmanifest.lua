fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_manage'
description 'Gestion du serveur (menu staff) : vue d\'ensemble en direct, catégories de réglages, journal de session'
version '0.1.0'

shared_scripts { '@pickax_theme/theme.lua', 'config.lua' }
server_script 'server/main.lua'
client_script 'client/main.lua'

ui_page 'html/index.html'
files { 'html/index.html', 'html/fonts.css', 'html/style.css', 'html/script.js', 'html/fonts/*' }

dependencies { 'es_extended', 'pickax_theme' }
