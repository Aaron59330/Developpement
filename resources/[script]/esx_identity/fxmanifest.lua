fx_version('bodacious')
game('gta5')
lua54 "on"

shared_scripts {
    'config.lua'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'server/main.lua'
}

client_scripts {
	'client/main.lua'
}

ui_page('html/index.html')

files({
	'html/index.html',
	'html/css/*.css',
	'html/js/*.js',
	'html/img/*.png'
})

escrow_ignore {
    'config.lua'
}