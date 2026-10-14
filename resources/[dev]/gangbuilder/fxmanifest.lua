fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'gangbuilder'
description 'Gang Builder ESX complet basé sur job2 : gangs, grades, garages, vestiaires, armureries, coffres, trésorerie, activités illégales, territoires (UI + oxmysql)'
version '1.0.0'

shared_scripts {
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/job2.lua',
    'server/builder.lua',
    'server/runtime.lua',
    'server/activities.lua',
    'server/territories.lua',
    'server/settings.lua',
}

client_scripts {
    'client/main.lua',
    'client/actions.lua',
    'client/activities.lua',
    'client/territories.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/bb-ui.js',
}

dependencies {
    'es_extended',
    'oxmysql',
}
