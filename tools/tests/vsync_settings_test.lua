local root = (arg[0]:match('^(.*)tools/tests/') or './') .. 'resources/'
local n, fails = 0, 0
local function ok(c, m) n = n + 1 if c then print('  ✓ ' .. m) else fails = fails + 1 print('  ✗ ' .. m) end end
setmetatable(_G, { __index = function(_, k) if type(k) == 'string' and k:match('^[A-Z]') then return function() end end end })
Config = { Trigger = {}, Licensestaff = {} }
Citizen = { CreateThread = function() end, Wait = function() end }
local ev, sent, H = {}, {}, {}
function CreateThread() end
function RegisterCommand() end function RegisterServerEvent() end
function AddEventHandler(name, f) H[name] = f end
function TriggerClientEvent(name, who, ...) sent[#sent + 1] = { name, ... } end
ESXCustom_Function_ServerSide = {}
dofile(root .. '[script]/pickax_core/system/vsync/server.lua')
local function last(name) for i = #sent, 1, -1 do if sent[i][1] == name then return sent[i] end end end
print('Météo & heure (vsync)')
sent = {} H['pickax_settings:changed']({ weather_dynamic = false, weather_type = 'RAIN' }, { weather_type = 'RAIN' })
ok(CurrentWeather == 'RAIN' and DynamicWeather == false, 'météo fixe : pluie')
local w = last('DME:updateWeather'); ok(w and w[2] == 'RAIN', 'la météo est envoyée à tous les joueurs')
sent = {} H['pickax_settings:changed']({ weather_dynamic = true, weather_type = 'RAIN' }, { weather_dynamic = true }); ok(DynamicWeather == true, 'météo dynamique activée')
sent = {} H['pickax_settings:changed']({ blackout = true }, { blackout = true }); local b = last('DME:updateWeather'); ok(b and b[3] == true, 'panne de courant envoyée aux joueurs')
sent = {} H['pickax_settings:changed']({ time_frozen = true, time_hour = 21 }, { time_frozen = true }); local t = last('DME:updateTime'); ok(t and t[4] == true, 'heure figée (freezeTime vrai) envoyée aux joueurs')
sent = {} H['pickax_settings:changed']({ time_frozen = false, time_hour = 21 }, { time_hour = 21 }); t = last('DME:updateTime'); ok(t and t[4] == false, 'heure libérée')
sent = {} H['pickax_settings:changed']({ friendly_fire = false }, { friendly_fire = false }); ok(#sent == 0, 'un réglage sans rapport n’envoie rien')
print(('\n%d vérifications, %d échec(s)'):format(n, fails)) os.exit(fails == 0 and 0 or 1)
