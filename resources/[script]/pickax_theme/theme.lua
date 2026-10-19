-- Lecture de la couleur principale définie dans pickax_theme/theme.js (même fichier de config pour le Lua et le NUI).
-- Utilisation : dans le fxmanifest d'une ressource → shared_script '@pickax_theme/theme.lua'
--               puis PickaxTheme.hex ('#00a4ff'), PickaxTheme.rgb ({0,164,255}), PickaxTheme.r / .g / .b
PickaxTheme = PickaxTheme or {}

do
    local hex = '#00a4ff'
    local raw = LoadResourceFile('pickax_theme', 'theme.js')
    if raw then
        raw = raw:gsub('/%*.-%*/', ''):gsub('//[^\n]*', '')                       -- ignore les commentaires
        local found = raw:match("PICKAX_ACCENT%s*=%s*['\"](#%x%x%x%x%x%x)['\"]")
        if found then hex = found end
    end
    PickaxTheme.hex = hex:lower()
    PickaxTheme.r = tonumber(hex:sub(2, 3), 16)
    PickaxTheme.g = tonumber(hex:sub(4, 5), 16)
    PickaxTheme.b = tonumber(hex:sub(6, 7), 16)
    PickaxTheme.rgb = { PickaxTheme.r, PickaxTheme.g, PickaxTheme.b }
end
