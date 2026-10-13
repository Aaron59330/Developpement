if ConfigRadio == nil then
    print('[FR] ^7[^1ESXCustom^0-^3Protect^7] ^1ERREUR^7 Le fichier ConfigRadio n\'est pas détécté.')
    print('[EN] ^7[^1ESXCustom^0-^3Protect^7] ^1ERROR^7 The ConfigRadio file is not detected.')
    return
end

if ConfigRadio.GestionRadio.VoiceChat ~= "pma-voice" and ConfigRadio.GestionRadio.VoiceChat ~= "mumble-voip" then
    print('[FR] : ^7[^1ESXCustom^0-^3Protect^7] ^1ERREUR^7 Le chat vocal n\'est pas détécté.')
    print('[EN]: ^7[^1ESXCustom^0-^3Protect^7] ^1ERROR^7 The voice chat is not detected.')
    return
end

local voiceChat = exports[ConfigRadio.GestionRadio.VoiceChat]
local open = false
function MenuRadio()
    local MenuRadio = RageUI.CreateMenu(ButtonRadio.TitleMenu, ButtonRadio.SubtitleMenu)
    MenuRadio.Closed = function()
        open = false
    end

    RageUI.Visible(MenuRadio, not RageUI.Visible(MenuRadio))
    Citizen.CreateThread(function()
        while open do
            RageUI.IsVisible(MenuRadio, true, true, true, function()
                for i = 1,#ConfigRadio.MenuRadio do 
                    local v = ConfigRadio.MenuRadio[i]

                    if v.Menu ~= nil then
                        if v.Menu == "Boutton" then
                            RageUI.ButtonWithStyle(v.Title, v.Desc, {RightLabel = v.RightLabel}, true, function(Hovered, Active, Selected)
                                if Selected then
                                    v.Selected()
                                    UseK = i
                                end
                            end)
                        elseif v.Menu == "Separator" then
                            RageUI.Separator(v.Title)
                        elseif v.Menu == "Line" then
                            RageUI.Line()
                        elseif v.Menu == "CheckBox" then
                            RageUI.Checkbox(v.Title, v.Desc, v.Status, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
                                v.Status = Checked;
                            end, function()
                                v.Status = true
                                v.Selected()
                            end, function()
                                v.Status = false
                                v.Selected2()
                            end)
                        end
                    end
                end
            end)

            if not open then
                MenuRadio = RMenu:DeleteType('MenuRadio', true)
            end

            Citizen.Wait(0)
        end
    end)
end

RegisterNetEvent("esx_custom:OpenRadio")
AddEventHandler("esx_custom:OpenRadio", function()
    ExecuteCommand(ConfigRadio.Commande.Commande)
end)

local LaDejaPerdu = false
RegisterKeyMapping(ConfigRadio.Commande.Commande, ConfigRadio.Commande.Description, 'keyboard', ConfigRadio.Commande.Bind)
RegisterCommand(ConfigRadio.Commande.Commande, function()
    if PlayerClass.pInWater then
        ESX.ShowNotification(NotificationRadio.Water)

        if ConfigRadio.Item.NeedItem and not LaDejaPerdu then
            LaDejaPerdu = true
            TriggerServerEvent("esx_custom:Radio:RemoveRadio")
        end
        return
    end

    if open then
        open = false
        RageUI.CloseAll()
    else
        if ConfigRadio.Item.NeedItem then
            LaDejaPerdu = false
            ESX.TriggerServerCallback('esx_custom:Radio:GetAmountItem', function(qtty)
                if qtty >= 1 then
                    open = true
                    if not IsPedDeadOrDying(PlayerPedId(), 1) then
                        MenuRadio()
                    end
                else
                    ESX.ShowNotification(NotificationRadio.NoRadio)
                end
            end)
        else
            open = true
            if not IsPedDeadOrDying(PlayerPedId(), 1) then
                MenuRadio()
            end
        end
    end
end, false)

local WasNotified = false
CreateThread(function()
    while true do
        Wait(1000)

        if PlayerClass.pInWater then
            if not WasNotified then
                WasNotified = true
                ESX.ShowNotification(NotificationRadio.Water2)
                RemoveFrequencyWater()
            end
        else
            if WasNotified then
                WasNotified = false
            end
        end
    end
end)

