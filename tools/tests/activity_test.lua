-- Activité (compteurs du jour / 7 jours) et alertes Discord de pickax_settings (natives simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local kvp, threads, http, exportsT = nil, {}, {}, {}
function GetResourceKvpString() return kvp end
function SetResourceKvp(_, v) kvp = v end
function CreateThread(f) threads[#threads + 1] = f end
function Wait() end
function AddEventHandler() end
function GetCurrentResourceName() return 'pickax_settings' end
function PerformHttpRequest(url, cb, method, body) http[#http + 1] = { url = url, body = body } end
json = { encode = function(t) return t end, decode = function(s) return s end }
exports = function(name, fn) exportsT[name] = fn end
local vals = { discord_alerts = true, discord_webhook = 'https://discord.com/api/webhooks/123/abc', discord_cat_gangs = true, discord_cat_police = false, discord_cat_labs = true, discord_digest = false, discord_digest_hour = 20 }
Settings = { Get = function(k) return vals[k] end }
dofile(ROOT .. '/resources/[dev]/pickax_settings/server/activity.lua')

Settings.Count('street_units', 3, 'Drogue vendue dans la rue (unités)')
Settings.Count('street_units', 2)
Settings.Count('seizures', 1, 'Saisies de police')
Settings.Count('', 5) Settings.Count('x', 'abc')
local act = Settings.Activity()
ok(#act == 2, 'deux compteurs (clé vide et valeur invalide ignorées)')
local by = {} for _, a in ipairs(act) do by[a.key] = a end
ok(by.street_units.today == 5 and by.street_units.week == 5 and by.street_units.label:find('rue'), 'cumul du jour et de la semaine, libellé conservé')
ok(by.seizures.today == 1, 'second compteur')
ok(act[1].label < act[2].label, 'trié par libellé')
-- la semaine inclut les jours précédents
do
    local d1 = os.date('%Y%m%d', os.time() - 3 * 86400)
    local t = kvp -- non persisté tant que le thread de sauvegarde n'a pas tourné : on lance un tour
end
for _, th in ipairs(threads) do local co = coroutine.create(th) local n = 0 Wait = function() n = n + 1 if n > 2 then error('stop') end coroutine.yield() end coroutine.resume(co) coroutine.resume(co) end
ok(type(kvp) == 'table' and kvp.days[os.date('%Y%m%d')].street_units == 5, 'compteurs sauvegardés (KVP)')
kvp.days[os.date('%Y%m%d', os.time() - 3 * 86400)] = { street_units = 10 }
kvp.days[os.date('%Y%m%d', os.time() - 20 * 86400)] = { street_units = 99 }
-- recharge
threads = {}
dofile(ROOT .. '/resources/[dev]/pickax_settings/server/activity.lua')
for _, th in ipairs(threads) do local co = coroutine.create(th) Wait = function() coroutine.yield() end coroutine.resume(co) end
local act2 = Settings.Activity()
local s2 = {} for _, a in ipairs(act2) do s2[a.key] = a end
ok(s2.street_units.today == 5 and s2.street_units.week == 15, 'semaine = aujourd\'hui + il y a 3 jours (pas il y a 20 jours)')
-- Discord
local p = Settings.DiscordPayload('Titre', 'Texte', 123)
ok(p.embeds[1].title == 'Titre' and p.embeds[1].color == 123 and p.embeds[1].timestamp:match('^%d+%-%d+%-%d+T'), 'embed Discord')
ok(#Settings.DiscordPayload(('x'):rep(500), ('y'):rep(5000)).embeds[1].description == 1500, 'texte tronqué à 1500 caractères')
ok(Settings.Discord('gangs', 'T', 'x') == true, 'catégorie gangs envoyée')
ok(Settings.Discord('police', 'T', 'x') == false, 'catégorie police désactivée')
ok(Settings.Discord('inconnue', 'T', 'x') == false, 'catégorie inconnue refusée')
vals.discord_webhook = 'http://evil.example/hook'
ok(Settings.Discord('gangs', 'T', 'x') == false, 'seules les adresses de webhooks Discord en https sont acceptées')
vals.discord_webhook = 'https://discord.com/api/webhooks/123/abc'
vals.discord_alerts = false
ok(Settings.Discord('gangs', 'T', 'x') == false, 'alertes désactivées')
print(('activity_test : %d vérifications OK'):format(checks))
