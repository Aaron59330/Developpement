-- ─────────────────────────────── Fourrière → enchères ───────────────────────────────
-- Un véhicule resté en fourrière trop longtemps est mis aux enchères par l'État (pickax_auction). Le propriétaire est prévenu avant ; si personne n'enchérit,
-- le véhicule lui est rendu (ou détruit selon la config de pickax_auction). Le produit va à la société définie dans pickax_auction (Config.State).

local V = Config.Vehicles
local function col(c) return '`' .. tostring(c):gsub('`', '') .. '`' end
local function A() return Config.ImpoundAuction or {} end

-- Faut-il mettre ce véhicule aux enchères ? (age en jours) → 'warn' | 'sell' | nil
function WB.auctionDecision(ageDays)
    local days, warn = tonumber(A().Days) or 14, tonumber(A().WarnDays) or 2
    if ageDays >= days then return 'sell' end
    if warn > 0 and ageDays >= days - warn then return 'warn' end
    return nil
end

local warned = {}
local function sweep()
    if not A().Enabled or GetResourceState('pickax_auction') ~= 'started' then return end
    local rows = MySQL.query.await(('SELECT i.plate, UNIX_TIMESTAMP(i.created_at) AS t, v.%s AS owner FROM worldbuilder_impound i JOIN %s v ON TRIM(v.%s) = i.plate WHERE v.%s = 2 AND v.%s NOT LIKE ?'):format(
        col(V.owner), col(V.table), col(V.plate), col(V.stored), col(V.owner)), { 'auction:%' }) or {}
    for _, r in ipairs(rows) do
        local age = (os.time() - (tonumber(r.t) or os.time())) / 86400
        local d = WB.auctionDecision(age)
        if d == 'warn' and not warned[r.plate] then
            warned[r.plate] = true
            local x = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(r.owner)
            if x then WB.notify(x.source, ('Ton véhicule %s va être vendu aux enchères si tu ne le récupères pas à la fourrière.'):format(r.plate), 'warning') end
        elseif d == 'sell' then
            local ok, id = pcall(function() return exports.pickax_auction:ListImpounded(r.plate, r.owner, A().StartPrice or 3000, A().Hours or 48) end)
            if ok and id then
                MySQL.update('DELETE FROM worldbuilder_impound WHERE plate = ?', { r.plate })
                warned[r.plate] = nil
                print(('^3[worldbuilder] %s mis aux enchères par la fourrière (n° %s)^0'):format(r.plate, tostring(id)))
            end
        end
    end
end

CreateThread(function()
    Wait(60000)
    while true do
        pcall(sweep)
        Wait(math.max(10, tonumber(A().CheckMinutes) or 60) * 60000)
    end
end)
