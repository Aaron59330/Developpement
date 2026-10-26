fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_panel'
description 'Liaison avec le panel web AERO : licence, statut, joueurs, actions à distance, thème, bans, whitelist, logs'
version '1.0.0'

shared_script 'config.lua'
server_script 'server/main.lua'

server_exports { 'IsLicensed', 'PanelLog', 'GetLicenseInfo' }
dependencies { 'es_extended' }
