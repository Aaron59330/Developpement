fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_wheel'
description 'Roue d\'armes (maintiens C) : UI GTA VI (React 19) — relâche sur une case pour équiper'
version '1.0.0'

shared_scripts { 'config.lua' }
client_scripts { 'client/main.lua' }

ui_page 'web/dist/index.html'
files { 'web/dist/index.html', 'web/dist/assets/*' }

dependencies { 'ox_inventory' }
