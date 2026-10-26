fx_version 'cerulean'
game 'gta5'
lua54 'yes'
node_version '22'

name 'pickax_guard'
description 'Protection de la base : sans clé de licence valide (set aero_panel_key dans le server.cfg), les ressources pickax_* ne démarrent pas.'
version '1.0.0'

server_scripts { 'config.lua', 'verify.js', 'guard.lua' }
server_exports { 'IsLicensed', 'Check', 'Status' }
