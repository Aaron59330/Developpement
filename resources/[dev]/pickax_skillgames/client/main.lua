local active, prom = false, nil

local function Play(game, cfg)
    if active then return nil end
    active = true
    prom = promise.new()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'play', game = game, cfg = cfg or {} })
    local score = Citizen.Await(prom)
    prom = nil
    active = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    return score
end
exports('Play', Play)
exports('IsPlaying', function() return active end)

RegisterNUICallback('done', function(d, cb) if prom then prom:resolve(d and tonumber(d.score)) end cb(1) end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() and active then SetNuiFocus(false, false) end end)

RegisterCommand('skillgame', function(_, args)
    local ESX = exports['es_extended']:getSharedObject()
    local g = ESX.GetPlayerData().group
    if not Config.AllowTest[g] then return end
    CreateThread(function() local s = Play(args[1] or 'pins', {}) print('[skillgames] score', s) end)
end, false)
