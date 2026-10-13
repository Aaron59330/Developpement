function WipePlayer(id)
    local sourcePed = ESX.GetPlayerFromId(id)

    SetEntityCoords(GetPlayerPed(id), -822.23, -122.5, 28.18)--Le TP

    sourcePed.setAccountMoney('money', 1500)--Set l'argent au joueur
    sourcePed.setAccountMoney('bank', 500)--Set l'argent en banque au joueur
    sourcePed.setAccountMoney('black_money', 0)--Set l'argent sale au joueur

    TriggerClientEvent('esx_identity:showRegisterIdentity', id)--Ouvrir le menu identity

    for k, v in ipairs(sourcePed.inventory) do--Exemple de whipe inventaire
        if v.count > 0 then
            sourcePed.removeInventoryItem(v.name, v.count)
        end
    end

    for k,v in ipairs(sourcePed.loadout) do--Exemple de whipe armes
        if not Config.ArmesPerm[v.name] then
            sourcePed.removeWeapon(v.name)
        end
    end

    MySQL.Async.execute([[DELETE FROM open_car WHERE identifier = @wipeID; DELETE FROM owned_vehicles WHERE owner = @wipeID;]], {['@wipeID'] = sourcePed.getIdentifier()})--Exemple de whipe garage
end