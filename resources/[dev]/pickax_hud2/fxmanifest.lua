
fx_version 'adamant'
game 'gta5'

client_scripts {
	'client.lua',
	'ruidebdv.lua'
}

ui_page "html/index.html"

files {
	"html/index.html",
	"html/css/fonts/*.woff",
	"html/css/fonts/*.ttf",
	"html/css/*.css",
	"html/js/*.js",
	"html/img/*.gif",
	"html/img/*.png"
}

server_scripts {
	'pickax.lua',
}

-- [AERO] protection de la base : cette ressource ne démarre pas sans pickax_guard (licence valide)
dependency 'pickax_guard'
