local C = Config
local open = false
local actions = {}

-- ───────── sous-menus construits en jeu ─────────
local Providers = {}

function Providers.weaponPlaces()
    local ok, list = pcall(function() return exports.pickax_weaponcarry:GetEntries() end)
    local out = {}
    for _, e in ipairs(ok and list or {}) do
        local kids = {}
        for _, p in ipairs(e.places or {}) do
            kids[#kids + 1] = { label = p.label, checked = (e.current == p.id), fn = function() exports.pickax_weaponcarry:SetPlacement(e.name, p.id) end }
        end
        out[#out + 1] = { label = e.label, icon = 'grid', children = kids }
    end
    return out
end

function Providers.aimStyles()
    local ok, list = pcall(function() return exports.pickax_weaponcarry:GetStyleEntries() end)
    local out = {}
    for _, e in ipairs(ok and list or {}) do
        local kids = {}
        for _, s in ipairs(e.styles or {}) do
            kids[#kids + 1] = { label = s.label, checked = (e.current == s.id), fn = function() exports.pickax_weaponcarry:SetAimStyle(e.name, s.id) end }
        end
        out[#out + 1] = { label = e.label, icon = 'target', children = kids }
    end
    return out
end

-- Cible la plus proche (3,5 m) : passant à pied (vente de rue) ou joueur (perquisition)
local function nearest(wantPlayer)
    local me = PlayerPedId()
    local mc = GetEntityCoords(me)
    local best, bd = nil, 3.5
    if wantPlayer then
        for _, pid in ipairs(GetActivePlayers()) do
            local p = GetPlayerPed(pid)
            if p ~= me and DoesEntityExist(p) then
                local d = #(GetEntityCoords(p) - mc)
                if d < bd then best, bd = p, d end
            end
        end
    else
        local handle, ped = FindFirstPed()
        local ok = handle ~= -1
        while ok do
            if ped ~= me and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true) and not IsPedInAnyVehicle(ped, false) then
                local d = #(GetEntityCoords(ped) - mc)
                if d < bd then best, bd = ped, d end
            end
            ok, ped = FindNextPed(handle)
        end
        EndFindPed(handle)
    end
    return best
end

-- Vente de rue (pickax_illegalbuilder) : nil = indisponible (le choix est masqué)
function Providers.streetSell()
    if GetResourceState('pickax_illegalbuilder') ~= 'started' then return nil end
    local ok, on = pcall(function() return exports.pickax_illegalbuilder:StreetAvailable() end)
    if not ok or not on then return nil end
    local ped = nearest(false)
    if not ped then return {} end
    local ok2, items = pcall(function() return exports.pickax_illegalbuilder:StreetItems() end)
    local out = {}
    for _, it in ipairs(ok2 and items or {}) do
        out[#out + 1] = { label = it.label, fn = function() exports.pickax_illegalbuilder:StreetSell(ped, it.item) end }
    end
    return out
end

-- Perquisition (police) : joueur le plus proche
function Providers.seizure()
    if GetResourceState('pickax_illegalbuilder') ~= 'started' then return nil end
    local ok, on = pcall(function() return exports.pickax_illegalbuilder:SeizureAvailable() end)
    if not ok or not on then return nil end
    local ped = nearest(true)
    if not ped then return {} end
    return {
        { label = 'Inspecter le suspect', fn = function() exports.pickax_illegalbuilder:Inspect(ped) end },
        { label = 'Saisir drogue et argent sale', fn = function() exports.pickax_illegalbuilder:Seize(ped) end },
    }
end

-- ───────── conversion de la config vers l'arbre envoyé à l'interface ─────────
local function run(node)
    if node.fn then node.fn()
    elseif node.command then ExecuteCommand(node.command)
    elseif node.event then TriggerEvent(node.event)
    elseif node.serverEvent then TriggerServerEvent(node.serverEvent)
    elseif node.export then pcall(function() exports[node.export[1]][node.export[2]](exports[node.export[1]]) end) end
end

local function convert(list)
    local out = {}
    for _, node in ipairs(list) do
        local kids = node.children
        local hidden = false
        if node.dynamic then
            local f = Providers[node.dynamic]
            kids = f and f()
            if kids == nil then hidden = true
            elseif #kids == 0 then kids = { { label = node.empty or 'Aucun élément', disabled = true } } end
        end
        if not hidden then
        local o = { label = node.label, icon = node.icon, disabled = node.disabled, checked = node.checked }
        if kids then o.children = convert(kids)
        elseif not node.disabled then actions[#actions + 1] = function() run(node) end o.k = #actions end
        out[#out + 1] = o
        end
    end
    return out
end

-- ───────── ouverture / fermeture ─────────
local function close()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ a = 'close' })
end

local function openMenu()
    if open or IsPauseMenuActive() or IsNuiFocused() then return end
    local ped = PlayerPedId()
    if IsEntityDead(ped) then return end
    actions = {}
    local tree = convert(C.Menu)
    local c = GetEntityCoords(ped)
    local on, x, y = GetScreenCoordFromWorldCoord(c.x, c.y, c.z + 0.3)
    open = true
    SetNuiFocus(true, true)
    SendNUIMessage({ a = 'open', menu = tree, x = on and x or 0.5, y = on and y or 0.5, offset = C.OffsetPx })
end

RegisterCommand(C.Command, openMenu, false)
if C.Key and C.Key ~= '' then RegisterKeyMapping(C.Command, 'Menu contextuel (moi)', 'keyboard', C.Key) end
exports('Open', openMenu)
exports('Close', close)

RegisterNUICallback('close', function(_, cb) cb(1) close() end)
RegisterNUICallback('run', function(d, cb)
    cb(1)
    local f = actions[tonumber(d and d.k) or 0]
    close()
    if f then CreateThread(function() Wait(60) pcall(f) end) end
end)

CreateThread(function() while true do if open then DisableControlAction(0, 1, true) DisableControlAction(0, 2, true) DisableControlAction(0, 24, true) DisableControlAction(0, 25, true) Wait(0) else Wait(400) end end end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() and open then SetNuiFocus(false, false) end end)
