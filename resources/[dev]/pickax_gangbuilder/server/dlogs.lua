-- Logs Discord de ce gang : réglés depuis l'onglet « Logs Discord » du builder (stockage et envoi : ressource pickax_dlogs)
local function fail(msg) return { ok = false, error = msg } end

local function ready()
    return GetResourceState('pickax_dlogs') == 'started'
end

local function entity(ref)
    return type(ref) == 'string' and GB.Gangs[ref] or nil
end

local function guard(name, fn)
    ESX.RegisterServerCallback('gangbuilder:' .. name, function(src, cb, ref, data)
        if not GB.isDev(src) then return cb(fail('Permission refusée')) end
        if not ready() then return cb(fail('La ressource pickax_dlogs n\'est pas démarrée (ensure pickax_dlogs)')) end
        local e = entity(ref)
        if not e then return cb(fail('Gang introuvable : enregistre-le d\'abord')) end
        cb(fn(src, tostring(ref), e, data))
    end)
end

guard('dlogsGet', function(_, ref)
    return exports.pickax_dlogs:View('gang', ref)
end)

guard('dlogsSave', function(src, ref, e, data)
    local res = exports.pickax_dlogs:Save('gang', ref, data)
    if res and res.ok then GB.log(ref, ESX.GetPlayerFromId(src), 'settings_saved', 'logs Discord') end
    return res
end)

guard('dlogsTest', function(src, ref, e)
    return exports.pickax_dlogs:Test('gang', ref, e.label, GetPlayerName(src))
end)
