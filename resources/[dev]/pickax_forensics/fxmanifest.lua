fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pickax_forensics'
description 'Police scientifique : douilles laissées par les tirs, empreinte balistique, analyse au laboratoire (arme, n° de série, propriétaire enregistré, correspondances entre scènes)'
version '1.0.0'

shared_scripts { 'ui.lua', 'config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua', 'server/traces.lua' }
client_scripts { 'client/main.lua' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }

dependencies { 'es_extended', 'oxmysql', 'ox_inventory', 'pickax_skillgames' }
