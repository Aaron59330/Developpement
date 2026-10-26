-- Environnement FiveM simulé pour pickax_guard (utilisé par guard_test.js) : lua5.4 guard_harness.lua
local root = (arg[0]:match('^(.*)tools/tests/') or './') .. 'resources/[dev]/pickax_guard/'
local function env(k, d) local v = os.getenv(k) if v == nil or v == '' then return d end return v end

-- ── JSON minimal ──
local json = {}
local function esc(s) return '"' .. s:gsub('[%c"\\]', function(c) return ({ ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' })[c] or string.format('\\u%04x', c:byte()) end) .. '"' end
function json.encode(v)
  local t = type(v)
  if t == 'table' then
    if #v > 0 or next(v) == nil then local o = {} for i, x in ipairs(v) do o[i] = json.encode(x) end return '[' .. table.concat(o, ',') .. ']' end
    local o = {} for k, x in pairs(v) do o[#o + 1] = esc(tostring(k)) .. ':' .. json.encode(x) end table.sort(o) return '{' .. table.concat(o, ',') .. '}'
  elseif t == 'string' then return esc(v) elseif t == 'nil' then return 'null' else return tostring(v) end
end
function json.decode(s)
  local i = 1
  local function ws() i = s:find('%S', i) or #s + 1 end
  local val
  local function str() local out, j = {}, i + 1 while true do local c = s:sub(j, j) if c == '"' then i = j + 1 return table.concat(out) elseif c == '\\' then local n = s:sub(j + 1, j + 1) local m = { n = '\n', r = '\r', t = '\t', b = '\b', f = '\f' } if n == 'u' then out[#out + 1] = utf8.char(tonumber(s:sub(j + 2, j + 5), 16)) j = j + 6 else out[#out + 1] = m[n] or n j = j + 2 end elseif c == '' then error('json') else out[#out + 1] = c j = j + 1 end end end
  function val()
    ws() local c = s:sub(i, i)
    if c == '{' then local o = {} i = i + 1 ws() if s:sub(i, i) == '}' then i = i + 1 return o end while true do ws() local k = str() ws() i = i + 1 o[k] = val() ws() local d = s:sub(i, i) i = i + 1 if d == '}' then return o end end
    elseif c == '[' then local o = {} i = i + 1 ws() if s:sub(i, i) == ']' then i = i + 1 return o end while true do o[#o + 1] = val() ws() local d = s:sub(i, i) i = i + 1 if d == ']' then return o end end
    elseif c == '"' then return str()
    elseif s:sub(i, i + 3) == 'true' then i = i + 4 return true elseif s:sub(i, i + 4) == 'false' then i = i + 5 return false elseif s:sub(i, i + 3) == 'null' then i = i + 4 return nil
    else local n = s:match('^-?%d+%.?%d*[eE]?[+-]?%d*', i) i = i + #n return tonumber(n) end
  end
  return val()
end
_G.json = json

-- ── ressources et événements ──
local ALL = { 'pickax_guard', 'pickax_core', 'pickax_ui', 'pickax_jobbuilder', 'pickax_panel', 'es_extended', 'oxmysql' }
local rstate, log = {}, { cancelled = {}, ensured = {}, stopped = {}, started = {}, prints = {} }
for _, n in ipairs(ALL) do rstate[n] = 'stopped' end
rstate.pickax_guard, rstate.es_extended, rstate.oxmysql, rstate.pickax_panel = 'started', 'started', 'started', 'started'
for n in env('PRESTARTED', ''):gmatch('[^,]+') do rstate[n] = 'started' end
local handlers = {}
function AddEventHandler(ev, f) handlers[ev] = handlers[ev] or {} table.insert(handlers[ev], f) end
local cancelled
function CancelEvent() cancelled = true end
local function trigger(ev, ...) cancelled = false for _, f in ipairs(handlers[ev] or {}) do f(...) end return cancelled end
function GetCurrentResourceName() return 'pickax_guard' end
function GetResourceMetadata() return '1.0.0' end
function GetConvar(k, d) return env('CV_' .. k, d) end
function GetNumResources() return #ALL end
function GetResourceByFindIndex(i) return ALL[i + 1] end
function GetResourceState(n) return rstate[n] or 'missing' end
local function startResource(n)
  if trigger('onResourceStarting', n) then log.cancelled[#log.cancelled + 1] = n return end
  rstate[n] = 'started' log.started[#log.started + 1] = n trigger('onResourceStart', n)
end
function ExecuteCommand(c) local n = c:match('^ensure (%S+)') if n then log.ensured[#log.ensured + 1] = n if rstate[n] ~= 'started' then startResource(n) end end end
function StopResource(n) if rstate[n] == 'started' then rstate[n] = 'stopped' log.stopped[#log.stopped + 1] = n end end
function LoadResourceFile(_, f) local h = io.open(env('GUARD_DIR', '/tmp') .. '/' .. f, 'r') if not h then return nil end local s = h:read('a') h:close() return s end
function SaveResourceFile(_, f, c) local h = io.open(env('GUARD_DIR', '/tmp') .. '/' .. f, 'w') if not h then return false end h:write(c) h:close() return true end
local realPrint = print
function print(...) local t = {} for i = 1, select('#', ...) do t[i] = tostring((select(i, ...))) end log.prints[#log.prints + 1] = table.concat(t, ' ') end

-- ── temps virtuel + threads ──
local realTime = os.time
local now, threads = realTime() + (tonumber(env('TIME_SHIFT', '0')) or 0), {}
os.time = function(t) if t then return realTime(t) end return math.floor(now) end
function CreateThread(f) threads[#threads + 1] = { co = coroutine.create(f), at = now } end
function SetTimeout(ms, f) CreateThread(function() Wait(ms) f() end) end
function Wait(ms) coroutine.yield((tonumber(ms) or 0) / 1000) end

-- ── exports de pickax_guard (Node simulé via un vrai node) ──
local function sh(cmd) local h = io.popen(cmd) local o = h:read('a') h:close() return o end
local function tmpfile(s) local n = os.tmpname() local h = io.open(n, 'w') h:write(s) h:close() return n end
local registered = {}
exports = setmetatable({}, { __call = function(_, name, f) registered[name] = f end, __index = function(_, res)
  return { Verify = function(_, payload, sig, pub)
      local a, b, c = tmpfile(payload), tmpfile(sig), tmpfile(pub)
      local out = sh(('node -e "const fs=require(\'fs\');const c=require(\'crypto\');try{const k=c.createPublicKey({key:Buffer.from(fs.readFileSync(\'%s\',\'utf8\'),\'base64\'),format:\'der\',type:\'spki\'});process.stdout.write(String(c.verify(null,Buffer.from(fs.readFileSync(\'%s\',\'utf8\')),k,Buffer.from(fs.readFileSync(\'%s\',\'utf8\'),\'base64\'))))}catch(e){process.stdout.write(\'false\')}"'):format(c, a, b))
      os.remove(a) os.remove(b) os.remove(c) return out == 'true' end,
    KeyHash = function(_, key) return (sh(('node -e "process.stdout.write(require(\'crypto\').createHash(\'sha256\').update(process.argv[1]).digest(\'hex\').slice(0,16))" "%s"'):format(key))) end,
    Random = function(_, n) local s = '' for _ = 1, n do s = s .. string.format('%x', math.random(0, 15)) end return s end }
end })

-- ── HTTP réel via curl (synchrone) ──
function PerformHttpRequest(url, cb, method, body, headers)
  local hdr = '' for k, v in pairs(headers or {}) do hdr = hdr .. ('-H "%s: %s" '):format(k, v) end
  local f = tmpfile(body or '')
  local out = sh(('curl -s -m 5 -o - -w "\\n%%{http_code}" -X %s %s --data-binary @%s "%s" 2>/dev/null'):format(method, hdr, f, url)) os.remove(f)
  local text, code = out:match('^(.*)\n(%d+)$')
  cb(tonumber(code) or 0, (tonumber(code) or 0) > 0 and text or nil)
end

math.randomseed(42)
Config = {} dofile(root .. 'config.lua') Config.PublicKey = env('PUBKEY', '')
local overrideInterval = tonumber(env('INTERVAL', '')) if overrideInterval then Config.Interval = overrideInterval end
dofile(root .. 'guard.lua')

-- scénario : demande de démarrage de ressources protégées pendant que la vérification est en cours, puis (option) avance dans le temps
local startOrder = { 'pickax_ui', 'pickax_core', 'pickax_jobbuilder', 'pickax_panel', 'es_extended' }
for _, n in ipairs(startOrder) do if rstate[n] ~= 'started' then startResource(n) end end
local hookAt, hookDone = tonumber(env('HOOK_AT', '')), false
local function run(seconds)
  local t0 = now
  local stop = now + seconds
  while now < stop do
    if hookAt and not hookDone and now - t0 >= hookAt then hookDone = true io.popen('curl -s -m 5 "' .. env('HOOK_URL', '') .. '"'):read('a') end
    local nextAt, ran = stop, false
    for _, t in ipairs(threads) do
      if coroutine.status(t.co) ~= 'dead' and t.at <= now then ran = true local ok, d = coroutine.resume(t.co) if not ok then log.prints[#log.prints + 1] = 'ERREUR LUA : ' .. tostring(d) end t.at = now + (tonumber(d) or 0) end
    end
    for _, t in ipairs(threads) do if coroutine.status(t.co) ~= 'dead' and t.at < nextAt then nextAt = t.at end end
    if not ran then now = math.max(now + 0.05, math.min(nextAt, stop)) end
  end
end
run(tonumber(env('RUN', '20')))
local out = { licensed = registered.IsLicensed and registered.IsLicensed() or false, status = registered.Status and registered.Status() or {}, cancelled = log.cancelled, ensured = log.ensured, stopped = log.stopped, started = log.started, states = {}, prints = log.prints }
for _, n in ipairs(ALL) do out.states[n] = rstate[n] end
realPrint('RESULT' .. json.encode(out))
