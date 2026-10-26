fx_version "cerulean"

description "Speedometer FiveM Script"
author "Rework Pickax"
version '1.0.0'

lua54 'yes'

games {
  "gta5",
  "rdr3"
}

ui_page 'web/build/index.html'

client_script "client/**/*"

files {
	'web/build/index.html',
	'web/build/**/*',
}

server_scripts {
    -- AUCUN fichier pour l’instant
}

-- [AERO] protection de la base : cette ressource ne démarre pas sans pickax_guard (licence valide)
dependency 'pickax_guard'
