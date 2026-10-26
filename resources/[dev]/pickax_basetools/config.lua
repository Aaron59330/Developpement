Config = {}

Config.Command     = 'aerotools'          -- commande qui ouvre le panneau
Config.AdminGroups = { 'admin', 'superadmin', 'owner' }   -- groupes ESX autorisés (ou l'ACE ci-dessous)
Config.Ace         = 'pickax.basetools'    -- add_ace group.admin pickax.basetools allow
Config.Webhook     = ''                    -- webhook Discord : audit, sauvegarde, restauration (vide = désactivé)

-- Ressources qui doivent tourner pour que la base fonctionne
Config.Required = {
    'oxmysql', 'ox_lib', 'es_extended', 'ox_inventory', 'pickax_theme', 'pickax_core', 'pickax_notify',
    'pickax_jobbuilder', 'pickax_gangbuilder', 'pickax_illegalbuilder', 'pickax_shopbuilder', 'pickax_worldbuilder',
    'pickax_dlogs', 'pickax_phone',
}

-- Tables SQL attendues (créées par les ressources ou par database.sql)
Config.Tables = {
    'jobbuilder_jobs', 'jobbuilder_points', 'jobbuilder_dealer_vehicles', 'jobbuilder_dealer_sales', 'jobbuilder_properties',
    'jobbuilder_furniture', 'jobbuilder_lab', 'gangbuilder_gangs', 'gangbuilder_points', 'illegalbuilder_entities',
    'shopbuilder_shops', 'worldbuilder_entities', 'pickax_dlogs', 'aero_phones', 'anticheat_logs',
}

-- Objets ox_inventory utilisés par la base
Config.Items = {
    'powerbank', 'weed_seed', 'coke_seed', 'opium_seed', 'wheat_seed', 'corn_seed', 'wheat', 'corn',
}

-- Tables de CONFIGURATION sauvegardées (jamais les logs ni les données joueurs sensibles)
Config.BackupTables = {
    'jobbuilder_jobs', 'jobbuilder_points', 'jobbuilder_settings', 'jobbuilder_dealer_vehicles', 'jobbuilder_properties',
    'jobbuilder_property_points', 'jobbuilder_property_outfits', 'gangbuilder_gangs', 'gangbuilder_points', 'gangbuilder_settings',
    'gangbuilder_territories', 'illegalbuilder_entities', 'illegalbuilder_settings', 'shopbuilder_shops', 'shopbuilder_settings',
    'worldbuilder_entities', 'worldbuilder_settings', 'pickax_dlogs',
}
Config.BackupKeep = 30    -- sauvegardes conservées dans la liste

-- Ressources relancées après une restauration (pour recharger la configuration)
Config.RestartAfterRestore = { 'pickax_jobbuilder', 'pickax_gangbuilder', 'pickax_illegalbuilder', 'pickax_shopbuilder', 'pickax_worldbuilder' }

-- Thème en direct : ressources relancées après un changement de couleur / nom / logo (les interfaces se mettent à jour pour tous les joueurs)
Config.ThemeRestart = { 'pickax_theme', 'pickax_basetools' }   -- pickax_basetools : le thème modifié est dans theme_live.json de cette ressource, les joueurs le récupèrent au redémarrage
