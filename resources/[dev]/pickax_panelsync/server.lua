-- Panel web -> serveur : couleur principale + logo. Rien n'est appliqué sans licence valide.
local C = PanelSync
local RES = GetCurrentResourceName()
local url = (C.Url ~= '' and C.Url or GetConvar('aero_panel_url', '')):gsub('/+$', '')
local key = C.Key ~= '' and C.Key or GetConvar('aero_panel_key', '')

local function log(m) print(('^5[panelsync]^7 %s'):format(m)) end
local function loadState() local ok, j = pcall(json.decode, LoadResourceFile(RES, 'state.json') or '{}') return ok and type(j) == 'table' and j or {} end
local function saveState(s) SaveResourceFile(RES, 'state.json', json.encode(s), -1) end

-- valeurs actuelles du thème (lues dans pickax_core/config.lua, comme pickax_theme)
local function currentTheme()
    local raw = (LoadResourceFile('pickax_core', 'config.lua') or ''):gsub('/%*.-%*/', ''):gsub('%-%-[^\n]*', '')
    local function str(k, d) local v = raw:match('[%s,{]' .. k .. "%s*=%s*'([^'\n]*)'") or raw:match('[%s,{]' .. k .. '%s*=%s*"([^"\n]*)"') return (v and v ~= '') and v or d end
    local inv = ''
    local ok, live = pcall(json.decode, LoadResourceFile('pickax_basetools', 'theme_live.json') or '{}')
    if ok and type(live) == 'table' and type(live.server) == 'table' and type(live.server.invColor) == 'string' then inv = live.server.invColor end
    return { AccentColor = str('AccentColor', '#fdc27d'), InventoryColor = inv, ServerName = str('ServerName', 'Serveur'), ServerShortName = str('ServerShortName', 'SERVEUR'),
        ServerTagline = str('ServerTagline', ''), ServerDiscord = str('ServerDiscord', ''), ServerLogo = str('ServerLogo', 'logo.png') }
end

local function get(path, cb) PerformHttpRequest(url .. path, function(code, body) cb(code, body) end, 'GET', '', {}) end

local function apply(t, logoFile)
    local v = currentTheme()
    if t.accent and t.accent:match('^#%x%x%x%x%x%x$') then v.AccentColor = t.accent:lower() end
    if logoFile then v.ServerLogo = logoFile end
    local r = exports.pickax_basetools:ApplyTheme(v, 'panel web', C.RestartCore == true)
    if r and r.ok then log(('thème appliqué (couleur %s%s)'):format(v.AccentColor, logoFile and ', logo ' .. logoFile or '')) else log('échec : ' .. tostring(r and r.error)) end
    return r and r.ok
end

local busy = false
local function check()
    if busy then return end
    if url == '' or key == '' then return end
    busy = true
    get('/api/agent/theme?key=' .. key, function(code, body)
        local ok, t = pcall(json.decode, body or '')
        if code ~= 200 or not ok or type(t) ~= 'table' or not t.ok then busy = false if code == 403 then log('licence refusée par le panel') end return end
        local st = loadState()
        if st.version == t.version then busy = false return end
        local function done(logoFile)
            if apply(t, logoFile) then st.version = t.version saveState(st) end
            busy = false
        end
        if t.logo and t.logo.url then
            get(t.logo.url, function(c2, img)
                if c2 ~= 200 or not img or #img < 100 then log('logo non téléchargé : thème appliqué sans logo') return done(nil) end
                local ext = (t.logo.type == 'image/png') and 'png' or 'jpg'
                local name = C.LogoFile .. '.' .. ext
                local saved = SaveResourceFile('pickax_theme', 'logo/' .. name, img, #img)
                if not saved then log('écriture du logo impossible : ajoute « add_filesystem_permission ' .. RES .. ' write pickax_theme » dans server.cfg') return done(nil) end
                done(name)
            end)
        else done(nil) end
    end)
end

CreateThread(function()
    if url == '' or key == '' then log('désactivé : renseigne aero_panel_url et aero_panel_key (server.cfg ou config.lua)') return end
    Wait(15000)   -- laisse démarrer pickax_basetools
    while true do check() Wait(math.max(15, C.IntervalSec or 60) * 1000) end
end)
