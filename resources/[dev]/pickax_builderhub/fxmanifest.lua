fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_builderhub'
description 'Panel central qui regroupe tous les builders (jobs, gangs, boutiques, monde) : accès rapide, état et statistiques'
version '1.0.0'

shared_scripts { 'config.lua' }

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

client_scripts {
    'pk_sound.lua', 'client.lua' }

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/bb-ui.js',
}

dependencies { 'es_extended', 'oxmysql' }
