fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_boutique'
description 'Interface moderne de la boutique à coins (véhicules, motos, armes, caisses, packs, entreprises) avec images ; la logique d\'achat reste celle de pickax_core'
version '1.0.0'

shared_script 'pk_theme.lua'
client_script 'client.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/fonts/*.woff2',
    'images/**/*',
}

dependencies { 'es_extended', 'pickax_core' }
