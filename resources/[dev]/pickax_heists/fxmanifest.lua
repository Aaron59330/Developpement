fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_heists'
description 'Braquages « GTA Online » : Doomsday Acte II — Le problème Bogdan (préparatifs, mises en place, finale à deux équipes)'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'pk_theme.lua',
    'config.lua',
    'missions/bogdan.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
    'client/runner.lua',
}

ui_page 'html/index.html'

files { 'html/index.html', 'html/style.css', 'html/script.js' }

dependencies { 'es_extended', 'oxmysql', 'ox_lib' }
