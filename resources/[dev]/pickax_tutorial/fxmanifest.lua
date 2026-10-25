fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_tutorial'
description 'Tutoriel d\'arrivée : étapes réglables (touches, téléphone, métiers, règles), affiché une seule fois à un nouveau joueur, récompense optionnelle'
version '1.0.0'

shared_scripts { '@ox_lib/init.lua', 'config.lua' }

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts { 'client/main.lua' }

ui_page 'html/index.html'

files { 'html/index.html', 'html/style.css', 'html/script.js' }

dependencies { 'oxmysql', 'ox_lib', 'es_extended' }
