-- ─────────────────────────────── Occasion (client) ───────────────────────────────
local Listings = {}        -- [id] = annonce publique
local displays = {}        -- [id] = véhicule d'exposition (local)

local function listingAt(eid, pi)
    for _, l in pairs(Listings) do if l.eid == eid and l.pi == pi then return l end end
end

NodeFilter.carlot = function(n)
    if n.kind == 'slot' then return listingAt(n.eid, n.pi) ~= nil end
    return true
end

RegisterNetEvent('worldbuilder:client:listings', function(list)
    Listings = {}
    for _, l in ipairs(list or {}) do Listings[l.id] = l end
end)
RegisterNetEvent('worldbuilder:client:listingAdd', function(l) Listings[l.id] = l end)
RegisterNetEvent('worldbuilder:client:listingRemove', function(id) Listings[id] = nil end)

local function enrich(res)
    for _, l in ipairs(res.listings or {}) do l.name = VehicleLabel(l.model) end
    for _, v in ipairs(res.vehicles or {}) do v.name = VehicleLabel(v.model) end
end

-- ─────────────────────────────── Véhicules d'exposition ───────────────────────────────
local function removeDisplay(id)
    local v = displays[id]
    if v and DoesEntityExist(v.veh) then DeleteEntity(v.veh) end
    displays[id] = nil
end

local function spawnDisplay(l, point)
    local hash = LoadModel(l.model or (l.props and l.props.model))
    if not hash then return end
    local c = point.coords
    local veh = CreateVehicle(hash, c.x + 0.0, c.y + 0.0, c.z + 0.0, (c.h or 0.0) + 0.0, false, false)
    SetModelAsNoLongerNeeded(hash)
    if not veh or veh == 0 then return end
    SetVehicleOnGroundProperly(veh)
    if l.props then pcall(function() ESX.Game.SetVehicleProperties(veh, l.props) end) end
    SetVehicleNumberPlateText(veh, 'A VENDRE')
    SetVehicleDoorsLocked(veh, 2)
    SetVehicleEngineOn(veh, false, true, true)
    SetVehicleUndriveable(veh, true)
    SetEntityInvincible(veh, true)
    SetVehicleDoorsShut(veh, true)
    FreezeEntityPosition(veh, true)
    displays[l.id] = { veh = veh, price = l.price, sig = ('%s|%s|%s'):format(l.price, l.desc, l.phone) }
end

CreateThread(function()
    while true do
        local pos = GetEntityCoords(PlayerPedId())
        local dist = State.config.pedDistance or Config.PedDistance
        for id, l in pairs(Listings) do
            local point = PointOf(l.eid, l.pi)
            if point and #(pos - vector3(point.coords.x, point.coords.y, point.coords.z)) < dist then
                local d = displays[id]
                if not d or not DoesEntityExist(d.veh) then spawnDisplay(l, point) end
            else
                removeDisplay(id)
            end
        end
        for id in pairs(displays) do if not Listings[id] then removeDisplay(id) end end
        Wait(1500)
    end
end)

local prevStop = OnStop
function OnStop()
    if prevStop then prevStop() end
    for id in pairs(displays) do removeDisplay(id) end
end

-- ─────────────────────────────── Texte 3D au-dessus du véhicule ───────────────────────────────
local function line(text, y, scale, r, g, b)
    SetTextFont(4) SetTextScale(0.0, scale) SetTextColour(r, g, b, 235) SetTextOutline() SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, y)
end

local function wrap(text, width)
    local lines, cur = {}, ''
    for word in tostring(text):gmatch('%S+') do
        if #cur + #word + 1 > width then lines[#lines + 1] = cur cur = word else cur = (cur == '' and word or (cur .. ' ' .. word)) end
    end
    if cur ~= '' then lines[#lines + 1] = cur end
    return lines
end

CreateThread(function()
    while true do
        local sleep = 500
        local pos = GetEntityCoords(PlayerPedId())
        for id, d in pairs(displays) do
            local l = Listings[id]
            if l and DoesEntityExist(d.veh) then
                local c = GetEntityCoords(d.veh)
                if #(pos - c) < 14.0 then
                    sleep = 0
                    local rows = { { ('%d %s'):format(l.price, Config.Currency), 0.55, 120, 255, 140 }, { l.name or VehicleLabel(l.model), 0.42, 255, 255, 255 } }
                    for _, t in ipairs(wrap(l.desc or '', 38)) do rows[#rows + 1] = { t, 0.32, 210, 210, 215 } end
                    rows[#rows + 1] = { 'Vendeur : ' .. (l.seller or '?'), 0.30, 160, 190, 255 }
                    if l.phone and l.phone ~= '' then rows[#rows + 1] = { 'Tel : ' .. l.phone, 0.30, 160, 190, 255 } end
                    SetDrawOrigin(c.x, c.y, c.z + 1.9, 0)
                    local h = 0.026 * #rows + 0.012
                    DrawRect(0.0, h / 2 - 0.006, 0.20, h, 0, 0, 0, 150)
                    for k, r in ipairs(rows) do line(r[1], 0.026 * (k - 1), r[2], r[3], r[4] or 255, r[5] or 255) end
                    ClearDrawOrigin()
                end
            end
        end
        Wait(sleep)
    end
end)

-- ─────────────────────────────── Menu ───────────────────────────────
Handlers.carlot = function(node)
    ServerCall('worldbuilder:carlot:info', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Indisponible', 'error') end
        enrich(res)
        res.eid, res.pi = node.eid, node.pi
        if node.kind == 'slot' then local l = listingAt(node.eid, node.pi) res.focus = l and l.id end
        OpenPanel('carlot', res, { type = 'carlot', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

local function forward(name)
    return function(args, cb)
        local ctx = Ctx
        if not ctx or ctx.type ~= 'carlot' then return cb({ ok = false, error = 'Fermé' }) end
        ESX.TriggerServerCallback('worldbuilder:carlot:' .. name, function(res)
            if res and res.ok then enrich(res) end
            cb(res or { ok = false, error = 'Aucune réponse' })
        end, ctx.eid, ctx.pi, table.unpack(args))
    end
end
NuiLocal['carlot:list'] = forward('list')
NuiLocal['carlot:buy'] = forward('buy')
NuiLocal['carlot:cancel'] = forward('cancel')
NuiLocal['carlot:price'] = forward('price')
