-- Chat aux couleurs du serveur : la couleur principale du config (Config.AccentColor) colore tous les messages du chat
-- (liseré, nom de l'auteur, léger dégradé). Le chat natif ne permet pas de changer sa fenêtre à chaud : seul le gabarit des messages est modifié.
local function accentRgb()
    local h = tostring(Config.AccentColor or '#00a4ff')
    local r, g, b = h:match('^#?(%x%x)(%x%x)(%x%x)$')
    if not r then return 0, 164, 255 end
    return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end
PickaxChatAccent = function() return accentRgb() end

local function applyTemplate()
    local r, g, b = accentRgb()
    local c = ('rgb(%d,%d,%d)'):format(r, g, b)
    local html = ('<div style="margin:2px 0;padding:4px 10px;border-left:3px solid %s;background:linear-gradient(90deg,rgba(%d,%d,%d,.20),rgba(%d,%d,%d,0));border-radius:0 6px 6px 0;">' ..
        '<b style="color:%s;margin-right:6px;">{0}</b><span>{1}</span></div>'):format(c, r, g, b, r, g, b, c)
    TriggerEvent('chat:addTemplate', 'default', html)
end

-- le chat peut démarrer avant ou après nous : on (re)applique à plusieurs moments
CreateThread(function()
    Wait(2500) applyTemplate()
    Wait(6000) applyTemplate()
end)
AddEventHandler('onClientResourceStart', function(res) if res == 'chat' then SetTimeout(1500, applyTemplate) end end)
AddEventHandler('playerSpawned', function() SetTimeout(3000, applyTemplate) end)
