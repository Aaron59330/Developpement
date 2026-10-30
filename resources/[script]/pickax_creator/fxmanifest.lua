fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_creator'
description 'Écrans plein format : création d\'identité, apparence (skin), point d\'apparition, message de bienvenue et gestionnaire d\'animations — style doré, avec lecteur de musique'
version '1.0.0'

shared_scripts { '@pickax_theme/theme.lua', 'config.lua' }
client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/music/*',
    'html/places/*',
    'html/faces/*',
    'html/*.png',
    'html/*.jpg',
    'html/*.webp',
}
