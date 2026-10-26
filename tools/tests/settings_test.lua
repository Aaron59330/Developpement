-- Réglages du panel : cohérence du schéma + consommateurs (gameplay, PNJ, météo/heure) : lua5.4 tools/tests/settings_test.lua
local root = (arg[0]:match('^(.*)tools/tests/') or './') .. 'resources/'
local n, fails = 0, 0
local function ok(c, m) n = n + 1 if c then print('  ✓ ' .. m) else fails = fails + 1 print('  ✗ ' .. m) end end

Settings = {} dofile(root .. '[dev]/pickax_settings/config.lua')
print('Schéma')
local seen, bad, noSec, badSel = {}, {}, {}, {}
for _, d in ipairs(Settings.Schema) do
  if seen[d.key] then bad[#bad + 1] = 'doublon ' .. d.key end seen[d.key] = true
  if not d.section then noSec[#noSec + 1] = d.key end
  if not d.label or d.label == '' or not d.group then bad[#bad + 1] = 'libellé/groupe ' .. d.key end
  if d.type == 'number' then
    if type(d.default) ~= 'number' then bad[#bad + 1] = 'défaut numérique ' .. d.key end
    if d.min and d.max and (d.min > d.max or d.default < d.min or d.default > d.max) then bad[#bad + 1] = 'bornes ' .. d.key end
  elseif d.type == 'bool' then if type(d.default) ~= 'boolean' then bad[#bad + 1] = 'défaut booléen ' .. d.key end
  elseif d.type == 'select' then local f = false for _, o in ipairs(d.options or {}) do if o[1] == d.default then f = true end end if not f then badSel[#badSel + 1] = d.key end
  elseif d.type == 'text' then if type(d.default) ~= 'string' then bad[#bad + 1] = 'défaut texte ' .. d.key end
  elseif d.type == 'list' then if type(d.default) ~= 'table' then bad[#bad + 1] = 'défaut liste ' .. d.key end
  else bad[#bad + 1] = 'type inconnu ' .. d.key end
end
ok(#bad == 0, 'clés uniques, types, bornes et défauts cohérents' .. (#bad > 0 and (' : ' .. table.concat(bad, ', ')) or ''))
ok(#noSec == 0 and #badSel == 0, 'chaque réglage a une section et une valeur par défaut valide pour les listes' .. (#noSec > 0 and (' : ' .. table.concat(noSec, ',')) or ''))
ok(#Settings.Schema >= 50, #Settings.Schema .. ' réglages au total')

-- ── environnement client simulé ──
local calls, handlers, threads = {}, {}, {}
local function join(...) local o = {} for i = 1, select('#', ...) do o[i] = tostring((select(i, ...))) end return table.concat(o, ',') end
local function rec(name) return function(...) calls[#calls + 1] = name .. '(' .. join(...) .. ')' end end
local stubs = { 'NetworkSetFriendlyFireOption', 'SetPlayerHealthRechargeMultiplier', 'SetPlayerWeaponDamageModifier', 'SetPlayerMeleeWeaponDamageModifier', 'SetPedSuffersCriticalHits', 'SetPlayerCanDoDriveBy', 'InvalidateIdleCam', 'InvalidateVehicleIdleCam', 'RestorePlayerStamina', 'SetMaxWantedLevel', 'ClearPlayerWantedLevel', 'SetPlayerWantedLevel', 'SetPlayerWantedLevelNow' }
for _, f in ipairs(stubs) do _G[f] = rec(f) end
function PlayerId() return 1 end function PlayerPedId() return 100 end function GetPlayerWantedLevel() return 3 end
function AddEventHandler(ev, f) handlers[ev] = f end
function CreateThread(f) threads[#threads + 1] = coroutine.wrap(f) end
function Wait() coroutine.yield() end
dofile(root .. '[dev]/pickax_settings/client/gameplay.lua')
local function fire(all, ov) calls = {} handlers['pickax_settings:changed'](all, ov) end
local function runThreads() for _, co in ipairs(threads) do pcall(co) end end
local function has(prefix) for _, c in ipairs(calls) do if c:find(prefix, 1, true) == 1 then return true end end return false end

print('Joueurs & combat (client)')
fire({}, {}); ok(#calls == 0 and #threads == 0, 'aucun réglage modifié : aucun appel et aucune boucle')
fire({ friendly_fire = false, health_regen = 0 }, { friendly_fire = false, health_regen = 0 })
ok(has('NetworkSetFriendlyFireOption(false)') and has('SetPlayerHealthRechargeMultiplier(1,0.0)'), 'tir ami coupé et régénération à 0 appliqués immédiatement')
ok(#threads == 1, 'une boucle de maintien démarre'); calls = {} runThreads(); ok(has('SetPlayerHealthRechargeMultiplier'), 'la boucle ré-applique la régénération (après une réapparition)')
fire({ friendly_fire = true, health_regen = 1.0 }, {})
ok(has('NetworkSetFriendlyFireOption(true)') and has('SetPlayerHealthRechargeMultiplier(1,1.0)'), 'réglage remis par défaut : la valeur d’origine est restaurée')
fire({ friendly_fire = true }, {}); ok(#calls == 0, 'puis plus aucun appel')
fire({ stamina_infinite = true }, { stamina_infinite = true }); calls = {} runThreads(); ok(has('RestorePlayerStamina'), 'endurance infinie : la boucle restaure l’endurance')
fire({ idle_cam = false }, { idle_cam = false }); calls = {} runThreads(); ok(has('InvalidateIdleCam'), 'caméra d’inactivité désactivée')
fire({ wanted_enabled = false }, { wanted_enabled = false }); calls = {} runThreads(); ok(has('SetMaxWantedLevel(0)') and has('ClearPlayerWantedLevel'), 'niveau de recherche coupé : les étoiles sont effacées')
fire({ wanted_enabled = true }, {}); ok(has('SetMaxWantedLevel(5)'), 'réglage remis par défaut : les étoiles reviennent')
fire({ weapon_damage = 0.5, melee_damage = 2, critical_hits = false, drive_by = false }, { weapon_damage = 0.5, melee_damage = 2, critical_hits = false, drive_by = false })
ok(has('SetPlayerWeaponDamageModifier(1,0.5)') and has('SetPlayerMeleeWeaponDamageModifier(1,2.0)') and has('SetPedSuffersCriticalHits(100,false)') and has('SetPlayerCanDoDriveBy(1,false)'), 'dégâts, coups critiques et tir en véhicule appliqués')

-- ── serveur : bienvenue + argent de départ ──
print('Nouveaux joueurs (serveur)')
local settingsVals, notes, money = { welcome_message = 'Salut {nom} !', start_money = 2500 }, {}, {}
Settings.Get = function(k) return settingsVals[k] end
local srvHandlers = {}
AddEventHandler = function(ev, f) srvHandlers[ev] = f end
function SetTimeout(_, f) f() end
function TriggerClientEvent(ev, src, msg) notes[#notes + 1] = { src, msg } end
function GetPlayerName() return 'Joueur' end
dofile(root .. '[dev]/pickax_settings/server/gameplay.lua')
local xp = { getName = function() return 'Maly' end, addAccountMoney = function(acc, a) money[#money + 1] = { acc, a } end }
srvHandlers['esx:playerLoaded'](5, xp, true)
ok(notes[1] and notes[1][2] == 'Salut Maly !', 'message de bienvenue avec le nom du joueur')
ok(money[1] and money[1][1] == 'bank' and money[1][2] == 2500, 'nouveau personnage : 2 500 $ bonus sur la banque')
notes, money = {}, {}; srvHandlers['esx:playerLoaded'](5, xp, false); ok(#money == 0 and #notes == 1, 'personnage existant : message mais pas d’argent bonus')
settingsVals = { welcome_message = '', start_money = 0 }; notes, money = {}, {}; srvHandlers['esx:playerLoaded'](5, xp, true); ok(#notes == 0 and #money == 0, 'réglages vides : rien n’est envoyé')
settingsVals = { welcome_message = '100 %{nom}', start_money = 0 }; notes = {}; srvHandlers['esx:playerLoaded'](5, { getName = function() return 'A%B' end }, false); ok(notes[1] and notes[1][2] == '100 %A%B', 'les caractères spéciaux du nom ne cassent pas le message')

-- ── PNJ (pickax_core) ──
print('Monde & PNJ (pickax_core)')
setmetatable(_G, { __index = function(_, k) if type(k) == 'string' and k:match('^[A-Z]') then return function() end end end })
local npcCalls = {}
for _, f in ipairs({ 'SetRandomBoats', 'SetRandomTrains', 'SetGarbageTrucks', 'SetCreateRandomCops', 'SetDispatchCopsForPlayer', 'EnableDispatchService' }) do rawset(_G, f, function(...) npcCalls[#npcCalls + 1] = f .. '(' .. join(...) .. ')' end) end
Citizen = { CreateThread = function(f) end, Wait = function() end }
local npcH = {} AddEventHandler = function(ev, f) npcH[ev] = f end
dofile(root .. '[script]/pickax_core/utils/npc/config.lua')
dofile(root .. '[script]/pickax_core/utils/npc/client.lua')
ok(ConfigNPC.AllowNPC == false and ConfigNPC.pnjdensity == 0.0, 'par défaut : aucun PNJ (comportement d’origine conservé)')
npcH['pickax_settings:changed']({ npc_enabled = true, npc_density = 0.4, traffic_density = 0.2, parked_density = 0.1 }, { npc_enabled = true })
ok(ConfigNPC.AllowNPC == true and ConfigNPC.pnjdensity == 0.4 and ConfigNPC.vehdensity == 0.2 and ConfigNPC.parkeddensity == 0.1, 'PNJ activés avec trois densités distinctes')
npcCalls = {} npcH['pickax_settings:changed']({ npc_police = true, npc_boats = true }, { npc_police = true, npc_boats = true })
local function hasN(p) for _, c in ipairs(npcCalls) do if c:find(p, 1, true) then return true end end return false end
ok(ConfigNPC.EnablePolice and ConfigNPC.EnableBoats and hasN('SetRandomBoats(true)') and hasN('SetCreateRandomCops(true)') and hasN('EnableDispatchService(1,true)'), 'police et bateaux PNJ activés : natives ré-appliquées')
npcH['pickax_settings:changed']({}, { friendly_fire = false }); ok(ConfigNPC.EnablePolice == true, 'un réglage sans rapport ne touche pas aux PNJ')

print(('\n%d vérifications, %d échec(s)'):format(n, fails))
os.exit(fails == 0 and 0 or 1)
