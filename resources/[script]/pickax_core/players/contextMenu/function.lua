-- Vente de rue du Builder Illégal (pickax_illegalbuilder) : sert à la place de l'ancien système (tablette vendeur, interrupteur panel, décisions côté serveur)
local function streetSale()
    if GetResourceState('pickax_illegalbuilder') ~= 'started' then return nil end
    local ok, on = pcall(function() return exports.pickax_illegalbuilder:StreetAvailable() end)
    if not ok or not on then return false end
    local ok2, items = pcall(function() return exports.pickax_illegalbuilder:StreetItems() end)
    local actions = {}
    for _, it in ipairs(ok2 and items or {}) do
        actions[#actions + 1] = { it.label, function() exports.pickax_illegalbuilder:StreetSell(LastEntityHit, it.item) end }
    end
    return actions
end

function _Peds()
    local street = streetSale()      -- nil : Builder Illégal absent (ancien système) · false : vente désactivée / pas de tablette · table : actions
    Action_Config = {
        Peds = {
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Distance = 3.0,
                Label = "Faire fuir",
                OnClick = function()
                    TaskSmartFleePed(LastEntityHit, PlayerPedId(), 9000.0, -1, false, false)
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Label = "Apaiser",
                OnClick = function()
                    ClearPedTasksImmediately(LastEntityHit)
                end,
            },
            {
                Type = "buttom-submenu",
                Label = "Vendre de la drogue",
                Blocked = street ~= nil,
                IsRestricted = false,
                CloseOnClick = true,
                Distance = 3.0,
                Condition = ESXCustomFonctionContextMenu:CheckSellDrugs(LastEntityHit),
                Action = {
                    {
                        "Coke", function()
                            ESXCustomFonctionContextMenu:Drugs(LastEntityHit, ConfigContextMenu.Drugs.DrugsList["coke"])
                        end
                    },                   
                    {
                        "Weed", function()
                            ESXCustomFonctionContextMenu:Drugs(LastEntityHit, ConfigContextMenu.Drugs.DrugsList["weed"])
                        end
                    },
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Vendre de la drogue",
                Blocked = not (type(street) == 'table' and #street > 0),
                IsRestricted = false,
                CloseOnClick = true,
                Distance = 3.0,
                Action = type(street) == 'table' and street or {},
            },
            {
                Type = "buttom-submenu",
                Label = "Animations PNJ",
                Blocked = false,
                IsRestricted = false,
                CloseOnClick = true,
                Distance = 3.0,
                Action = {
                    {
                        "Serrer la main", function()
                            ESXCustomFonctionContextMenu:MakeEntityFaceEntity(PlayerPedId(), LastEntityHit)
                            ESXCustomFonctionContextMenu:MakeEntityFaceEntity(LastEntityHit, PlayerPedId())
                            ESXCustomFonctionContextMenu:PlayAnim(PlayerPedId(), "mp_common", "givetake1_a", 8.0, -1, 0)
                            ESXCustomFonctionContextMenu:PlayAnim(LastEntityHit, "mp_common", "givetake1_a", 8.0, -1, 0)
                        end
                    },
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Actions admin",
                Blocked = false,
                IsRestricted = true,
                CloseOnClick = true,
                Action = {
                    {
                        ("ID : %s"):format(LastEntityHit or "Inconnu"), function()
                        end
                    },
                    {
                        'Freeze le PNJ', function()
                            if IsEntityPositionFrozen(LastEntityHit) then
                                FreezeEntityPosition(LastEntityHit, false)
                            else
                                FreezeEntityPosition(LastEntityHit, true)
                            end
                        end
                    },
                    {
                        'Supprimer le PNJ', function()
                            DeleteEntity(LastEntityHit)
                        end
                    },
                    {
                        "Téléporté sur lui", function()
                            SetEntityCoords(PlayerPedId(), GetEntityCoords(LastEntityHit))
                        end
                    },
                    {
                        "Téléporté à moi", function()
                            SetEntityCoords(LastEntityHit, GetEntityCoords(PlayerPedId()))
                        end
                    },
                    {
                        "Changer l'aparence", function()
                            SetPedRandomComponentVariation(LastEntityHit, 1)
                        end
                    },
                    {
                        "Prendre l'aparence", function()
                            model = GetEntityModel(LastEntityHit)
                            SetPlayerModel(PlayerId(), model)
                            SetPedDefaultComponentVariation(PlayerPedId())
                        end
                    },
                    {
                        "Reprendre son aparence", function()
                            ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                                local isMale = skin.sex == 0
                        
                                TriggerEvent('skinchanger:loadDefaultModel', isMale, function()
                                    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                                        TriggerEvent('skinchanger:loadSkin', skin)
                                        Citizen.Wait(200)
                                        TriggerEvent('esx:restoreLoadout')
                                    end)
                                end)
                            end)
                        end
                    },
                    {
                        "Give une arme", function()
                            local weapongivePNJ = ESXCustomFonctionContextMenu:Keyboard("Quelle arme donner au PNJ ? (ex: WEAPON_CARBINRIFLE)", 999, "small_text")

                            if weapongivePNJ ~= nil then
                                weapongivePNJ = weapongivePNJ:upper()
                                GiveWeaponToPed(LastEntityHit, GetHashKey(weapongivePNJ), 250, true, true)
                                ESX.ShowNotification("Le PNJ a bien reçu l\'arme.")
                            end
                        end
                    },
                    {
                        "Enlever son arme", true, function()
                            GiveWeaponToPed(LastEntityHit, GetHashKey("weapon_unarmed"), 250, true, true)
                        end
                    },
                    {
                        "Revive le PNJ", true, function()
                            ESXCustomFonctionContextMenu:RevivePed(LastEntityHit)
                        end
                    }
                },
            },
        },
    }
end

function _Object()
    Action_Config = {
        Object = {
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = false,
                FlecheActive = false,
                Props = {
                    [666561306] = true,
                    [1329570871] = true,
                    [218085040] = true,
                    [-1426008804] = true,
                    [-228596739] = true,
                    [-1681329307] = true
                },
                Distance = 2.0,
                -- Label = ("Votre ID : ~b~%s"):format(GetEntityModel(LastEntityHit)),
                Label = "Fouillez",
                OnClick = function()
                    ESXCustomFonctionContextMenu:Poubelle(LastEntityHit)
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = false,
                FlecheActive = false,
                Props = {
                    [-742198632] = true
                },
                Distance = 2.0,
                Label = "Prendre de l'eau ~g~2$",
                OnClick = function()
                    moneyremove = 2
                    ESXCustomFonctionContextMenu:TakeWaterOrCoffee(LastEntityHit, moneyremove)
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = false,
                FlecheActive = false,
                Props = {
                    [690372739] = true
                },
                Distance = 3,
                Label = "Prendre du café ~g~2$",
                OnClick = function()
                    moneyremove = 2
                    ESXCustomFonctionContextMenu:TakeWaterOrCoffee(LastEntityHit, moneyremove)
                end,
            },
            {
                Type = "buttom-submenu",
                Label = "Accedez à la machine",
                IsRestricted = false,
                CloseOnClick = true,
                FlecheActive = false,
                Distance = 3,
                Props = {
                    [1114264700] = true,
                    [992069095] = true,
                    [-654402915] = true
                },
                Action = {
                    {
                        "Prendre du coca ~g~2$", function()
                            ESXCustomFonctionContextMenu:Machine(LastEntityHit, 2, "coca")
                        end
                    },
                    {
                        "Prendre du sprite ~g~2$", function()
                            ESXCustomFonctionContextMenu:Machine(LastEntityHit, 2, "sprite")
                        end
                    },
                    {
                        "Prendre du orangina ~g~2$", function()
                            ESXCustomFonctionContextMenu:Machine(LastEntityHit, 2, "orangina")
                        end
                    },
                    {
                        "Prendre du fanta ~g~2$", function()
                            ESXCustomFonctionContextMenu:Machine(LastEntityHit, 2, "fanta")
                        end
                    }
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Accedez à l'ATM",
                IsRestricted = false,
                CloseOnClick = true,
                Props = {
                    [-870868698] = true,
                    [-1249610058] = true,
                    [-1126237515] = true,
                    [-1364697528] = true
                },
                Action = {
                    {
                        "↓ ~b~Vos informations~s~ ↓", function()
                        end
                    },
                    {
                        "Nom :~p~ "..GetPlayerName(PlayerId()), function()
                        end
                    },
                    {
                        "Votre argent : ~g~"..GroupDigits(Argent).."$", function()
                        end
                    },
                    {
                        "Votre argent en banque : ~b~"..GroupDigits(ArgentBanque).."$", function()
                        end
                    },
                    {
                        "Separator", function()
                        end
                    },
                    {
                        "Déposer de l'argent", function()
                            ESXCustomFonctionContextMenu:CloseMenu()
                            ESXCustomFonctionContextMenu:saisiedepot()
                        end
                    },
                    {
                        "Retiré de l'argent", function()
                            ESXCustomFonctionContextMenu:CloseMenu()
                            ESXCustomFonctionContextMenu:saisieretrait()
                        end
                    },
                    {
                        "Envoyer de l'argent", function()
                            ESXCustomFonctionContextMenu:CloseMenu()
                            ESXCustomFonctionContextMenu:transferetopersonne()
                        end
                    }
                
                },
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = false,
                FlecheActive = false,
                Props = {
                    [526185503] = true,
                    [-1971298567] = true,
                    [-1118419705] = true,
                    [538002882] = true,
                    [1805980844] = true,
                    [-784954167] = true,
                    [-1278649385] = true,
                    [558578166] = true,
                    [589738836] = true,
                    [1028260687] = true,
                    [-1761659350] = true,
                    [-2016553006] = true,
                    [47332588] = true,
                    [867556671] = true,
                    [-470815620] = true,
                    [736919402] = true,
                    [-628719744] = true,
                    [-377849416] = true,
                    [1037469683] = true,
                    [-109356459] = true,
                    [1816935351] = true,
                    [1889748069] = true,
                    [1577885496] = true,
                    [-1692911878] = true,
                    [-501934650] = true,
                    [-741944541] = true
                },
                Distance = 3,
                Label = "S'assoir",
                Condition = IlestAssis ~= true,
                OnClick = function()
                    ESXCustomFonctionContextMenu:SitChair(LastEntityHit)
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = false,
                FlecheActive = false,
                Props = {
                    [526185503] = true,
                    [-1971298567] = true,
                    [-1118419705] = true,
                    [538002882] = true,
                    [1805980844] = true,
                    [-784954167] = true,
                    [-1278649385] = true,
                    [558578166] = true,
                    [589738836] = true,
                    [1028260687] = true,
                    [-1761659350] = true,
                    [-2016553006] = true,
                    [47332588] = true,
                    [867556671] = true,
                    [-470815620] = true,
                    [736919402] = true,
                    [-628719744] = true,
                    [-377849416] = true,
                    [1037469683] = true,
                    [-109356459] = true,
                    [1816935351] = true,
                    [1889748069] = true,
                    [1577885496] = true,
                    [-1692911878] = true,
                    [-501934650] = true,
                    [-741944541] = true
                },
                Distance = 3,
                Label = "Se lever",
                Condition = IlestAssis == true,
                OnClick = function()
                    ESXCustomFonctionContextMenu:LiftChair()
                end,
            },
            {
                Type = "buttom-submenu",
                Label = "Actions admin",
                IsRestricted = true,
                CloseOnClick = true,
                FlecheActive = false,
                Action = {
                    {
                        "ID : ~b~"..GetEntityModel(LastEntityHit), function()
                        end
                    },
                    {
                        "Supprimer le props", function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                SetEntityAsMissionEntity(LastEntityHit)
                                DeleteEntity(LastEntityHit)
                            end
                        end
                    },
                    {
                        "Déplacer le props", function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                ESXCustomFonctionContextMenu:SpawnObj(LastEntityHit)
                                SetEntityAsMissionEntity(LastEntityHit)
                                DeleteEntity(LastEntityHit)
                            end
                        end
                    },
                    {
                        "Dupliquer le props", function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                ESXCustomFonctionContextMenu:SpawnObj(LastEntityHit)
                            end
                        end
                    }
                },
            },
        },
    }
end

function _MoiMort()
    Action_Config = {
        MoiMort = {
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = false,
                FlecheActive = false,
                Label = "~r~Vous êtes mort !",
                OnClick = function()
                end,
            },
        },
    }
