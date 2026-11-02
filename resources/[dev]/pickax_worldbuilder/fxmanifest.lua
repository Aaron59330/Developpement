fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_worldbuilder'
description 'World Builder ESX : crée en jeu des garages, fourrières, locations de véhicules, stations essence, etc. (drogues et braquages : voir pickax_illegalbuilder) — UI + oxmysql'
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
    'server/insurance.lua',
    'server/autoauction.lua',
    'server/rental.lua',
    'server/bank.lua',
    'server/driving.lua',
    'server/fuel.lua',
    'server/gazoline.lua',
    'server/preset.lua',
    'server/carwash.lua',
    'server/locksmith.lua',
    'server/jobcenter.lua',
    'server/doorlock.lua',
    'server/carlot.lua',
    'server/chase.lua',
    'server/pvp.lua',
    'server/casino.lua',
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
    'client/gazoline.lua',
    'client/carwash.lua',
    'client/locksmith.lua',
    'client/jobcenter.lua',
    'client/doorlock.lua',
    'client/carlot.lua',
    'client/chase.lua',
    'client/pvp.lua',
    'client/casino.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/atelier.css',
    'html/garage.css',
    'html/vehicles/**/*',     -- images des véhicules (html/vehicles/<modèle>.webp) ; à défaut : docs.fivem.net
    'html/atelier.js',
    'html/script.js',
    'html/menus.js',
    'html/bb-ui.js',
}

dependencies {
    'es_extended',
    'oxmysql',
}
