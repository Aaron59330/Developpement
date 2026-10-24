ConfigBasicNeeds = {
    RegisterItemUsable = {
        {
            name = "bread",
            IsUsed = function(source)
                ESX.GetPlayerFromId(source).removeInventoryItem('bread', 1)
                TriggerClientEvent('esx_status:add', source, 'hunger', 250000)
                TriggerClientEvent('esx_basicneeds:onEatbread', source)
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous avez mangé du pain")
            end
        },
        {
            name = "water",
            IsUsed = function(source)
                ESX.GetPlayerFromId(source).removeInventoryItem('water', 1)
                TriggerClientEvent('esx_status:add', source, 'thirst', 250000)
                TriggerClientEvent('esx_basicneeds:onEatwater', source)
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous avez bu de l'eau")
            end
        }
    },
    RegisterItemUsableClientSide = {
        {
            name = "bread",--Le trigger Sera "esx_basicneeds:onEat"+ le name donc = "esx_basicneeds:onEatbread"
            IsUsed = function(prop_name)
                prop_name = prop_name or 'prop_cs_burger_01'
            
                Citizen.CreateThread(function()
                    local playerPed = PlayerPedId()
                    local x,y,z = table.unpack(GetEntityCoords(playerPed))
                    local prop = CreateObject(GetHashKey(prop_name), x, y, z + 0.2, true, true, true)
                    local boneIndex = GetPedBoneIndex(playerPed, 18905)
                    AttachEntityToEntity(prop, playerPed, boneIndex, 0.12, 0.028, 0.001, 10.0, 175.0, 0.0, true, true, false, true, 1, true)
            
                    ESX.Streaming.RequestAnimDict('mp_player_inteat@burger', function()
                        TaskPlayAnim(playerPed, 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 8.0, -8, -1, 49, 0, 0, 0, 0)
            
                        Citizen.Wait(3000)
                        ClearPedSecondaryTask(playerPed)
                        DeleteObject(prop)
                    end)
                end)
            end
        },
        {
            name = "water",--Le trigger Sera "esx_basicneeds:onEat"+ le name donc = "esx_basicneeds:onEatwater"
            IsUsed = function(prop_name)
                prop_name = prop_name or 'prop_ld_flow_bottle'
            
                Citizen.CreateThread(function()
                    local playerPed = PlayerPedId()
                    local x,y,z = table.unpack(GetEntityCoords(playerPed))
                    local prop = CreateObject(GetHashKey(prop_name), x, y, z + 0.2, true, true, true)
                    local boneIndex = GetPedBoneIndex(playerPed, 18905)
                    AttachEntityToEntity(prop, playerPed, boneIndex, 0.12, 0.028, 0.001, 10.0, 175.0, 0.0, true, true, false, true, 1, true)
            
                    ESX.Streaming.RequestAnimDict('mp_player_inteat@burger', function()
                        TaskPlayAnim(playerPed, 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 8.0, -8, -1, 49, 0, 0, 0, 0)
            
                        Citizen.Wait(3000)
                        ClearPedSecondaryTask(playerPed)
                        DeleteObject(prop)
                    end)
                end)
            end
        }
    }
}

-- ═══════════════ Objets consommables : un seul tableau (effet + animation + prop) ═══════════════
-- kind  : eat (manger) | drink (boire) | alcohol (boire de l'alcool : ivresse) | smoke (fumer) | heal (soin) | armor (gilet)
-- hunger / thirst : ajouté à la barre (max 1 000 000) ; health : points de vie rendus (heal) ; drunk : durée d'ivresse en secondes (alcohol)
-- anim  = { dict, clip, flag, ms }   prop = { model, bone, x, y, z, rx, ry, rz }   msg = notification
local EAT   = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp', flag = 49, ms = 3500 }
local DRINK = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49, ms = 3500 }
local HAND  = { bone = 18905, x = 0.12, y = 0.028, z = 0.001, rx = 10.0, ry = 175.0, rz = 0.0 }
local function hand(model) return { model = model, bone = HAND.bone, x = HAND.x, y = HAND.y, z = HAND.z, rx = HAND.rx, ry = HAND.ry, rz = HAND.rz } end
local TEND  = { dict = 'amb@medic@standing@tendtodead@idle_a', clip = 'idle_a', flag = 1, ms = 4500 }

