local ESX = exports['es_extended']:getSharedObject()
local C = Config
-- ───────────── Rôle du joueur (noms de jobs ESX ou type du Job Builder) ─────────────
local function hasRole(names, types)
    local d = ESX.GetPlayerData()
    local job = d and d.job and d.job.name
    for _, n in ipairs(names or {}) do if job == n then return true end end
    if types and #types > 0 and GetResourceState('pickax_jobbuilder') == 'started' then
        local ok, t = pcall(function() return exports.pickax_jobbuilder:GetJobType() end)
        if ok and t then for _, x in ipairs(types) do if t == x then return true end end end
    end
    return false
end

local function notify(kind, txt) lib.notify({ type = kind, description = txt, duration = 7000 }) end
local function res(r) if r and r.ok then notify(r.warranted == false and 'warning' or (r.over or r.fake) and 'error' or 'success', r.msg or 'OK') else notify('error', (r and r.error) or 'Impossible') end end

local function nearestPlayer(maxDist)
    local me, best, bd = PlayerPedId(), nil, maxDist
    local mc = GetEntityCoords(me)
    for _, p in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(p)
        if ped ~= me then local d = #(mc - GetEntityCoords(ped)) if d < bd then best, bd = GetPlayerServerId(p), d end end
    end
    return best
end

-- ───────────── Mandats ─────────────
local function newWarrant()
    local input = lib.inputDialog('Délivrer un mandat', {
        { type = 'select', label = 'Type', required = true, options = { { value = 'search', label = 'Perquisition' }, { value = 'arrest', label = 'Arrestation' } }, default = 'search' },
        { type = 'input', label = 'Personne visée (nom complet)', required = true, max = 100 },
        { type = 'textarea', label = 'Motif', required = true, max = 300 },
        { type = 'input', label = 'Lieu (facultatif)', max = 120 },
    })
    if not input then return end
    ESX.TriggerServerCallback('pickax_justice:warrantCreate', res, input[1], input[2], input[3], input[4] or '')
end
if C.UseCommands then RegisterCommand(C.Warrants.Command, function() newWarrant() end, false) end
exports('NewWarrant', newWarrant)

local function showWarrants()
    ESX.TriggerServerCallback('pickax_justice:warrantList', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Indisponible') end
        if #r.rows == 0 then return notify('inform', 'Aucun mandat actif.') end
        local opts = {}
        for _, w in ipairs(r.rows) do
            opts[#opts + 1] = { title = ('#%d — %s : %s'):format(w.id, w.kind == 'arrest' and 'Arrestation' or 'Perquisition', w.subject), description = ('%s · par %s · expire le %s%s'):format(w.reason, w.issued_by, w.expires, w.place and (' · ' .. w.place) or ''),
                icon = w.kind == 'arrest' and 'handcuffs' or 'house-lock', onSelect = function()
                    local choice = lib.alertDialog({ header = ('Mandat #%d'):format(w.id), content = ('**%s**\n\n%s'):format(w.subject, w.reason), centered = true, cancel = true, labels = { confirm = r.judge and 'Annuler le mandat' or 'Marquer exécuté', cancel = 'Fermer' } })
                    if choice == 'confirm' then ESX.TriggerServerCallback('pickax_justice:warrantSet', res, w.id, r.judge and 'revoke' or 'execute') end
                end }
        end
        lib.registerContext({ id = 'pk_warrants', title = 'Mandats actifs', options = opts })
        lib.showContext('pk_warrants')
    end)
end
if C.UseCommands then RegisterCommand(C.Warrants.ListCommand, function() showWarrants() end, false) end
exports('ShowWarrants', showWarrants)

-- ───────────── Saisies ─────────────
local function seize(forced, args)
    args = args or {}
    local target = forced or tonumber(args[1]) or nearestPlayer(C.Seizures.Distance)
    if not target then return notify('error', 'Personne à proximité.') end
    local note = table.concat(args, ' ', tonumber(args[1]) and 2 or 1)
    if note == '' then
        local input = lib.inputDialog('Saisie', { { type = 'input', label = 'Objets saisis', required = true, max = 300 } })
        if not input then return end
        note = input[1]
    end
    ESX.TriggerServerCallback('pickax_justice:seize', res, target, note)
