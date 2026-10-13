-- ─────────────────────────────── Compatibilité esx_society / esx_addonaccount ───────────────────────────────
-- esx_society ne connaît que les sociétés enregistrées auprès de lui, et esx_addonaccount que les comptes chargés à son démarrage.
-- Les jobs créés par le builder leur sont donc inconnus : le « coffre de l'entreprise » d'un menu contextuel (esx_society:getSocietyMoney),
-- une tablette ou un menu boss tiers n'affichent rien ou 0. On les leur déclare ici, sans redémarrage quand c'est possible.

local noAddShared = {}   -- [ressource] = true : pas d'export AddSharedAccount (on ne réessaie pas)

-- Garantit les lignes SQL du compte (sinon rien ne persiste et le repli SQL ne peut rien modifier)
function JB.ensureRows(acc, jobName, money)
    local job = JB.Jobs[jobName]
    local label = job and job.label or jobName
    MySQL.update.await('INSERT IGNORE INTO addon_account (name, label, shared) VALUES (?, ?, 1)', { acc, label })
    MySQL.update.await('INSERT INTO addon_account_data (account_name, money, owner) SELECT ?, ?, NULL FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM addon_account_data WHERE account_name = ? AND owner IS NULL)', { acc, money or 0, acc })
end

local function accountHost()
    if GetResourceState('esx_addonaccount') == 'started' then return 'esx_addonaccount' end
    if GetResourceState('CorePickax') == 'started' then return 'CorePickax' end
end

-- Charge le compte société en mémoire d'esx_addonaccount (export AddSharedAccount), sans perdre le solde
local function ensureAccountInMemory(name, job)
    JB.forgetUnknownAccount(JB.societyAccount(name))
    if JB.sharedAccount(name) then return true end
    local host = accountHost()
    if not host or noAddShared[host] then return false end
    local acc = JB.societyAccount(name)
    local money = JB.sqlBalance(acc)
    -- AddSharedAccount crée lui-même les lignes : on les retire un instant, et on les rétablit si l'export n'existe pas / échoue
    MySQL.update.await('DELETE FROM addon_account_data WHERE account_name = ? AND owner IS NULL', { acc })
    MySQL.update.await('DELETE FROM addon_account WHERE name = ?', { acc })
    local ok, res = pcall(function() return exports[host]:AddSharedAccount({ name = acc, label = job.label }, money) end)
    JB.forgetUnknownAccount(acc)
    local mem = ok and JB.sharedAccount(name)
    if mem then
        -- l'export a chargé le compte : on s'assure que la base a bien ses lignes, avec le bon solde
        JB.ensureRows(acc, name, math.floor(tonumber(mem.money) or money))
        return true
    end
    JB.ensureRows(acc, name, money)
    if not ok then noAddShared[host] = true end
    return false
end

function JB.registerSociety(name)
    local job = JB.Jobs[name]
    if not job or not job.society then return end
    local acc = JB.societyAccount(name)
    pcall(ensureAccountInMemory, name, job)
    -- esx_society : enregistrement (idempotent)
    if GetResourceState('esx_society') == 'started' or GetResourceState('CorePickax') == 'started' then
        pcall(function() TriggerEvent('esx_society:registerSociety', name, job.label, acc, acc, acc, { type = 'private' }) end)
    end
end

function JB.registerAllSocieties()
    local n = 0
    for name, job in pairs(JB.Jobs) do
        if job.society then JB.registerSociety(name) n = n + 1 end
    end
    if n > 0 then print(('^2[jobbuilder] %d société(s) déclarée(s) à esx_society / esx_addonaccount.^0'):format(n)) end
end

-- Au démarrage, et à chaque (re)démarrage des scripts concernés (leurs listes sont alors vidées)
AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        CreateThread(function()
            while not JB.ready do Wait(200) end
            Wait(3000)
            JB.registerAllSocieties()
        end)
    elseif res == 'esx_society' or res == 'esx_addonaccount' or res == 'CorePickax' then
        noAddShared = {}
        CreateThread(function()
            Wait(5000)
            if JB.ready then JB.registerAllSocieties() end
        end)
    end
end)
