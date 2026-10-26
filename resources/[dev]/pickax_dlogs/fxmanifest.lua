fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_dlogs'
description 'Logs Discord par métier / gang / boutique / événement : webhook et informations envoyées réglables depuis chaque builder'
version '1.0.0'

shared_script 'catalog.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

exports {
    'Send', 'View', 'Save', 'Delete', 'Test',
}

dependencies {
    'oxmysql',
}

-- [AERO] protection de la base : cette ressource ne démarre pas sans pickax_guard (licence valide)
dependency 'pickax_guard'
