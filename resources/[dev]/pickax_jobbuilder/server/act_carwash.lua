local KEY = 'carwash'

-- Baies : points « bay » configurés, sinon alignées devant le dépôt
local function bays(st)
    local list = AJ.pts(st, 'bay')
    if #list > 0 then return list end
    local d = AJ.pts(st, 'depot')[1]
    if not d then return {} end
    local rad = math.rad(d.h)
    local fx, fy, rx, ry = -math.sin(rad), math.cos(rad), math.cos(rad), math.sin(rad)
    local out = {}
    for i = 1, Config.Act.Jobs[KEY].customers do
        local o = (i - 2) * 6.5
        out[i] = { x = d.x + fx * 10.0 + rx * o, y = d.y + fy * 10.0 + ry * o, z = d.z, h = (d.h + 90.0) % 360 }
    end
    return out
end

AJ.Modules[KEY] = {
    start = function(src, st)
        local list = bays(st)
        if #list == 0 then return nil, 'Dépôt non configuré' end
        st.bays, st.pending, st.last, st.nextId = list, {}, 0, 1
        return { bays = list, wash = Config.Act.Jobs[KEY].washSeconds }
    end,
    stop = function() end,
}

RegisterNetEvent('aj:carwash:request', function()
    local src = source
    local st = AJ.session(src, KEY)
    if not st then return end
    local j = Config.Act.Jobs[KEY]
    local n, used = 0, {}
    for _, c in pairs(st.pending) do n = n + 1 used[c.bay] = true end
    if n >= math.min(j.customers, #st.bays) or os.time() - st.last < j.interval * 0.7 then return end
    local bay
    for i = 1, #st.bays do if not used[i] then bay = i break end end
    if not bay then return end
    st.last = os.time()
    local id = st.nextId
    st.nextId = id + 1
    st.pending[id] = { bay = bay, t0 = os.time() }
    TriggerClientEvent('aj:carwash:customer', src, { id = id, bay = bay, model = j.models[math.random(#j.models)] })
end)

RegisterNetEvent('aj:carwash:done', function(id)
    local src = source
    local st = AJ.session(src, KEY)
    local c = st and st.pending[id]
    if not c then return end
    local j = Config.Act.Jobs[KEY]
    local elapsed = os.time() - c.t0
    if elapsed < j.washSeconds * 0.8 then return end                 -- lavage trop rapide pour être réel
    st.pending[id] = nil
    local limit = j.washSeconds * 3
    local quality = math.max(0.0, math.min(1.0, (limit - elapsed) / limit))
    local tip = math.floor(j.tipMax * quality * (0.5 + math.random() * 0.5))
    local paid = AJ.pay(src, KEY, j.payPerWash + tip, 12, 'Lavage', 1)
    AJ.notify(src, ('Voiture lavée : %d $ (pourboire %d $)'):format(paid, tip), 'success')
end)

RegisterNetEvent('aj:carwash:abandon', function(id)
    local st = AJ.session(source, KEY)
    if st then st.pending[id] = nil end
end)
