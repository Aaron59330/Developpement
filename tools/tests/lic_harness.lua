-- Exécute le bloc « -- [AERO:LIC] » d'un fichier de ressource avec un FiveM simulé. Variables : FILE, RES, MODE (v|hub), TOKEN (none|good|stub|...), PAYLOAD, SIG, PK, KEY, LICNODE, CORE (ok|missing|bad)
local function env(k, d) return os.getenv(k) or d end
local FILE, RES, MODE = env('FILE'), env('RES'), env('MODE', 'v')
local src = io.open(FILE, 'r'):read('a')
local block = src:match('(%-%- %[AERO:LIC%].-%-%- %[/AERO:LIC%])')
assert(block, 'bloc introuvable')
if MODE == 'v' then block = block:gsub("local AERO_PK = '[^']*'", function() return "local AERO_PK = '" .. env('PK', '') .. "'" end, 1) end
local now, threads, stopped, prints, exported = 0, {}, {}, {}, {}
local cur
function GetCurrentResourceName() return RES end
function GetConvar(n, d) if n == 'aero_panel_key' then return env('KEY', d) end return d end
function GetResourceState(r) if env('CORE','ok') == 'missing' then return 'missing' end return 'started' end
function StopResource(r) stopped[#stopped + 1] = r end
function CreateThread(f) threads[#threads + 1] = { co = coroutine.create(f), at = now } end
function Wait(ms) coroutine.yield(ms) end
function exports(n, f) exported[n] = f end
math.randomseed(1)
local function verifyViaNode(payload, sig, pk, key)
  local f = io.popen(string.format("node -e \"let F;new Function('exports','require',require('fs').readFileSync(process.argv[1],'utf8'))((n,f)=>{F=f},require);process.stdout.write(String(F(process.argv[2],process.argv[3],process.argv[4],process.argv[5])))\" %q '%s' '%s' '%s' '%s'", env('LICNODE'), payload, sig, pk, key))
  local r = f:read('a'); f:close(); return r == 'true'
end
local tokenMode = env('TOKEN', 'good')
local mt = {}
local function mk(tbl) return setmetatable({}, { __index = function(_, k) return tbl[k] end }) end
local guard = mk({ Token = function(_) if tokenMode == 'none' then return nil end return { payload = env('PAYLOAD'), sig = env('SIG') } end })
local core = mk({ Licensed = function(_) local m = env('CORE', 'ok') if m == 'missing' then error('no such export') end return m == 'ok' end })
local selfExp = mk({ LicVerify = function(_, p, s, pk, k) if env('NODE_READY_AFTER') and now < tonumber(env('NODE_READY_AFTER')) then error('not ready') end return verifyViaNode(p, s, pk, k) end })
local ex = setmetatable({}, { __index = function(_, k)
  if k == RES and MODE == 'v' then return selfExp end
  if k == 'pickax_guard' then if tokenMode == 'absent' then return setmetatable({}, { __index = function() error('resource absente') end }) end return guard end
  if k == 'pickax_core' then return core end
  if k == RES then return selfExp end
end })
-- exports est à la fois une fonction (déclaration) et une table (appel) : on enveloppe
local E = setmetatable({}, { __call = function(_, n, f) exported[n] = f end, __index = function(_, k) return ex[k] end })
exports = E
local fn, err = load(block .. '\nreturn true', '=lic', 't', setmetatable({}, { __index = _G }))
assert(fn, err)
local ok, e = pcall(fn)
local topError = not ok
-- boucle de simulation : 15 min virtuelles
local RUN = tonumber(env('RUN', '900')) * 1000
while now <= RUN do
  local alive = false
  for _, t in ipairs(threads) do
    if coroutine.status(t.co) ~= 'dead' then
      alive = true
      if t.at <= now then
        local okc, w = coroutine.resume(t.co)
        if not okc then prints[#prints + 1] = 'ERR ' .. tostring(w) end
        t.at = now + (tonumber(w) or 0)
      end
    end
  end
  if not alive or #stopped > 0 then break end
  now = now + 100
end
local js = {}
for _, s in ipairs(stopped) do js[#js + 1] = '"' .. s .. '"' end
print(string.format('RESULT{"topError":%s,"stopped":[%s],"licensedExport":%s,"errs":%d}', tostring(topError), table.concat(js, ','), exported.Licensed and tostring(exported.Licensed()) or 'null', #prints))
