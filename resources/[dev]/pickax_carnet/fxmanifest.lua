fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_carnet'
description 'Carnet du joueur : série de connexion, objectifs du jour et de la semaine, défi de la ville (récompenses automatiques, toujours quelque chose à faire)'
version '1.0.0'

shared_script 'config.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts { 'client/main.lua' }

ui_page 'html/index.html'

files { 'html/index.html', 'html/style.css', 'html/script.js' }

server_exports { 'Report', 'Snapshot' }

dependencies { 'oxmysql', 'es_extended' }
