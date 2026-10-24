local KEY = 'farmer'
local run = 0

AJ.Mod[KEY] = {
    start = function(d)
        run = run + 1
        local my = run
        local plots, objs = {}, {}
        local order = {}
        for k in pairs(d.crops) do order[#order + 1] = k end
        table.sort(order)
        local sel = 1
        local f = d.field
        local count = d.rows * d.cols

        local function plotPos(i)
            local row, col = (i - 1) // d.cols, (i - 1) % d.cols
            return f.x + (col - (d.cols - 1) / 2) * d.spacing, f.y + (row - (d.rows - 1) / 2) * d.spacing
        end
        local function groundZ(x, y)
            local ok, z = GetGroundZFor_3dCoord(x, y, f.z + 8.0, false)
            return ok and z or f.z
        end

        local function setPlots(list)
            plots = {}
            for _, p in ipairs(list or {}) do plots[p.plot] = p end
        end
        setPlots(d.plots)
        RegisterNetEvent('aj:farm:plots', function(list) if run == my then setPlots(list) end end)

        AJ.Blip(f, 479, 2, 'Champ', true)
        AJ.Blip(d.market, 52, 5, 'Marché', false)
        if d.spawn and d.tractor then AJ.SpawnVehicle(d.tractor, d.spawn, 'FERME', false) end

        local function crop() return d.crops[order[sel]] end
        local function hud()
            local c = crop()
            local seeds = exports.ox_inventory:Search('count', c.seed) or 0
            AJ.SetHud({ 'FERMIER', ('Culture : %s  (G pour changer)'):format(c.label), ('Graines : %d'):format(seeds), 'Sème → arrose → récolte → vends au marché' })
        end

        -- rendu des plantes
        CreateThread(function()
            while run == my and AJ.Active == KEY do
                local pos = GetEntityCoords(PlayerPedId())
                for i = 1, count do
                    local x, y = plotPos(i)
                    local p = plots[i]
                    local near = #(pos - vector3(x, y, f.z)) < 90.0
                    local o = objs[i]
                    if p and near then
                        local model = d.crops[p.crop].models[p.stage]
                        if not o or o.model ~= model then
                            if o and DoesEntityExist(o.e) then DeleteEntity(o.e) end
                            local h = AJ.LoadModel(model)
                            if h then
                                local e = CreateObject(h, x, y, groundZ(x, y), false, false, false)
                                PlaceObjectOnGroundProperly(e) FreezeEntityPosition(e, true) SetModelAsNoLongerNeeded(h)
                                objs[i] = { e = e, model = model }
                            end
                        end
                    elseif o and (not p or not near) then
                        if DoesEntityExist(o.e) then DeleteEntity(o.e) end
                        objs[i] = nil
                    end
                end
                Wait(1500)
            end
        end)

        -- interactions
        CreateThread(function()
            while run == my and AJ.Active == KEY do
                local sleep = 500
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                hud()
                if #(pos - vector3(f.x, f.y, f.z)) < (d.rows + d.cols) * d.spacing + 20.0 then
                    sleep = 0
                    if IsControlJustPressed(0, 47) then sel = sel % #order + 1 end
                    for i = 1, count do
                        local x, y = plotPos(i)
                        local z = groundZ(x, y)
                        local dist = #(pos - vector3(x, y, z))
                        if dist < 14.0 then
                            local p = plots[i]
                            local r, g, b = 120, 90, 50
                            if p then if p.ready then r, g, b = 80, 220, 90 else r, g, b = 0, 164, 255 end end
                            DrawMarker(1, x, y, z - 0.02, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 0.15, r, g, b, 120, false, false, 2, false, nil, nil, false)
                            if dist < 1.5 and not IsPedInAnyVehicle(ped, false) then
                                if not p then
                                    AJ.Help(('~INPUT_PICKUP~ Semer du %s'):format(crop().label:lower()))
                                    if IsControlJustPressed(0, Config.Act.Interact) then
                                        if AJ.Progress('Semis', 3, { scenario = 'WORLD_HUMAN_GARDENER_PLANT', radius = 3.0 }) then TriggerServerEvent('aj:farm:sow', i, order[sel]) end
                                    end
                                elseif p.ready then
                                    AJ.Help('~INPUT_PICKUP~ Récolter')
                                    if IsControlJustPressed(0, Config.Act.Interact) then
                                        if AJ.Progress('Récolte', 3.5, { scenario = 'WORLD_HUMAN_GARDENER_PLANT', radius = 3.0 }) then TriggerServerEvent('aj:farm:harvest', i) end
                                    end
                                elseif not p.watered then
                                    AJ.Help(('~INPUT_PICKUP~ Arroser (pousse plus vite) — prêt dans %d min'):format(math.ceil(p.left / 60)))
                                    if IsControlJustPressed(0, Config.Act.Interact) then
                                        if AJ.Progress('Arrosage', 3, { scenario = 'WORLD_HUMAN_BUM_WASH', radius = 3.0 }) then TriggerServerEvent('aj:farm:water', i) end
                                    end
                                else
                                    AJ.Text3D(x, y, z + 1.0, ('%s · prêt dans %d min'):format(d.crops[p.crop].label, math.ceil(p.left / 60)), 0.3)
                                end
                            end
                        end
                    end
                end
                -- marché : vente et achat de graines
                local md = #(pos - vector3(d.market.x, d.market.y, d.market.z))
                if md < Config.Act.DrawDistance then
                    sleep = 0
                    AJ.Marker(d.market, 1, 255, 190, 0)
                    if md < 3.0 then
                        local c = crop()
                        AJ.Help(('~INPUT_PICKUP~ Vendre la récolte    ~INPUT_VEH_HEADLIGHT~ Acheter 10 graines de %s (%d $)'):format(c.label:lower(), c.seedPrice * 10))
                        if IsControlJustPressed(0, Config.Act.Interact) then TriggerServerEvent('aj:farm:sell') end
                        if IsControlJustPressed(0, 74) then TriggerServerEvent('aj:farm:buy', order[sel], 10) end
                    end
                end
                Wait(sleep)
            end
        end)
    end,
    stop = function() run = run + 1 end,
}
