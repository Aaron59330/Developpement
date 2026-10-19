-- Charge l'identité commune (couleur / nom / logo : pickax_theme/theme.lua) SANS dépendre du démarrage de pickax_theme.
-- Si pickax_theme est absent ou arrêté, PickaxTheme reste nil et chaque config utilise ses valeurs par défaut.
if not PickaxTheme then
    local code = LoadResourceFile('pickax_theme', 'theme.lua')
    local fn = code and load(code, '@pickax_theme/theme.lua')
    if fn then pcall(fn) end
end
