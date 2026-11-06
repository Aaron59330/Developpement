ESX = exports['es_extended']:getSharedObject()
local C = Config
local startedAt = os.time()
local journal = {}

local function groupOf(src) local x = ESX.GetPlayerFromId(src) return x and x.getGroup and x.getGroup() or 'user' end
local function inList(list, g) for _, v in ipairs(list) do if v == g then return true end end return false end
local function allowed(src) return IsPlayerAceAllowed(src, C.Ace) or inList(C.AdminGroups, groupOf(src)) end

local function log(who, text)
    table.insert(journal, 1, { t = os.time(), who = who, text = text })
    while #journal > (C.JournalMax or 60) do table.remove(journal) end
end

local function stats()
    local players, staff = GetPlayers(), 0
    for _, id in ipairs(players) do if inList(C.StaffGroups, groupOf(tonumber(id))) then staff = staff + 1 end end
    local active, stopped, err = 0, 0, 0
    for i = 0, GetNumResources() - 1 do
        local s = GetResourceState(GetResourceByFindIndex(i))
        if s == 'started' or s == 'starting' then active = active + 1
        elseif s == 'stopped' or s == 'uninitialized' or s == 'stopping' then stopped = stopped + 1
        else err = err + 1 end
    end
    return { players = #players, max = GetConvarInt('sv_maxclients', 48), staff = staff, uptime = os.time() - startedAt, res = { active = active, error = err, stopped = stopped } }
end

ESX.RegisterServerCallback('pickax_manage:open', function(src, cb)
    if not allowed(src) then cb(false) return end
    local x = ESX.GetPlayerFromId(src)
    local g = groupOf(src)
    cb({ user = { name = GetPlayerName(src), id = src, role = C.RoleLabels[g] or g }, stats = stats(), journal = journal })
end)
ESX.RegisterServerCallback('pickax_manage:refresh', function(src, cb)
    if not allowed(src) then cb(false) return end
    cb({ stats = stats(), journal = journal })
end)
RegisterNetEvent('pickax_manage:log', function(text)
    local src = source
    if not allowed(src) then return end
    log(GetPlayerName(src), tostring(text or ''):sub(1, 120))
end)

-- ═════════════════ RÉGLAGES EN DIRECT (pickax_settings) ═════════════════
-- Le menu édite les réglages de pickax_settings (météo, heure, PNJ, circulation, gangs, drogues…) : ils sont enregistrés, appliqués tout de suite et conservés après redémarrage.
local HIDDEN = { discord_webhook = true }   -- jamais envoyé au menu
for _, k in ipairs(C.HiddenKeys or {}) do HIDDEN[k] = true end
local function settingsUp() return GetResourceState('pickax_settings') == 'started' end

ESX.RegisterServerCallback('pickax_manage:settings', function(src, cb)
    if not allowed(src) then cb(false) return end
    if not settingsUp() then cb({ error = 'La ressource pickax_settings n\'est pas démarrée.' }) return end
    local schema, all, ov = exports.pickax_settings:Schema(), exports.pickax_settings:GetAll(), exports.pickax_settings:Overrides()
    local out, values, over = {}, {}, {}
    for _, d in ipairs(schema) do
        if not HIDDEN[d.key] then out[#out + 1] = d values[d.key] = all[d.key] if ov[d.key] ~= nil then over[d.key] = true end end
    end
    cb({ schema = out, values = values, over = over })
end)

-- tbl : { clé = valeur } ; la valeur '__reset' remet le réglage à sa valeur d'origine
ESX.RegisterServerCallback('pickax_manage:set', function(src, cb, tbl)
    if not allowed(src) then cb(false) return end
    if not settingsUp() or type(tbl) ~= 'table' then cb({ ok = false }) return end
    local schema, by = exports.pickax_settings:Schema(), {}
    for _, d in ipairs(schema) do by[d.key] = d end
    local apply, labels = {}, {}
    for k, v in pairs(tbl) do
        if by[k] and not HIDDEN[k] then
            apply[k] = (v == '__reset') and { __reset = true } or v
            labels[#labels + 1] = by[k].label .. ((v == '__reset') and ' → défaut' or (' → ' .. (type(v) == 'table' and (#v .. ' ligne(s)') or tostring(v))))
        end
    end
    exports.pickax_settings:SetMany(apply)
    table.sort(labels)
    log(GetPlayerName(src), table.concat(labels, ' · '):sub(1, 140))
    local all, ov = exports.pickax_settings:GetAll(), exports.pickax_settings:Overrides()
    local values, over = {}, {}
    for k in pairs(apply) do values[k] = all[k] over[k] = ov[k] ~= nil end
    cb({ ok = true, values = values, over = over })
end)
