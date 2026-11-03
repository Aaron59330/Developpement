-- Identité du serveur (couleur, nom, slogan, Discord, logo) lue dans pickax_core/config.lua, sinon valeurs par défaut.
-- Utilisation : dans le fxmanifest d'une ressource → shared_script '@pickax_theme/theme.lua'
--   PickaxTheme.hex ('#fdc27d'), PickaxTheme.rgb ({253,194,125}), PickaxTheme.r / .g / .b
--   PickaxTheme.name, .short, .tagline, .discord ('discord.gg/xxx'), .logo (nom de fichier ou lien)
PickaxTheme = PickaxTheme or {}

do
    local raw = LoadResourceFile('pickax_core', 'config.lua') or ''
    raw = raw:gsub('/%*.-%*/', ''):gsub('%-%-[^\n]*', '')                                -- ignore les commentaires
    local function str(key, default)
        local v = raw:match('[%s,{]' .. key .. "%s*=%s*'([^'\n]*)'") or raw:match('[%s,{]' .. key .. '%s*=%s*"([^"\n]*)"')
        if v and v ~= '' then return v end
        return default
    end
    local hex = str('AccentColor', '#fdc27d')
    if not hex:match('^#%x%x%x%x%x%x$') then hex = '#fdc27d' end
    PickaxTheme.hex = hex:lower()
    PickaxTheme.r = tonumber(hex:sub(2, 3), 16)
    PickaxTheme.g = tonumber(hex:sub(4, 5), 16)
    PickaxTheme.b = tonumber(hex:sub(6, 7), 16)
    PickaxTheme.rgb = { PickaxTheme.r, PickaxTheme.g, PickaxTheme.b }
    PickaxTheme.name = str('ServerName', 'Bluebay Roleplay')
    PickaxTheme.short = str('ServerShortName', 'BLUEBAY')
    PickaxTheme.tagline = str('ServerTagline', 'RP sérieux · Free-Access')
    PickaxTheme.discord = str('ServerDiscord', 'discord.gg/bluebayrp'):gsub('^https?://', '')
    PickaxTheme.logo = str('ServerLogo', 'logo.png')
    local inv = str('InventoryColor', '')
    -- Marker de tout le serveur (Config.GlobalMarker) et blips (Config.GlobalBlip) du config du core
    local function block(name)
        local a = raw:find('Config%.' .. name .. '%s*=%s*{')
        if not a then return nil end
        local b = raw:find('\n}', a, true)
        return raw:sub(a, b or #raw)
    end
    local gm = block('GlobalMarker')
    if gm then
        local t = tonumber(gm:match('[%s,{]Type%s*=%s*(%d+)'))
        local sz = gm:match('[%s,{]Size%s*=%s*{([^}]*)}')
        local co = gm:match('[%s,{]Color%s*=%s*{([^}]*)}')
        local function n(src, k, d) return tonumber(src and src:match(k .. '%s*=%s*(-?[%d%.]+)')) or d end
        PickaxTheme.marker = {
            type = t or 23,
            scale = { x = n(sz, 'x', 1.0), y = n(sz, 'y', 1.0), z = n(sz, 'z', 0.5) },
            color = (co and co:match('r%s*=%s*%d') and co:match('g%s*=%s*%d') and co:match('b%s*=%s*%d')) and { n(co, 'r', PickaxTheme.r), n(co, 'g', PickaxTheme.g), n(co, 'b', PickaxTheme.b) } or { PickaxTheme.r, PickaxTheme.g, PickaxTheme.b },
            alpha = math.floor(n(co, 'a', 150)),
        }
    end
    local gb = block('GlobalBlip')
    if gb then
        PickaxTheme.blipScale = tonumber(gb:match('[%s,{]Scale%s*=%s*([%d%.]+)'))
        local c = tonumber(gb:match('[%s,{]Color%s*=%s*(-?%d+)'))
        PickaxTheme.blipColor = (c and c >= 0) and c or nil
    end
    PickaxTheme.invHex = inv:match('^#%x%x%x%x%x%x$') and inv:lower() or PickaxTheme.hex
end

-- ─────────────── Aides communes à tout le serveur (client) : même aide « Appuie sur E… » et même marker partout ───────────────
--   PickaxTheme.Help('~INPUT_CONTEXT~ Ouvrir')           → aide pickax_notify (à appeler à chaque frame tant qu'elle doit rester visible)
--   PickaxTheme.Marker(x, y, z [, sx, sy, sz])             → marker au style du serveur (Config.GlobalMarker de pickax_core) ; taille optionnelle
if not IsDuplicityVersion() then
    function PickaxTheme.Help(msg)
        msg = tostring(msg or '')
        if GetResourceState('pickax_notify') == 'started' then exports['pickax_notify']:ShowHelpNotification(msg) return end
        BeginTextCommandDisplayHelp('STRING')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandDisplayHelp(0, false, false, -1)
    end

    function PickaxTheme.Marker(x, y, z, sx, sy, sz)
        local m = PickaxTheme.marker or {}
        local sc = m.scale or { x = 1.0, y = 1.0, z = 0.5 }
        local col = m.color or PickaxTheme.rgb
        DrawMarker(m.type or 1, x + 0.0, y + 0.0, z + 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            (sx or sc.x) + 0.0, (sy or sc.y) + 0.0, (sz or sc.z) + 0.0, col[1], col[2], col[3], m.alpha or 150, false, true, 2, false, nil, nil, false)
    end
end
