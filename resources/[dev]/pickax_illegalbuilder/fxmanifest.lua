fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_illegalbuilder'
description 'Builder Illégal ESX : drogues (récolte / laboratoires / traitement / vente / blanchiment), braquages (supérettes, banques, bijouteries...) et Go Fast — UI + oxmysql'
version '1.0.0'

shared_scripts {
    'pk_theme.lua',   -- couleur principale commune (pickax_theme/theme.js)
    'config.lua',
    'panelsettings.lua',   -- réglages modifiables depuis le panel web (pickax_settings)
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/builder.lua',
    'server/drugs.lua',
    'server/robbery.lua',
    'server/plants.lua',
    'server/gofast.lua',
    'server/seed.lua',
}

client_scripts {
    'pk_sound.lua',
    'client/bb_map.lua',
    'client/main.lua',
    'client/drugs.lua',
    'client/robbery.lua',
    'client/plants.lua',
    'client/gofast.lua',
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

dependencies {
    'es_extended',
    'oxmysql',
}
