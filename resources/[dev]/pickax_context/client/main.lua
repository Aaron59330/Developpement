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
        if node.dynamic then
            local f = Providers[node.dynamic]
            kids = f and f() or {}
            if #kids == 0 then kids = { { label = node.empty or 'Aucun élément', disabled = true } } end
        end
        local o = { label = node.label, icon = node.icon, disabled = node.disabled, checked = node.checked }
        if kids then o.children = convert(kids)
        elseif not node.disabled then actions[#actions + 1] = function() run(node) end o.k = #actions end
        out[#out + 1] = o
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
