-- Lit la configuration du « Parcours d'arrivée » enregistrée depuis le panel web (document « creator », synchronisé par pickax_panel)
-- et la transmet aux joueurs. Sans panel : les valeurs de config.lua s'appliquent.
local function readDoc()
    local raw = GetResourceState('pickax_panel') == 'started' and LoadResourceFile('pickax_panel', 'cache_creator.json') or nil
    if not raw or raw == '' then return nil end
    local ok, v = pcall(json.decode, raw)
    return ok and type(v) == 'table' and v or nil
end
RegisterNetEvent('pickax_creator:cfg', function()
    TriggerClientEvent('pickax_creator:cfg', source, readDoc() or {})
end)

-- ───────────── Capture des têtes (images réelles des visages du jeu) ─────────────
-- /capturefaces (admin / ACE « command ») : prend une capture de chacun des 46 visages et l'enregistre dans html/faces/<id>.png.
-- Nécessite la ressource « screenshot-basic » (à installer et démarrer une fois). Les images servent ensuite à l'écran de création.
local function allowed(src) return src == 0 or IsPlayerAceAllowed(src, 'command') or IsPlayerAceAllowed(src, 'pickax.admin') end
RegisterCommand('capturefaces', function(src)
    if not allowed(src) then return end
    if GetResourceState('screenshot-basic') ~= 'started' then
        local m = 'Installe et démarre la ressource « screenshot-basic » (https://github.com/citizenfx/screenshot-basic), puis relance /capturefaces.'
        if src == 0 then print('[pickax_creator] ' .. m) else TriggerClientEvent('chat:addMessage', src, { args = { 'Création', m } }) end
        return
    end
    if src == 0 then print('[pickax_creator] /capturefaces doit être lancé en jeu par un admin') return end
    TriggerClientEvent('pickax_creator:captureFaces', src)
end, false)

RegisterNetEvent('pickax_creator:faceShot', function(id)
    local src = source
    if not allowed(src) or GetResourceState('screenshot-basic') ~= 'started' then return end
    id = math.floor(tonumber(id) or -1)
    if id < 0 or id > 45 then return end
    local path = GetResourcePath(GetCurrentResourceName()) .. ('/html/faces/%d.png'):format(id)
    exports['screenshot-basic']:requestClientScreenshot(src, { encoding = 'png', fileName = path, quality = 0.95 }, function(err)
        TriggerClientEvent('pickax_creator:faceShotDone', src, id, err == false or err == nil)
    end)
end)
