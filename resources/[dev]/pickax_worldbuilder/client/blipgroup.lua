-- /blipgroup : test de regroupement des blips dans la légende de la carte (outil de réglage, blips locaux supprimés au bout de 10 minutes ou avec /blipgroup off)
-- Crée 5 paires de blips de même nom autour du joueur, chaque paire avec une méthode différente. Ouvre la carte (Échap) : la méthode qui affiche UNE ligne « Test X 1/2 » est la bonne.
local testBlips = {}

local function clear()
    for _, b in ipairs(testBlips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    testBlips = {}
end

local function shared(name)
    local key = ('PKTEST_%x'):format(GetHashKey(name))
    AddTextEntry(key, name)
    return key
end

local METHODS = {
    { 'Test A', function(b, name) BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(name) EndTextCommandSetBlipName(b) end },                 -- texte simple (comme avant)
    { 'Test B', function(b, name) BeginTextCommandSetBlipName(shared(name)) EndTextCommandSetBlipName(b) end },                                                       -- texte partagé
    { 'Test C', function(b, name) SetBlipCategory(b, 7) BeginTextCommandSetBlipName(shared(name)) EndTextCommandSetBlipName(b) end },                                  -- + catégorie 7
    { 'Test D', function(b, name) SetBlipCategory(b, 2) BeginTextCommandSetBlipName(shared(name)) EndTextCommandSetBlipName(b) end },                                  -- + catégorie 2
    { 'Test E', function(b, name) SetBlipCategory(b, 11) BeginTextCommandSetBlipName(shared(name)) EndTextCommandSetBlipName(b) end },                                 -- + catégorie 11
}

RegisterCommand('blipgroup', function(_, args)
    clear()
    if args[1] == 'off' then return end
    local p = GetEntityCoords(PlayerPedId())
    for i, m in ipairs(METHODS) do
        for k = 1, 2 do
            local b = AddBlipForCoord(p.x + (i - 3) * 120.0, p.y + (k == 1 and 60.0 or 160.0), p.z)
            SetBlipSprite(b, 357) SetBlipColour(b, 3) SetBlipScale(b, 0.9) SetBlipDisplay(b, 4) SetBlipAsShortRange(b, false)
            m[2](b, m[1])
            testBlips[#testBlips + 1] = b
        end
    end
    TriggerEvent('chat:addMessage', { args = { '^2blipgroup', '10 blips créés (5 méthodes × 2). Ouvre la carte (Échap) et regarde la légende. « /blipgroup off » les supprime.' } })
    SetTimeout(600000, clear)
end, false)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then clear() end end)