end
if C.UseCommands then RegisterCommand(C.Seizures.Command, function(_, args) seize(nil, args) end, false) end

local function showSeizures()
    ESX.TriggerServerCallback('pickax_justice:seizureList', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Indisponible') end
        local opts = {}
        for _, s in ipairs(r.rows) do
            opts[#opts + 1] = { title = ('#%d — %s'):format(s.id, s.target), description = ('%s · %s · %s'):format(s.note, s.officer, s.date), icon = s.contestable and 'triangle-exclamation' or 'check',
                metadata = { { label = 'Mandat', value = s.contestable and 'AUCUN — contestable' or ('n°' .. s.warrant_id) } } }
        end
        lib.registerContext({ id = 'pk_seizures', title = 'Journal des saisies', options = opts })
        lib.showContext('pk_seizures')
    end)
end
if C.UseCommands then RegisterCommand(C.Seizures.ListCommand, function() showSeizures() end, false) end
exports('ShowSeizures', showSeizures)

-- ───────────── Alcootest ─────────────
local function breath(forced, args)
    local target = forced or tonumber(args and args[1]) or nearestPlayer(C.Alcohol.Distance)
    if not target then return notify('error', 'Personne à proximité.') end
    if not lib.progressBar({ duration = C.Alcohol.Seconds * 1000, label = 'Alcootest…', canCancel = true, disable = { move = true }, anim = { dict = 'mp_common', clip = 'givetake1_a' } }) then return end
    ESX.TriggerServerCallback('pickax_justice:breath', res, target)
end
if C.UseCommands then RegisterCommand(C.Alcohol.Command, function(_, args) breath(nil, args) end, false) end

-- ───────────── Contrôle des papiers ─────────────
local function papers(forced, args)
    local target = forced or tonumber(args and args[1]) or nearestPlayer(C.Papers.Distance)
    if not target then return notify('error', 'Personne à proximité.') end
    notify('inform', 'Contrôle en cours…')
    ESX.TriggerServerCallback('pickax_justice:papers', res, target)
end
if C.UseCommands then RegisterCommand(C.Papers.Command, function(_, args) papers(nil, args) end, false) end

-- Le contrôlé choisit le document qu'il présente
RegisterNetEvent('pickax_justice:ask', function(officer, seconds)
    local choice = lib.alertDialog({ header = 'Contrôle d\'identité', content = ('**%s** te demande tes papiers. Quel document présentes-tu ?\n\n_Sans réponse en %d s, tu présentes ton vrai document._'):format(officer, seconds), centered = true, cancel = true, labels = { confirm = 'Vrai document', cancel = 'Faux document' } })
    TriggerServerEvent('pickax_justice:answer', choice == 'cancel' and 'fake' or 'real')
end)

-- ───────────── Menu contextuel : clic droit sur une personne (police) ─────────────
local CTX_ACTIONS = {
    { id = 'papers', label = 'Contrôler les papiers',    target = 'player' },
    { id = 'breath', label = 'Alcootest',                target = 'player' },
    { id = 'seize',  label = 'Enregistrer une saisie',   target = 'player' },
}
exports('ContextCan', function(id, ent) return ent ~= PlayerPedId() and hasRole(C.Police.Jobs, C.Police.Types) end)
exports('ContextDo', function(id, ent)
    local sid = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ent))
    if not sid or sid <= 0 then return end
    if id == 'papers' then papers(sid) elseif id == 'breath' then breath(sid) else seize(sid) end
end)
local function registerContext() exports.pickax_core:RegisterContextActions(GetCurrentResourceName(), CTX_ACTIONS) end
CreateThread(function() Wait(2500) registerContext() end)
AddEventHandler('onResourceStart', function(r) if r == 'pickax_core' then SetTimeout(2500, registerContext) end end)
