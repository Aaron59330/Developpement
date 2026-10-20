fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_worldbuilder'
description 'World Builder ESX : crée en jeu des garages, fourrières, locations de véhicules, stations essence, drogues (récolte / laboratoires / traitement / vente / blanchiment) et braquages (supérettes, banques, bijouteries...) — UI + oxmysql'
version '1.0.0'

shared_scripts {
    'pk_theme.lua',   -- couleur principale commune (pickax_theme/theme.js)
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/builder.lua',
    'server/garage.lua',
    'server/rental.lua',
    'server/bank.lua',
    'server/driving.lua',
    'server/fuel.lua',
    'server/carwash.lua',
    'server/locksmith.lua',
    'server/jobcenter.lua',
    'server/drugs.lua',
    'server/robbery.lua',
    'server/doorlock.lua',
    'server/carlot.lua',
    'server/chase.lua',
    'server/pvp.lua',
}

client_scripts {
    'pk_sound.lua',
    'client/bb_map.lua',
    'client/main.lua',
    'client/garage.lua',
    'client/rental.lua',
    'client/bank.lua',
    'client/driving.lua',
    'client/fuel.lua',
    'client/carwash.lua',
    'client/locksmith.lua',
    'client/jobcenter.lua',
    'client/drugs.lua',
    'client/robbery.lua',
    'client/doorlock.lua',
    'client/carlot.lua',
    'client/chase.lua',
    'client/pvp.lua',
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
