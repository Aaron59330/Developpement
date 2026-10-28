-- ─────────────────────────────── Pègre (client) : marché noir, contrats de livraison ───────────────────────────────
local bm = { coords = nil, near = false, offers = {} }
local contract, cBlip = nil, nil

local function money(n) return ('%d $'):format(n) end

-- /marchenoir : indique où se trouve le vendeur du moment, et liste son stock quand on est sur place
RegisterCommand('marchenoir', function()
    ESX.TriggerServerCallback('illegalbuilder:bm:info', function(r)
        if not r or not r.ok then return Notify((r and r.error) or 'Indisponible', 'error') end
        bm.coords, bm.near, bm.offers = r.coords, r.near, r.offers
        if not r.near then
            SetNewWaypoint(r.coords.x + 0.0, r.coords.y + 0.0)
            return Notify(('On dit qu\'un vendeur est %s. Prochain changement dans %d h.'):format(r.hint or 'dans le coin', math.ceil(r.until_ / 3600)), 'info')
        end
        if #r.offers == 0 then return Notify('Il n\'a rien à vendre aujourd\'hui.', 'info') end
        Notify('Stock du jour — /acheter <n°> [quantité]', 'info')
        for _, o in ipairs(r.offers) do Notify(('%d · %s — %s%s'):format(o.id, o.label, money(o.price), o.rare and ' (rare)' or ''), 'info') end
    end)
end, false)

RegisterCommand('acheter', function(_, args)
    ESX.TriggerServerCallback('illegalbuilder:bm:buy', function(r)
        if not r or not r.ok then return Notify((r and r.error) or 'Impossible', 'error') end
        Notify(('Acheté : %d × %s pour %s'):format(r.qty, r.label, money(r.paid)), 'success')
    end, tonumber(args[1]), tonumber(args[2]) or 1)
end, false)

-- /contrat : prend une livraison ; /annulercontrat l'abandonne
local function clearContract()
    if cBlip and DoesBlipExist(cBlip) then RemoveBlip(cBlip) end
    cBlip, contract = nil, nil
end

RegisterCommand('contrat', function()
    ESX.TriggerServerCallback('illegalbuilder:contract:start', function(r)
        if not r or not r.ok then return Notify((r and r.error) or 'Impossible', 'error') end
        clearContract()
        contract = { coords = r.coords, endsAt = GetGameTimer() + r.limit * 1000, label = r.label }
        cBlip = AddBlipForCoord(r.coords.x + 0.0, r.coords.y + 0.0, r.coords.z + 0.0)
        SetBlipSprite(cBlip, 514); SetBlipColour(cBlip, 5); SetBlipRoute(cBlip, true); SetBlipRouteColour(cBlip, 5)
        BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName('Livraison'); EndTextCommandSetBlipName(cBlip)
        Notify(('Contrat : livre au %s en %d min %02d s.'):format(r.label or 'point indiqué', r.limit // 60, r.limit % 60), 'warning')
    end)
end, false)

RegisterCommand('annulercontrat', function()
    if contract then TriggerServerEvent('illegalbuilder:server:contractCancel') clearContract() Notify('Contrat abandonné.', 'info') end
end, false)

CreateThread(function()
    while true do
        if not contract then Wait(1500) else
            Wait(500)
            local p = GetEntityCoords(PlayerPedId())
            local c = contract.coords
            if GetGameTimer() > contract.endsAt then
                Notify('Temps écoulé : le client a annulé.', 'error')
                TriggerServerEvent('illegalbuilder:server:contractCancel')
                clearContract()
            elseif #(p - vector3(c.x, c.y, c.z)) < ((Config.Contracts or {}).Radius or 15.0) then
                local done = contract
                contract = nil
                ESX.TriggerServerCallback('illegalbuilder:contract:done', function(r)
                    clearContract()
                    if r and r.ok then Notify(('Livraison réussie : +%s%s'):format(money(r.reward), r.fast and ' (prime de rapidité)' or ''), 'success')
                    else Notify((r and r.error) or 'Livraison refusée.', 'error') end
                end)
            end
        end
    end
end)

-- vendeur : colonne lumineuse quand on est proche
CreateThread(function()
    while true do
        if not bm.coords then Wait(2000) else
            Wait(0)
            local c = bm.coords
            if #(GetEntityCoords(PlayerPedId()) - vector3(c.x, c.y, c.z)) < 25.0 then
                DrawMarker(1, c.x + 0.0, c.y + 0.0, c.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 1.4, 168, 85, 247, 200, false, false, 2, false, nil, nil, false)
            else Wait(800) end
        end
    end
end)
