fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Worxox'
description 'HUD Hunger/Thirst BlueBay - ESX/esx_status compatible'
version '1.1.0'

shared_script 'config.lua'
client_script 'client.lua'

ui_page 'index.html'

files {
    'index.html',
    'style.css',
    'arcade.css',
    'script.js'
}

-- [AERO] protection de la base : cette ressource ne démarre pas sans pickax_guard (licence valide)
dependency 'pickax_guard'
