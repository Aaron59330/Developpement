fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_justice'
description 'Justice et sécurité : mandats (perquisition, arrestation) délivrés par un juge, journal des saisies (contestables sans mandat), alcootest et contrôle des papiers (faux détectés selon leur qualité)'
version '1.0.0'

shared_scripts { 'ui.lua', 'config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_scripts { 'client/main.lua' }

dependencies { 'es_extended', 'oxmysql', 'ox_inventory', 'pickax_skillgames' }
