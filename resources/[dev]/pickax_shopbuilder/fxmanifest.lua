fx_version 'cerulean'
game 'gta5'
lua54 'yes'
node_version '22'

name 'pickax_shopbuilder'
description 'Shop Builder ESX : crée n\'importe quelle boutique (supérette, armurerie, vêtements, coiffeur, pharmacie, bar, marché noir...) en jeu, avec stocks, promos, accès par métier, statistiques (UI + oxmysql)'
version '1.0.0'

shared_scripts {
    'pk_theme.lua',   -- couleur principale commune (pickax_theme/theme.js)
    'config.lua',
}

server_script 'lic.js'   -- [AERO] vérification de licence (doit rester AVANT les autres scripts serveur)
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/builder.lua',
    'server/dlogs.lua',
    'server/shop.lua',
}

client_scripts {
    'pk_sound.lua',
    'client/bb_map.lua',
    'client/main.lua',
    'client/clothing.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/atelier.css',
    'html/lux.css',
    'html/atelier.js',
    'html/script.js',
    'html/dlogs-ui.js',
    'html/bb-ui.js',
}

dependencies {
    'es_extended',
    'oxmysql',
}

-- [AERO] protection de la base : cette ressource ne démarre pas sans pickax_guard (licence valide)
dependency 'pickax_guard'