ConfigBasicNeeds.Consumables = {
    -- nourriture
    bread       = { kind = 'eat', hunger = 250000, anim = EAT, prop = hand('prop_sandwich_01'),   msg = 'Vous avez mangé du pain' },
    burger      = { kind = 'eat', hunger = 350000, anim = EAT, prop = hand('prop_cs_burger_01'),  msg = 'Vous avez mangé un burger' },
    pomme       = { kind = 'eat', hunger = 100000, anim = EAT, prop = hand('ng_proc_food_aple1a'), msg = 'Vous avez mangé une pomme' },
    orange      = { kind = 'eat', hunger = 100000, anim = EAT, prop = hand('ng_proc_food_ornge1a'), msg = 'Vous avez mangé une orange' },
    tarte_pomme = { kind = 'eat', hunger = 220000, anim = EAT, prop = hand('prop_donut_02'),      msg = 'Vous avez mangé une tarte aux pommes' },
    mixapero    = { kind = 'eat', hunger = 150000, anim = EAT, prop = hand('prop_food_bs_chips'), msg = 'Vous avez grignoté un mix apéritif' },
    raisin      = { kind = 'eat', hunger = 80000,  anim = EAT, prop = hand('ng_proc_food_aple1a'), msg = 'Vous avez mangé du raisin' },
    -- boissons sans alcool
    water       = { kind = 'drink', thirst = 250000, anim = DRINK, prop = hand('prop_ld_flow_bottle'), msg = "Vous avez bu de l'eau" },
    cola        = { kind = 'drink', thirst = 200000, anim = DRINK, prop = hand('prop_ecola_can'),      msg = 'Vous avez bu un cola' },
    redbull     = { kind = 'drink', thirst = 180000, anim = DRINK, prop = hand('prop_ld_can_01'),      msg = 'Vous avez bu un Redbull' },
    limonade    = { kind = 'drink', thirst = 200000, anim = DRINK, prop = hand('prop_cs_bs_cup'),      msg = 'Vous avez bu une limonade' },
    jus_coca    = { kind = 'drink', thirst = 200000, anim = DRINK, prop = hand('prop_cs_bs_cup'),      msg = 'Vous avez bu un jus de coca' },
    jus_raisin  = { kind = 'drink', thirst = 200000, anim = DRINK, prop = hand('prop_cs_bs_cup'),      msg = 'Vous avez bu un jus de raisin' },
    jusfruit    = { kind = 'drink', thirst = 200000, anim = DRINK, prop = hand('prop_cs_bs_cup'),      msg = 'Vous avez bu un jus de fruits' },
    orange_juice = { kind = 'drink', thirst = 200000, anim = DRINK, prop = hand('prop_cs_bs_cup'),     msg = "Vous avez bu un jus d'orange" },
    -- alcools (bière / vin en bouteille, spiritueux au verre, cocktails)
    beer        = { kind = 'alcohol', thirst = 120000, drunk = 45,  anim = DRINK, prop = hand('prop_beer_bottle'),  msg = 'Vous avez bu une bière' },
    vine        = { kind = 'alcohol', thirst = 80000,  drunk = 60,  anim = DRINK, prop = hand('prop_wine_red'),     msg = 'Vous avez bu du vin' },
    vittvin     = { kind = 'alcohol', thirst = 80000,  drunk = 60,  anim = DRINK, prop = hand('prop_wine_white'),   msg = 'Vous avez bu du vin blanc' },
    grand_cru   = { kind = 'alcohol', thirst = 80000,  drunk = 75,  anim = DRINK, prop = hand('prop_wine_red'),     msg = 'Vous avez bu un grand cru' },
    jager       = { kind = 'alcohol', thirst = 40000,  drunk = 90,  anim = DRINK, prop = hand('prop_drink_whisky'), msg = 'Vous avez bu un Jägermeister' },
    jagerbomb   = { kind = 'alcohol', thirst = 80000,  drunk = 90,  anim = DRINK, prop = hand('prop_drink_whisky'), msg = 'Vous avez bu un Jägerbomb' },
    jagercerbere = { kind = 'alcohol', thirst = 40000, drunk = 100, anim = DRINK, prop = hand('prop_drink_whisky'), msg = 'Vous avez bu un Jäger Cerbère' },
    rhum        = { kind = 'alcohol', thirst = 40000,  drunk = 100, anim = DRINK, prop = hand('prop_drink_whisky'), msg = 'Vous avez bu du rhum' },
    tequila     = { kind = 'alcohol', thirst = 40000,  drunk = 100, anim = DRINK, prop = hand('prop_drink_whisky'), msg = 'Vous avez bu de la tequila' },
    teqpaf      = { kind = 'alcohol', thirst = 60000,  drunk = 100, anim = DRINK, prop = hand('prop_drink_whisky'), msg = 'Vous avez bu un Teq\'paf' },
    vodka       = { kind = 'alcohol', thirst = 40000,  drunk = 100, anim = DRINK, prop = hand('prop_drink_whisky'), msg = 'Vous avez bu de la vodka' },
    whisky      = { kind = 'alcohol', thirst = 40000,  drunk = 100, anim = DRINK, prop = hand('prop_drink_whisky'), msg = 'Vous avez bu du whisky' },
    martini     = { kind = 'alcohol', thirst = 60000,  drunk = 70,  anim = DRINK, prop = hand('prop_cocktail'),     msg = 'Vous avez bu un martini' },
    mojito      = { kind = 'alcohol', thirst = 100000, drunk = 70,  anim = DRINK, prop = hand('prop_cocktail'),     msg = 'Vous avez bu un mojito' },
    rhumcoca    = { kind = 'alcohol', thirst = 100000, drunk = 80,  anim = DRINK, prop = hand('prop_cocktail'),     msg = 'Vous avez bu un rhum-coca' },
    rhumfruit   = { kind = 'alcohol', thirst = 100000, drunk = 80,  anim = DRINK, prop = hand('prop_cocktail'),     msg = 'Vous avez bu un rhum-jus de fruits' },
    vodkaenergy = { kind = 'alcohol', thirst = 100000, drunk = 80,  anim = DRINK, prop = hand('prop_cocktail'),     msg = 'Vous avez bu une vodka-energy' },
    vodkafruit  = { kind = 'alcohol', thirst = 100000, drunk = 80,  anim = DRINK, prop = hand('prop_cocktail'),     msg = 'Vous avez bu une vodka-jus de fruits' },
    vodkaredbull = { kind = 'alcohol', thirst = 100000, drunk = 80, anim = DRINK, prop = hand('prop_cocktail'),     msg = 'Vous avez bu une vodka-Redbull' },
    whiskycoca  = { kind = 'alcohol', thirst = 100000, drunk = 80,  anim = DRINK, prop = hand('prop_cocktail'),     msg = 'Vous avez bu un whisky-coca' },
    -- cigarettes : scénario de fumeur (la cigarette est fournie par le scénario)
    cigarette   = { kind = 'smoke', scenario = 'WORLD_HUMAN_SMOKING', ms = 9000, msg = 'Vous avez fumé une cigarette' },
    malbora     = { kind = 'smoke', scenario = 'WORLD_HUMAN_SMOKING', ms = 9000, msg = 'Vous avez fumé une Malboro' },
    gitanes     = { kind = 'smoke', scenario = 'WORLD_HUMAN_SMOKING', ms = 9000, msg = 'Vous avez fumé une Gitane' },
    -- soins
    bandage     = { kind = 'heal', health = 25, anim = TEND, msg = 'Vous avez appliqué un bandage' },
    medikit     = { kind = 'heal', health = 60, anim = TEND, msg = 'Vous avez utilisé un medikit' },
    firstaidkit = { kind = 'heal', health = 40, anim = TEND, msg = 'Vous avez utilisé une trousse de premier secours' },
    armor       = { kind = 'armor', armor = 100, anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d', flag = 49, ms = 3000 }, msg = 'Vous avez enfilé un gilet pare-balles' },
}
