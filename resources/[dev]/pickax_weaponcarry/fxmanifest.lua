fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_weaponcarry'
description 'Armes portées visibles sur le personnage (dans le dos, à la ceinture, dans la poche) ou invisibles ; le placement se choisit depuis le menu contextuel (pickax_core)'
version '1.0.0'

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

dependencies { 'es_extended', 'ox_inventory' }

-- [AERO] protection de la base : cette ressource ne démarre pas sans pickax_guard (licence valide)
dependency 'pickax_guard'
