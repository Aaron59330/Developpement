local KEY = 'garbage'

AJ.Modules[KEY] = {
    start = function(src, state)
        local j = Config.Act.Jobs[KEY]
        local spawn = AJ.spawnPoint(state)
        if not spawn then return nil, 'Dépôt non configuré' end
        local zones = AJ.pts(state, 'zone')
        if #zones == 0 then return nil, 'Aucune zone de ramassage' end
        local zone = zones[math.random(#zones)]
        state.total = math.random(j.bags[1], j.bags[2])
        state.collected = 0
        state.last = 0
        return { zone = zone, total = state.total, vehicle = j.vehicle, spawn = spawn, radius = j.searchRadius, plate = 'EBOUE' .. math.random(100, 999) }
    end,
    stop = function() end,
}

RegisterNetEvent('aj:garbage:bag', function()
    local src = source
    local st = AJ.session(src, KEY)
    if not st or st.collected >= st.total then return end
    local now = GetGameTimer()
    if now - st.last < 2000 then return end        -- on ne peut pas jeter 2 sacs en 2 secondes
    st.last = now
    st.collected = st.collected + 1
end)

RegisterNetEvent('aj:garbage:finish', function()
    local src = source
    local st = AJ.session(src, KEY)
    local dep = AJ.pts(st, 'depot')[1]
    if not st or not dep or not AJ.near(src, dep, 40.0) then return end
    if st.collected <= 0 then return AJ.notify(src, 'Tu n\'as ramassé aucun sac.', 'error') end
    local j = Config.Act.Jobs[KEY]
    local full = st.collected >= st.total
    local base = st.collected * j.payPerBag + (full and j.bonus or 0)
    local paid = AJ.pay(src, KEY, base, st.collected * 4 + (full and 20 or 0), 'Tournée de ramassage', 1)
    AJ.notify(src, ('Tournée terminée : %d sac(s)%s — %d $'):format(st.collected, full and ' + prime' or '', paid), 'success')
    AJ.stopShift(src, nil)
end)
