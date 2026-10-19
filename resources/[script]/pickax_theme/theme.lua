-- Identité du serveur (couleur, nom, slogan, Discord, logo) lue dans pickax_core/config.lua, sinon valeurs par défaut.
-- Utilisation : dans le fxmanifest d'une ressource → shared_script '@pickax_theme/theme.lua'
--   PickaxTheme.hex ('#00a4ff'), PickaxTheme.rgb ({0,164,255}), PickaxTheme.r / .g / .b
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
    local hex = str('AccentColor', '#00a4ff')
    if not hex:match('^#%x%x%x%x%x%x$') then hex = '#00a4ff' end
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
    PickaxTheme.invHex = inv:match('^#%x%x%x%x%x%x$') and inv:lower() or PickaxTheme.hex
end
