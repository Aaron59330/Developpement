fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_basetools'
description 'Outils de la base : audit de santé (ressources, SQL, items, données), sauvegardes / restauration de la configuration des builders, nouveautés et guide'
version '1.0.0'

shared_scripts { '@ox_lib/init.lua', 'config.lua', 'changelog.lua' }

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts { 'client/main.lua' }

ui_page 'html/index.html'

files { 'html/index.html', 'html/style.css', 'html/script.js' }

dependencies { 'oxmysql', 'ox_lib', 'es_extended' }
