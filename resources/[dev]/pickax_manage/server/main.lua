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
