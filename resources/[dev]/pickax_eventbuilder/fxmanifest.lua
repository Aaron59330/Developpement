fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_eventbuilder'
description 'Event Builder : crée et lance des événements en jeu (braquage de fourgon blindé, largage, braquage de commerce, épave, livraison illégale, contrôle de zone…) avec butin, police, blips et planification automatique'
version '1.0.0'

shared_scripts {
    'pk_theme.lua',   -- couleur principale commune (pickax_theme/theme.js)
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/builder.lua',
    'server/dlogs.lua',
    'server/runtime.lua',
}

client_scripts {
    'pk_sound.lua',
    'client/main.lua',
    'client/runtime.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/atelier.css',
    'html/atelier.js',
    'html/script.js',
    'html/dlogs-ui.js', 'html/pk-snd.js',
}

dependencies { 'es_extended', 'oxmysql' }
