-- Remplace les interfaces d'ox_lib (notifications, menus, formulaires, confirmations, barres de progression) par celles du serveur.
-- À charger APRÈS ox_lib s'il est présent : shared_scripts { '@ox_lib/init.lua', '@pickax_skillgames/ui.lua', 'config.lua' }
-- Les appels lib.notify / lib.progressBar / lib.registerContext + lib.showContext / lib.inputDialog / lib.alertDialog gardent la même syntaxe.
if IsDuplicityVersion() then return end

lib = lib or {}

lib.notify = function(d)
    if GetResourceState('pickax_notify') == 'started' then exports.pickax_notify:Notify(d)
    else BeginTextCommandThefeedPost('STRING') AddTextComponentSubstringPlayerName(type(d) == 'table' and (d.description or '') or tostring(d)) EndTextCommandThefeedPostTicker(false, false) end
end

lib.progressBar = function(cfg) return exports.pickax_skillgames:Progress(cfg) end

local contexts = {}
lib.registerContext = function(c) if type(c) == 'table' and c.id then contexts[c.id] = c end end
lib.showContext = function(id)
    local c = contexts[id]
    if c then exports.pickax_skillgames:ShowMenu({ title = c.title, options = c.options }) end
end
lib.hideContext = function() exports.pickax_skillgames:CloseKit() end

lib.inputDialog = function(title, fields, opts) return exports.pickax_skillgames:Input({ title = title, fields = fields }) end
lib.alertDialog = function(cfg) return exports.pickax_skillgames:Confirm(cfg) end
