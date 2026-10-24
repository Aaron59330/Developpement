fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_jobbuilder'
description 'Job Builder ESX complet : jobs, grades, garages, vestiaires, armureries, coffres, boss, boutiques (UI + oxmysql)'
version '1.0.0'

shared_scripts {
    'pk_theme.lua',   -- couleur principale commune (pickax_theme/theme.js)
    'config.lua',
    'config_active.lua',
}

server_scripts {
    'server/notify.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/builder.lua',
    'server/dlogs.lua',
    'server/duty.lua',
    'server/runtime.lua',
    'server/props.lua',
    'server/property.lua',
    'server/furniture.lua',
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
    'server/act_core.lua',
    'server/act_garbage.lua',
    'server/act_towing.lua',
    'server/act_carwash.lua',
    'server/act_trucker.lua',
    'server/act_farmer.lua',
    'server/act_firefighter.lua',
    'server/act_train.lua',
    'server/compat.lua',
}

client_scripts {
    'pk_sound.lua',
    'client/notify.lua',
    'client/bb_map.lua',
    'client/main.lua',
    'client/actions.lua',
    'client/property.lua',
    'client/furniture.lua',
    'client/dealer.lua',
    'client/gov.lua',
    'client/missions.lua',
    'client/kitchen.lua',
    'client/tablet.lua',
    'client/tuning.lua',
    'client/death.lua',
    'client/emstablet.lua',
    'client/bank.lua',
    'client/vehctl.lua',
    'client/props.lua',
    'client/act_core.lua',
    'client/act_garbage.lua',
    'client/act_towing.lua',
    'client/act_carwash.lua',
    'client/act_trucker.lua',
    'client/act_farmer.lua',
    'client/act_firefighter.lua',
    'client/act_train.lua',
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
