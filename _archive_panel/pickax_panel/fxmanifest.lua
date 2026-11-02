fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_panel'
description 'Liaison avec le panel web AERO : licence, statut, joueurs, actions à distance, thème, bans, whitelist, logs'
version '1.0.0'

shared_script 'config.lua'
client_script 'client/main.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua', 'fs/main.js' }
node_version '22'

server_exports { 'IsLicensed', 'PanelLog', 'GetLicenseInfo', 'FsList', 'FsRead', 'FsWrite' }
dependencies { 'es_extended', 'oxmysql' }
