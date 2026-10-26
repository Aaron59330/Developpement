fx_version 'cerulean'
game 'gta5'

name 'pickax_notify'
author 'OpenAI'
description 'Notifications ESX style Pickax - compatible ShowNotification / ShowAdvancedNotification / ShowHelpNotification'
version '1.0.3'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/arcade.css',
    'html/app.js'
}

client_scripts {
    'pk_theme.lua',   -- couleur principale commune (pickax_theme/theme.js)
    'config.lua',
    'client.lua'
}

-- [AERO] protection de la base : cette ressource ne démarre pas sans pickax_guard (licence valide)
dependency 'pickax_guard'
