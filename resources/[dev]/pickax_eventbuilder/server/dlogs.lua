-- Logs Discord de cet événement : réglés depuis l'onglet « Logs Discord » du builder (stockage et envoi : ressource pickax_dlogs)
local function fail(msg) return { ok = false, error = msg } end

local function ready()
    return GetResourceState('pickax_dlogs') == 'started'
end

local function entity(ref)
    return EB.Defs[tonumber(ref) or 0]
end

local function guard(name, fn)
    ESX.RegisterServerCallback('eventbuilder:' .. name, function(src, cb, ref, data)
        if not EB.isAdmin(src) then return cb(fail('Permission refusée')) end
        if not ready() then return cb(fail('La ressource pickax_dlogs n\'est pas démarrée (ensure pickax_dlogs)')) end
        local e = entity(ref)
        if not e then return cb(fail('Événement introuvable : enregistre-le d\'abord')) end
        cb(fn(src, e.id, e, data))
    end)
end

guard('dlogsGet', function(_, ref)
    return exports.pickax_dlogs:View('event', ref)
end)

guard('dlogsSave', function(src, ref, e, data)
    local res = exports.pickax_dlogs:Save('event', ref, data)
    if res and res.ok then EB.log(e, ESX.GetPlayerFromId(src), 'save', 'logs Discord modifiés') end
    return res
end)

guard('dlogsTest', function(src, ref, e)
    return exports.pickax_dlogs:Test('event', ref, e.label, GetPlayerName(src))
end)