end

function _Moi()
    Action_Config = {
        My = {
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = false,
                FlecheActive = false,
                Label = ("Votre ID : ~b~%s"):format(ESXCustomFonctionContextMenu:MonID()),
                OnClick = function()
                end,
            },
            {
                Type = "buttom-submenu",
                Label = "Vos informations",
                IsRestricted = false,
                CloseOnClick = true,
                FlecheActive = false,
                DoubleSub = true,
                DoubleSubLabel = "Vos cartes",
                TripleSub = true,
                TripleSubLabel = "Vos factures",
                Action = {
                    {
                        ("Job : %s"):format(ESX.PlayerData.job.label), function()
                        end
                    },
                    {
                        ("Organisation : %s"):format(ESX.PlayerData.job2.label), function()
                        end
                    },
                    {
                        ("Votre argent (sur vous) : ~g~%s$"):format(Argent), function()
                        end
                    },
                    {
                        ("Votre argent (en banque) : ~b~%s$"):format(ArgentBanque), function()
                        end
                    },
                    {
                        ("Votre argent (sale) : ~r~%s$"):format(ArgentSale), function()
                        end
                    }
                },
                DoubleSubAction = {
                    {
                        'Montrer sa ~b~carte d\'identité', function() 
                            local closestPlayer, closestDistance = GetClosestPlayer()
                            if closestDistance ~= -1 and closestDistance <= 3.0 then
                                TriggerServerEvent("jsfour-idcard:open", ESXCustomFonctionContextMenu:MonID(), GetPlayerServerId(closestPlayer))
                            else
                                ESX.ShowNotification("Aucun joueur à proximité")
                            end
                        end
                    },
                    {
                        "Voir sa ~b~carte d\'identité", function()
                            TriggerServerEvent("jsfour-idcard:open", ESXCustomFonctionContextMenu:MonID(), ESXCustomFonctionContextMenu:MonID())
                        end
                    },
                    {
                        "Montrer son ~g~permis de conduire", function()
                            local closestPlayer, closestDistance = GetClosestPlayer()
                            if closestDistance ~= -1 and closestDistance <= 3.0 then
                                TriggerServerEvent("jsfour-idcard:open", ESXCustomFonctionContextMenu:MonID(), GetPlayerServerId(closestPlayer), 'driver')
                            else
                                ESX.ShowNotification("~y~Personne autour de vous~s~")
                            end
                        end
                    },
                    {
                        "Voir son ~g~permis de conduire", function()
                            TriggerServerEvent("jsfour-idcard:open", ESXCustomFonctionContextMenu:MonID(), ESXCustomFonctionContextMenu:MonID(), 'driver')
                        end
                    },
                    {
                        "Montrer son ~r~permis port d\'armes", function()
                            local closestPlayer, closestDistance = GetClosestPlayer()
                            if closestDistance ~= -1 and closestDistance <= 3.0 then
                                TriggerServerEvent("jsfour-idcard:open", ESXCustomFonctionContextMenu:MonID(), GetPlayerServerId(closestPlayer), 'weapon')
                            else
                                ESX.ShowNotification("~y~Personne autour de vous~s~")
                            end
                        end
                    },
                    {
                        "Voir son ~r~permis port d\'armes", function()
                            TriggerServerEvent("jsfour-idcard:open", ESXCustomFonctionContextMenu:MonID(), ESXCustomFonctionContextMenu:MonID(), 'weapon')
                        end
                    }
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Actions RP",
                Condition = ConfigContextMenu.Menu.RPActions ~= false,
                IsRestricted = false,
                CloseOnClick = true,
                Action = {
                    { "Attendre (impatient)", true, function()
                        ESXCustomFonctionContextMenu:RPScenario("WORLD_HUMAN_STAND_IMPATIENT")
                    end },
                    { "S'appuyer au mur", true, function()
                        ESXCustomFonctionContextMenu:RPScenario("WORLD_HUMAN_LEANING")
                    end },
                    { "Prendre un appel", true, function()
                        ESXCustomFonctionContextMenu:RPScenario("WORLD_HUMAN_STAND_MOBILE", "passe un appel")
                    end },
                    { "Regarder autour (jumelles)", true, function()
                        ESXCustomFonctionContextMenu:RPScenario("WORLD_HUMAN_BINOCULARS", "regarde au loin avec des jumelles")
                    end },
                    { "Prendre des notes", true, function()
                        ESXCustomFonctionContextMenu:RPScenario("WORLD_HUMAN_CLIPBOARD", "prend des notes")
                    end },
                    { "Se faire entendre (/me)", true, function()
                        ESXCustomFonctionContextMenu:CloseMenu()
                        local txt = ESXCustomFonctionContextMenu:Keyboard("Action /me", 120, "small_text")
                        if txt and txt ~= "" then ESXCustomFonctionContextMenu:Command("me " .. txt) end
                    end },
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Autre menu",
                IsRestricted = false,
                CloseOnClick = true,
                FlecheActive = false,
                DoubleSub = false,
                DoubleSubLabel = "nothing",
                TripleSub = false,
                TripleSubLabel = "nothing",
                Action = {
                    {
                        "Ouvrir le menu emote", true, function()
                            OpenEmoteMenu()
                        end
                    },
                    {
                        "Ouvrir le menu clef", true, function()
                            OpenMenuListeClef()
                        end
                    }
                },
                DoubleSubAction = {
                },
                TripleSubAction = {
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Graphismes",
                IsRestricted = false,
                CloseOnClick = true,
                FlecheActive = false,
                DoubleSub = false,
                DoubleSubLabel = "nothing",
                TripleSub = false,
                TripleSubLabel = "nothing",
                Action = {
                    {
                        "Changer la Vue en Normal !", function()
                            ESXCustomFonctionContextMenu:Graphisme('')
                        end
                    },
                    {
                        "Vue & lumières améliorées", function()
                            ESXCustomFonctionContextMenu:Graphisme('tunnel')
                        end
                    },
                    {
                        "Couleurs amplifiées", function()
                            ESXCustomFonctionContextMenu:Graphisme('rply_saturation')
                        end
                    },
                    {
                        "Noir & blancs", function()
                            ESXCustomFonctionContextMenu:Graphisme('rply_saturation_neg')
                        end
                    },
                    {
                        "Optimisation", function()
                            ESXCustomFonctionContextMenu:Optimisation()
                        end
                    }
                },
                DoubleSubAction = {
                },
                TripleSubAction = {
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Entreprise",
                IsRestricted = false,
                CloseOnClick = true,
                FlecheActive = false,
                DoubleSub = false,
                DoubleSubLabel = "nothing",
                TripleSub = false,
                TripleSubLabel = "nothing",
                Condition = ESX.PlayerData.job.grade_name == 'boss' and ESX.PlayerData.job.name ~= "unemployed",
                Action = {
                    {
                        ESX.PlayerData.job.label.." à ~g~"..societymoney.."$~s~ dans l'entreprise", function()
                        end
                    },
                    {
                        "Recruter le joueur", function()
                            local closestPlayer, closestDistance = GetClosestPlayer()
                            if closestPlayer == -1 or closestDistance > 3.0 then
                                ESX.ShowNotification('Aucun joueur proche.')
                            else
                                TriggerServerEvent('ContextMenu:Boss_recruterplayer', GetPlayerServerId(closestPlayer))
                            end
                        end
                    },
                    {
                        "Promouvoir le joueur", function()
                            local closestPlayer, closestDistance = GetClosestPlayer()
                            if closestPlayer == -1 or closestDistance > 3.0 then
                                ESX.ShowNotification('Aucun joueur proche.')
                            else
                                TriggerServerEvent('ContextMenu:Boss_promouvoirplayer', GetPlayerServerId(closestPlayer))
                            end
                        end
                    },
                    {
                        "Rétrogradé le joueur", function()
                            local closestPlayer, closestDistance = GetClosestPlayer()
                            if closestPlayer == -1 or closestDistance > 3.0 then
                                ESX.ShowNotification('Aucun joueur proche.')
                            else
                                TriggerServerEvent('ContextMenu:Boss_destituerplayer', GetPlayerServerId(closestPlayer))
                            end
                        end
                    },
                    {
                        "Viré le joueur", function()
                            local closestPlayer, closestDistance = GetClosestPlayer()
                            if closestPlayer == -1 or closestDistance > 3.0 then
                                ESX.ShowNotification('Aucun joueur proche.')
                            else
                                TriggerServerEvent('ContextMenu:Boss_virerplayer', GetPlayerServerId(closestPlayer))
                            end
                        end
                    }
                },
                DoubleSubAction = {
                },
                TripleSubAction = {
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Organisation",
                IsRestricted = false,
                CloseOnClick = true,
                FlecheActive = false,
                DoubleSub = false,
                DoubleSubLabel = "nothing",
                TripleSub = false,
                TripleSubLabel = "nothing",
                Condition = ESX.PlayerData.job2 and ESX.PlayerData.job2.name ~= "unemployed2" and ESX.PlayerData.job2.name ~= "unemployed",

                Action = {
                    {
                        ESX.PlayerData.job2.label.." à ~r~"..societymoney2.."$~s~ dans l'Organisation", function()
                        end
                    },
                    {
                        "Recruter le joueur", function()
                            local closestPlayer, closestDistance = GetClosestPlayer()
                            if closestPlayer == -1 or closestDistance > 3.0 then
                                ESX.ShowNotification('Aucun joueur proche.')
                            else
                                TriggerServerEvent('ContextMenu:Boss_recruterplayer2', GetPlayerServerId(closestPlayer))
                            end
                        end
                    },
                    {
                        "Promouvoir le joueur", function()
                            local closestPlayer, closestDistance = GetClosestPlayer()
                            if closestPlayer == -1 or closestDistance > 3.0 then
                                ESX.ShowNotification('Aucun joueur proche.')
                            else
                                TriggerServerEvent('ContextMenu:Boss_promouvoirplayer2', GetPlayerServerId(closestPlayer))
                            end
                        end
                    },
                    {
                        "Rétrogradé le joueur", function()
                            local closestPlayer, closestDistance = GetClosestPlayer()
                            if closestPlayer == -1 or closestDistance > 3.0 then
                                ESX.ShowNotification('Aucun joueur proche.')
                            else
                                TriggerServerEvent('ContextMenu:Boss_destituerplayer2', GetPlayerServerId(closestPlayer))
                            end
                        end
                    },
                    {
                        "Viré le joueur", function()
                            local closestPlayer, closestDistance = GetClosestPlayer()
                            if closestPlayer == -1 or closestDistance > 3.0 then
                                ESX.ShowNotification('Aucun joueur proche.')
                            else
                                TriggerServerEvent('ContextMenu:Boss_virerplayer2', GetPlayerServerId(closestPlayer))
                            end
                        end
                    },
                    {
                        "Ouvrir la tablette de gang", true, function()
                            if GetResourceState('pickax_gangbuilder') ~= 'started' then
                                ESX.ShowNotification("~r~La tablette n'est pas démarrée.")
                                return
                            end
                            ESXCustomFonctionContextMenu:CloseMenu()
                            CreateThread(function()
                                Wait(300)
                                TriggerEvent('gangbuilder:client:openTablet')
                            end)
                        end
                    }
                },
                DoubleSubAction = {
                },
                TripleSubAction = {
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Actions admin",
                IsRestricted = true,
                CloseOnClick = true,
                Action = {
                    {
                        "ID du joueurs : "..ESXCustomFonctionContextMenu:MonID(), function()
                        end
                    },
                    {
                        'Se give un item', function() 
                            local obj_give = ESXCustomFonctionContextMenu:Keyboard('Nom de l\'item', 320, "small_text")
                            local obj_givenb = ESXCustomFonctionContextMenu:Keyboard('Combien ?', 320, "small_text")

                            if obj_give ~= nil and obj_givenb ~= nil then
                                ESXCustomFonctionContextMenu:Command('giveitem '..ESXCustomFonctionContextMenu:MonID()..' '..obj_give..' '..obj_givenb..'')
                            end
                        end
                    },
                    {
                        'Heal', function()
                            TriggerServerEvent('ContextMenu:healPlayer', ESXCustomFonctionContextMenu:MonID())
                        end
                    },
                    {
                        'Revive', function() 
                            ExecuteCommand("revive "..ESXCustomFonctionContextMenu:MonID())
                        end
                    },
                    {
                        'Menu giveItem', function() 
                            ESXCustomMenu:OpenGiveitems(PlayerPedId())
                        end
                    },
                    {
                        'Spawn véhicule', function() 
                            ESXCustomFonctionContextMenu:CloseMenu()
                            local modelede = ESXCustomFonctionContextMenu:Keyboard("Entrez le modèle", 100, "small_text")
                            if IsModelInCdimage(modelede) then
                                ESX.ShowNotification("Chargement du véhicule...")
                                Wait(500)
                                local playerPed = PlayerPedId()
                                local playerCoords, playerHeading = GetEntityCoords(playerPed), GetEntityHeading(playerPed)
                                
                                ESX.Game.SpawnVehicle(modelede, playerCoords, playerHeading, function(vehicle)
                                    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                                    ESX.ShowNotification("~g~Le véhicule a bien spawn")
                                end)
                            else
                                ESX.ShowNotification("Chargement du véhicule...")
                                Wait(1000)
                                ESX.ShowNotification("~r~Le véhicule souhaitez n'existe pas !")
                            end
                        end
                    },
                    {
                        'Gestion message', function()
                            ESXCustomMenu:OpenMenuMessage()
                        end
                    },
                    {
                        'CheckboxESXCustom', "No-Clip", function()
                            ESXCustomFonctionContextMenu:NoClip()
                        end
                    },
                },
            }
        },
    }

    -- Placement des armes (pickax_weaponcarry) : catégorie « Gestion armes » → une arme → dos / ceinture / poche / cachée
    if GetResourceState('pickax_weaponcarry') == 'started' then
        local ok, entries = pcall(function() return exports['pickax_weaponcarry']:GetEntries() end)
        if ok and type(entries) == 'table' and #entries > 0 then
            table.insert(Action_Config.My, { Type = "Separator" })
            local groups = {}
            for _, w in ipairs(entries) do
                local actions = {}
                local cur = "Cachée"
                for _, pl in ipairs(w.places) do
                    local name = w.name
                    if pl.id == w.current then cur = pl.label end
                    local on = pl.id == w.current
                    actions[#actions + 1] = { (on and "~b~" or "") .. pl.label, function()
                        exports['pickax_weaponcarry']:SetPlacement(name, pl.id)
                    end, on and "~b~ACTIF" or nil }
                end
                groups[#groups + 1] = { Label = ("%s ~b~· %s"):format(w.label, cur), Action = actions }
            end
            table.insert(Action_Config.My, { Type = "nested-submenu", Label = "Gestion armes", Blocked = false, IsRestricted = false, CloseOnClick = true, Groups = groups })
        end

        -- Style de visée (posture de l'arme en main) : une entrée par arme qui propose au moins un style
        local okS, styled = pcall(function() return exports['pickax_weaponcarry']:GetStyleEntries() end)
        if okS and type(styled) == 'table' and #styled > 0 then
            local sgroups = {}
            for _, w in ipairs(styled) do
                local actions, cur = {}, 'Standard'
                for _, st in ipairs(w.styles) do
                    local name = w.name
                    if st.id == w.current then cur = st.label end
                    local on = st.id == w.current
                    actions[#actions + 1] = { (on and "~b~" or "") .. st.label, function()
                        exports['pickax_weaponcarry']:SetAimStyle(name, st.id)
                    end, on and "~b~ACTIF" or nil }
                end
                sgroups[#sgroups + 1] = { Label = ("%s ~b~· %s"):format(w.label, cur), Action = actions }
            end
            table.insert(Action_Config.My, { Type = "nested-submenu", Label = "Style de visée", Blocked = false, IsRestricted = false, CloseOnClick = true, Groups = sgroups })
        end
    end
end

function _Weather()
    Action_Config = {
        Weather = {
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = false,
                Condition = AdminPlayerJoueur == false,
                Label = ("Vous devez être admin"),
                OnClick = function()
                end,
            },
            {
                Type = "buttom",
                IsRestricted = true,
                Blocked = false,
                CloseOnClick = false,
                Label = ("~y~Admin"),
                OnClick = function()
                end,
            },
            {
                Type = "buttom-submenu",
                Label = "Changer le temps",
                IsRestricted = true,
                CloseOnClick = true,
                DoubleSub = false,
                DoubleSubLabel = "Changer le temps",
                Distance = 10.0,
                DoubleSubAction = {
                },
                Action = {
                    {
                        '~b~Freeze le temps', true, function()--mettre true si vous voulez mettre la fleche sinon mettez rien
                            ESXCustomFonctionContextMenu:Weather("freezeweather")
                        end
                    },
                    {
                        "Separator", function()
                        end
                    },
                    {   
                        "Dégager", function()
                            ESXCustomFonctionContextMenu:Weather("Clear")
                        end
                    },
                    {
                        "Extra-ensoleillé", function()
                            ESXCustomFonctionContextMenu:Weather("Extrasunny")
                        end
                    },
                    {
                        "Nuageux", function()
                            ESXCustomFonctionContextMenu:Weather("Clouds")
                        end
                    },
                    {
                        "Ciel couvert", function()
                            ESXCustomFonctionContextMenu:Weather("Overcast")
                        end
                    },
                    {
                        "Pluie", function()
                            ESXCustomFonctionContextMenu:Weather("Rain")
                        end
                    },
                    {
                        "Dégager", function()
                            ESXCustomFonctionContextMenu:Weather("Clearing")
                        end
                    },
                    {
                        "Orage", function()
                            ESXCustomFonctionContextMenu:Weather("Thunder")
                        end
                    },
                    {
                        "Ciel pollué", function()
                            ESXCustomFonctionContextMenu:Weather("Smog")
                        end
                    },
                    {
                        "Brumeux", function()
                            ESXCustomFonctionContextMenu:Weather("Foggy")
                        end
                    },
                    {
                        "Neige", function()
                            ESXCustomFonctionContextMenu:Weather("Xmas")
                        end
                    },
                    {
                        "Temps de noël", function()
                            ESXCustomFonctionContextMenu:Weather("Snowlight")
                        end
                    },
                    {
                        "Tempête de neige", function()
                            ESXCustomFonctionContextMenu:Weather("Blizzard")
                        end
                    },
                    {
                        "Halloween", function()
                            ESXCustomFonctionContextMenu:Weather("Halloween")
                        end
                    }
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Changer l'heure",
                IsRestricted = true,
                CloseOnClick = true,
                DoubleSub = false,
                DoubleSubLabel = "Changer l'heure",
                DoubleSubAction = {
                },
                Action = {
                    {
                        '~b~Freeze l\'heure', true, function()--mettre true si vous voulez mettre la fleche sinon mettez rien
                            ESXCustomFonctionContextMenu:Command("freezetime")
                        end
                    },
                    {
                        "Separator", function()
                        end
                    },
                    { 
                        "Matin", function()
                            ESXCustomFonctionContextMenu:Command("time 8 0")
                        end
                    },
                    {
                        "Après-midi", function()
                            ESXCustomFonctionContextMenu:Command("time 12 0")
                        end
                    },
                    { 
                        "Soir", function()
                            ESXCustomFonctionContextMenu:Command("time 18 0")
                        end
                    },
                    { 
                        "Nuit", function()
                            ESXCustomFonctionContextMenu:Command("time 0 0")
                        end
                    },
                },
            }
        },
    }
end

function _AtPose()
    Action_Config = {
        AtPose = {
            [1] = {
                Name = "Ouvrir le coffre LTD",
                Condition = ESX.PlayerData.job ~= nil and ESX.PlayerData.job.name == "ltd1",
                height = 0.03,
                FlecheActive = true,
                CloseOnClick = true,
                MaxCoords = 2.0,
                Coords = vec3(-706.147766, -912.944580, 19.215588),
                OnClick = function()
                    print("Vous avez ouvert le coffre ltd.")
                end
            }
        }
    }
end

function _Other()
    Action_Config = {
        Other = {
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = false,
                Condition = AdminPlayerJoueur == false,
                Label = "Ya rien ici !",
                OnClick = function()
                end
            },
            {
                Type = "buttom",
                IsRestricted = true,
                Blocked = false,
                CloseOnClick = false,
                Label = "Poser un PNJ",
                OnClick = function()
                    local pedname = ESXCustomFonctionContextMenu:Keyboard("Nom du ped", 999, "small_text")

                    if pedname ~= nil then
                        Citizen.CreateThread(function()
                            RequestModel(pedname)
                    
                            while not HasModelLoaded(pedname) do
                                Citizen.Wait(1)
                            end
                
                            local weaponforpnj = ESXCustomFonctionContextMenu:Keyboard("Donner une arme au PNJ ? (Oui ou non)", 3, "small_text")
                            local ped = CreatePed(GetPedType(pedname), pedname, PoseCursor, GetEntityHeading(PlayerPedId()), false, true)
                            if weaponforpnj == "yes" or weaponforpnj == "oui" or weaponforpnj == "Oui" or weaponforpnj == "Yes" then
                                local weapongivePNJ = ESXCustomFonctionContextMenu:Keyboard("Quelle arme donner au PNJ ? (ex: WEAPON_CARBINERIFLE)", 999, "small_text")
                                if weapongivePNJ ~= nil then
                                    GiveWeaponToPed(ped, GetHashKey(weapongivePNJ), 250, true, true)
                                    ESX.ShowNotification("Le PNJ a bien reçu l\'arme.")
                                end
                            end
                        end)
                    end
                end
            },
            {
                Type = "buttom",
                IsRestricted = true,
                Blocked = false,
                CloseOnClick = false,
                Label = "Poser un props",
                OnClick = function()
                    local PropsForSpawn = ESXCustomFonctionContextMenu:Keyboard("Nom du props ?", 999, "small_text")
                    if PropsForSpawn ~= nil then
                        local hash = GetHashKey(PropsForSpawn)
                        local props = CreateObject(hash, PoseCursor, true, false, true)
                    end
                end
            },
            {
                Type = "buttom",
                IsRestricted = true,
                Blocked = false,
                CloseOnClick = false,
                Label = "Poser un véhicule",
                OnClick = function()
                    local laquelle = ESXCustomFonctionContextMenu:Keyboard("Nom du véhicule ?", 15, "small_text")
                    ESXCustomFonctionContextMenu:SpawnCar(laquelle, PoseCursor)
                end
            },
            {
                Type = "buttom",
                IsRestricted = true,
                Blocked = false,
                CloseOnClick = false,
                Label = "Afficher un message ici",
                OnClick = function()
                    local laquelle = ESXCustomFonctionContextMenu:Keyboard("Que-voulez mettre comme texte ?", 999, "small_text")
                    if laquelle ~= nil then
                        ESXCustomFonctionContextMenu:LoadText(laquelle)
                    end
                end
            },
        },
    }
end

function _Vehicle()
    Action_Config = {
        Vehicle = {
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Distance = 3.0,
                Label = "Status du véhicule : "..stateofcartext,
                OnClick = function()
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Label = CloseCarext.." le véhicule",
                OnClick = function()
                    ESX.TriggerServerCallback('CorePickax:GotAkey', function(gotkey)
                        if gotkey then
                            local locked = GetVehicleDoorLockStatus(LastEntityHit)
                            if locked == 1 or locked == 0 then -- if unlocked
                                SetVehicleDoorsLocked(LastEntityHit, 2)
                                PlayVehicleDoorCloseSound(LastEntityHit, 1)
                                ESX.ShowNotification("Vous avez ~r~fermé~s~ le véhicule")
                                TriggerServerEvent("ESXCustomsv:PlayOnSource", "lock", 0.8)
                            elseif locked == 2 then -- if locked
                                SetVehicleDoorsLocked(LastEntityHit, 1)
                                PlayVehicleDoorOpenSound(LastEntityHit, 0)
                                ESX.ShowNotification("Vous avez ~g~ouvert~s~ le véhicule")
                                TriggerServerEvent("ESXCustomsv:PlayOnSource", "unlock", 0.8)
                            end
                        else
                            ESX.ShowNotification("~r~Vous n'avez pas les clés de ce véhicule")
                        end
                    end, GetVehicleNumberPlateText(LastEntityHit))
                end,
            },
            {
                Type = "Separator"
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Label = "Crocheter",
                Condition = GetVehicleDoorLockStatus(LastEntityHit) ~= 1 and not IsPedSittingInAnyVehicle(PlayerPedId()),
                OnClick = function()
                    ESX.TriggerServerCallback('ContextMenu:HasItem', function(HasItem)
                        if HasItem then
                            local playerPed = PlayerPedId()
                            local coords = GetEntityCoords(playerPed, false)

                            if IsAnyVehicleNearPoint(coords, 3.0) then
                                local vehicle = GetClosestVehicle(coords, 3.0, 0, 71)
                            
                                if DoesEntityExist(vehicle) then
                                    Citizen.CreateThread(function()
                                        TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)
                                        Citizen.Wait(20000)
                                        ClearPedTasksImmediately(playerPed)
                                        SetVehicleDoorsLocked(vehicle, 1)
                                        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
                                        ESX.ShowNotification("~r~Véhicule déverrouiller ")
                                    end)
                                end
                            end
                        else
                            ESX.ShowNotification("~r~Action Impossible~s~ : Vous devez avoir un outil de crochetage pour faire ceci !", false, false, nil)
                        end
                    end)
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Label = "Ouvrir le coffre",
                Condition = GetVehicleDoorLockStatus(LastEntityHit) == 1 and not IsPedSittingInAnyVehicle(PlayerPedId()),
                OnClick = function()
                    TriggerEvent("Coffre:OpenESXCustom")
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Distance = 3,
                Label = "Entrer dans le coffre",
                Condition = GetVehicleDoorLockStatus(LastEntityHit) == 1 and not IsPedSittingInAnyVehicle(PlayerPedId()),
                OnClick = function()
                    ESXCustomFonctionContextMenu:InTruck(LastEntityHit)
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Condition = IsPedSittingInAnyVehicle(PlayerPedId()) and GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false)) == GetVehicleNumberPlateText(LastEntityHit),
                Label = "Ouvrir CarPlay",
                OnClick = function()
                    if GetResourceState('pickax_carplay') ~= 'started' then return ESX.ShowNotification("~r~CarPlay n'est pas démarré.") end
                    CreateThread(function()
                        Wait(250)
                        TriggerEvent('carplay:client:open')
                    end)
                end,
            },
            {
                Type = "buttom-submenu",
                Label = "Limitateur",
                Blocked = false,
                IsRestricted = true,
                CloseOnClick = true,
                Condition = IsPedSittingInAnyVehicle(PlayerPedId()) and GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false)) == GetVehicleNumberPlateText(LastEntityHit),
                Action = {
                    {
                        "Limitateur : 50km/h", function()
                            ESX.ShowNotification('Le ~b~limitateur~s~ est ~g~activée ~s~à ~o~50 Km/H.')
                            SetVehicleMaxSpeed(LastEntityHit, 50/3.6)
                        end
                    },
                    {
                        "Limitateur : 80km/h", function()
                            ESX.ShowNotification('Le ~b~limitateur~s~ est ~g~activée ~s~à ~o~80 Km/H.')
                            SetVehicleMaxSpeed(LastEntityHit, 80/3.6)
                        end
                    },
                    {
                        "Limitateur : 120km/h", function()
                            ESX.ShowNotification('Le ~b~limitateur~s~ est ~g~activée ~s~à ~o~120 Km/H.')
                            SetVehicleMaxSpeed(LastEntityHit, 120/3.6)
                        end
                    },
                    {
                        "Limitateur : 150km/h", function()
                            ESX.ShowNotification('Le ~b~limitateur~s~ est ~g~activée ~s~à ~o~150 Km/H.')
                            SetVehicleMaxSpeed(LastEntityHit, 150/3.6)
                        end
                    },
                    {
                        "Limitateur : Désactiver", function()
                            ESX.ShowNotification('Le ~b~limitateur~s~ est ~r~desactivée')
                            SetVehicleMaxSpeed(LastEntityHit, 1000/3.6)
                        end
                    },
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Changer de place",
                Blocked = false,
                IsRestricted = false,
                CloseOnClick = true,
                Condition = IsPedSittingInAnyVehicle(PlayerPedId()) and GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false)) == GetVehicleNumberPlateText(LastEntityHit),
                Action = {
                    {
                        "Place 1", function()
                            SetPedIntoVehicle(PlayerPedId(), LastEntityHit, -1)
                        end
                    },
                    {
                        "Place 2", function()
                            SetPedIntoVehicle(PlayerPedId(), LastEntityHit, 0)
                        end
                    },
                    {
                        "Place 3", function()
                            SetPedIntoVehicle(PlayerPedId(), LastEntityHit, 1)
                        end
                    },
                    {
                        "Place 4", function()
                            SetPedIntoVehicle(PlayerPedId(), LastEntityHit, 2)
                        end
                    }
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Porte",
                IsRestricted = false,
                CloseOnClick = false,
                Blocked = false,
                Action = {
                    {
                        'Avant Gauche',
                        function()
                            dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(LastEntityHit))
                            if dist < 3 then
                                if GetVehicleDoorAngleRatio(LastEntityHit, 0) == 0 then
                                    SetVehicleDoorOpen(LastEntityHit, 0, false, false)
                                else
                                    SetVehicleDoorShut(LastEntityHit, 0, false)
                                end
                            end
                        end
                    },
                    {
                        'Avant Droite',
                        function()
                            dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(LastEntityHit))
                            if dist < 3 then
                                if GetVehicleDoorAngleRatio(LastEntityHit, 1) == 0 then
                                    SetVehicleDoorOpen(LastEntityHit, 1, false, false)
                                else
                                    SetVehicleDoorShut(LastEntityHit, 1, false)
                                end
                            end
                        end
                    },
                    {
                        'Arrière Gauche',
                        function()
                            dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(LastEntityHit))
                            if dist < 3 then
                                if GetVehicleDoorAngleRatio(LastEntityHit, 2) == 0 then
                                    SetVehicleDoorOpen(LastEntityHit, 2, false, false)
                                else
                                    SetVehicleDoorShut(LastEntityHit, 2, false)
                                end
                            end
                        end
                    },
                    {
                        'Arrière Droite',
                        function()
                            dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(LastEntityHit))
                            if dist < 3 then
                                if GetVehicleDoorAngleRatio(LastEntityHit, 3) == 0 then
                                    SetVehicleDoorOpen(LastEntityHit, 3, false, false)
                                else
                                    SetVehicleDoorShut(LastEntityHit, 3, false)
                                end
                            end
                        end
                    },
                    {
                        'Capot',
                        function()
                            dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(LastEntityHit))
                            if dist < 3 then
                                if GetVehicleDoorAngleRatio(LastEntityHit, 4) == 0 then
                                    SetVehicleDoorOpen(LastEntityHit, 4, false, false)
                                else
                                    SetVehicleDoorShut(LastEntityHit, 4, false)
                                end
                            end
                        end
                    },
                    {
                        'Coffre', function()
                            dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(LastEntityHit))
                            if dist < 3 then
                                if GetVehicleDoorAngleRatio(LastEntityHit, 5) == 0 then
                                    SetVehicleDoorOpen(LastEntityHit, 5, false, false)
                                else
                                    SetVehicleDoorShut(LastEntityHit, 5, false)
                                end
                            end
                        end
                    },
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Actions admin",
                Blocked = false,
                IsRestricted = true,
                CloseOnClick = true,
                Action = {
                    {
                        ("ID : %s"):format(LastEntityHit or "Inconnu"), function()
                        end
                    },
                    {
                        ("Nom du véhicule : %s"):format(GetDisplayNameFromVehicleModel(GetEntityModel(LastEntityHit))), function()
                        end
                    },
                    {
                        ("Plaque du véhicule : %s"):format(GetVehicleNumberPlateText(LastEntityHit)), function()
                        end
                    },
                    {
                        "Suppression du véhicule", function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                SetEntityAsMissionEntity(LastEntityHit)
                                DeleteEntity(LastEntityHit)
                                ESX.ShowNotification("~g~Véhicule supprimer.")
                            end
                        end
                    },
                    {
                        "~g~Ouvrir~s~ le vehicule", function()
                            SetVehicleDoorsLocked(LastEntityHit, 1)
                        end
                    },
                    {
                        
                        "~r~Fermer~s~ le vehicule", function()
                            SetVehicleDoorsLocked(LastEntityHit, 2)
                        end
                    },
                    {
                        
                        "Reparer le véhicule", function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                SetVehicleEngineHealth(LastEntityHit, 1000)
                                SetVehicleEngineOn( LastEntityHit, true, true )
                                SetVehicleFixed(LastEntityHit)
                                ESX.ShowNotification("~g~Véhicule reparer.")
                            end
                        end
                    },
                    {
                        
                        "Nettoyer le véhicule", function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                SetVehicleDirtLevel(LastEntityHit, 0)
                                ESX.ShowNotification("~g~Véhicule nettoyer.")
                            end
                        end
                    },
                    {
                        
                        "Mettre le plein", function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                SetFuel(LastEntityHit, 100)
                                ESX.ShowNotification("~g~Véhicule mis a 100%.")
                            end
                        end
                    },
                    {
                        
                        "Retourner le véhicule", function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                local plyCoords = GetEntityCoords(LastEntityHit)
                                local newCoords = plyCoords + vector3(0.0, 2.0, 0.0)
                    
                                SetEntityCoords(LastEntityHit, newCoords)
                                ESX.ShowNotification('~g~Voiture retourné.')
                            end
                        end
                    },
                    {
                        
                        "Expulser les joueurs du véhicule", function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                ESXCustomFonctionContextMenu:KickAllVeh(LastEntityHit)
                            end
                        end
                    },
                    {
                        "~b~Info sur le véhicule", function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                ESXCustomFonctionContextMenu:InfoVeh(LastEntityHit)
                            end
                        end
                    },
                },
                DoubleSub = true,
                DoubleSubLabel = "Custom le véhicule",
                DoubleSubAction = {
                    {
                        "Moteur 4", function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                ESXCustomFonctionContextMenu:CustomVehicle(LastEntityHit, 3, "moteur")
                            end
                        end
                    },
                    {
                        "Freins 4", function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                ESXCustomFonctionContextMenu:CustomVehicle(LastEntityHit, 3, "freins")
                            end
                        end
                    },
                    {
                        "Transmissions 4", function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                ESXCustomFonctionContextMenu:CustomVehicle(LastEntityHit, 3, "transmissions")
                            end
                        end
                    },
                    {
                        "Suspension 4", function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                ESXCustomFonctionContextMenu:CustomVehicle(LastEntityHit, 3, "suspension")
                            end
                        end
                    },
                    {
                        'Checkbox', "Turbo", statesTurbo, function()
                            ESXCustomFonctionContextMenu:TurboVeh(LastEntityHit)
                        end
                    },
                },
            },
        },
    }
