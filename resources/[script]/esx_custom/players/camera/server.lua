RegisterNetEvent('esx_custom:receivePermissions', function()
    local isWhitelisted = false

    if IsPlayerAceAllowed(source, ConfigCamera.AcePerm) then
        isWhitelisted = true
    else
        isWhitelisted = false
    end

    TriggerClientEvent('esx_custom:receivePermissions', source, isWhitelisted)
end)