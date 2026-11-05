fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_wheel'
description 'Roue d\'armes (maintiens CAPSLOCK) : 6 emplacements, mains nues incluses — relâche pour sortir l\'arme'
version '1.0.0'

shared_scripts { '@pickax_theme/theme.lua', 'config.lua' }
client_scripts { 'client/main.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }

dependencies { 'pickax_theme', 'ox_inventory' }
