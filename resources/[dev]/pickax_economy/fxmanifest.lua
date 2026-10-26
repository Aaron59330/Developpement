fx_version 'cerulean'
game 'gta5'
lua54 'yes'
node_version '22'

name 'pickax_economy'
description 'Économie dynamique : multiplicateurs de prix selon l\'offre et la demande (boutiques, récoltes…), retour progressif à la normale, événements de pénurie / surplus'
version '1.0.0'

shared_script 'config.lua'
server_script 'lic.js'   -- [AERO] vérification de licence (doit rester AVANT les autres scripts serveur)
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }

exports { 'Multiplier', 'Price', 'Record', 'Snapshot', 'Event', 'Reset', 'Preset', 'Presets', 'SetPreset', 'Scale' }
dependencies { 'oxmysql' }

-- [AERO] protection de la base : cette ressource ne démarre pas sans pickax_guard (licence valide)
dependency 'pickax_guard'
