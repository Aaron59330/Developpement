-- ─────────────────────────────── Braquages (client) ───────────────────────────────
local States = {}          -- [eid] = { owner, endsAt (GetGameTimer), done, coop }
local Guards = {}          -- gardes que CE joueur a fait apparaître
local starting = false
local myId = nil

local function myServerId()
    if not myId then myId = GetPlayerServerId(PlayerId()) end
    return myId
end

local TARGETS = { register = true, safe = true, vault = true, loot = true }

NodeFilter.robbery = function(n)
    local st = States[n.eid]
    if n.kind == 'start' then return st == nil and n.entity.trigger == 'interact' end   -- en mode « en joue », le départ se fait sur le vendeur (point clerk)
    if not TARGETS[n.kind] then return false end
    if not st or st.done[n.pi] then return false end
    return st.owner == myServerId() or st.coop
end

local function clearGuards(delay)
    local list = Guards
    Guards = {}
    SetTimeout(delay or 0, function()
        for _, g in ipairs(list) do if DoesEntityExist(g) then DeleteEntity(g) end end
    end)
end

local function setState(eid, st)
    if st then
        States[eid] = { owner = st.owner, endsAt = GetGameTimer() + (st.endsAt or 0) * 1000, done = st.done or {}, coop = st.coop }
    else
        States[eid] = nil
        if #Guards > 0 then clearGuards(30000) end
    end
end

RegisterNetEvent('worldbuilder:client:robState', setState)
RegisterNetEvent('worldbuilder:client:robStates', function(list)
    States = {}
    for _, r in ipairs(list or {}) do setState(r.eid, r.state) end
end)

function OnStop() clearGuards(0) end

-- ─────────────────────────────── Gardes armés ───────────────────────────────
local function spawnGuards(eid, cfg)
    local e = EntityById(eid)
    if not e or not cfg or not cfg.enabled or (cfg.count or 0) < 1 then return end
    local hash = LoadModel(cfg.model ~= '' and cfg.model or 's_m_m_security_01')
    if not hash then return end
    local n = 0
    for _, p in ipairs(e.points) do
        if p.kind == 'guard' and n < cfg.count then
            n = n + 1
            local ped = CreatePed(4, hash, p.coords.x + 0.0, p.coords.y + 0.0, p.coords.z - 1.0, (p.coords.h or 0.0) + 0.0, true, false)
            SetPedRelationshipGroupHash(ped, joaat('HATES_PLAYER'))
            GiveWeaponToPed(ped, joaat(cfg.weapon ~= '' and cfg.weapon or 'WEAPON_PISTOL'), 250, false, true)
            SetPedArmour(ped, 50)
            SetEntityMaxHealth(ped, math.floor(cfg.health or 200))
            SetEntityHealth(ped, math.floor(cfg.health or 200))
            SetPedAccuracy(ped, math.floor(cfg.accuracy or 30))
            SetPedCombatAttributes(ped, 46, true)
            SetPedFleeAttributes(ped, 0, false)
            SetPedDropsWeaponsWhenDead(ped, false)
            TaskCombatPed(ped, PlayerPedId(), 0, 16)
            Guards[#Guards + 1] = ped
        end
    end
    SetModelAsNoLongerNeeded(hash)
end

-- ─────────────────────────────── Démarrage ───────────────────────────────
local function robStart(eid, pi)
    if starting or Busy then return end
    starting = true
    ESX.TriggerServerCallback('worldbuilder:rob:start', function(res)
        starting = false
        if not res or not res.ok then return Notify((res and res.error) or 'Impossible', 'error') end
        Notify('Braquage en cours ! Vide les cibles avant la fin du temps.', 'info')
        local ped = WBPed(eid, pi)
        if ped then TaskHandsUp(ped, (res.duration or 60) * 1000, PlayerPedId(), -1, true) end
        spawnGuards(eid, res.guards)
    end, eid, pi)
end

local function robTarget(node)
    ESX.TriggerServerCallback('worldbuilder:rob:begin', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Impossible', 'error') end
        CreateThread(function()
            local done = RunAction({ seconds = res.seconds, label = res.label, anim = res.anim, minigame = res.minigame })
            TriggerServerEvent('worldbuilder:server:robFinish', done)
            if not done then Notify('Action interrompue.', 'error') end
        end)
    end, node.eid, node.pi)
end

Handlers.robbery = function(node)
    if node.kind == 'start' then return robStart(node.eid, node.pi) end
    if TARGETS[node.kind] then return robTarget(node) end
end

-- Déclenchement « en joue » : viser le vendeur avec une arme
CreateThread(function()
    while true do
        local sleep = 800
        if not IsUIOpen() and not Busy and not starting then
            local pos = GetEntityCoords(PlayerPedId())
            for _, e in ipairs(State.entities) do
                if e.type == 'robbery' and e.trigger == 'aim' and not States[e.id] then
                    for _, p in ipairs(e.points) do
                        if p.kind == 'clerk' and #(pos - vector3(p.coords.x, p.coords.y, p.coords.z)) < 12.0 then
                            sleep = 150
                            local ped = WBPed(e.id, p.i)
                            local pl = PlayerPedId()
                            if ped and IsPedArmed(pl, 4) and IsPlayerFreeAiming(PlayerId()) then
                                local ok, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
                                local cc = (p.ped and p.ped.pos) or p.coords
                                if ok and target and target ~= 0 and (target == ped or (IsEntityAPed(target) and #(GetEntityCoords(target) - vector3(cc.x, cc.y, cc.z)) < 5.0)) then
                                    robStart(e.id, p.i)
                                end
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Compte à rebours affiché pendant un braquage auquel on participe
local function drawText(x, y, text)
    SetTextFont(4) SetTextScale(0.0, 0.5) SetTextColour(255, 255, 255, 230) SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

CreateThread(function()
    while true do
        local sleep = 1000
        for eid, st in pairs(States) do
            if st.owner == myServerId() then
                sleep = 0
                local left = math.max(0, math.floor((st.endsAt - GetGameTimer()) / 1000))
                drawText(0.5, 0.92, ('BRAQUAGE — %02d:%02d'):format(left // 60, left % 60))
            end
        end
        Wait(sleep)
    end
end)
