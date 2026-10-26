-- ─────────────────────────────── Pickax Guard ───────────────────────────────
-- 1) vérifie la licence auprès du panel (réponse signée Ed25519, liée à un nonce : impossible de la rejouer ou de la fabriquer) ;
-- 2) tant que la licence n'est pas valide, empêche le démarrage des ressources protégées (onResourceStarting annulé) puis les relance dans l'ordre ;
-- 3) si la licence devient invalide (révoquée, expirée, clé retirée), arrête les ressources protégées.
local SELF = GetCurrentResourceName()
local VERSION = GetResourceMetadata(SELF, 'version', 0) or '1.0.0'
local state = { ok = false, reason = 'démarrage', plan = nil, expires_at = nil, valid_until = 0, checked = 0, token = nil }
local held, heldSet = {}, {}
local releasing = false
local KEY = GetConvar('aero_panel_key', '')
local URL = (GetConvar('aero_panel_url', '') or ''):gsub('/+$', '')

local REASONS = {
    ['clé absente']      = 'Aucune clé de licence : ajoute  set aero_panel_key "AERO-XXXXXX-XXXXXX-XXXXXX-XXXXXX"  dans ton server.cfg (la clé est dans ton panel > Licence & installation).',
    ['url absente']      = 'Adresse du panel absente : ajoute  set aero_panel_url "https://…"  dans ton server.cfg.',
    ['clé publique']     = 'pickax_guard/config.lua : Config.PublicKey est vide (panel web > Administration > Protection de la base).',
    ['signature']        = 'La réponse du panel n\'est pas authentique (mauvaise adresse de panel, ou panel non officiel).',
    ['réponse invalide'] = 'Réponse du panel illisible.',
    ['panel injoignable'] = 'Panel injoignable et aucune vérification récente en mémoire.',
    unknown  = 'Clé de licence inconnue.',
    expired  = 'Licence expirée : renouvelle-la depuis ton espace client.',
    suspended = 'Licence suspendue.',
    revoked  = 'Licence révoquée.',
    ip       = 'Licence déjà utilisée depuis une autre adresse IP : délie-la depuis ton panel (Licence & installation).',
}

local function say(color, msg) print(('^%d[AERO]^7 %s'):format(color, msg)) end

