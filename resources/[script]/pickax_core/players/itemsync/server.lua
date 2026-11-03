-- Synchronisation des items : tout ce qui est défini dans ox_inventory/data/items.lua est créé dans la table `items` de la base (si absent).
-- Ne modifie jamais une ligne existante (label/poids déjà en base gardés). Désactivable : Config.ItemSync = false dans config_sv.lua.
CreateThread(function()
    if Config and Config.ItemSync == false then return end
    Wait(8000)
    local ok, items = pcall(function() return exports.ox_inventory:Items() end)
    if not ok or type(items) ~= 'table' then print('^3[itemsync] ox_inventory:Items() indisponible : synchronisation ignorée^0') return end
    local added = 0
    for name, it in pairs(items) do
        if type(name) == 'string' and not name:upper():find('^WEAPON_') and type(it) == 'table' then
            local label = tostring(it.label or name):sub(1, 50)
            local kg = (tonumber(it.weight) or 0) / 1000
            if kg < 0 then kg = 0 end
            local n = MySQL.update.await('INSERT INTO items (name, label, weight, rare, can_remove) SELECT ?, ?, ?, 0, 1 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM items WHERE name = ?)', { name, label, kg, name })
            if n and n > 0 then added = added + 1 end
        end
    end
    print(('^2[itemsync] %d item(s) ajouté(s) dans la table items^0'):format(added))
end)