function RemoveFrequencyWater()
    if ConfigRadio.GestionRadio.VoiceChat == "mumble-voip" then
        voiceChat:SetRadioChannel(0)
    else
        voiceChat:setRadioChannel(0)
    end
    Radio.Frequence = "0"
    RageUI.Visible(MenuRadio, false)
    open = false
end

AddEventHandler('esx:onPlayerDeath', function(data)
    RemoveFrequencyWater()
end)

--Accès au fonction
Radio = {Tick = false, Bruitages = true, Volume = 1, Frequence = 0}
function AddFrequency()
    local verif, Frequence = ESXCustom_Function_ClientSide:CheckQuantity2(ESXCustom_Function_ClientSide:KeyboardInput(ButtonRadio.KeyboardInput, 5))
    if verif then
        if Frequence <= ConfigRadio.GestionRadio.MaxFrequency then
            if ConfigRadio.GestionJobs.Job1 and ConfigRadio.GestionJobs.Job2 then
                if ConfigRadio.GestionJobs.Jobs1[Frequence] == ESX.PlayerData.job.name or ConfigRadio.GestionJobs.Jobs2[Frequence] == ESX.PlayerData.job2.name then
                    Radio.Frequence = Frequence
                    if ConfigRadio.GestionRadio.VoiceChat == "mumble-voip" then
                        voiceChat:SetRadioChannel(Frequence)
                    else
                        voiceChat:setRadioChannel(Frequence)
                    end
                    ESX.ShowNotification((NotificationRadio.AccesYes):format(Frequence))
                    if tonumber(GetResourceKvpString("SetRadioESXCustomAuthorized")) ~= nil and tonumber(GetResourceKvpString("SetRadioESXCustomAuthorized")) == 1 then
                        DeleteResourceKvp("SetRadioESXCustom")
                        SetResourceKvp("SetRadioESXCustom", Frequence)
                    end
                else
                    if ConfigRadio.GestionJobs.Jobs1[Frequence] == nil and ConfigRadio.GestionJobs.Jobs2[Frequence] == nil then
                        Radio.Frequence = Frequence
                        if ConfigRadio.GestionRadio.VoiceChat == "mumble-voip" then
                            voiceChat:SetRadioChannel(Frequence)
                        else
                            voiceChat:setRadioChannel(Frequence)
                        end
                        ESX.ShowNotification((NotificationRadio.AccesYes):format(Frequence))
                        if tonumber(GetResourceKvpString("SetRadioESXCustomAuthorized")) ~= nil and tonumber(GetResourceKvpString("SetRadioESXCustomAuthorized")) == 1 then
                            DeleteResourceKvp("SetRadioESXCustom")
                            SetResourceKvp("SetRadioESXCustom", Frequence)
                        end
                    else
                        ESX.ShowNotification(NotificationRadio.AccesNo)
                    end
                end
            elseif ConfigRadio.GestionJobs.Job1 and ConfigRadio.GestionJobs.Job2 == false then
                if ConfigRadio.GestionJobs.Jobs1[Frequence] == ESX.PlayerData.job.name or ConfigRadio.GestionJobs.Jobs1[Frequence] == nil then
                    Radio.Frequence = Frequence
                    if ConfigRadio.GestionRadio.VoiceChat == "mumble-voip" then
                        voiceChat:SetRadioChannel(Frequence)
                    else
                        voiceChat:setRadioChannel(Frequence)
                    end
                    ESX.ShowNotification((NotificationRadio.AccesYes):format(Frequence))
                    if tonumber(GetResourceKvpString("SetRadioESXCustomAuthorized")) ~= nil and tonumber(GetResourceKvpString("SetRadioESXCustomAuthorized")) == 1 then
                        DeleteResourceKvp("SetRadioESXCustom")
                        SetResourceKvp("SetRadioESXCustom", Frequence)
                    end
                else
                    ESX.ShowNotification(NotificationRadio.AccesNo)
                end
            elseif ConfigRadio.GestionJobs.Job1 == false and ConfigRadio.GestionJobs.Job2 then
                if ConfigRadio.GestionJobs.Jobs2[Frequence] == ESX.PlayerData.job2.name or ConfigRadio.GestionJobs.Jobs2[Frequence] == nil  then
                    Radio.Frequence = Frequence
                    if ConfigRadio.GestionRadio.VoiceChat == "mumble-voip" then
                        voiceChat:SetRadioChannel(Frequence)
                    else
                        voiceChat:setRadioChannel(Frequence)
                    end
                    ESX.ShowNotification((NotificationRadio.AccesYes):format(Frequence))
                    if tonumber(GetResourceKvpString("SetRadioESXCustomAuthorized")) ~= nil and tonumber(GetResourceKvpString("SetRadioESXCustomAuthorized")) == 1 then
                        DeleteResourceKvp("SetRadioESXCustom")
                        SetResourceKvp("SetRadioESXCustom", Frequence)
                    end
                else
                    ESX.ShowNotification(NotificationRadio.AccesNo)
                end
            elseif ConfigRadio.GestionJobs.Job1 == false and ConfigRadio.GestionJobs.Job2 == false then
                Radio.Frequence = Frequence
                if ConfigRadio.GestionRadio.VoiceChat == "mumble-voip" then
                    voiceChat:SetRadioChannel(Frequence)
                else
                    voiceChat:setRadioChannel(Frequence)
                end
                if tonumber(GetResourceKvpString("SetRadioESXCustomAuthorized")) ~= nil and tonumber(GetResourceKvpString("SetRadioESXCustomAuthorized")) == 1 then
                    DeleteResourceKvp("SetRadioESXCustom")
                    SetResourceKvp("SetRadioESXCustom", Frequence)
                end
                ESX.ShowNotification((NotificationRadio.AccesYes):format(Frequence))
            end
        else
            ESX.ShowNotification((NotificationRadio.Error999):format(ConfigRadio.GestionRadio.MaxFrequency))
        end
    else
        ESX.ShowNotification(NotificationRadio.ErrorNotNumber)
    end
