-- Lecture de la couleur principale définie dans pickax_core/config.lua (Config.AccentColor), sinon pickax_theme/theme.js.
-- Utilisation : dans le fxmanifest d'une ressource → shared_script '@pickax_theme/theme.lua'
--               puis PickaxTheme.hex ('#00a4ff'), PickaxTheme.rgb ({0,164,255}), PickaxTheme.r / .g / .b
PickaxTheme = PickaxTheme or {}

do
    local hex = '#00a4ff'
    local function read(res, file, key)
        local raw = LoadResourceFile(res, file)
        if not raw then return nil end
        raw = raw:gsub('/%*.-%*/', ''):gsub('%-%-[^\n]*', ''):gsub('//[^\n]*', '')     -- ignore les commentaires
        return raw:match(key .. "%s*=%s*['\"](#%x%x%x%x%x%x)['\"]")
    end
    -- priorité : Config.AccentColor du core (pickax_core/config.lua), sinon la ligne de pickax_theme/theme.js
    hex = read('pickax_core', 'config.lua', 'AccentColor') or read('pickax_theme', 'theme.js', 'PICKAX_ACCENT') or hex
    PickaxTheme.hex = hex:lower()
    PickaxTheme.r = tonumber(hex:sub(2, 3), 16)
    PickaxTheme.g = tonumber(hex:sub(4, 5), 16)
    PickaxTheme.b = tonumber(hex:sub(6, 7), 16)
    PickaxTheme.rgb = { PickaxTheme.r, PickaxTheme.g, PickaxTheme.b }
end
