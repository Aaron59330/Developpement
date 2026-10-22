fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_staff'
description 'Panel staff en jeu (remplace le menu admin F11) : joueurs, reports, sanctions, véhicules, monde, équipe, journal'
version '1.0.0'

shared_scripts {
    'pk_theme.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/players.lua',
    'server/misc.lua',
}

client_scripts {
    'client/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/bb-ui.js',
}

exports { 'Toggle', 'Open', 'Close' }

dependencies {
    'es_extended',
    'oxmysql',
    'pickax_core',
}