end

local function AddFrequency2(Frequence)
    Radio.Frequence = Frequence
    if ConfigRadio.GestionRadio.VoiceChat == "mumble-voip" then
        voiceChat:SetRadioChannel(Frequence)
    else
        voiceChat:setRadioChannel(Frequence)
    end
end

function GetFrequency(k)
    ConfigRadio.MenuRadio[k].RightLabel = Radio.Frequence
    return Radio.Frequence
end

function GetVolumeRadio(Augmenter, k)
    if ESXCustom_Function_ClientSide:MathRound(Radio.Volume*100) <= 20 then 
        ColorRadio = "~g~" 
    elseif ESXCustom_Function_ClientSide:MathRound(Radio.Volume*100) <= 45 then 
        ColorRadio ="~y~" 
    elseif ESXCustom_Function_ClientSide:MathRound(Radio.Volume*100) <= 65 then 
        ColorRadio ="~o~" 
    elseif ESXCustom_Function_ClientSide:MathRound(Radio.Volume*100) <= 100 then 
        ColorRadio ="~r~" 
    end

    if Augmenter == true then
        if ESXCustom_Function_ClientSide:MathRound(Radio.Volume*100) == 100 then
            ESX.ShowNotification(NotificationRadio.SoundRadioMax)
        else
            Radio.Volume = Radio.Volume + 0.05
        end
    else
        if ESXCustom_Function_ClientSide:MathRound(Radio.Volume*100) == 0 then
            ESX.ShowNotification(NotificationRadio.SoundRadioMin)
        else
            Radio.Volume = Radio.Volume - 0.05
        end
    end

    ConfigRadio.MenuRadio[k].Title = (ButtonRadio.Sound):format(ColorRadio, ESXCustom_Function_ClientSide:MathRound(Radio.Volume*100))
end

function ChangeStateRadio(k)
    if not Radio.Tick then 
        Radio.Tick = true
        if ConfigRadio.GestionRadio.VoiceChat == "mumble-voip" then
            voiceChat:SetMumbleProperty("radioEnabled", true)
        else
            voiceChat:setVoiceProperty("radioEnabled", true)
        end
        ESX.ShowNotification(NotificationRadio.RadioON)
        ConfigRadio.MenuRadio[k].RightLabel = ButtonRadio.RightLabelTurnOffOnRadio
    else
        Radio.Tick = false
        if ConfigRadio.GestionRadio.VoiceChat == "mumble-voip" then
            voiceChat:SetMumbleProperty("radioEnabled", false)
            voiceChat:SetRadioChannel(0)
        else
            voiceChat:setRadioChannel(0)
            voiceChat:setVoiceProperty("radioEnabled", false)
        end
        ESX.ShowNotification(NotificationRadio.RadioOFF)
        ConfigRadio.MenuRadio[k].RightLabel = ButtonRadio.RightLabelTurnOffOnRadio2
        DeleteResourceKvp("SetRadioESXCustom")
    end
