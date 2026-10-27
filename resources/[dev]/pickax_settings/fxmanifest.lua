fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_settings'
description 'Réglages du serveur modifiables depuis le panel web : maintenance, annonces, redémarrages, monde et PNJ, météo et heure, combat, nouveaux joueurs, interface, voix, économie, carnet. Aucun coût tant que rien n\'est réglé.'
version '1.0.0'

shared_script 'config.lua'
server_scripts { 'server/main.lua', 'server/gameplay.lua' }
client_scripts { 'client/main.lua', 'client/gameplay.lua' }

server_exports { 'Get', 'GetAll', 'Overrides', 'Set', 'SetMany', 'ApplyRemote', 'Schema', 'Reset', 'FpsStats' }
exports { 'Get', 'GetAll', 'Overrides', 'IsPerf', 'Fps' }
