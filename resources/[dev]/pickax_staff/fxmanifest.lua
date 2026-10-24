fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_staff'
description 'Actions staff côté serveur utilisées par le menu admin (le panel UI a été retiré)'
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

exports { 'Toggle', 'Open', 'Close' }

dependencies {
    'es_extended',
    'oxmysql',
    'pickax_core',
}
