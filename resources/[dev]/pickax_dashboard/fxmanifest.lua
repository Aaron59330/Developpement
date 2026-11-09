fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_dashboard'
description 'Tableau de bord du joueur : profil, quêtes, métiers, factures, véhicules, propriétés, animaux, boutique et paramètres'
version '1.0.0'

shared_script 'config.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_script 'client/main.lua'

ui_page 'html/index.html'
files { 'html/index.html', 'html/fonts.css', 'html/style.css', 'html/script.js', 'html/fonts/*' }

dependencies { 'es_extended', 'oxmysql' }
