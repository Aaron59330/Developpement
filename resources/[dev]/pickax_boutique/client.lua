-- Interface de la boutique à coins : ne contient aucune logique d'achat (tout passe par les exports de pickax_core, comme l'ancien menu)
local ESX = exports['es_extended']:getSharedObject()
local open = false
local points = 0

RegisterNetEvent('CorePickax:ReceiveClientSideBoutique', function(info)
    if info and info.points ~= nil then
        points = tonumber(info.points) or 0
        if open then SendNUIMessage({ action = 'points', points = points }) end
    end
end)

local function Close()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    TriggerEvent('pickax:inventory', false)       -- réaffiche les HUD
end

local function Open()
    if open or IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true then return end
    if GetResourceState('pickax_core') ~= 'started' then return end
    local ok, cat = pcall(function() return exports['pickax_core']:BoutiqueCatalog() end)
    if not ok or type(cat) ~= 'table' then
        ESX.ShowNotification('~r~Boutique indisponible pour le moment.')
        return
    end
    local d = promise.new()
    ESX.TriggerServerCallback('pickax_boutique:descs', function(res) d:resolve(res) end)
    local res = Citizen.Await(d)
    if type(res) == 'table' and res.ok then
        cat.dev = res.dev == true
        cat.dailyInfo = res.daily
        if res.boutiqueId then cat.boutiqueId = res.boutiqueId end
        for c in pairs({ vehicle = 1, moto = 1, other = 1, weapon = 1, crate = 1, pack = 1, business = 1 }) do
            for _, it in ipairs(cat[c] or {}) do
                local txt = res.map[c .. '|' .. tostring(it.model or it.name)]
                if txt then it.desc = txt end
            end
        end
    end
    open = true
    points = tonumber(cat.points) or points
    SetNuiFocus(true, true)
    TriggerEvent('pickax:inventory', true)        -- masque les HUD pendant la boutique
    local okS, st = pcall(function() return exports['pickax_core']:GetGlobalStyle() end)
    if okS and type(st) == 'table' and type(st.tebex) == 'string' and st.tebex ~= '' then cat.link = st.tebex end   -- TebexStore (pickax_core/config.lua)
    cat.accent = PickaxTheme and PickaxTheme.hex or nil          -- couleur du serveur (pickax_core/config.lua → AccentColor)
    SendNUIMessage({ action = 'open', data = cat })
end

exports('Open', Open)
exports('Close', Close)

CreateThread(function()
    while true do
        Wait(250)
        if open and (IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true) then Close() end
    end
end)

RegisterNUICallback('close', function(_, cb) Close() cb({}) end)

-- Appels serveur autorisés (historique, parrainage, codes, administration)
local Remote = { saveDesc = true, history = true, overview = true, redeem = true, previewCode = true,
    ['admin:data'] = true, ['admin:giveAll'] = true, ['admin:saveCode'] = true, ['admin:toggleCode'] = true, ['admin:deleteCode'] = true, ['admin:saveSettings'] = true }

RegisterNUICallback('rpc', function(body, cb)
    local name, args = body.name, body.args or {}
    if not Remote[name] then return cb({ ok = false, error = 'Appel inconnu' }) end
    ESX.TriggerServerCallback('pickax_boutique:' .. name, function(res) cb(res or { ok = false, error = 'Aucune réponse' }) end, table.unpack(args))
end)

-- Gestion des coins par joueur : mêmes appels serveur que le menu de base (pickax_core vérifie lui-même le droit d'administrer)
local CoreAdmin = { online = 'CorePickax:boutique:admin:online', search = 'CorePickax:boutique:admin:search', recent = 'CorePickax:boutique:admin:recent', coins = 'CorePickax:boutique:admin:coins', vip = 'CorePickax:boutique:admin:vip' }
RegisterNUICallback('coreadmin', function(body, cb)
    local name = CoreAdmin[body.name]
    if not name then return cb({ ok = false, error = 'Appel inconnu' }) end
    local a = body.args or {}
    ESX.TriggerServerCallback(name, function(r, extra)
        if body.name == 'vip' then cb({ ok = r == true, error = r ~= true and tostring(extra or 'Refusé') or nil, message = r == true and extra or nil })
        elseif body.name == 'coins' then cb({ ok = r == true, error = r ~= true and tostring(r == false and extra or 'Refusé') or nil, points = r == true and extra or nil })
        else cb({ ok = true, list = r or {} }) end
    end, a[1], a[2], a[3])
end)

-- Paiement du panier : le serveur contrôle les prix, la remise et le solde ; le client livre ensuite les articles un par un
local paying = false
RegisterNUICallback('checkout', function(body, cb)
    if paying then return cb({ ok = false, error = 'Un paiement est déjà en cours' }) end
    ESX.TriggerServerCallback('pickax_boutique:prepare', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Paiement impossible' }) end
        paying = true
        cb({ ok = true, count = #res.queue, final = res.final, total = res.total, pct = res.pct })
        CreateThread(function()
            local failed = 0
            for i, it in ipairs(res.queue) do
                SendNUIMessage({ action = 'checkoutProgress', i = i, n = #res.queue, name = it.name })
                TriggerServerEvent('pickax_boutique:arm', i)      -- le serveur applique la remise de cet article
                Wait(150)
                local ok, r = pcall(function() return exports['pickax_core']:BoutiqueBuy(it.cat, it.idx, true) end)
                if not ok or not r or not r.ok then failed = failed + 1 end
                Wait(Config.CheckoutSpacing or 3000)
            end
            TriggerServerEvent('pickax_boutique:done')
            paying = false
            SendNUIMessage({ action = 'checkoutDone', failed = failed })
        end)
    end, body.cart, body.code)
end)

-- achat direct d'un seul article = panier d'un article
RegisterNUICallback('buy', function(body, cb)
    if paying then return cb({ ok = false, error = 'Un paiement est déjà en cours' }) end
    local ok, res = pcall(function() return exports['pickax_core']:BoutiqueBuy(tostring(body.cat), tonumber(body.idx)) end)
    cb(ok and res or { ok = false, error = 'Achat impossible' })
end)

RegisterNUICallback('classic', function(_, cb)
    cb({})
    Close()
    SetTimeout(250, function() pcall(function() exports['pickax_core']:BoutiqueOpenClassic() end) end)
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and open then SetNuiFocus(false, false) TriggerEvent('pickax:inventory', false) end
end)
