fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_settings'
description 'Réglages du serveur modifiables depuis le panel web : maintenance, annonces automatiques, redémarrages programmés, interface (notifications, boussole, HUD), voix, économie. Aucun coût tant que rien n\'est réglé.'
version '1.0.0'

shared_script 'config.lua'
server_script 'server/main.lua'
client_script 'client/main.lua'

server_exports { 'Get', 'GetAll', 'Overrides', 'Set', 'SetMany', 'ApplyRemote', 'Schema', 'Reset' }
exports { 'Get', 'GetAll', 'Overrides' }
