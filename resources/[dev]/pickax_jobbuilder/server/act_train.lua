local KEY = 'train'

AJ.Modules[KEY] = {
    start = function(src, st)
        local j = Config.Act.Jobs[KEY]
        local stations = AJ.pts(st, 'station')
        if #stations < 2 then return nil, 'Il faut au moins 2 stations (points d\'activité « Station » dans le Job Builder)' end
        st.idx, st.last = 2, 0       -- on part de la station 1 : prochain arrêt = station 2
        return { stations = stations, variation = j.variation, maxSpeed = j.maxSpeed, stopRadius = j.stopRadius, stopSpeed = j.stopSpeed, dwell = j.dwell }
    end,
    stop = function() end,
}

RegisterNetEvent('aj:train:stop', function(idx)
    local src = source
    local st = AJ.session(src, KEY)
    local stations = st and AJ.pts(st, 'station') or {}
    if not st or idx ~= st.idx or not stations[idx] then return end
    local j = Config.Act.Jobs[KEY]
    if not AJ.near(src, stations[idx], j.stopRadius + 40.0) then return end
    if os.time() - st.last < j.dwell then return end
    st.last = os.time()
    local paid = AJ.pay(src, KEY, j.payPerStop, 12, 'Arrêt en station', 1)
    AJ.notify(src, ('Arrêt « %s » effectué : %d $'):format(stations[idx].label ~= '' and stations[idx].label or ('station ' .. idx), paid), 'success')
    st.idx = idx + 1
    if st.idx > #stations then
        local b = AJ.pay(src, KEY, j.bonusLine, 50, 'Ligne terminée', 0)
        AJ.notify(src, ('Ligne terminée ! Prime : %d $'):format(b), 'success')
        AJ.stopShift(src, nil)
    end
end)
