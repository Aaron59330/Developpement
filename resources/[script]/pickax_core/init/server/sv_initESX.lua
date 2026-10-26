-- [AERO:LIC] vérification autonome de la licence (jeton signé du panel, clé publique embarquée) : ne pas retirer
local AERO_PK = 'MCowBQYDK2VwAyEA3ygdLUgkYhpVm8Y7uOZQRyBbbjMZ8pAvWfCp0aAE0mU='
local aeroLic = false
exports('Licensed', function() return aeroLic == true end)   -- utilisé par les autres ressources de la base
do
    local res = GetCurrentResourceName()
    local function token()
        local ok, t = pcall(function() return exports.pickax_guard:Token() end)
        if ok and type(t) == 'table' and type(t.payload) == 'string' and type(t.sig) == 'string' then return t end
    end
    -- true / false ; nil si le module de vérification de cette ressource n'est pas encore chargé
    local function verify()
        local t = token()
        if not t then return nil end   -- pas encore de jeton (vérification du panel en cours) ou pickax_guard absent
        local ok, v = pcall(function() return exports[res]:LicVerify(t.payload, t.sig, AERO_PK, GetConvar('aero_panel_key', '')) end)
        if not ok then return nil end
        return v == true
    end
    local function die(why) print(('^1[AERO] %s arrêtée : %s^0'):format(res, why)) StopResource(res) end
    local first = verify()
    if first == false then die('licence invalide ou pickax_guard absent') error('AERO : licence invalide', 0) end
    aeroLic = first == true
    CreateThread(function()
        local tries = 0
        while first ~= true and tries < 40 do
            tries = tries + 1 Wait(500)
            first = verify()
            if first == false then die('licence invalide') return end
            aeroLic = first == true
        end
        if first ~= true then die('vérification de la licence impossible') return end
        while true do
            Wait(240000 + math.random(0, 120000))
            local good = false
            for _ = 1, 4 do if verify() == true then good = true break end Wait(10000) end
            aeroLic = good
            if not good then die('licence invalide') return end
        end
    end)
end
-- [/AERO:LIC]

ESX = exports["es_extended"]:getSharedObject()
