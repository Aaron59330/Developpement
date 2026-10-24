-- Style global du serveur (couleur, marker, blips) exposé aux autres ressources par export : lecture directe de Config (aucune lecture de fichier).
-- Utilisé par pickax_theme / les builders :  exports['pickax_core']:GetGlobalStyle()
exports('GetGlobalStyle', function()
    local gm, gb = Config.GlobalMarker or {}, Config.GlobalBlip or {}
    local c, s = gm.Color or {}, gm.Size or {}
    local bs = tonumber(gb.Scale)
    local bc = tonumber(gb.Color)
    return {
        hex = Config.AccentColor,
        name = Config.ServerName, short = Config.ServerShortName, tagline = Config.ServerTagline, discord = Config.ServerDiscord, logo = Config.ServerLogo,
        invColor = Config.InventoryColor,
        tebex = Config.TebexStore,
        marker = gm.Type and {
            type = tonumber(gm.Type) or 23,
            scale = { x = tonumber(s.x) or 1.0, y = tonumber(s.y) or 1.0, z = tonumber(s.z) or 0.5 },
            color = { tonumber(c.r) or 253, tonumber(c.g) or 194, tonumber(c.b) or 125 },
            alpha = math.floor(tonumber(c.a) or 150),
        } or nil,
        blipScale = bs,
        blipColor = (bc and bc >= 0) and bc or nil,
    }
end)
