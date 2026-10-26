fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_minigames'
description 'Mini-jeux Builder : crée en jeu des mini-jeux (basket, football, tennis, boxe, paintball, laser game, courses…) avec lobby, scores, récompenses, classements — interface style Apple'
version '1.0.0'

shared_scripts {
    'pk_theme.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/builder.lua',
    'server/progress.lua',
    'server/preset.lua',
    'server/match.lua',
}

client_scripts {
    'pk_sound.lua',
    'client/bb_map.lua',
    'client/main.lua',
    'client/games.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/atelier.css',
    'html/atelier.js',
    'html/script.js',
    'html/bb-ui.js',
}

dependencies { 'es_extended', 'oxmysql' }

-- [AERO] protection de la base : cette ressource ne démarre pas sans pickax_guard (licence valide)
dependency 'pickax_guard'
