fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_phone'
author 'Pickax'
description 'Aura — smartphone complet (ESX · QBCore · Qbox · standalone) : appels vocaux, messages, réseaux sociaux, banque, crypto, photos, mails, GPS, services, AirShare, App Store…'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'pk_theme.lua',   -- couleur / nom du serveur (pickax_theme)
    'config.lua',
}

client_scripts {
    'bridge/client.lua',
    'client/main.lua',
    'client/calls.lua',
    'client/camera.lua',
    'client/extras.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'server/core.lua',
    'server/calls.lua',
    'server/messages.lua',
    'server/social.lua',
    'server/finance.lua',
    'server/services.lua',
    'server/misc.lua',
    'server/extras.lua',
    'server/extras2.lua',
    'server/api.lua',
}

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/js/apps/*.js',
    'html/img/*',
}

dependencies { 'oxmysql', 'ox_lib' }   -- framework, inventaire et voix : détectés automatiquement (voir config.lua)