end

function _Player()
    Action_Config = {
        Joueur = {
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Distance = 3.0,
                Label = "Copier l'animation",
                OnClick = function()
                    if IsPedOnFoot(PlayerPedId()) then
                        ESXCustomFonctionContextMenu:CopieAnimation(LastEntityHit)
                    else
                        ESX.ShowNotification("~r~Vous devez être a pied.")
                    end
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Distance = 3.0,
                Label = "Otage",
                OnClick = function()
                    if IsPedOnFoot(PlayerPedId()) then
                        ESXCustomFonctionContextMenu:Command("otage")
                    else
                        ESX.ShowNotification("~r~Vous devez être a pied.")
                    end
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Distance = 3.0,
                Label = "Porter sur le dos",
                OnClick = function()
                    if IsPedOnFoot(PlayerPedId()) then
                        ESXCustomFonctionContextMenu:Command("porter")
                    else
                        ESX.ShowNotification("~r~Vous devez être a pied.")
                    end
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Distance = 3.0,
                Label = "Enlever le masque",
                OnClick = function()
                    ESXCustomFonctionContextMenu:RemoveMask(LastEntityHit)
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Distance = 3.0,
                Condition = ESX.PlayerData.job.name ~= "unemployed",
                Label = "Faire une facture",
                OnClick = function()
                    ESXCustomFonctionContextMenu:Facture(LastEntityHit)
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Distance = 3.0,
                Label = "Fouillez",
                OnClick = function()
                    ESXCustomFonctionContextMenu:Fouille(LastEntityHit)
                end,
            },
            {
                Type = "buttom-submenu",
                Label = "Interactions RP",
                Condition = ConfigContextMenu.Menu.RPActions ~= false,
                Distance = 3.0,
                Blocked = false,
                IsRestricted = false,
                CloseOnClick = true,
                Action = {
                    { "Serrer la main", true, function()
                        ESXCustomFonctionContextMenu:RPWithPlayer("mp_ped_interaction", "handshake_guy_a", 3000, "serre la main de la personne en face")
                    end },
                    { "Faire un câlin", true, function()
                        ESXCustomFonctionContextMenu:RPWithPlayer("mp_ped_interaction", "hugs_guy_a", 3500, "fait un câlin à la personne en face")
                    end },
                    { "Saluer", true, function()
                        ESXCustomFonctionContextMenu:RPWithPlayer("gestures@m@standing@casual", "gesture_hello", 2500, "salue la personne en face")
                    end },
                    { "Prendre le pouls", true, function()
                        ESXCustomFonctionContextMenu:RPWithPlayer("amb@medic@standing@tendtodead@base", "base", 4000, "prend le pouls de la personne en face")
                    end },
                    { "Faire signe d'approcher", true, function()
                        ESXCustomFonctionContextMenu:RPWithPlayer("gestures@m@standing@casual", "gesture_come_here_soft", 2500, "fait signe d'approcher à la personne en face")
                    end },
                },
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = true,
                FlecheActive = true,
                Distance = 3.0,
                Label = "Donnez des items",
                OnClick = function()
                    ESXCustomFonctionContextMenu:GiveItemMenu(LastEntityHit)
                end,
            },
            {
                Type = "buttom-submenu",
                Label = "Donnez de l'argent",
                Blocked = false,
                IsRestricted = false,
                CloseOnClick = true,
                Action = {
                    {
                        "Votre argent : ~g~"..GroupDigits(Argent).."$", function()
                        end
                    },
                    {
                        "Votre argent (sale) : ~r~"..GroupDigits(ArgentSale).."$", function()
                        end
                    },
                    {
                        "Separator", function()
                        end
                    },
                    {
                        "Donnez de l'~g~argent~s~", true, function()
                            ESXCustomFonctionContextMenu:CloseMenu()
                            local amount = ESXCustomFonctionContextMenu:Keyboard("Donné argent", 15, "small_text")
                
                            if amount ~= nil then
                                amount = tonumber(amount)
                            
                                if type(amount) == 'number' then
                                    ESXCustomFonctionContextMenu:DonnerArgent(LastEntityHit, 'item_account', "money", amount)
                                else
                                    ESX.ShowNotification("Vous n'avez pas saisi un montant")
                                end
                            end
                        end
                    },
                    {
                        "Donnez de l'~r~argent sale~s~", true, function()
                            ESXCustomFonctionContextMenu:CloseMenu()
                            local amount = ESXCustomFonctionContextMenu:Keyboard("Donné argent", 15, "small_text")
                        
                            if amount ~= nil then
                                amount = tonumber(amount)
                            
                                if type(amount) == 'number' then
                                    ESXCustomFonctionContextMenu:DonnerArgent(LastEntityHit, 'item_account', "black_money", amount)
                                else
                                    ESX.ShowNotification("Vous n'avez pas saisi un montant")
                                end
                            end
                        end
                    }
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Report rapide",
                Blocked = false,
                IsRestricted = true,
                CloseOnClick = true,
                Action = {
                    {
                        "Freekill", function()
                            ESXCustomFonctionContextMenu:Command("report freekill ID : ~b~"..ESXCustomFonctionContextMenu:Player(LastEntityHit))
                        end
                    },
                    {
                        "Troll", function()
                            ESXCustomFonctionContextMenu:Command("report troll ID : ~b~"..ESXCustomFonctionContextMenu:Player(LastEntityHit))
                        end
                    },
                    {
                        "Moddeur", function()
                            ESXCustomFonctionContextMenu:Command("report moddeur ID : ~b~"..ESXCustomFonctionContextMenu:Player(LastEntityHit))
                        end
                    },
                    {
                        "Carkill", function()
                            ESXCustomFonctionContextMenu:Command("report carkill ID : ~b~"..ESXCustomFonctionContextMenu:Player(LastEntityHit))
                        end
                    },
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Actions admin",
                Blocked = false,
                IsRestricted = true,
                CloseOnClick = true,
                Action = {
                    {
                        "ID du joueurs : "..ESXCustomFonctionContextMenu:Player(LastEntityHit), function()
                        end
                    },
                    {
                        "Envoyer un message", function()
                            ESXCustomFonctionContextMenu:CloseMenu()
                            local txt = ESXCustomFonctionContextMenu:Keyboard("Le message a envoyé au joueurs ?", 30, "small_text")
                            if txt ~= nil then
                                TriggerServerEvent('ContextMenu:SendMessageStaff', PlayerPedId(), ESXCustomFonctionContextMenu:Player(LastEntityHit), txt)
                                ESX.ShowNotification("~r~Action effectué.")
                            end
                        end
                    },
                    {
                        "Heal", function()
                            TriggerServerEvent('ContextMenu:healPlayer', ESXCustomFonctionContextMenu:Player(LastEntityHit))
                        end
                    },
                    {
                        "Revive", function()
                            ExecuteCommand("revive "..ESXCustomFonctionContextMenu:Player(LastEntityHit))
                        end
                    },
                    {
                        "Give item", function()
                            ESXCustomMenu:OpenGiveitems(ESXCustomFonctionContextMenu:Player(LastEntityHit))
                        end
                    },
                },
                DoubleSub = true,
                DoubleSubLabel = "Jail",
                DoubleSubAction = {
                    {
                        "Jail (5 minutes)", function()
                            ExecuteCommand("Jail "..ESXCustomFonctionContextMenu:Player(LastEntityHit).." 5")
                        end
                    },
                    {
                        "Jail (10 minutes)", function()
                            ExecuteCommand("Jail "..ESXCustomFonctionContextMenu:Player(LastEntityHit).." 10")
                        end
                    },
                    {
                        "Jail (15 minutes)", function()
                            ExecuteCommand("Jail "..ESXCustomFonctionContextMenu:Player(LastEntityHit).." 15")
                        end
                    },
                },
                TripleSub = true,
                TripleSubLabel = "TP",
                TripleSubAction = {
                    {
                        "TP au PC", function()
                            pos = vector3(217.14, -810.72, 30.69)
                            TriggerServerEvent("ContextMenu:TPJoueur", PlayerPedId(), ESXCustomFonctionContextMenu:Player(LastEntityHit), pos)
                        end
                    },
                    {
                        "TP au Fourrière", function()
                            pos = vector3(401.65, -1627.99, 29.29)
                            TriggerServerEvent("ContextMenu:TPJoueur", PlayerPedId(), ESXCustomFonctionContextMenu:Player(LastEntityHit), pos)
                        end
                    },
                    {
                        "TP au EMS", function()
                            pos = vector3(297.13, -601.71, 43.39)
                            TriggerServerEvent("ContextMenu:TPJoueur", PlayerPedId(), ESXCustomFonctionContextMenu:Player(LastEntityHit), pos)
                        end
                    },
                    {
                        "TP au LSPD", function()
                            pos = vector3(435.63, -974.47, 30.72)
                            TriggerServerEvent("ContextMenu:TPJoueur", PlayerPedId(), ESXCustomFonctionContextMenu:Player(LastEntityHit), pos)
                        end
                    },
                    {
                        "TP au Sherrif", function()
                            pos = vector3(-432.19, 6009.74, 31.49)
                            TriggerServerEvent("ContextMenu:TPJoueur", PlayerPedId(), ESXCustomFonctionContextMenu:Player(LastEntityHit), pos)
                        end
                    },
                },
            }
        },
    }
end

function GainPoubelle()--Pour les gains des poubelles
    local test = math.random(1, 7)
    if test == 1 then
        ESXCustomFonctionContextMenu:GiveItems("water", 2, "Eau", LastEntityHit)
    elseif test == 2 then
        ESXCustomFonctionContextMenu:GiveItems("bread", 2, "Pain", LastEntityHit)
    else
        ESX.ShowNotification("~r~Vous avez rien trouvez !")
    end
end
