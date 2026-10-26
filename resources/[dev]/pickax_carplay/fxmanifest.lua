fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_carplay'
description 'CarPlay : autoradio de véhicule (YouTube, liens directs, radios, file d\'attente, son synchronisé et spatialisé)'
version '1.0.0'

shared_scripts { 'config.lua', 'shared.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server.lua' }
client_scripts { 'client.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/engine.js', 'html/script.js' }

dependencies { 'es_extended', 'oxmysql' }

-- [AERO] protection de la base : cette ressource ne démarre pas sans pickax_guard (licence valide)
dependency 'pickax_guard'
