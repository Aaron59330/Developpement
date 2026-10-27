-- [AERO:LIC] contrôle de licence via pickax_core (qui vérifie lui-même la signature du panel) : ne pas retirer
do
    local res = GetCurrentResourceName()
    local function ok() local good, v = pcall(function() return exports.pickax_core:Licensed() end) return good and v == true end
    local function die(why) print(('^1[AERO] %s arrêtée : %s^0'):format(res, why)) StopResource(res) end
    if GetResourceState('pickax_core') == 'started' and not ok() then die('licence invalide (pickax_core)') error('AERO : licence invalide', 0) end
    CreateThread(function()
        local tries = 0
        while not ok() do
            tries = tries + 1
            if tries > 16 then die('pickax_core absent ou licence invalide') return end
            Wait(2500)
        end
        while true do
            Wait(240000 + math.random(0, 120000))
            local good = false
            for _ = 1, 4 do if ok() then good = true break end Wait(10000) end
            if not good then die('licence invalide') return end
        end
    end)
end
-- [/AERO:LIC]

local ESX = exports['es_extended']:getSharedObject()

ESX.RegisterServerCallback('pickax_weaponcarry:isDev', function(src, cb)
    local x = ESX.GetPlayerFromId(src)
    cb(x ~= nil and Config.DevGroups[x.getGroup()] == true)
end)
