local ActualyMoney = 0
local ActualyMoneyBank = 0

RegisterNetEvent("ESXCustomGTAO:ReloadHUD", function()
    if ConfigHUDGTA.Allow then
        ESX.TriggerServerCallback("gtaOHud:GetAccountData", function(accounts) 
            if accounts ~= nil then
                SetMultiplayerBankCash()
                SetMultiplayerWalletCash()

                ActualyMoney = accounts.money
                ActualyMoneyBank = accounts.bank

                StatSetInt("BANK_BALANCE", accounts.bank, true) -- Bank
                StatSetInt("MP0_WALLET_BALANCE", accounts.money, true) -- Money
            end
        end)
    end
end)

local isShowing = false
RegisterCommand("hidehud", function()
    if not isShowing then
        isShowing = true
        SetMultiplayerBankCash()
        SetMultiplayerWalletCash()

        TriggerEvent('CorePickax:HUD:Reload:ClientSide', isShowing)

        StatSetInt("BANK_BALANCE", ActualyMoneyBank, true) -- Bank
        StatSetInt("MP0_WALLET_BALANCE", ActualyMoney, true) -- Money

        Citizen.SetTimeout(5000, function()
            RemoveMultiplayerBankCash()
            RemoveMultiplayerWalletCash()
            isShowing = false
            TriggerEvent('CorePickax:HUD:Reload:ClientSide', isShowing)
        end)
    end
end, false)

RegisterKeyMapping('hidehud', 'Affichage d\'argent.', 'keyboard', "W")

function CheckGTAO()
    return ConfigHUDGTA.Allow
end

exports('CheckGTAO', CheckGTAO)