local function isProtected(name)
    if type(name) ~= 'string' or name == SELF then return false end
    for _, ex in ipairs(Config.Exclude) do if ex == name then return false end end
    if name:sub(1, #Config.Prefix) == Config.Prefix then return true end
    for _, n in ipairs(Config.Protect) do if n == name then return true end end
    return false
end

local function protectedNames()
    local out = {}
    for i = 0, GetNumResources() - 1 do local n = GetResourceByFindIndex(i) if isProtected(n) then out[#out + 1] = n end end
    return out
end

local function hold(name) if not heldSet[name] then heldSet[name] = true held[#held + 1] = name end end

-- ─────────────── Démarrage des ressources protégées ───────────────
-- Tant que la licence n'est pas valide, on annule leur démarrage ; dès qu'elle l'est, on les relance dans l'ordre où elles ont été demandées.
AddEventHandler('onResourceStarting', function(name)
    if not state.ok and isProtected(name) then hold(name) CancelEvent() end
end)

local function release()
    if releasing then return end
    releasing = true
    CreateThread(function()
        while #held > 0 and state.ok do
            local name = table.remove(held, 1)
            heldSet[name] = nil
            ExecuteCommand('ensure ' .. name)
            local t = 0
            while t < 150 and GetResourceState(name) == 'starting' do Wait(100) t = t + 1 end
            Wait(150)
        end
        releasing = false
    end)
end

local function stopProtected(why)
    local n = 0
    for _, name in ipairs(protectedNames()) do
        local st = GetResourceState(name)
        if st == 'started' or st == 'starting' then hold(name) StopResource(name) n = n + 1 end
    end
    if n > 0 then say(1, ('%d ressource(s) de la base arrêtée(s) : %s'):format(n, why)) end
end

-- ─────────────── État ───────────────
local lastBanner = 0
local function setBad(reason, detail)
    local was = state.ok
    state.ok, state.reason, state.valid_until, state.token = false, reason, 0, nil
    local now = os.time()
    if was or now - lastBanner > 55 then
        lastBanner = now
        say(1, '^1LICENCE INVALIDE^7 — ' .. (REASONS[reason] or REASONS[detail or ''] or tostring(detail or reason)))
        say(1, 'La base ne démarre pas tant que la licence n\'est pas valide.')
    end
    if was then stopProtected('licence invalide') end
end

local function setOk(payload, source, resp)
    local was = state.ok
    state.token = resp
    state.ok, state.reason, state.plan, state.expires_at = true, source or 'panel', payload.plan, payload.expires_at
    state.valid_until = (tonumber(payload.iat) or os.time()) + (tonumber(payload.grace) or 86400)
    state.checked = os.time()
    if not was then say(2, ('Licence valide (%s) — démarrage de la base.'):format(payload.plan or 'plan inconnu')) end
    if #held > 0 then release() end
end

-- vérifie une réponse signée du panel ; renvoie la charge utile ou nil, raison
local function open(resp, nonce, cached)
    if type(resp) ~= 'table' or type(resp.payload) ~= 'string' or type(resp.sig) ~= 'string' then return nil, 'réponse invalide' end
    local good = exports[SELF]:Verify(resp.payload, resp.sig, Config.PublicKey)
    if good ~= true then return nil, 'signature' end
    local ok, p = pcall(json.decode, resp.payload)
    if not ok or type(p) ~= 'table' then return nil, 'réponse invalide' end
    if p.kh ~= exports[SELF]:KeyHash(KEY) then return nil, 'signature' end
    if nonce and p.nonce ~= nonce then return nil, 'signature' end
    if not cached and math.abs(os.time() - (tonumber(p.iat) or 0)) > 900 then return nil, 'signature' end   -- réponse trop ancienne (rejouée) ou horloge du serveur décalée
    return p
end

local function useCache()
    local raw = LoadResourceFile(SELF, 'cache.json')
    if raw and raw ~= '' then
        local ok, resp = pcall(json.decode, raw)
        if ok then
            local p = open(resp, nil, true)   -- le cache n'est pas lié à un nonce ; la signature, l'empreinte de la clé et la durée de grâce restent contrôlées
            if p and p.valid == true and os.time() < (tonumber(p.iat) or 0) + (tonumber(p.grace) or 0) then setOk(p, 'cache', resp) return true end
        end
    end
    return false
end

-- ─────────────── Vérification auprès du panel ───────────────
local function check()
    if KEY == '' or KEY:find('^%s*$') then return setBad('clé absente') end
    if URL == '' then return setBad('url absente') end
    if Config.PublicKey == '' then return setBad('clé publique') end
    local nonce = exports[SELF]:Random(32)
    PerformHttpRequest(URL .. '/api/agent/verify', function(status, text)
        if status ~= 200 or not text then
            if useCache() then return end
            return setBad('panel injoignable', 'Panel injoignable (' .. tostring(status) .. ') et aucune vérification récente en mémoire.')
        end
        local okJson, resp = pcall(json.decode, text)
        local p, why = open(okJson and resp or nil, nonce)
        if not p then return setBad(why) end
        if p.valid == true then
            SaveResourceFile(SELF, 'cache.json', text, -1)
            setOk(p, 'panel', resp)
        else
            setBad(p.status or 'unknown', p.status)
        end
    end, 'POST', json.encode({ nonce = nonce, host = GetConvar('sv_hostname', ''), build = VERSION }), { ['Content-Type'] = 'application/json', ['X-License-Key'] = KEY })
end

CreateThread(function()
    Wait(500)
    stopProtected('démarrage sans licence vérifiée')   -- ressources déjà démarrées avant le guard (ordre du resources.cfg)
    check()
    while true do
        Wait(state.ok and (Config.Interval * 1000 + math.random(0, 20000)) or (Config.RetryInterval * 1000))
        check()
    end
end)

-- ─────────────── Exports ───────────────
exports('IsLicensed', function() return state.ok == true and os.time() < state.valid_until end)
-- point de contrôle appelé par les ressources de la base : renvoie true seulement si la licence est valide
exports('Check', function(resource) return state.ok == true and os.time() < state.valid_until end)
-- réponse signée du panel (jeton) : les ressources de la base la vérifient ELLES-MÊMES (clé publique embarquée), un faux guard ne peut pas la fabriquer
exports('Token', function() if state.ok == true and os.time() < state.valid_until then return state.token end return nil end)
exports('Status', function() return { ok = state.ok, reason = state.reason, plan = state.plan, expires_at = state.expires_at, checked = state.checked } end)

-- Une ressource protégée qui se lancerait malgré tout (démarrage forcé) est arrêtée aussitôt.
AddEventHandler('onResourceStart', function(name)
    if not state.ok and isProtected(name) then
        hold(name)
        SetTimeout(0, function() StopResource(name) end)
    end
end)
