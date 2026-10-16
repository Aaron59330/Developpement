-- ─────────────────────────────── Chargeur des modules intégrés ───────────────────────────────
-- Modules sans interface NUI (écran de connexion…) déplacés dans pickax_core SANS changer leur logique. Chargé côté serveur uniquement.
-- Chaque module est exécuté dans son propre environnement Lua : ses variables globales (Config, GB, JB, ESX…) restent privées,
-- exactement comme quand il était une ressource séparée. Seuls quelques appels sont adaptés pour cohabiter dans une seule ressource :
--   • SendNUIMessage / RegisterNUICallback / SetNuiFocus : étiquetés avec le nom du module (le hub NUI route vers le bon cadre)
--   • LoadResourceFile / SaveResourceFile : chemins relatifs au dossier du module
-- Désactiver un module : set pickax:disable_modules "gangbuilder,hud2"  (server.cfg)
local RES = GetCurrentResourceName()
local SERVER = IsDuplicityVersion()
local SIDE = SERVER and 'server' or 'client'

local rawLoad, rawFile, rawSave = LoadResourceFile, LoadResourceFile, SaveResourceFile
local rawSend, rawRegNui, rawFocus
if not SERVER then rawSend, rawRegNui, rawFocus = SendNUIMessage, RegisterNUICallback, SetNuiFocus end

local function log(color, msg) print(('^%d[pickax_core/modules] %s^0'):format(color, msg)) end

local function loadChunk(path, env)
    local code = rawFile(RES, path)
    if not code then return nil, 'fichier introuvable' end
    local fn, err = load(code, '@' .. RES .. '/' .. path, 't', env)
    if not fn then return nil, err end
    return fn
end

local registryFn, rerr = loadChunk('modules/registry.lua', {})
if not registryFn then return log(1, 'registry.lua illisible : ' .. tostring(rerr)) end
local registry = registryFn()

local disabled = {}
for name in tostring(GetConvar('pickax:disable_modules', '')):gmatch('[%w_]+') do disabled[name] = true end

-- Environnement privé d'un module : globals propres, repli sur le global du core (natives, exports, ESX, MySQL, source…)
local function makeEnv(mod)
    local prefix = 'modules/' .. mod.name .. '/'
    local env = {}
    env._G = env

    env.LoadResourceFile = function(res, path) return rawLoad(res, res == RES and (prefix .. path) or path) end
    env.SaveResourceFile = function(res, path, data, len) return rawSave(res, res == RES and (prefix .. path) or path, data, len) end

    if not SERVER then
        env.SendNUIMessage = function(data) return rawSend({ __ui = mod.name, __d = data }) end
        env.RegisterNUICallback = function(name, cb) return rawRegNui(mod.name .. ':' .. name, cb) end
        env.HubStatus = function() rawSend({ __hub = 'status' }) end      -- diagnostic : état des cadres du hub NUI (résultat dans la console F8)
        env.SetNuiFocus = function(hasFocus, hasCursor)
            rawSend({ __hub = 'focus', ui = mod.name, on = hasFocus and true or false })
            return rawFocus(hasFocus, hasCursor)
        end
    end
    return setmetatable(env, { __index = _G })
end

local function runList(mod, env, list)
    for _, rel in ipairs(list or {}) do
        local fn, err = loadChunk('modules/' .. mod.name .. '/' .. rel, env)
        if not fn then
            log(1, ('%s : %s (%s)'):format(mod.name, rel, tostring(err)))
        else
            local ok, e = xpcall(fn, function(m) return m end)
            if not ok then log(1, ('%s : erreur dans %s : %s'):format(mod.name, rel, tostring(e))) end
        end
    end
end

local loaded = {}
for _, mod in ipairs(registry) do
    if disabled[mod.name] then
        log(3, ('module %s désactivé (pickax:disable_modules)'):format(mod.name))
    elseif (mod.shared and #mod.shared > 0) or (mod[SIDE] and #mod[SIDE] > 0) then
        local env = makeEnv(mod)
        runList(mod, env, mod.shared)
        runList(mod, env, mod[SIDE])
        loaded[#loaded + 1] = mod.name
    end
end

if SERVER then
    log(2, ('%d module(s) chargé(s) : %s'):format(#loaded, table.concat(loaded, ', ')))
end

if not SERVER then
    -- réponse du hub NUI à { __hub = 'status' } : cadres présents / chargés
    RegisterNUICallback('hubstatus', function(data, cb)
        cb({})
        print('^3[pickax_core/hub] ' .. json.encode(data) .. '^0')
    end)
end

-- Liste des modules (côté client : pour les autres scripts du core)
exports('GetLoadedModules', function() return loaded end)
