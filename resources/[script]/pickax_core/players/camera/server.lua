RegisterNetEvent('CorePickax:receivePermissions', function()
    local isWhitelisted = false

    if IsPlayerAceAllowed(source, ConfigCamera.AcePerm) then
        isWhitelisted = true
    else
        isWhitelisted = false
    end

    TriggerClientEvent('CorePickax:receivePermissions', source, isWhitelisted)
end)