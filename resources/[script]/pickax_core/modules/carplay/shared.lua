-- Fonctions communes client / serveur : validation des liens (le client revérifie ce que lit l'état du véhicule : jamais d'URL arbitraire)
CarPlay = {}

local function lower(s) return tostring(s or ''):lower() end

-- Identifiant vidéo YouTube (11 caractères) ou nil
function CarPlay.ytId(url)
    url = tostring(url or '')
    local host = lower(url:match('^https?://([^/:?#@]+)') or '')
    if not (host == 'youtu.be' or host == 'youtube.com' or host:sub(-12) == '.youtube.com' or host == 'www.youtube.com') then return nil end
    local id = url:match('youtu%.be/([%w_%-]+)') or url:match('[?&]v=([%w_%-]+)') or url:match('/shorts/([%w_%-]+)')
        or url:match('/embed/([%w_%-]+)') or url:match('/live/([%w_%-]+)')
    if id and #id == 11 then return id end
    return nil
end

local function privateHost(h)
    if h == 'localhost' or h:sub(-6) == '.local' or h:sub(-9) == '.internal' or h == '0.0.0.0' or h:find('^%[') then return true end
    local a, b = h:match('^(%d+)%.(%d+)%.%d+%.%d+$')
    if a then
        a, b = tonumber(a), tonumber(b)
        return a == 10 or a == 127 or a == 0 or (a == 169 and b == 254) or (a == 192 and b == 168) or (a == 172 and b >= 16 and b <= 31) or (a == 100 and b >= 64 and b <= 127)
    end
    return false
end

-- Analyse d'un lien : retourne kind ('yt' | 'direct'), ref (id vidéo ou url) — ou nil, raison
function CarPlay.parse(url)
    if type(url) ~= 'string' then return nil, 'Lien invalide' end
    url = url:gsub('^%s+', ''):gsub('%s+$', '')
    if #url < 8 or #url > 300 or url:find('[%c%s]') then return nil, 'Lien invalide' end
    if not url:match('^https?://') then return nil, 'Le lien doit commencer par http(s)://' end
    local id = CarPlay.ytId(url)
    if id then return 'yt', id end
    if not Config.AllowDirectLinks then return nil, 'Seuls les liens YouTube sont acceptés' end
    local auth = url:match('^https?://([^/?#]+)') or ''
    if auth:find('@') then return nil, 'Lien invalide' end
    local host = lower(auth:match('^([^:]+)') or auth)
    if host == '' then return nil, 'Lien invalide' end
    if Config.BlockPrivateHosts and privateHost(host) then return nil, 'Adresse non autorisée' end
    for _, h in ipairs(Config.BlockedHosts or {}) do if host == lower(h) or host:sub(-#h - 1) == '.' .. lower(h) then return nil, 'Site non autorisé' end end
    local allow = Config.AllowedHosts or {}
    if #allow > 0 then
        local ok = false
        for _, h in ipairs(allow) do if host == lower(h) or host:sub(-#h - 1) == '.' .. lower(h) then ok = true break end end
        if not ok then return nil, 'Site non autorisé' end
    end
    return 'direct', url
end
