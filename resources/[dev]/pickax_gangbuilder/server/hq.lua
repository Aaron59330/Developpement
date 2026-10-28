-- ─────────────────────────────── QG de gang : niveaux et raids ───────────────────────────────
-- Le QG d'un gang est son coffre (point « Coffre »). Niveaux : améliorés par le bureau avec la trésorerie, ils augmentent le revenu des territoires et la protection
-- après capture, et réduisent ce qu'un raid peut piller. Raid : un gang rival (2 membres min.) tient la zone du QG sans qu'aucun défenseur n'y soit pendant HoldSeconds ;
-- il vole alors une part de l'argent sale de la trésorerie. Tout est calculé côté serveur (positions, vie, temps).

local Raid = nil            -- { target, attacker, coords, progress, startedAt, lastPush }
local raidCool = {}         -- [gang cible] = fin du délai
local atkCool = {}          -- [gang attaquant] = fin du délai

local function H() return Config.HQ end
local function label(name) return GB.Gangs[name] and GB.Gangs[name].label or name end
local function clamp(x, a, b) return math.max(a, math.min(b, x)) end

function GB.hqLevel(gangName)
    local g = GB.Gangs[gangName]
    local n = math.floor(tonumber(g and g.settings and g.settings.hq_level) or 1)
    return clamp(n, 1, math.max(1, #(H().Levels or {})))
end

-- Multiplicateur d'un niveau de QG pour une clé (income / protection / steal) ; 1.0 si non défini ou QG désactivé
function GB.hqMul(gangName, key)
    if not H().Enabled then return 1.0 end
    local L = (H().Levels or {})[GB.hqLevel(gangName)]
    local v = L and tonumber(L[key])
    return (v and v > 0) and v or 1.0
end

-- Coffre (QG) d'un gang : point de type « stash »
function GB.hqPoint(gangName)
    for _, p in pairs(GB.Points) do
        if p.gang_name == gangName and p.type == 'stash' and p.coords and p.coords.x then return p end
    end
end

-- Progression d'un raid sur une seconde (pure, testée hors jeu) : renvoie la nouvelle progression
function GB.hqRaidStep(progress, attackers, defenders)
    if attackers > 0 and defenders == 0 then return progress + 1 end    -- on tient le QG
    if defenders > 0 then return math.max(0, progress - 1) end          -- les défenseurs contestent la zone
    return math.max(0, progress - 2)                                    -- plus personne : la prise retombe
end

-- Somme pillée par un raid réussi
function GB.hqStealAmount(dirty, level, R)
    if dirty < (R.MinDirty or 0) then return 0 end
    local mul = (H().Levels[level] and tonumber(H().Levels[level].steal)) or 1.0
    return math.min(R.MaxSteal or math.huge, math.floor(dirty * (R.StealPercent or 10) / 100 * mul))
end

-- ─── Amélioration ───
function GB.hqUpgrade(gangName)
    local C = H()
    if not C.Enabled then return false, 'off' end
    local lvl = GB.hqLevel(gangName)
    local nextL = (C.Levels or {})[lvl + 1]
    if not nextL then return false, 'max' end
    local cost = math.floor(tonumber(nextL.cost) or 0)
    if cost > 0 and not GB.treasuryRemove(gangName, C.UpgradeAccount == 'money' and 'money' or 'dirty', cost) then return false, 'funds' end
    local g = GB.Gangs[gangName]
    g.settings.hq_level = lvl + 1
    MySQL.update('UPDATE gangbuilder_gangs SET settings = ? WHERE name = ?', { json.encode(g.settings), gangName })
    GB.log(gangName, nil, 'hq_upgrade', ('QG niveau %d'):format(lvl + 1))
    if GB.news then GB.news(('%s améliore son QG (niveau %d).'):format(label(gangName), lvl + 1), 'territory') end
    return true, lvl + 1
end

-- ─── Raid ───
local function inRadius(c, p, r)
    local dx, dy, dz = c.x - p.x, c.y - p.y, c.z - p.z
    return dx * dx + dy * dy <= r * r and math.abs(dz) <= 8.0
end
local function alive(ped) return ped and ped ~= 0 and GetEntityHealth(ped) > 101 end

local function counts()
    local a, d = 0, 0
    for src, g in pairs(GB.PlayerGang) do
        local ped = GetPlayerPed(src)
        if alive(ped) and inRadius(GetEntityCoords(ped), Raid.coords, H().Raid.Radius or 12.0) then
            if g.name == Raid.attacker then a = a + 1 elseif g.name == Raid.target then d = d + 1 end
        end
    end
    return a, d
end

local function snap()
    if not Raid then return nil end
    local R = H().Raid
    return { target = Raid.target, targetLabel = label(Raid.target), attackerLabel = label(Raid.attacker), coords = Raid.coords, radius = R.Radius or 12.0,
        progress = math.floor(Raid.progress), hold = R.HoldSeconds or 90, left = math.max(0, Raid.startedAt + (R.MaxSeconds or 600) - os.time()) }
end

local function push()
    local s = snap()
    for _, name in ipairs({ Raid.target, Raid.attacker }) do
        for _, src in ipairs(GB.onlineMembers(name)) do TriggerClientEvent('gangbuilder:client:hqRaid', src, s, name == Raid.attacker and 'attacker' or 'defender') end
    end
end

local function stopRaid(reason)
    if not Raid then return end
    for _, name in ipairs({ Raid.target, Raid.attacker }) do
        for _, src in ipairs(GB.onlineMembers(name)) do TriggerClientEvent('gangbuilder:client:hqRaid', src, nil) end
    end
    Raid = nil
end

-- Peut-on raider ce QG ? → ok, raison ('off' | 'self' | 'nohq' | 'busy' | 'cool' | 'acool' | 'att' | 'def')
function GB.hqRaidCheck(target, attacker)
    local R = H().Raid or {}
    if not H().Enabled or not R.Enabled then return false, 'off' end
    if target == attacker then return false, 'self' end
    if not GB.Gangs[target] or not GB.hqPoint(target) then return false, 'nohq' end
    if Raid then return false, 'busy' end
    if (raidCool[target] or 0) > os.time() then return false, 'cool' end
    if (atkCool[attacker] or 0) > os.time() then return false, 'acool' end
    if #GB.onlineMembers(attacker) < (R.MinAttackers or 1) then return false, 'att' end
    if #GB.onlineMembers(target) < (R.MinDefenders or 1) then return false, 'def' end
    return true
end

GB.HqReasons = { off = 'Les raids de QG sont désactivés', self = 'C\'est ton propre QG', nohq = 'Ce gang n\'a pas de QG (coffre)', busy = 'Un raid est déjà en cours', cool = 'Ce QG a été raidé récemment',
    acool = 'Ton gang a lancé un raid récemment', att = 'Pas assez de membres de ton gang en ligne', def = 'Aucun défenseur connecté' }

function GB.hqStartRaid(target, attacker)
    local ok, why = GB.hqRaidCheck(target, attacker)
    if not ok then return false, why end
    local R = H().Raid
    local p = GB.hqPoint(target)
    Raid = { target = target, attacker = attacker, coords = { x = p.coords.x, y = p.coords.y, z = p.coords.z }, progress = 0, startedAt = os.time(), lastPush = 0 }
    atkCool[attacker] = os.time() + (R.AttackerCooldown or 1800)
    for _, s in ipairs(GB.onlineMembers(target)) do GB.notify(s, ('~r~%s~s~ raide votre QG ! Défendez-le : ils doivent tenir %d s sans qu\'un des vôtres soit dans la zone.'):format(label(attacker), R.HoldSeconds or 90)) end
    for _, s in ipairs(GB.onlineMembers(attacker)) do GB.notify(s, ('Raid lancé sur le QG de ~y~%s~s~ : tenez la zone %d s sans défenseur.'):format(label(target), R.HoldSeconds or 90)) end
    if GB.news then GB.news(('%s raide le QG de %s.'):format(label(attacker), label(target)), 'war') end
    push()
    return true
end

local function succeed()
    local R = H().Raid
    local t, a = Raid.target, Raid.attacker
    local dirtyBefore = select(2, GB.treasury(t)) or 0
    local amount = GB.hqStealAmount(dirtyBefore, GB.hqLevel(t), R)
    if amount > 0 and GB.treasuryRemove(t, 'dirty', amount) then GB.treasuryAdd(a, 'dirty', amount) else amount = 0 end
    raidCool[t] = os.time() + (R.Cooldown or 3600)
    for _, s in ipairs(GB.onlineMembers(a)) do GB.notify(s, amount > 0 and ('~g~Raid réussi~s~ : ~g~+%d $~s~ volés au QG de %s !'):format(amount, label(t)) or ('~y~Raid réussi~s~ mais le QG de %s était vide.'):format(label(t))) end
    for _, s in ipairs(GB.onlineMembers(t)) do GB.notify(s, ('~r~Votre QG a été pillé par %s~s~%s.'):format(label(a), amount > 0 and (' : ~r~-' .. amount .. ' $~s~') or ' (la trésorerie était vide)')) end
    GB.log(a, nil, 'hq_raid_win', ('QG de %s : %d $'):format(t, amount))
    GB.log(t, nil, 'hq_raid_loss', ('pillé par %s : %d $'):format(a, amount))
    if GB.addRep then GB.addRep(a, 25) end
    if GB.news then GB.news(('%s pille le QG de %s%s.'):format(label(a), label(t), amount > 0 and (' (' .. amount .. ' $)') or ''), 'war') end
    stopRaid('win')
end

CreateThread(function()
    while true do
        Wait(1000)
        if Raid then
            local R = H().Raid
            if not GB.Gangs[Raid.target] or not GB.Gangs[Raid.attacker] or os.time() >= Raid.startedAt + (R.MaxSeconds or 600) or #GB.onlineMembers(Raid.attacker) == 0 then
                for _, s in ipairs(GB.onlineMembers(Raid.attacker)) do GB.notify(s, '~y~Raid terminé sans succès.') end
                for _, s in ipairs(GB.onlineMembers(Raid.target)) do GB.notify(s, '~g~Votre QG a tenu : le raid est terminé.') end
                stopRaid('timeout')
            else
                local a, d = counts()
                Raid.progress = GB.hqRaidStep(Raid.progress, a, d)
                if Raid.progress >= (R.HoldSeconds or 90) then
                    local ok, err = pcall(succeed)
                    if not ok then Raid = nil print(('^1[gangbuilder] erreur raid : %s^0'):format(tostring(err))) end
                elseif os.time() - Raid.lastPush >= 5 then
                    Raid.lastPush = os.time()
                    push()
                end
            end
        end
    end
end)

-- Staff / bureau : /raidhq <gang>
RegisterCommand('raidhq', function(src, args)
    if src == 0 then return end
    local gang, grade = GB.gangOf(src)
    if not gang then return GB.notify(src, '~r~Tu n\'es dans aucun gang.') end
    if grade < (gang.boss_grade or 0) then return GB.notify(src, '~r~Réservé au bureau du gang.') end
    local ok, why = GB.hqStartRaid(args[1], gang.name)
    if not ok then GB.notify(src, '~r~' .. (GB.HqReasons[why] or 'Impossible')) end
end, false)

function GB.hqInfo(gangName)
    local C = H()
    if not C.Enabled then return { enabled = false } end
    local lvl = GB.hqLevel(gangName)
    local nextL = (C.Levels or {})[lvl + 1]
    local targets = {}
    for name, g in pairs(GB.Gangs) do
        if name ~= gangName and GB.hqPoint(name) then
            local can, why = GB.hqRaidCheck(name, gangName)
            targets[#targets + 1] = { name = name, label = g.label, color = g.color, online = #GB.onlineMembers(name), level = GB.hqLevel(name), can = can, why = why }
        end
    end
    table.sort(targets, function(a, b) return a.label < b.label end)
    local mine = Raid and (Raid.target == gangName or Raid.attacker == gangName) and snap() or nil
    local L = (C.Levels or {})[lvl] or {}
    return { enabled = true, level = lvl, max = #(C.Levels or {}), hasHQ = GB.hqPoint(gangName) ~= nil, income = tonumber(L.income) or 1, protection = tonumber(L.protection) or 1, steal = tonumber(L.steal) or 1,
        upgrade = nextL and { cost = math.floor(tonumber(nextL.cost) or 0), income = tonumber(nextL.income) or 1, protection = tonumber(nextL.protection) or 1, steal = tonumber(nextL.steal) or 1, account = C.UpgradeAccount == 'money' and 'propre' or 'sale' } or nil,
        raidEnabled = (C.Raid or {}).Enabled and true or false, targets = targets, raid = mine, hold = (C.Raid or {}).HoldSeconds, reasons = GB.HqReasons }
end

exports('GetHQLevel', function(gang) return GB.hqLevel(gang) end)
