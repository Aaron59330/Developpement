-- Charge l'identité commune (couleur / nom / logo / marker / blips) SANS dépendre du démarrage de pickax_theme.
-- Ordre : 1) export direct de pickax_core (Config en mémoire, fiable)  2) lecture de pickax_core/config.lua via pickax_theme/theme.lua
-- Si rien n'est disponible, PickaxTheme reste nil et chaque config utilise ses valeurs par défaut.
if not PickaxTheme then
    local code = LoadResourceFile('pickax_theme', 'theme.lua')
    local fn = code and load(code, '@pickax_theme/theme.lua')
    if fn then pcall(fn) end

    local ok, st = pcall(function() return exports['pickax_core']:GetGlobalStyle() end)
    if ok and type(st) == 'table' then
        PickaxTheme = PickaxTheme or {}
        local function hexOk(h) return type(h) == 'string' and h:match('^#%x%x%x%x%x%x$') end
        if hexOk(st.hex) then
            PickaxTheme.hex = st.hex:lower()
            PickaxTheme.r, PickaxTheme.g, PickaxTheme.b = tonumber(st.hex:sub(2, 3), 16), tonumber(st.hex:sub(4, 5), 16), tonumber(st.hex:sub(6, 7), 16)
            PickaxTheme.rgb = { PickaxTheme.r, PickaxTheme.g, PickaxTheme.b }
        end
        for k, v in pairs({ name = st.name, short = st.short, tagline = st.tagline, discord = st.discord, logo = st.logo }) do
            if type(v) == 'string' and v ~= '' then PickaxTheme[k] = v end
        end
        if hexOk(st.invColor) then PickaxTheme.invHex = st.invColor:lower() end
        if type(st.marker) == 'table' then PickaxTheme.marker = st.marker end
        if st.blipScale then PickaxTheme.blipScale = st.blipScale end
        PickaxTheme.blipColor = st.blipColor
        PickaxTheme.viaExport = true
    end

    -- Diagnostic (console serveur) : confirme ce que cette ressource a réellement lu
    if IsDuplicityVersion() then
        CreateThread(function()
            Wait(2000)
            local res = GetCurrentResourceName()
            if PickaxTheme and PickaxTheme.blipScale then
                print(('^2[%s] réglages globaux lus (%s) : blips x%s, marker %s^0'):format(res, PickaxTheme.viaExport and 'export pickax_core' or 'fichier config.lua',
                    tostring(PickaxTheme.blipScale), PickaxTheme.marker and tostring(PickaxTheme.marker.type) or '?'))
            else
                print(('^3[%s] réglages globaux (pickax_core/config.lua) NON lus : valeurs par défaut utilisées. Vérifie que pickax_core démarre AVANT cette ressource.^0'):format(res))
            end
        end)
    end
end
