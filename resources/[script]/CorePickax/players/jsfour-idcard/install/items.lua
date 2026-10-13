-- À copier dans ox_inventory/data/items.lua
-- Les images sont dans jsfour-idcard/install/images/ -> à copier dans ox_inventory/web/images/

['id_card'] = {
	label = "Carte d'identité",
	weight = 10,
	stack = false,
	close = true,
	description = "Carte nationale d'identité",
	server = { export = 'CorePickax.id_card' }
},

['driver_license'] = {
	label = 'Permis de conduire',
	weight = 10,
	stack = false,
	close = true,
	description = 'Permis de conduire',
	server = { export = 'CorePickax.driver_license' }
},

['weapon_license'] = {
	label = "Permis de port d'arme",
	weight = 10,
	stack = false,
	close = true,
	description = "Permis de port d'arme",
	server = { export = 'CorePickax.weapon_license' }
},
