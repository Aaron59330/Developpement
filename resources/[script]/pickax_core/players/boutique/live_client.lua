-- Client : reçoit la boutique réglée depuis le panel web (envoyée par le serveur à la connexion et à chaque modification).
RegisterNetEvent('CorePickax:boutique:cfg', function(ov) BoutiqueApplyOverride(ov) end)
CreateThread(function() Wait(4000) TriggerServerEvent('CorePickax:boutique:cfgRequest') end)
AddEventHandler('esx:playerLoaded', function() Wait(2000) TriggerServerEvent('CorePickax:boutique:cfgRequest') end)
