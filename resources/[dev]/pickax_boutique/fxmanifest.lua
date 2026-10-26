fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_boutique'
description 'Interface moderne de la boutique à coins (véhicules, motos, armes, caisses, packs, entreprises) avec images ; la logique d\'achat reste celle de pickax_core'
version '1.0.0'

shared_scripts { 'pk_theme.lua', 'config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server.lua' }
client_scripts { 'pk_sound.lua', 'client.lua' }

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js', 'html/pk-snd.js',
    'html/fonts/*.woff2',
    'images/**/*',
}

dependencies { 'es_extended', 'oxmysql', 'pickax_core' }

-- [AERO] protection de la base : cette ressource ne démarre pas sans pickax_guard (licence valide)
dependency 'pickax_guard'
