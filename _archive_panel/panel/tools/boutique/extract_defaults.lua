-- Lit resources/[script]/pickax_core/players/boutique/config.lua et écrit panel/public/boutique-defaults.js (valeurs d'origine proposées dans le panel)
-- Utilisation : lua5.4 panel/tools/boutique/extract_defaults.lua   (depuis la racine du dépôt)
vector3 = function(x, y, z) return { x = x, y = y, z = z } end
vec3 = vector3
dofile('resources/[script]/pickax_core/players/boutique/config.lua')
local function isArray(t) local n = 0 for k in pairs(t) do if type(k) ~= 'number' then return false end n = n + 1 end return n == #t end
local function enc(v)
  local t = type(v)
  if t == 'string' then return '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '') .. '"' end
  if t == 'number' or t == 'boolean' then return tostring(v) end
  if t == 'table' then
    if isArray(v) then local a = {} for i = 1, #v do a[i] = enc(v[i]) end return '[' .. table.concat(a, ',') .. ']' end
    local keys = {} for k in pairs(v) do keys[#keys + 1] = tostring(k) end table.sort(keys)
    local a = {} for _, k in ipairs(keys) do local val = v[k] if val == nil then val = v[tonumber(k)] end a[#a + 1] = enc(k) .. ':' .. enc(val) end
    return '{' .. table.concat(a, ',') .. '}'
  end
  return 'null'
end
local C, out = ConfigBoutique, {}
for _, k in ipairs({ 'vehicle', 'Motos', 'Autres', 'weapon', 'caisse', 'pack', 'vip', 'Entreprise', 'boost', 'ESXCustom', 'chance', 'weaponCustom', 'weaponCustomPrice', 'WeaponAmmoInWeapon', 'LinkShop' }) do
  if C[k] ~= nil then out[#out + 1] = '"' .. k .. '":' .. enc(C[k]) end
end
local f = assert(io.open('panel/public/boutique-defaults.js', 'w'))
f:write('// Généré par tools/boutique/extract_defaults.lua : valeurs d\'origine de la boutique (config.lua)\nwindow.BOUTIQUE_DEFAULT = {' .. table.concat(out, ',') .. '};\n')
f:close()
print('ok', #out .. ' blocs')
