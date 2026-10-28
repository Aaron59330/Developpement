fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_bourse'
description 'Bourse : actions fictives dont le prix évolue côté serveur (marche aléatoire + actualités), achat / vente, portefeuille, plus-values — menus ox_lib'
version '1.0.0'

shared_scripts { '@ox_lib/init.lua', 'config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_scripts { 'client/main.lua' }

dependencies { 'oxmysql', 'ox_lib', 'es_extended' }
