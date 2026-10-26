fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Pickax'
description 'Affichage NUI des menus (remplace le rendu natif de RageUI), style worldbuilder'
version '1.0.0'

ui_page 'html/index.html'

client_scripts { 'pk_theme.lua', 'client.lua' }

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/snd.js',
    'html/banner.jpg',
}

-- [AERO] protection de la base : cette ressource ne démarre pas sans pickax_guard (licence valide)
dependency 'pickax_guard'
