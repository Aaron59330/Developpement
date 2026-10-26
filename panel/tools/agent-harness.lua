-- Simule FiveM pour exécuter resources/[dev]/pickax_panel/server/main.lua : lua5.4 tools/agent-harness.lua <url> <clé> <dossier-ressource>
local URL, KEY, DIR = arg[1], arg[2], arg[3]
-- JSON minimal
local json = {}
local function enc(v)
  local t = type(v)
  if t == 'nil' then return 'null' elseif t == 'boolean' or t == 'number' then return tostring(v)
  elseif t == 'string' then return '"' .. v:gsub('[%c"\\]', function(c) return ({['"']='\\"',['\\']='\\\\',['\n']='\\n',['\r']='\\r',['\t']='\\t'})[c] or string.format('\\u%04x', c:byte()) end) .. '"'
  else
    local n, isArr = 0, true
    for k in pairs(v) do n = n + 1 if type(k) ~= 'number' then isArr = false end end
    local out = {}
    if isArr then for i = 1, #v do out[i] = enc(v[i]) end return '[' .. table.concat(out, ',') .. ']' end
    for k, x in pairs(v) do out[#out + 1] = enc(tostring(k)) .. ':' .. enc(x) end return '{' .. table.concat(out, ',') .. '}'
  end
end
function json.encode(v) return enc(v) end
function json.decode(s)
  local i = 1
  local function ws() i = s:find('[^ \n\r\t]', i) or #s + 1 end
  local val
  local function str() local j = i + 1 local out = {} while true do local c = s:sub(j, j) if c == '"' then i = j + 1 return table.concat(out) elseif c == '\\' then local n = s:sub(j + 1, j + 1) if n == 'u' then out[#out + 1] = utf8.char(tonumber(s:sub(j + 2, j + 5), 16)) j = j + 6 else out[#out + 1] = ({n='\n',t='\t',r='\r',b='\b',f='\f'})[n] or n j = j + 2 end else out[#out + 1] = c j = j + 1 end end end
  function val()
    ws() local c = s:sub(i, i)
    if c == '{' then local o = {} i = i + 1 ws() if s:sub(i, i) == '}' then i = i + 1 return o end while true do ws() local k = str() ws() i = i + 1 o[k] = val() ws() local d = s:sub(i, i) i = i + 1 if d == '}' then return o end end
    elseif c == '[' then local a = {} i = i + 1 ws() if s:sub(i, i) == ']' then i = i + 1 return a end while true do a[#a + 1] = val() ws() local d = s:sub(i, i) i = i + 1 if d == ']' then return a end end
    elseif c == '"' then return str()
    elseif s:sub(i, i + 3) == 'true' then i = i + 4 return true elseif s:sub(i, i + 4) == 'false' then i = i + 5 return false elseif s:sub(i, i + 3) == 'null' then i = i + 4 return nil
    else local n = s:match('^-?%d+%.?%d*[eE]?[+-]?%d*', i) i = i + #n return tonumber(n) end
  end
  return val()
end
_G.json = json
local files = {}
local threads = {}
-- natives FiveM simulés
local players = { ['7'] = { name = 'Jean', job = { name = 'police', grade = 2 }, group = 'admin', money = 500, bank = 9000 } }
local events = {}
local ESX = { GetPlayerFromId = function(id) local p = players[tostring(id)] if not p then return nil end
  return { getJob = function() return p.job end, getGroup = function() return p.group end, getAccount = function(a) return { money = a == 'money' and p.money or p.bank } end,
    setJob = function(j, g) p.job = { name = j, grade = g } end, setGroup = function(g) p.group = g end,
    addAccountMoney = function(a, n) if a == 'money' then p.money = p.money + n else p.bank = p.bank + n end end, removeAccountMoney = function(a, n) p.money = p.money - n end } end,
  DoesJobExist = function(j, g) return j == 'police' or j == 'mecano' end }
function GetConvar(k, d) return ({ aero_panel_url = URL, aero_panel_key = KEY, version = 'FXServer-sim', sv_hostname = 'HarnessRP' })[k] or d end
function GetConvarInt(k, d) return d end
function GetResourceMetadata() return '1.0.0' end
function GetCurrentResourceName() return 'pickax_panel' end
function GetPlayers() local t = {} for id in pairs(players) do t[#t + 1] = id end return t end
function GetPlayerName(id) local p = players[tostring(id)] return p and p.name end
function GetPlayerIdentifiers(id) return { 'license:harness' .. id, 'steam:1100001' } end
function GetPlayerIdentifier(id, n) return 'license:harness' .. id end
function GetPlayerPing() return 33 end
function GetGameTimer() return 120000 end
function GetNumResources() return 2 end
function GetResourceByFindIndex(i) return ({ [0] = 'pickax_core', [1] = 'pma-voice' })[i] end
function GetResourceState(r) if r == 'pickax_basetools' then return 'started' end return 'started' end
function DropPlayer(id, r) events[#events + 1] = 'DropPlayer ' .. id .. ' ' .. r players[tostring(id)] = nil end
function TriggerClientEvent(e, who, ...) events[#events + 1] = 'Client ' .. e .. ' -> ' .. tostring(who) .. ' ' .. tostring((...)) end
function ExecuteCommand(c) events[#events + 1] = 'cmd ' .. c end
function AddEventHandler() end
function RegisterNetEvent() end
function SetTimeout(ms, f) f() end
function Wait() end
function CreateThread(f) threads[#threads + 1] = f end
function LoadResourceFile(r, f) return files[f] end
function SaveResourceFile(r, f, c) files[f] = c return true end
exports = setmetatable({ es_extended = { getSharedObject = function() return ESX end } }, { __call = function(t, name, fn) t[name] = fn end })
exports.pickax_basetools = { ApplyTheme = function(_, v, by) events[#events + 1] = 'ApplyTheme ' .. v.AccentColor .. ' ' .. v.ServerName return { ok = true } end }
exports.ox_inventory = { AddItem = function(_, id, item, n) events[#events + 1] = 'AddItem ' .. item .. ' x' .. n return true end }
function PerformHttpRequest(url, cb, method, body, headers)
  local f = io.open('/tmp/agent_body.json', 'w') f:write(body) f:close()
  local h = {} for k, v in pairs(headers or {}) do h[#h + 1] = string.format("-H '%s: %s'", k, v) end
  local p = io.popen(string.format("curl -s -o /tmp/agent_out.txt -w '%%{http_code}' -X %s %s --data-binary @/tmp/agent_body.json '%s'", method, table.concat(h, ' '), url))
  local code = tonumber(p:read('*a')) p:close()
  local o = io.open('/tmp/agent_out.txt') local text = o:read('*a') o:close() cb(code, text)
end
Config = nil
dofile(DIR .. '/config.lua')
local main = loadfile(DIR .. '/server/main.lua')
main()
-- exécute 2 cycles de la boucle (le thread attend Wait() qui est un no-op) : on lance le thread avec une limite
local n = 0
_G.Wait = function() n = n + 1 if n > 6 then error('fin') end end
for _, t in ipairs(threads) do pcall(t) end
print('--- événements simulés ---') for _, e in ipairs(events) do print(e) end
print('--- joueur 7 ---', players['7'] and (players['7'].job.name .. ' ' .. players['7'].job.grade .. ' ' .. players['7'].group .. ' $' .. players['7'].money) or 'absent')
print('--- cache ---', files['cache_bans.json'], files['cache_motd.json'])
