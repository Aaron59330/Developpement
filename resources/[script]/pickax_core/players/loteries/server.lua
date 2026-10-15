local AllPlayersLotery = {}
local AllPlayersLoteryByID = {}
local FinishTime = ""
local MontantAll = 0
local IDTOCHECK2 = 0

CreateThread(function()--Ajout des informations au cache
	Wait(1500)
    if Config.Debug then
        print('ESXCustom : Initialisation du menu loteries...')
    end
    MySQL.Async.fetchAll('SELECT * FROM lotery', {}, function(InfoReceive)
		for k, v in pairs(InfoReceive) do
            if AllPlayersLotery[v.identifier] == nil then
                AllPlayersLotery[v.identifier] = {}
                AllPlayersLotery[v.identifier].identifier = v.identifier

                AllPlayersLotery[v.identifier].code = {}
                if v.win == 1 then
                    AllPlayersLotery[v.identifier].code[v.code] = {code = v.code, win = true, gain = v.gain}
                else
                    AllPlayersLotery[v.identifier].code[v.code] = {code = v.code}
                end
                AllPlayersLotery[v.identifier].id = {}
                AllPlayersLotery[v.identifier].id[v.id] = v.id
            else
                if v.win == 1 then
                    AllPlayersLotery[v.identifier].code[v.code] = {code = v.code, win = true, gain = v.gain}
                else
                    AllPlayersLotery[v.identifier].code[v.code] = {code = v.code}
                end
                AllPlayersLotery[v.identifier].id[v.id] = v.id
            end

            AllPlayersLoteryByID[v.code] = {}
            AllPlayersLoteryByID[v.code].identifier = v.identifier
            AllPlayersLoteryByID[v.code].id = IDTOCHECK2 + 1
            IDTOCHECK2 = IDTOCHECK2 +1

            if v.win == 0 then
                MontantAll = MontantAll + 1
            end
		end

        if Config.Debug then
		    print('[^5LOAD^0] [^5'..#InfoReceive..'^0] tickets loteries ont été load avec succès !')
        end
    end)

    local currentDate = os.date("%Y-%m-%d")
    local year, month, day = currentDate:match("(%d+)-(%d+)-(%d+)")
    local currentDayOfWeek = tonumber(os.date("%w", os.time({year = year, month = month, day = day})))
    local daysUntilSunday = (7 - currentDayOfWeek) % 7
    local nextSundayDate = os.date("%d/%m/%Y à 00h00", os.time({year = year, month = month, day = day}) + daysUntilSunday * 24 * 60 * 60)
    FinishTime = nextSundayDate

    local SundayDay = os.date("%d", os.time({year = year, month = month, day = day}) + daysUntilSunday * 24 * 60 * 60)
    local SundayMonth = os.date("%m", os.time({year = year, month = month, day = day}) + daysUntilSunday * 24 * 60 * 60)
    if tonumber(os.date("%d")) == SundayDay and tonumber(os.date("%m")) == SundayMonth then
        Wait(2500)
        local pd = math.random(IDTOCHECK2)
        for k, v in pairs(AllPlayersLoteryByID) do
            if v.id == pd then
                AllPlayersLotery[v.identifier].code[k].win = true
                MySQL.Async.execute('UPDATE lotery SET win = @win, gain = @gain WHERE identifier = @identifier AND code = @code', {
                    ['@identifier'] = v.identifier,
                    ["@code"] = tonumber(AllPlayersLotery[v.identifier].code[k].code),
                    ["@win"] = tonumber(1),
                    ["@gain"] = tonumber(AllPlayersLotery[v.identifier].code[k].gain),
                }, function()
                end)

                MySQL.Async.fetchAll('SELECT * FROM lotery', {}, function(InfoReceive)
                    for q, z in pairs(InfoReceive) do
                        if z.win == 0 then
                            MySQL.Async.execute('DELETE FROM lotery WHERE win = @win', {
                                ['@win'] = 0
                            }, function(rowsChanged)
                            end)
                            if AllPlayersLoteryByID[z.code] ~= nil then
                                AllPlayersLoteryByID[z.code] = nil
                            end
    
                            if AllPlayersLotery[z.identifier] ~= nil and AllPlayersLotery[z.identifier].code[z.code] ~= nil then
                                AllPlayersLotery[z.identifier].code[z.code] = nil
                            end

                            MontantAll = MontantAll - 1
                        end
                    end
                end)
            end
        end
    end
end)

ESX.RegisterServerCallback("lotery:GetAll",function(source, cb)
    cb({all = MontantAll, source = AllPlayersLotery[ESX.GetPlayerFromId(source).identifier], Time = FinishTime})
end)

--Event
local ListToSave = {}
AddEventHandler('playerDropped', function (reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if (xPlayer) then
        local lotery = ListToSave[xPlayer.identifier]

        if lotery ~= nil then
            for k, v in pairs(lotery.code) do
                if not v.save then
                    MySQL.Async.execute('INSERT INTO lotery (identifier, code) VALUES (@identifier, @code)', {
                        ['@identifier'] = xPlayer.identifier,
                        ["@code"] = tonumber(k),
                    }, function()
                    end)
                end
            end
            lotery = nil
        end
    end
end)

RegisterServerEvent('switchFinished')
AddEventHandler('switchFinished', function()
	local _src = source
    local amount = 0
    local xPlayer = ESX.GetPlayerFromId(_src)

    if AllPlayersLotery[xPlayer.identifier] ~= nil then
        for k, v in pairs(AllPlayersLotery[xPlayer.identifier].code) do
            if v.win then
                amount = amount + 1
            end
        end

        if amount >= 1 then
            TriggerClientEvent(Config.Trigger.TriggerNotification, _src, "~y~Vous avez gagné avec x"..amount.." ticket, rendez-vous à la loterie.~s~")
        end
    end
end)

RegisterNetEvent('lotery:GiveServerSide', function(info)
    local _src = source

    if info.anticheat == nil or (info.anticheat ~= nil and info.anticheat == false) then
        if ConfigAC.AntiTrigger.Active then
            if ConfigAC.AntiTrigger.Kick then
                return ESXCustomServerUtils.rejectSuspiciousAction(_src, 'Désynchronisation avec le serveur ou detection de Cheat [Lotery]')
            elseif ConfigAC.AntiTrigger.Ban then
                TriggerEvent("BanSql:ICheatServer", _src, "Anticheat | Anti trigger [Lotery]", -1)
            end
        end
        return
    end

    VerifyToken(_src, function()
        ESXCustomServerUtils.GetDistance(_src, vector3(ConfigLotery.Pos[info.id].x, ConfigLotery.Pos[info.id].y, ConfigLotery.Pos[info.id].z), 10, "Loterie", true, function()
            local xPlayer = ESX.GetPlayerFromId(_src)
            if AllPlayersLotery[xPlayer.identifier] == nil then
                AllPlayersLotery[xPlayer.identifier] = {}
                AllPlayersLotery[xPlayer.identifier].identifier = xPlayer.identifier
                AllPlayersLotery[xPlayer.identifier].code = {}
                AllPlayersLotery[xPlayer.identifier].code[info.code] = {code = info.code}
            else
                AllPlayersLotery[xPlayer.identifier].code[info.code] = {code = info.code}
            end

            if ListToSave[xPlayer.identifier] == nil then
                ListToSave[xPlayer.identifier] = {}
                ListToSave[xPlayer.identifier].identifier = xPlayer.identifier
                ListToSave[xPlayer.identifier].code = {}
                ListToSave[xPlayer.identifier].code[info.code] = {code = info.code, save = false}
            else
                ListToSave[xPlayer.identifier].code[info.code] = {code = info.code, save = false}
            end

            RemoveMoneyOnBanque(_src, ConfigLotery.Price)
            TriggerClientEvent(Config.Trigger.TriggerNotification, _src, ConfigLotery.Text)
            MontantAll = MontantAll + 1
            TriggerClientEvent(Config.Trigger.TriggerNotification, -1, (ConfigLotery.Text2):format(MontantAll * ConfigLotery.PriceByTicket))
        end, function()
        end)
    end)
end)

RegisterNetEvent('lotery:Felicitations', function(info)
    local _src = source

    if info.anticheat == nil or (info.anticheat ~= nil and info.anticheat == false) then
        if ConfigAC.AntiTrigger.Active then
            if ConfigAC.AntiTrigger.Kick then
                return ESXCustomServerUtils.rejectSuspiciousAction(_src, 'Désynchronisation avec le serveur ou detection de Cheat [Lotery]')
            elseif ConfigAC.AntiTrigger.Ban then
                TriggerEvent("BanSql:ICheatServer", _src, "Anticheat | Anti trigger [Lotery]", -1)
            end
        end
        return
    end

    VerifyToken(_src, function()
        ESXCustomServerUtils.GetDistance(_src, vector3(ConfigLotery.Pos[info.id].x, ConfigLotery.Pos[info.id].y, ConfigLotery.Pos[info.id].z), 10, "Loterie", true, function()
            local xPlayer = ESX.GetPlayerFromId(_src)
            if AllPlayersLotery[xPlayer.identifier] == nil then
                if ConfigAC.AntiTrigger.Active then
                    if ConfigAC.AntiTrigger.Kick then
                        return ESXCustomServerUtils.rejectSuspiciousAction(_src, 'Désynchronisation avec le serveur ou detection de Cheat [Lotery]')
                    elseif ConfigAC.AntiTrigger.Ban then
                        TriggerEvent("BanSql:ICheatServer", _src, "Anticheat | Anti trigger [Lotery]", -1)
                    end
                end
                return
            else
                if AllPlayersLotery[xPlayer.identifier].code[info.code] == nil then
                    ESXCustomServerUtils.rejectSuspiciousAction(_src, 'Désynchronisation avec le serveur ou detection de Cheat [Lotery]')
                    return
                else
                    if AllPlayersLotery[xPlayer.identifier].code[info.code].win then
                        if ListToSave[xPlayer.identifier] ~= nil and ListToSave[xPlayer.identifier].code[info.code] ~= nil then
                            ListToSave[xPlayer.identifier].code[info.code] = nil
                        end
                        AddMoney(_src, AllPlayersLotery[xPlayer.identifier].code[info.code].gain)
                        TriggerClientEvent(Config.Trigger.TriggerNotification, _src, "Vous avez gagné avec ce ticket, toutes nos félicitations.\nVous avez gagnez : ~g~"..AllPlayersLotery[xPlayer.identifier].code[info.code].gain.."$~s~")
                        MySQL.Async.execute('DELETE FROM lotery WHERE code = @code', {
                            ['@code'] = info.code
                        }, function(rowsChanged)
                        end)
                        AllPlayersLotery[xPlayer.identifier].code[info.code] = nil
                    else
                        if ConfigAC.AntiTrigger.Active then
                            if ConfigAC.AntiTrigger.Kick then
                                return ESXCustomServerUtils.rejectSuspiciousAction(_src, 'Désynchronisation avec le serveur ou detection de Cheat [Lotery]')
                            elseif ConfigAC.AntiTrigger.Ban then
                                TriggerEvent("BanSql:ICheatServer", _src, "Anticheat | Anti trigger [Lotery]", -1)
                            end
                        end
                        return
                    end
                end
            end
        end, function()
        end)
    end)
end)