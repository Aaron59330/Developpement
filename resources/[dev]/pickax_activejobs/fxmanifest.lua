fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_activejobs'
description 'Moteur des métiers actifs (éboueur, dépanneur, laveur auto, camionneur, fermier, pompier, conducteur de train) : missions, XP, niveaux — les jobs se créent dans le Job Builder'
version '1.0.0'

shared_scripts {
    'pk_theme.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/garbage.lua',
    'server/towing.lua',
    'server/carwash.lua',
    'server/trucker.lua',
    'server/farmer.lua',
    'server/firefighter.lua',
    'server/train.lua',
}

client_scripts {
    'client/core.lua',
    'client/garbage.lua',
    'client/towing.lua',
    'client/carwash.lua',
    'client/trucker.lua',
    'client/farmer.lua',
    'client/firefighter.lua',
    'client/train.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

dependencies {
    'es_extended',
    'oxmysql',
    'pickax_jobbuilder',
}
