fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_gangbuilder'
description 'Gang Builder ESX complet basé sur job2 : gangs, grades, garages, vestiaires, armureries, coffres, trésorerie, activités illégales, territoires (UI + oxmysql)'
version '1.0.0'

shared_scripts {
    'pk_theme.lua',   -- couleur principale commune (pickax_theme/theme.js)
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/job2.lua',
    'server/builder.lua',
    'server/dlogs.lua',
    'server/runtime.lua',
    'server/activities.lua',
    'server/territories.lua',
    'server/conflicts.lua',
    'server/objectives.lua',
    'server/tablet.lua',
    'server/settings.lua',
}

client_scripts {
    'pk_sound.lua',
    'client/bb_map.lua',
    'client/main.lua',
    'client/actions.lua',
    'client/activities.lua',
    'client/territories.lua',
    'client/conflicts.lua',
    'client/objectives.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/dlogs-ui.js',
    'html/tablet.js',
    'html/tablet.css',
    'html/bb-ui.js',
}

dependencies {
    'es_extended',
    'oxmysql',
}
