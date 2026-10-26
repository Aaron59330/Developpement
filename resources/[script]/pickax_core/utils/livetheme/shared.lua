-- Thème « vivant » : réglages faits depuis le panel web (Personnalisation) ou les outils de la base, mémorisés dans pickax_basetools/theme_live.json.
-- Ils sont appliqués à Config en mémoire (couleur, nom, marker global, blips) : tout le serveur les suit sans réécrire config.lua.
-- Si le fichier est absent ou invalide, rien ne change.
local function hexOk(h) return type(h) == 'string' and h:match('^#%x%x%x%x%x%x$') ~= nil end
local function num(v, lo, hi) v = tonumber(v) if not v then return nil end return math.max(lo, math.min(hi, v)) end

local function apply(live)
    if type(live) ~= 'table' or not Config then return false end
    if hexOk(live.accent) then Config.AccentColor = live.accent:lower() end
    local s = live.server
    if type(s) == 'table' then
        if hexOk(s.invColor) then Config.InventoryColor = s.invColor:lower() elseif s.invColor == '' then Config.InventoryColor = '' end
        for cfgKey, k in pairs({ ServerName = 'name', ServerShortName = 'short', ServerTagline = 'tagline', ServerDiscord = 'discord', ServerLogo = 'logo' }) do
            if type(s[k]) == 'string' and s[k] ~= '' then Config[cfgKey] = s[k] end
        end
    end
    local m = live.marker
    if type(m) == 'table' then
        Config.GlobalMarker = Config.GlobalMarker or { Enabled = true }
        local g = Config.GlobalMarker
        local t = num(m.type, 0, 43)
        if t then g.Type = math.floor(t) end
        if type(m.size) == 'table' then g.Size = { x = num(m.size.x, 0.1, 5) or 1.0, y = num(m.size.y, 0.1, 5) or 1.0, z = num(m.size.z, 0.1, 5) or 0.5 } end
        g.Color = g.Color or {}
        if type(m.color) == 'table' and num(m.color.r, 0, 255) and num(m.color.g, 0, 255) and num(m.color.b, 0, 255) then
            g.Color.r, g.Color.g, g.Color.b = math.floor(m.color.r), math.floor(m.color.g), math.floor(m.color.b)
        else
            g.Color.r, g.Color.g, g.Color.b = nil, nil, nil   -- couleur automatique = couleur principale du serveur
        end
        local a = num(m.alpha, 0, 255)
        if a then g.Color.a = math.floor(a) end
    end
    local b = live.blip
    if type(b) == 'table' then
        Config.GlobalBlip = Config.GlobalBlip or {}
        local sc = num(b.scale, 0.1, 3)
        if sc then Config.GlobalBlip.Scale = sc end
        local col = tonumber(b.color)
        if col then Config.GlobalBlip.Color = math.floor(col) end
    end
    return true
end

local function load()
    local raw = LoadResourceFile('pickax_basetools', 'theme_live.json')
    if not raw or raw == '' then return false end
    local ok, j = pcall(json.decode, raw)
    if not ok then return false end
    return apply(j)
end

load()
-- Côté joueur, pickax_basetools peut ne pas être encore chargé quand pickax_core démarre : on réessaie quelques fois
CreateThread(function()
    for _ = 1, 20 do
        Wait(3000)
        if load() then break end
    end
end)
