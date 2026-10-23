fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_jobbuilder'
description 'Job Builder ESX complet : jobs, grades, garages, vestiaires, armureries, coffres, boss, boutiques (UI + oxmysql)'
version '1.0.0'

shared_scripts {
    'pk_theme.lua',   -- couleur principale commune (pickax_theme/theme.js)
    'config.lua',
}

server_scripts {
    'server/notify.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/builder.lua',
    'server/dlogs.lua',
    'server/runtime.lua',
    'server/property.lua',
    'server/settings.lua',
    'server/dealer.lua',
    'server/gov.lua',
    'server/missions.lua',
    'server/kitchen.lua',
    'server/tablet.lua',
    'server/tuning.lua',
    'server/death.lua',
    'server/emstablet.lua',
    'server/bank.lua',
    'server/announce.lua',
    'server/phone.lua',
    'server/compat.lua',
}

client_scripts {
    'pk_sound.lua',
    'client/notify.lua',
    'client/bb_map.lua',
    'client/main.lua',
    'client/actions.lua',
    'client/property.lua',
    'client/dealer.lua',
    'client/gov.lua',
    'client/missions.lua',
    'client/kitchen.lua',
    'client/tablet.lua',
    'client/tuning.lua',
    'client/death.lua',
    'client/emstablet.lua',
    'client/bank.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/atelier.css',
    'html/atelier.js',
    'html/script.js',
    'html/dlogs-ui.js',
    'html/bb-ui.js',
    'html/map/**/*',
}

dependencies {
    'es_extended',
    'oxmysql',
}
