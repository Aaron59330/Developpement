Config = {}

Config.AdminGroups = { admin = true, superadmin = true }     -- groupes ESX pouvant lancer /pickaxdoctor en jeu (la console serveur peut toujours)
Config.RunOnStart = true                                      -- vérifie / crée les index et purge les journaux à chaque démarrage (quelques secondes après oxmysql)
Config.StartDelay = 8000                                      -- ms avant le premier passage

-- ═══════════ Index SQL ═══════════
-- { table, { colonnes } } : l'index n'est créé que si la table et les colonnes existent et qu'aucun index ne commence déjà par ces colonnes.
-- Aucune donnée n'est modifiée ; la création d'un index est un ALTER TABLE en ligne (rapide, même sur de grosses tables).
Config.Indexes = {
    -- ESX / base
    { 'owned_vehicles', { 'owner' } }, { 'owned_vehicles', { 'plate' } },
    { 'billing', { 'identifier' } },
    { 'user_licenses', { 'owner' } },
    { 'addon_account_data', { 'account_name' } }, { 'addon_inventory_items', { 'inventory_name' } }, { 'datastore_data', { 'name' } },
    { 'job_grades', { 'job_name' } }, { 'users', { 'job' } },
    { 'jail', { 'identifier' } }, { 'vips', { 'identifier' } }, { 'playerstattoos', { 'identifier' } }, { 'boitegant', { 'plate' } },
    { 'account_info', { 'license' } }, { 'casino_wallets', { 'identifier' } }, { 'coffre_armeperm', { 'identifier' } },
    -- builders
    { 'jobbuilder_logs', { 'job_name' } }, { 'jobbuilder_records', { 'job_name' } }, { 'jobbuilder_properties', { 'job_name' } },
    { 'jobbuilder_dealer_vehicles', { 'job_name' } }, { 'jobbuilder_bank_clients', { 'job_name' } }, { 'jobbuilder_bank_loans', { 'job_name' } },
    { 'jobbuilder_bank_loans', { 'client_id' } }, { 'jobbuilder_bank_entries', { 'job_name' } }, { 'jobbuilder_property_outfits', { 'property_id' } },
    { 'worldbuilder_impound', { 'plate' } }, { 'gangbuilder_wars', { 'status' } }, { 'minigames_stats', { 'game_id' } },
    -- téléphone
    { 'aero_conv_members', { 'conv' } }, { 'aero_messages', { 'conv' } }, { 'aero_dc_msgs', { 'room' } }, { 'aero_dc_members', { 'room' } },
    { 'aero_contacts', { 'owner' } }, { 'aero_follows', { 'app' } },
}

-- ═══════════ Purge des journaux ═══════════
-- { table, jours } : supprime les lignes plus anciennes que `jours` (colonne de date détectée automatiquement). Les tables absentes sont ignorées.
-- Jamais touchées : historiques financiers (boutique_history, casino_history), sanctions, véhicules, comptes.
Config.Purge = {
    { 'jobbuilder_logs', 90 }, { 'illegalbuilder_logs', 90 }, { 'eventbuilder_logs', 90 }, { 'minigames_logs', 60 },
    { 'worldbuilder_logs', 90 }, { 'gangbuilder_logs', 90 }, { 'shopbuilder_logs', 90 }, { 'carplay_history', 60 }, { 'pickax_dlogs', 60 },
}
Config.PurgeDateColumns = { 'created_at', 'created', 'date', 'time', 'ts', 't' }      -- noms de colonnes de date essayés dans l'ordre

-- ═══════════ Cache mémoire ═══════════
Config.Cache = { MaxEntries = 5000, DefaultTTL = 60 }      -- secondes
