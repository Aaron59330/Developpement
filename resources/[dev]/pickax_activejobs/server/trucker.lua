local KEY = 'trucker'

AJ.Modules[KEY] = {
    start = function(src, st)
        local j = Config.Jobs[KEY]
        local spawn, dep = AJ.spawnPoint(st), AJ.pts(st, 'depot')[1]
        local dests = AJ.pts(st, 'dest')
        if not spawn or #dests == 0 then return nil, 'Destinations non configurées (point d\'activité « Destination » dans le Job Builder)' end
        local best = {}
        for _, d in ipairs(dests) do if AJ.dist(d, dep) > 1500.0 then best[#best + 1] = d end end
        if #best == 0 then best = dests end
        local dest = best[math.random(#best)]
        local km = AJ.dist(dest, dep) / 1000.0
        st.dest, st.km, st.t0, st.delivered, st.limit = dest, km, os.time(), false, math.floor(km * j.timePerKm) + 120
        return { truck = j.truck, trailer = j.trailers[math.random(#j.trailers)], spawn = spawn, dest = dest, km = km, limit = st.limit, plate = 'CAMION' .. math.random(10, 99) }
    end,
    stop = function() end,
}

RegisterNetEvent('aj:trucker:deliver', function(health)
    local src = source
    local st = AJ.session(src, KEY)
    if not st or st.delivered or not AJ.near(src, st.dest, 45.0) then return end
    local j = Config.Jobs[KEY]
    local cond = math.max(0.4, math.min(1.0, tonumber(health) or 1.0))
    local elapsed = os.time() - st.t0
    local base = (j.payBase + st.km * j.payPerKm) * cond
    local late = elapsed > st.limit
    if late then base = base * 0.75 end
    local paid = AJ.pay(src, KEY, base, 30 + math.floor(st.km * 6), 'Livraison poids lourd', 1)
    st.delivered = true
    AJ.notify(src, ('Livraison effectuée (%.1f km, %d%% de cargaison intacte%s) : %d $'):format(st.km, math.floor(cond * 100), late and ', en retard' or '', paid), 'success')
    TriggerClientEvent('aj:trucker:delivered', src)
end)

RegisterNetEvent('aj:trucker:return', function()
    local src = source
    local st = AJ.session(src, KEY)
    local dep = st and AJ.pts(st, 'depot')[1]
    if not st or not st.delivered or not dep or not AJ.near(src, dep, 40.0) then return end
    local paid = AJ.pay(src, KEY, Config.Jobs[KEY].returnBonus, 10, 'Retour au dépôt', 0)
    AJ.notify(src, ('Camion rendu : prime de retour %d $'):format(paid), 'success')
    AJ.stopShift(src, nil)
end)
