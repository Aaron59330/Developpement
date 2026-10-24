-- Couleur du chat : la couleur principale du config (Config.AccentColor) est exposée aux scripts qui écrivent dans le chat (chat staff…).
-- Le chat natif refuse de redéfinir son modèle de message par défaut (« duplicate template 'default' ») : on ne le touche donc plus ;
-- seuls nos propres messages utilisent le modèle « pickax » aux couleurs du serveur.
local function accentRgb()
    local h = tostring(Config.AccentColor or '#fdc27d')
    local r, g, b = h:match('^#?(%x%x)(%x%x)(%x%x)$')
    if not r then return 253, 194, 125 end
    return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end
PickaxChatAccent = function() return accentRgb() end

local function addTemplate()
    local r, g, b = accentRgb()
    local c = ('rgb(%d,%d,%d)'):format(r, g, b)
    TriggerEvent('chat:addTemplate', 'pickax', ('<div style="margin:2px 0;padding:4px 10px;border-left:3px solid %s;background:linear-gradient(90deg,rgba(%d,%d,%d,.20),rgba(%d,%d,%d,0));border-radius:0 6px 6px 0;">' ..
        '<b style="color:%s;margin-right:6px;">{0}</b><span>{1}</span></div>'):format(c, r, g, b, r, g, b, c))
end
PickaxChatTemplate = addTemplate

local done = false
CreateThread(function() Wait(3000) if not done then done = true addTemplate() end end)
AddEventHandler('onClientResourceStart', function(res) if res == 'chat' then done = true SetTimeout(1500, addTemplate) end end)
