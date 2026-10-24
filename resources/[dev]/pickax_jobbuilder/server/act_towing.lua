local KEY = 'towing'

local function newMission(st)
    local j = Config.Act.Jobs[KEY]
    local zones = AJ.pts(st, 'zone')
    local z = zones[math.random(#zones)]
    st.zone = { x = z.x, y = z.y }
    st.model = j.models[math.random(#j.models)]
    st.loaded = false
    st.t0 = os.time()
    return { zone = st.zone, model = st.model, plate = 'PANNE' .. math.random(10, 99) }
end

AJ.Modules[KEY] = {
    start = function(src, st)
        local j = Config.Act.Jobs[KEY]
        local spawn, scrap = AJ.spawnPoint(st), AJ.pts(st, 'scrap')[1]
        if not spawn or not scrap then return nil, 'Fourrière non configurée (point d\'activité « Fourrière » dans le Job Builder)' end
        if #AJ.pts(st, 'zone') == 0 then return nil, 'Aucun lieu de panne' end
        local m = newMission(st)
        m.vehicle, m.spawn, m.scrap = j.vehicle, spawn, scrap
        m.plate = 'DEPAN' .. math.random(100, 999)
        m.mission = { zone = st.zone, model = st.model, plate = 'PANNE' .. math.random(10, 99) }
        return m
    end,
    stop = function() end,
}

RegisterNetEvent('aj:towing:loaded', function()
    local src = source
    local st = AJ.session(src, KEY)
    if not st or st.loaded then return end
    if not AJ.near(src, { x = st.zone.x, y = st.zone.y, z = 0.0 }, 1e9) then return end
    local ped = GetPlayerPed(src)
    local p = GetEntityCoords(ped)
    -- le joueur doit être dans la zone de panne (rayon de tolérance : la route la plus proche peut être décalée)
    if #(vector2(p.x, p.y) - vector2(st.zone.x, st.zone.y)) > Config.Act.Jobs[KEY].searchRadius then return end
    st.loaded = true
end)

RegisterNetEvent('aj:towing:done', function()
    local src = source
    local st = AJ.session(src, KEY)
    local scrap = st and AJ.pts(st, 'scrap')[1]
    if not st or not st.loaded or not scrap or not AJ.near(src, scrap, 35.0) then return end
    local j = Config.Act.Jobs[KEY]
    local km = #(vector2(st.zone.x, st.zone.y) - vector2(scrap.x, scrap.y)) / 1000.0
    local paid = AJ.pay(src, KEY, j.payBase + km * j.payPerKm, 25 + math.floor(km * 5), 'Dépannage', 1)
    AJ.notify(src, ('Véhicule déposé à la fourrière (%.1f km) : %d $'):format(km, paid), 'success')
    local m = newMission(st)
    TriggerClientEvent('aj:towing:next', src, m)
end)
