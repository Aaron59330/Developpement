-- ─────────────────────────────── Vente de drogue dans la rue (client) ───────────────────────────────
-- Appelée par le menu contextuel (pickax_core) : exports.pickax_illegalbuilder:StreetAvailable() pour afficher l'entrée,
-- exports.pickax_illegalbuilder:StreetSell(ped) pour proposer de la drogue à un PNJ. Les décisions (acceptation, quantité, prix, paiement) sont prises par le serveur.
local sold = {}      -- PNJ déjà sollicités (on ne harcèle pas le même)
local busy = false

local function tabletOk(cfg)
    if not cfg.tablet or cfg.tablet == '' then return true end
    local ok, n = pcall(function() return exports.ox_inventory:Search('count', cfg.tablet) end)
    return ok and (tonumber(n) or 0) > 0
end

-- L'entrée du menu contextuel s'affiche si la vente de rue est activée et que le joueur a la tablette vendeur (si elle est exigée)
exports('StreetAvailable', function()
    local cfg = (State.config or {}).street
    return cfg ~= nil and cfg.enabled == true and tabletOk(cfg)
end)

local function face(a, b)
    local c = GetEntityCoords(b)
    TaskTurnPedToFaceCoord(a, c.x, c.y, c.z, 800)
end

local function playExchange(ped)
    local me = PlayerPedId()
    face(me, ped); face(ped, me)
    SetPedTalk(ped)
    PlayAmbientSpeech1(ped, 'GENERIC_HI', 'SPEECH_PARAMS_STANDARD')
    Wait(700)
    RequestAnimDict('mp_common')
    local t = GetGameTimer() + 2000
    while not HasAnimDictLoaded('mp_common') and GetGameTimer() < t do Wait(0) end
    TaskPlayAnim(me, 'mp_common', 'givetake1_a', 8.0, -8.0, 1600, 48, 0, false, false, false)
    TaskPlayAnim(ped, 'mp_common', 'givetake1_a', 8.0, -8.0, 1600, 48, 0, false, false, false)
    Wait(1600)
    PlayAmbientSpeech1(ped, 'GENERIC_THANKS', 'SPEECH_PARAMS_STANDARD')
end

local function doSell(ped, item)
    busy = true
    ESX.TriggerServerCallback('illegalbuilder:street:sell', function(r)
        if not r or not r.ok then busy = false return Notify((r and r.error) or 'Impossible', 'error') end
        sold[ped] = true
        if not r.accepted then
            face(ped, PlayerPedId()); SetPedTalk(ped)
            PlayAmbientSpeech1(ped, 'GENERIC_INSULT_MED', 'SPEECH_PARAMS_STANDARD')
            busy = false
            return Notify('Le passant n\'est pas intéressé.', 'warning')
        end
        playExchange(ped)
        SetPedAsNoLongerNeeded(ped)
        busy = false
        Notify(('Vendu : %d × %s pour %s $%s'):format(r.qty, r.label or r.item, r.total, r.purity and (' (pureté ' .. r.purity .. ' %)') or ''), 'success')
        if r.levelUp then Notify(('Nouvelle réputation : %s !'):format(r.levelUp), 'success') end
        if (r.heat or 0) >= 60 then Notify('Le quartier est chaud : change de secteur.', 'warning')
        elseif (r.saturation or 0) >= 60 then Notify('Le quartier est saturé : les prix baissent.', 'warning') end
    end, item)
end

-- Articles proposables dans le menu : ceux que le joueur possède (le serveur revérifie tout à la vente)
exports('StreetItems', function()
    local cfg, out = (State.config or {}).street, {}
    if not cfg or cfg.enabled ~= true then return out end
    for _, it in ipairs(cfg.items or {}) do
        local ok, n = pcall(function() return exports.ox_inventory:Search('count', it.item) end)
        if ok and (tonumber(n) or 0) > 0 then out[#out + 1] = { item = it.item, label = it.label } end
    end
    return out
end)

exports('StreetSell', function(ped, item)
    if busy or type(item) ~= 'string' then return end
    if not ped or not DoesEntityExist(ped) or IsPedAPlayer(ped) or IsPedDeadOrDying(ped, true) then return end
    if sold[ped] then return Notify('Ce passant n\'est plus intéressé.', 'warning') end
    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ped)) > 3.5 then return Notify('Approche-toi du passant.', 'warning') end
    doSell(ped, item)
end)