end

function BruitagesRadio()
    if not Radio.Bruitages then
        Radio.Bruitages = true 
        if ConfigRadio.GestionRadio.VoiceChat == "mumble-voip" then
            voiceChat:SetMumbleProperty("micClicks", true)
        else
            voiceChat:setVoiceProperty("micClicks", true)
        end
        ESX.ShowNotification(NotificationRadio.SoundEffectsOn)
    else
        Radio.Bruitages = false
        if ConfigRadio.GestionRadio.VoiceChat == "mumble-voip" then
            voiceChat:SetMumbleProperty("micClicks", false)
        else
            voiceChat:setVoiceProperty("micClicks", false)
        end
        ESX.ShowNotification(NotificationRadio.SoundEffectsOff)
    end
end

function SaveFrequency(State, k)
    if State then
        DeleteResourceKvp("SetRadioESXCustomAuthorized")
        SetResourceKvp("SetRadioESXCustomAuthorized", 1)
        ESX.ShowNotification(NotificationRadio.EnableRadioFeedback)
        ConfigRadio.MenuRadio[k].Status = true
    else
        DeleteResourceKvp("SetRadioESXCustomAuthorized")
        SetResourceKvp("SetRadioESXCustomAuthorized", 2)
        ESX.ShowNotification(NotificationRadio.DisableRadioFeedback)
        ConfigRadio.MenuRadio[k].Status = false
    end
end

if ConfigRadio.GestionRadio.PersistentFrequency then
    RegisterNetEvent("esx:playerLoaded")
    AddEventHandler("esx:playerLoaded", function(xPlayer)
        local kvp = GetResourceKvpString("SetRadioESXCustom")

        if kvp ~= nil then
            Wait(5000)
            if tonumber(GetResourceKvpString("SetRadioESXCustomAuthorized")) ~= nil and tonumber(GetResourceKvpString("SetRadioESXCustomAuthorized")) == 1 then
                if ConfigRadio.Item.NeedItem then
                    ESX.TriggerServerCallback('esx_custom:Radio:GetAmountItem', function(qtty)
                        if qtty >= 1 then
                            AddFrequency2(tonumber(kvp))
                            ESX.ShowNotification(NotificationRadio.RedefinedRadio)
                            GetFrequency(ConfigRadio.MenuRadio.MenuChange.ChooseFrequency)
                            ConfigRadio.MenuRadio[ConfigRadio.MenuRadio.MenuChange.MenuRetourRadio].Status = true
            
                            Radio.Tick = true
                            if ConfigRadio.GestionRadio.VoiceChat == "mumble-voip" then
                                voiceChat:SetMumbleProperty("radioEnabled", true)
                            else
                                voiceChat:setVoiceProperty("radioEnabled", true)
                            end
                            ConfigRadio.MenuRadio[ConfigRadio.MenuRadio.MenuChange.MenuEteindreAllumer].RightLabel = ButtonRadio.RightLabelTurnOffOnRadio
                        end
                    end)
                else
                    AddFrequency2(tonumber(kvp))
                    ESX.ShowNotification(NotificationRadio.RedefinedRadio)
                    GetFrequency(ConfigRadio.MenuRadio.MenuChange.ChooseFrequency)
                    ConfigRadio.MenuRadio[ConfigRadio.MenuRadio.MenuChange.MenuRetourRadio].Status = true
    
                    Radio.Tick = true
                    if ConfigRadio.GestionRadio.VoiceChat == "mumble-voip" then
                        voiceChat:SetMumbleProperty("radioEnabled", true)
                    else
                        voiceChat:setVoiceProperty("radioEnabled", true)
                    end
                    ConfigRadio.MenuRadio[ConfigRadio.MenuRadio.MenuChange.MenuEteindreAllumer].RightLabel = ButtonRadio.RightLabelTurnOffOnRadio
                end
            end
        end
    end)
end