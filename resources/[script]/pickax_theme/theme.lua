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
            color = { n(co, 'r', 64), n(co, 'g', 224), n(co, 'b', 208) },
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
