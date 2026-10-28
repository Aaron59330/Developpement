-- ─────────────────────────────── Pègre (suite, client) : informateurs et prison ───────────────────────────────
local function money(n) return ('%d $'):format(n) end

-- /indic : parler à un informateur proche ; /tuyau <sujet> achète un tuyau
RegisterCommand('indic', function()
    ESX.TriggerServerCallback('illegalbuilder:informant:info', function(r)
        if not r or not r.ok then return Notify((r and r.error) or 'Indisponible', 'error') end
        if not r.near then return Notify('Aucun informateur ici. Ils traînent dans les coins sombres de la ville.', 'info') end
        if #r.offers == 0 then return Notify('Il n\'a rien à te vendre.', 'info') end
        Notify('Que veux-tu savoir ? /tuyau <sujet>', 'info')
        for _, o in ipairs(r.offers) do Notify(('%s — %s : /tuyau %s'):format(o.label, money(o.price), o.kind), 'info') end
    end)
end, false)

RegisterCommand('tuyau', function(_, args)
    ESX.TriggerServerCallback('illegalbuilder:informant:buy', function(r)
        if not r or not r.ok then return Notify((r and r.error) or 'Impossible', 'error') end
        Notify(('%s (%s)'):format(r.text, money(r.paid)), 'success')
        SetNewWaypoint(r.coords.x + 0.0, r.coords.y + 0.0)
    end, tostring(args[1] or ''))
end, false)

-- indic : petite marque quand on est tout près
CreateThread(function()
    while true do
        local locs = (Config.Informants or {}).Locations
        if not locs or (Config.Informants or {}).Enabled == false then Wait(3000) else
            local p = GetEntityCoords(PlayerPedId())
            local near = false
            for _, l in ipairs(locs) do
                if #(p - vector3(l.coords.x, l.coords.y, l.coords.z)) < 12.0 then
                    near = true
                    DrawMarker(1, l.coords.x + 0.0, l.coords.y + 0.0, l.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.5, 250, 204, 21, 160, false, false, 2, false, nil, nil, false)
                end
            end
            Wait(near and 0 or 700)
        end
    end
end)

-- prison : la peine, la tenue et le minuteur sont ceux de pickax_core ; ici seulement les postes de travail qui la réduisent
local jailed = false

RegisterNetEvent('CorePickax:SetJail', function() jailed = true end)
RegisterNetEvent('CorePickax:unjailPlayer', function() jailed = false end)

local function text(y, str, r, g, b)
    SetTextFont(4); SetTextScale(0.0, 0.4); SetTextColour(r, g, b, 235); SetTextOutline(); SetTextCentre(true)
    BeginTextCommandDisplayText('STRING'); AddTextComponentSubstringPlayerName(str); EndTextCommandDisplayText(0.5, y)
end

CreateThread(function()
    while true do
        if not jailed or (Config.Prison or {}).Enabled == false then Wait(1500) else
            Wait(0)
            local p = GetEntityCoords(PlayerPedId())
            for _, s in ipairs(((Config.Prison or {}).Work or {}).Spots or {}) do
                local c = s.coords
                if #(p - vector3(c.x, c.y, c.z)) < 15.0 then
                    DrawMarker(1, c.x + 0.0, c.y + 0.0, c.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.5, 74, 222, 128, 170, false, false, 2, false, nil, nil, false)
                    if #(p - vector3(c.x, c.y, c.z)) < 2.0 then
                        text(0.88, ('[E] Travailler — %s'):format(s.label or 'atelier'), 74, 222, 128)
                        if IsControlJustReleased(0, 38) then
                            ESX.TriggerServerCallback('illegalbuilder:jail:work', function(r)
                                if not r or not r.ok then return Notify((r and r.error) or 'Impossible', 'error') end
                                Notify(('Travail effectué : peine réduite de %d s.'):format(r.cut), 'success')
                            end)
                        end
                    end
                end
            end
        end
    end
end)
