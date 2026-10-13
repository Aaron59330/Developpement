IsProne = false
local isCrouched = false
local isCrawling = false
local inAction = false
local proneType = "onfront"
local lastKeyPress = 0

-- Utils --
local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
		Citizen.Wait(0)
	end
end

local function LoadAnimSet(set)
    RequestAnimSet(set)
    while not HasAnimSetLoaded(set) do
		Citizen.Wait(0)
	end
end

local function IsPlayerAiming(player)
    return IsPlayerFreeAiming(player) or IsAimCamActive() or IsAimCamThirdPersonActive()
end

local function CanPlayerCrouchCrawl(playerPed)
    if not IsPedOnFoot(playerPed) or IsPedJumping(playerPed) or IsPedFalling(playerPed) or IsPedInjured(playerPed) or IsPedInMeleeCombat(playerPed) or IsPedRagdoll(playerPed) then
        return false
    end

    return true
end

local function PlayAnimOnce(playerPed, animDict, animName, blendInSpeed, blendOutSpeed, duration, startTime)
    LoadAnimDict(animDict)
    TaskPlayAnim(playerPed, animDict, animName, blendInSpeed or 2.0, blendOutSpeed or 2.0, duration or -1, 0, startTime or 0.0, false, false, false)
    RemoveAnimDict(animDict)
end

local function ChangeHeadingSmooth(playerPed, amount, time)
    local times = math.abs(amount)
    local test = amount / times
    local wait = time / times

    for _i = 1, times do
        Wait(wait)
        SetEntityHeading(playerPed, GetEntityHeading(playerPed) + test)
    end
end


-- Crouching --
local function ResetCrouch()
    local playerPed = PlayerPedId()

    ResetPedStrafeClipset(playerPed)
    ResetPedWeaponMovementClipset(playerPed)
    SetPedMaxMoveBlendRatio(playerPed, 1.0)
    SetPedCanPlayAmbientAnims(playerPed, true)
    local walkStyle = GetResourceKvpString("walkstyle")
    if walkStyle ~= nil then
        LoadAnimSet(walkStyle)
        SetPedMovementClipset(playerPed, walkStyle, 0.6)
        RemoveAnimSet(walkStyle)
    else
        ResetPedMovementClipset(playerPed, 0.5)
    end

    RemoveAnimSet("move_ped_crouched")
end

local function CrouchThread()
    CreateThread(function()
        local playerId = PlayerId()

        while isCrouched do
            local playerPed = PlayerPedId()
            if not CanPlayerCrouchCrawl(playerPed) then
                isCrouched = false
                break
            end
            if IsPlayerAiming(playerId) then
                SetPedMaxMoveBlendRatio(playerPed, 0.15)
            end
            SetPedCanPlayAmbientAnims(playerPed, false)
            DisableControlAction(0, 36, true)
            if IsPedUsingActionMode(playerPed) == 1 then
                SetPedUsingActionMode(playerPed, false, -1, "DEFAULT_ACTION")
            end

            DisableFirstPersonCamThisFrame()

            Wait(0)
        end

        ResetCrouch()
    end)
end

local function StartCrouch()
    isCrouched = true
    LoadAnimSet("move_ped_crouched")
    local playerPed = PlayerPedId()
    if GetPedStealthMovement(playerPed) == 1 then
        SetPedStealthMovement(playerPed, false, "DEFAULT_ACTION")
        Wait(100)
    end

    if GetFollowPedCamViewMode() == 4 then
        SetFollowPedCamViewMode(0)
    end

    SetPedMovementClipset(playerPed, "move_ped_crouched", 0.6)
    SetPedStrafeClipset(playerPed, "move_ped_crouched_strafing")

    CrouchThread()
end

local function AttemptCrouch(playerPed)
    if CanPlayerCrouchCrawl(playerPed) then
        StartCrouch()
        return true
    else
        return false
    end
end

local function CrouchKeyPressed()
    if inAction then
        return
    end

    if isCrouched then
        isCrouched = false
        return
    end

    local playerPed = PlayerPedId()

    if ConfigMenuEmote.CrouchOverride then
        DisableControlAction(0, 36, true)
    else
        local crouchKey = GetControlInstructionalButton(0, 0xD2D0BEBA, false)
        local duckKey = GetControlInstructionalButton(0, 36, false)

        if crouchKey == duckKey and not IsProne then
            local timer = GetGameTimer()
            if GetPedStealthMovement(playerPed) == 1 and timer - lastKeyPress < 1000 then
                DisableControlAction(0, 36, true)
                lastKeyPress = 0
                AttemptCrouch(playerPed)
                return
            end
            lastKeyPress = timer
            return
        end
    end

    if AttemptCrouch(playerPed) and IsProne then
        inAction = true
        IsProne = false
        PlayAnimOnce(playerPed, "get_up@directional@transition@prone_to_knees@crawl", "front", nil, nil, 780)
        Wait(780)
        inAction = false
    end
end


-- Crawling --
local function ShouldPlayerDiveToCrawl(playerPed)
    if IsPedRunning(playerPed) or IsPedSprinting(playerPed) then
        return true
    end

    return false
end

local function PlayIdleCrawlAnim(playerPed, heading, blendInSpeed)
    local playerCoords = GetEntityCoords(playerPed)
    TaskPlayAnimAdvanced(playerPed, "move_crawl", proneType.."_fwd", playerCoords.x, playerCoords.y, playerCoords.z, 0.0, 0.0, heading or GetEntityHeading(playerPed), blendInSpeed or 2.0, 2.0, -1, 2, 1.0, false, false)
end

local function PlayExitCrawlAnims(forceEnd)
    if not forceEnd then
        inAction = true
        local playerPed = PlayerPedId()

        if proneType == "onfront" then
            PlayAnimOnce(playerPed, "get_up@directional@transition@prone_to_knees@crawl", "front", nil, nil, 780)
            if not isCrouched then
                Wait(780)
                PlayAnimOnce(playerPed, "get_up@directional@movement@from_knees@standard", "getup_l_0", nil, nil, 1300)
            end
        else
            PlayAnimOnce(playerPed, "get_up@directional@transition@prone_to_seated@crawl", "back", 16.0, nil, 950)
            if not isCrouched then
                Wait(950)
                PlayAnimOnce(playerPed, "get_up@directional@movement@from_seated@standard", "get_up_l_0", nil, nil, 1300)
            end
        end
    end
end

local function Crawl(playerPed, type, direction)
    isCrawling = true

    TaskPlayAnim(playerPed, "move_crawl", type.."_"..direction, 8.0, -8.0, -1, 2, 0.0, false, false, false)

    local time = {
        ["onfront"] = {
            ["fwd"] = 820,
            ["bwd"] = 990
        },
        ["onback"] = {
            ["fwd"] = 1200,
            ["bwd"] = 1200
        }
    }

    SetTimeout(time[type][direction], function()
        isCrawling = false
    end)
end

local function CrawlFlip(playerPed)
    inAction = true
    local heading = GetEntityHeading(playerPed)

    if proneType == "onfront" then
        proneType = "onback"

        PlayAnimOnce(playerPed, "get_up@directional_sweep@combat@pistol@front", "front_to_prone", 2.0)
        ChangeHeadingSmooth(playerPed, -18.0, 3600)
    else
        proneType = "onfront"

        PlayAnimOnce(playerPed, "move_crawlprone2crawlfront", "back", 2.0, nil, -1)
        ChangeHeadingSmooth(playerPed, 12.0, 1700)
    end

    PlayIdleCrawlAnim(playerPed, heading + 180.0)
    Wait(400)
    inAction = false
end

local function CrawlThread()
    CreateThread(function()
        Wait(400)

        local forceEnd = false

        while IsProne do
            local playerPed = PlayerPedId()
            if not CanPlayerCrouchCrawl(playerPed) or IsEntityInWater(playerPed) then
                ClearPedTasks(playerPed)
                IsProne = false
                forceEnd = true
                break
            end

            local forward, backwards = IsControlPressed(0, 32), IsControlPressed(0, 33)
            if not isCrawling then
                if forward then
                    Crawl(playerPed, proneType, "fwd")
                elseif backwards then
                    Crawl(playerPed, proneType, "bwd")
                end
            end

            if IsControlPressed(0, 34) then
                if isCrawling then
                    local headingDiff = forward and 1.0 or -1.0
                    SetEntityHeading(playerPed, GetEntityHeading(playerPed) + headingDiff)
                else
                    inAction = true
                    if proneType == "onfront" then
                        local playerCoords = GetEntityCoords(playerPed)
                        TaskPlayAnimAdvanced(playerPed, "move_crawlprone2crawlfront", "left", playerCoords.x, playerCoords.y, playerCoords.z, 0.0, 0.0, GetEntityHeading(playerPed), 2.0, 2.0, -1, 2, 0.1, false, false)
                        ChangeHeadingSmooth(playerPed, -10.0, 300)
                        Wait(700)
                    else
                        PlayAnimOnce(playerPed, "get_up@directional_sweep@combat@pistol@left", "left_to_prone")
                        ChangeHeadingSmooth(playerPed, 25.0, 400)
                        PlayIdleCrawlAnim(playerPed)
                        Wait(600)
                    end
                    inAction = false
                end
            elseif IsControlPressed(0, 35) then
                if isCrawling then
                    local headingDiff = backwards and 1.0 or -1.0
                    SetEntityHeading(playerPed, GetEntityHeading(playerPed) + headingDiff)
                else
                    inAction = true
                    if proneType == "onfront" then
                        local playerCoords = GetEntityCoords(playerPed)
                        TaskPlayAnimAdvanced(playerPed, "move_crawlprone2crawlfront", "right", playerCoords.x, playerCoords.y, playerCoords.z, 0.0, 0.0, GetEntityHeading(playerPed), 2.0, 2.0, -1, 2, 0.1, false, false)
                        ChangeHeadingSmooth(playerPed, 10.0, 300)
                        Wait(700)
                    else
                        PlayAnimOnce(playerPed, "get_up@directional_sweep@combat@pistol@right", "right_to_prone")
                        ChangeHeadingSmooth(playerPed, -25.0, 400)
                        PlayIdleCrawlAnim(playerPed)
                        Wait(600)
                    end
                    inAction = false
                end
            end

            if not isCrawling then
                if IsControlPressed(0, 22) then
                    CrawlFlip(playerPed)
                end
            end

            Wait(0)
        end
        PlayExitCrawlAnims(forceEnd)
        isCrawling = false
        inAction = false
        proneType = "onfront"
        SetPedConfigFlag(PlayerPedId(), 48, false)
        RemoveAnimDict("move_crawl")
        RemoveAnimDict("move_crawlprone2crawlfront")
    end)
end

local function CrawlKeyPressed()
    if inAction then
        return
    end

    if IsPauseMenuActive() then
        return
    end

    if IsProne then
        IsProne = false
        return
    end

    if IsInAnimation then
        EmoteCancel()
    end

    local wasCrouched = false
    if isCrouched then
        isCrouched = false
        wasCrouched = true
    end

    local playerPed = PlayerPedId()
    if not CanPlayerCrouchCrawl(playerPed) or IsEntityInWater(playerPed) then
        return
    end
    inAction = true

    if Pointing then
        Pointing = false
    end

    IsProne = true
    SetPedConfigFlag(playerPed, 48, true)

    if GetPedStealthMovement(playerPed) == 1 then
        SetPedStealthMovement(playerPed, false, "DEFAULT_ACTION")
        Wait(100)
    end

    LoadAnimDict("move_crawl")
    LoadAnimDict("move_crawlprone2crawlfront")

    if ShouldPlayerDiveToCrawl(playerPed) then
        PlayAnimOnce(playerPed, "explosions", "react_blown_forwards", nil, 3.0)
        Wait(1100)
    elseif wasCrouched then
        PlayAnimOnce(playerPed, "amb@world_human_sunbathe@male@front@enter", "enter", nil, nil, -1, 0.3)
        Wait(1500)
    else
        PlayAnimOnce(playerPed, "amb@world_human_sunbathe@male@front@enter", "enter")
        Wait(3000)
    end

    if CanPlayerCrouchCrawl(playerPed) and not IsEntityInWater(playerPed) then
        PlayIdleCrawlAnim(playerPed, nil, 3.0)
    end
    inAction = false

    CrawlThread()
end

if ConfigMenuEmote.CrouchEnabled then
    if ConfigMenuEmote.CrouchKeybindEnabled then
        RegisterKeyMapping('+crouch', ConfigMenuEmote.Key.DescriptionCrouch, "keyboard", ConfigMenuEmote.CrouchKeybind)
        RegisterCommand('+crouch', function() CrouchKeyPressed() end, false)
        RegisterCommand('-crouch', function() end, false)
    end
    RegisterCommand('crouch', function()
        if isCrouched then
            isCrouched = false
            return
        end

        AttemptCrouch(PlayerPedId())
    end, false)
end

if ConfigMenuEmote.CrawlEnabled then
    if ConfigMenuEmote.CrawlKeybindEnabled then
        RegisterKeyMapping('crawl', ConfigMenuEmote.Key.DescriptionCrawl, "keyboard", ConfigMenuEmote.CrawlKeybind)
    end
    RegisterCommand('crawl', function() CrawlKeyPressed() end, false)
end

local function IsPlayerCrouched()
	return isCrouched
end

local function IsPlayerProne()
	return IsProne
end

local function IsPlayerCrawling()
	return isCrawling
end

exports('IsPlayerCrouched', IsPlayerCrouched)
exports('IsPlayerProne', IsPlayerProne)
exports('IsPlayerCrawling', IsPlayerCrawling)

-- You probably shouldnt touch these.
local AnimationDuration = -1
local ChosenAnimation = ""
local ChosenDict = ""
local ChosenAnimOptions = false
local MovementType = 0
local PlayerGender = "male"
local PlayerHasProp = false
local PlayerProps = {}
local PlayerParticles = {}
local SecondPropEmote = false
local lang = ConfigMenuEmote.MenuLanguage
local PtfxNotif = false
local PtfxPrompt = false
local PtfxWait = 500
local PtfxCanHold = false
local PtfxNoProp = false
local AnimationThreadStatus = false
local CanCancel = true
local InExitEmote = false
IsInAnimation = false

local emoteTypes = {
    "Shared",
    "Dances",
    "Emotes",
    "PropEmotes",
}

for i = 1, #emoteTypes do
    local emoteType = emoteTypes[i]
    for emoteName, emoteData in pairs(ESXCustomEmote[emoteType]) do
        local shouldRemove = false
        if ConfigMenuEmote.AdultEmotesDisabled and emoteData.AdultAnimation then shouldRemove = true end
        if emoteData[1] and not ((emoteData[1] == 'Scenario') or (emoteData[1] == 'ScenarioObject') or (emoteData[1] == 'MaleScenario')) and not DoesAnimDictExist(emoteData[1]) then shouldRemove = true end
        if shouldRemove then ESXCustomEmote[emoteType][emoteName] = nil end
    end
end

local function IsPlayerAiming(player)
    return IsPlayerFreeAiming(player) or IsAimCamActive() or IsAimCamThirdPersonActive()
end

local function RunAnimationThread()
    local playerId = PlayerId()
    if AnimationThreadStatus then return end
    AnimationThreadStatus = true
    CreateThread(function()
        local sleep
        while AnimationThreadStatus and (IsInAnimation or PtfxPrompt) do
            sleep = 500

            if IsInAnimation then
                sleep = 0
                if IsPlayerAiming(playerId) then
                    EmoteCancel()
                end
            end

            if PtfxPrompt then
                sleep = 0
                if not PtfxNotif then
                    ESX.ShowNotification(PtfxInfo)
                    PtfxNotif = true
                end
                if IsControlPressed(0, 47) then
                    PtfxStart()
                    Wait(PtfxWait)
                    if PtfxCanHold then
                        while IsControlPressed(0, 47) and IsInAnimation and AnimationThreadStatus do
                            Wait(5)
                        end
                    end
                    PtfxStop()
                end
            end

            Wait(sleep)
        end
    end)
end

if ConfigMenuEmote.EnableXtoCancel then
    RegisterKeyMapping("emotecancel", ConfigMenuEmote.Key.DescriptionCancelEmote, "keyboard", ConfigMenuEmote.CancelEmoteKey)
end

if ConfigMenuEmote.HandsupKeybindEnabled then
    RegisterKeyMapping("handsup", ConfigMenuEmote.Key.DescriptionHandsup, "keyboard", ConfigMenuEmote.HandsupKeybind)
end

-----------------------------------------------------------------------------------------------------
-- Commands / Events --------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/e', 'Play an emote',{ { name = "emotename", help = "dance, camera, sit or any valid emote." }, { name = "texturevariation", help = "(Optional) 1, 2, 3 or any number. Will change the texture of some props used in emotes, for example the color of a phone. Enter -1 to see a list of variations." } })
    TriggerEvent('chat:addSuggestion', '/emote', 'Play an emote',{ { name = "emotename", help = "dance, camera, sit or any valid emote." }, { name = "texturevariation", help = "(Optional) 1, 2, 3 or any number. Will change the texture of some props used in emotes, for example the color of a phone. Enter -1 to see a list of variations." } })
    if ConfigMenuEmote.SqlKeybinding then
        TriggerEvent('chat:addSuggestion', '/emotebind', 'Bind an emote',{{ name = "key", help = "num4, num5, num6, num7. num8, num9. Numpad 4-9!"}, { name = "emotename", help = "dance, camera, sit or any valid emote." } })
        TriggerEvent('chat:addSuggestion', '/emotebinds', 'Check your currently bound emotes.')
    end
    TriggerEvent('chat:addSuggestion', '/emotemenu', 'Open rpemotes menu (F4) by default. This may differ from server to server.')
    TriggerEvent('chat:addSuggestion', '/emotes', 'List available emotes.')
    TriggerEvent('chat:addSuggestion', '/walk', 'Set your walkingstyle.',{{ name = "style", help = "/walks for a list of valid styles" }})
    TriggerEvent('chat:addSuggestion', '/walks', 'List available walking styles.')
    TriggerEvent('chat:addSuggestion', '/emotecancel', 'Cancel currently playing emote.')
    TriggerEvent('chat:addSuggestion', '/handsup', 'Put your arms up.')
end)

RegisterCommand('e', function(source, args, raw) EmoteCommandStart(source, args, raw) end, false)
RegisterCommand('emote', function(source, args, raw) EmoteCommandStart(source, args, raw) end, false)
if ConfigMenuEmote.SqlKeybinding then
    RegisterCommand('emotebind', function(source, args, raw) EmoteBindStart(source, args, raw) end, false)
    RegisterCommand('emotebinds', function(source, args, raw) EmoteBindsStart(source, args, raw) end, false)
end
if ConfigMenuEmote.MenuKeybindEnabled then
    RegisterCommand('emoteui', function() OpenEmoteMenu() end, false)
    RegisterKeyMapping("emoteui", ConfigMenuEmote.Key.DescriptionOpenMenu, "keyboard", ConfigMenuEmote.MenuKeybind)
else
    RegisterCommand('emotemenu', function() OpenEmoteMenu() end, false)
end
RegisterCommand('emotes', function() EmotesOnCommand() end, false)
RegisterCommand('walk', function(source, args, raw) WalkCommandStart(source, args, raw) end, false)
RegisterCommand('walks', function() WalksOnCommand() end, false)
RegisterCommand('emotecancel', function() EmoteCancel() end, false)

RegisterCommand('handsup', function()
	if ConfigMenuEmote.HandsupKeybindEnabled then
		if IsEntityPlayingAnim(PlayerPedId(), "missminuteman_1ig_2", "handsup_base", 51) then
			EmoteCancel()
		else
			EmoteCommandStart(nil, {"handsup"}, nil)
		end
	end
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        local ply = PlayerPedId()
        DestroyAllProps()
        ClearPedTasksImmediately(ply)
        DetachEntity(ply, true, false)
        ResetPedMovementClipset(ply, 0.8)
        AnimationThreadStatus = false
    end
end)

-----------------------------------------------------------------------------------------------------
------ Functions and stuff --------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

function EmoteCancel(force)
    -- Don't cancel if we are in an exit emote
    if InExitEmote then
        return
    end

    local ply = PlayerPedId()
	if not CanCancel and force ~= true then return end
    if ChosenDict == "MaleScenario" and IsInAnimation then
        ClearPedTasksImmediately(ply)
        IsInAnimation = false
        DebugPrint("Forced scenario exit")
    elseif ChosenDict == "Scenario" and IsInAnimation then
        ClearPedTasksImmediately(ply)
        IsInAnimation = false
        DebugPrint("Forced scenario exit")
    end

    PtfxNotif = false
    PtfxPrompt = false
	Pointing = false
    PlayerClass.pEmoteEnCours = nil

    if IsInAnimation then
        if LocalPlayer.state.ptfx then
            PtfxStop()
        end
        DetachEntity(ply, true, false)
        CancelSharedEmote(ply)

        if ChosenAnimOptions and ChosenAnimOptions.ExitEmote then
            -- If the emote exit type is not spesifed it defaults to Emotes
            local options = ChosenAnimOptions
            local ExitEmoteType = options.ExitEmoteType or "Emotes"

            -- Checks that the exit emote actually exists
            if not ESXCustomEmote[ExitEmoteType] or not ESXCustomEmote[ExitEmoteType][options.ExitEmote] then
                DebugPrint("Exit emote was invalid")
                ClearPedTasks(ply)
                IsInAnimation = false
                return
            end

            OnEmotePlay(ESXCustomEmote[ExitEmoteType][options.ExitEmote])
            DebugPrint("Playing exit animation")

            -- Check that the exit emote has a duration, and if so, set InExitEmote variable
            local animationOptions = ESXCustomEmote[ExitEmoteType][options.ExitEmote].AnimationOptions
            if animationOptions and animationOptions.EmoteDuration then
                InExitEmote = true
                SetTimeout(animationOptions.EmoteDuration, function()
                    InExitEmote = false
                    DestroyAllProps()
                    ClearPedTasks(ply)
                end)
                return
            end
        else
            ClearPedTasks(ply)
            IsInAnimation = false
        end
        DestroyAllProps()
    end
    AnimationThreadStatus = false
end

function EmoteChatMessage(msg, multiline)
    if msg then
        TriggerEvent("chat:addMessage", { multiline = multiline == true or false, color = { 255, 255, 255 }, args = { "^5Help^0", tostring(msg) } })
    end
end

function DebugPrint(args)
    if ConfigMenuEmote.DebugDisplay then
        print(args)
    end
end

--#region ptfx
function PtfxThis(asset)
    while not HasNamedPtfxAssetLoaded(asset) do
        RequestNamedPtfxAsset(asset)
        Wait(10)
    end
    UseParticleFxAsset(asset)
end

function PtfxStart()
    LocalPlayer.state:set('ptfx', true, true)
end

function PtfxStop()
    LocalPlayer.state:set('ptfx', false, true)
end

AddStateBagChangeHandler('ptfx', nil, function(bagName, key, value, _unused, replicated)
    local plyId = tonumber(bagName:gsub('player:', ''), 10)

    -- We stop here if we don't need to go further
    -- We don't need to start or stop the ptfx twice
    if (PlayerParticles[plyId] and value) or (not PlayerParticles[plyId] and not value) then return end

    -- Only allow ptfx change on players
    local ply = GetPlayerFromServerId(plyId)
    if ply == 0 then return end

    local plyPed = GetPlayerPed(ply)
    if not DoesEntityExist(plyPed) then return end

    local stateBag = Player(plyId).state
    if value then
        -- Start ptfx

        local asset = stateBag.ptfxAsset
        local name = stateBag.ptfxName
        local offset = stateBag.ptfxOffset
        local rot = stateBag.ptfxRot
        local boneIndex = stateBag.ptfxBone and GetPedBoneIndex(plyPed, stateBag.ptfxBone) or GetEntityBoneIndexByName(name, "VFX")
        local scale = stateBag.ptfxScale or 1
        local color = stateBag.ptfxColor
        local propNet = stateBag.ptfxPropNet
        local entityTarget = plyPed
        -- Only do for valid obj
        if propNet then
            local propObj = NetToObj(propNet)
            if DoesEntityExist(propObj) then
                entityTarget = propObj
            end
        end
        PtfxThis(asset)
        PlayerParticles[plyId] = StartNetworkedParticleFxLoopedOnEntityBone(name, entityTarget, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneIndex, scale + 0.0, 0, 0, 0, 1065353216, 1065353216, 1065353216, 0)
        if color then
            if color[1] and type(color[1]) == 'table' then
                local randomIndex = math.random(1, #color)
                color = color[randomIndex]
            end
            SetParticleFxLoopedAlpha(PlayerParticles[plyId], color.A)
            SetParticleFxLoopedColour(PlayerParticles[plyId], color.R / 255, color.G / 255, color.B / 255, false)
        end
        DebugPrint("Started PTFX: " .. PlayerParticles[plyId])
    else
        -- Stop ptfx
        DebugPrint("Stopped PTFX: " .. PlayerParticles[plyId])
        StopParticleFxLooped(PlayerParticles[plyId], false)
        RemoveNamedPtfxAsset(stateBag.ptfxAsset)
        PlayerParticles[plyId] = nil
    end
end)
--#endregion ptfx

function EmotesOnCommand(source, args, raw)
    local EmotesCommand = ""
    for a in pairsByKeys(ESXCustomEmote.Emotes) do
        EmotesCommand = EmotesCommand .. "" .. a .. ", "
    end
    EmoteChatMessage(EmotesCommand)
    EmoteChatMessage(ConfigMenuEmoteLanguages[lang]['emotemenucmd'])
end

function pairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a, f)
    local i = 0 -- iterator variable
    local iter = function() -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function EmoteMenuStart(args, hard, textureVariation)
    local name = args
    local etype = hard

    if etype == "dances" then
        if ESXCustomEmote.Dances[name] ~= nil then
            OnEmotePlay(ESXCustomEmote.Dances[name], nil, name)
        end
    elseif etype == "props" then
        if ESXCustomEmote.PropEmotes[name] ~= nil then
            OnEmotePlay(ESXCustomEmote.PropEmotes[name], textureVariation, name)
        end
    elseif etype == "emotes" then
        if ESXCustomEmote.Emotes[name] ~= nil then
            OnEmotePlay(ESXCustomEmote.Emotes[name], nil, name)
        end
    elseif etype == "expression" then
        if ESXCustomEmote.Expressions[name] ~= nil then
            SetPlayerPedExpression(ESXCustomEmote.Expressions[name][1], true)
        end
    end
end

function EmoteCommandStart(source, args, raw)
    if #args > 0 then
        local name = string.lower(args[1])
        if name == "c" then
            if IsInAnimation then
                EmoteCancel()
            else
                EmoteChatMessage(ConfigMenuEmoteLanguages[lang]['nocancel'])
            end
            return
        elseif name == "help" then
            EmotesOnCommand()
            return
        end

        PlayerClass.pEmoteEnCours = name
        if ESXCustomEmote.Emotes[name] ~= nil then
            OnEmotePlay(ESXCustomEmote.Emotes[name], nil, name)
            return
        elseif ESXCustomEmote.Dances[name] ~= nil then
            OnEmotePlay(ESXCustomEmote.Dances[name], nil, name)
            return
        elseif ESXCustomEmote.Exits[name] ~= nil then
            OnEmotePlay(ESXCustomEmote.Exits[name], nil, name)
            return
        elseif ESXCustomEmote.PropEmotes[name] ~= nil then
            if ESXCustomEmote.PropEmotes[name].AnimationOptions.PropTextureVariations then
                if #args > 1 then
                    local textureVariation = tonumber(args[2])
                    if (ESXCustomEmote.PropEmotes[name].AnimationOptions.PropTextureVariations[textureVariation] ~= nil) then
                        OnEmotePlay(ESXCustomEmote.PropEmotes[name], textureVariation - 1, name)
                        return
                    else
                        local str = ""
                        for k, v in ipairs(ESXCustomEmote.PropEmotes[name].AnimationOptions.PropTextureVariations) do
                            str = str .. string.format("\n(%s) - %s", k, v.Name)
                        end

                        EmoteChatMessage(string.format(ConfigMenuEmoteLanguages[lang]['invalidvariation'], str), true)
                        OnEmotePlay(ESXCustomEmote.PropEmotes[name], 0, name)
                        return
                    end
                end
            end
            OnEmotePlay(ESXCustomEmote.PropEmotes[name], nil, name)
            return
        else
            EmoteChatMessage("'" .. name .. "' " .. ConfigMenuEmoteLanguages[lang]['notvalidemote'] .. "")
        end
    end
end

function LoadAnim(dict)
    if not DoesAnimDictExist(dict) then
        return false
    end

    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(10)
    end

    return true
end

function LoadPropDict(model)
    while not HasModelLoaded(joaat(model)) do
        RequestModel(joaat(model))
        Wait(10)
    end
end

function DestroyAllProps()
    for _, v in pairs(PlayerProps) do
        DeleteEntity(v)
    end
    PlayerHasProp = false
    DebugPrint("Destroyed Props")
end

function AddPropToPlayer(prop1, bone, off1, off2, off3, rot1, rot2, rot3, textureVariation)
    local Player = PlayerPedId()
    local x, y, z = table.unpack(GetEntityCoords(Player))

    if not IsModelValid(prop1) then
        DebugPrint(tostring(prop1).." is not a valid model!")
        return false
    end

    if not HasModelLoaded(prop1) then
        LoadPropDict(prop1)
    end

    prop = CreateObject(joaat(prop1), x, y, z + 0.2, true, true, true)
    if textureVariation ~= nil then
        SetObjectTextureVariation(prop, textureVariation)
    end
    AttachEntityToEntity(prop, Player, GetPedBoneIndex(Player, bone), off1, off2, off3, rot1, rot2, rot3, true, true,
        false, true, 1, true)
    table.insert(PlayerProps, prop)
    PlayerHasProp = true
    SetModelAsNoLongerNeeded(prop1)
    return true
end

-----------------------------------------------------------------------------------------------------
-- V -- This could be a whole lot better, i tried messing around with "IsPedMale(ped)"
-- V -- But i never really figured it out, if anyone has a better way of gender checking let me know.
-- V -- Since this way doesnt work for ped models.
-- V -- in most cases its better to replace the scenario with an animation bundled with prop instead.
-----------------------------------------------------------------------------------------------------

function CheckGender()
    local playerPed = PlayerPedId()

    if GetEntityModel(playerPed) == joaat("mp_f_freemode_01") then
        PlayerGender = "female"
    else
        PlayerGender = "male"
    end

    DebugPrint("Set gender as = (" .. PlayerGender .. ")")
end

-----------------------------------------------------------------------------------------------------
------ This is the major function for playing emotes! -----------------------------------------------
-----------------------------------------------------------------------------------------------------
CheckAnimation = function(EmoteName)
    for k, v in pairs(Config.AnimationsHandsupList) do
        if v.anim == EmoteName[2] then
            return true
        end
    end

    return false
end

function OnEmotePlay(EmoteName, textureVariation, Name)
    InVehicle = IsPedInAnyVehicle(PlayerPedId(), true)
	Pointing = false

    if not ConfigMenuEmote.AllowedInCars and InVehicle == 1 then
        return
    end

    if not DoesEntityExist(PlayerPedId()) then
        return false
    end

    if InExitEmote then
        return false
    end

    local animOption = EmoteName.AnimationOptions
    if animOption and animOption.NotInVehicle and InVehicle then
        return EmoteChatMessage("You can't play this animation while in vehicle.")
    end

    if ChosenAnimOptions and ChosenAnimOptions.ExitEmote then
        if not (animOption and ChosenAnimOptions.ExitEmote == animOption.ExitEmote) and ESXCustomEmote.Exits[ChosenAnimOptions.ExitEmote][2] ~= EmoteName[2] then
            return
        end
    end

    if IsPedArmed(PlayerPedId(), 6) then
        if not CheckAnimation(EmoteName) then
            EmoteChatMessage("Vous ne pouvez pas faire cette animation lorsque vous êtes armées.")
            return false
        end
    end

    if IsPedFalling(PlayerPedId()) then
        EmoteChatMessage("Vous ne pouvez pas faire cette animation lorsque vous tombez.")
        return false
    end

    if IsPedJumping(PlayerPedId()) then
        EmoteChatMessage("Vous ne pouvez pas faire cette animation lorsque vous sautez.")
        return false
    end

    if IsPedRagdoll(PlayerPedId()) then
        EmoteChatMessage("Vous ne pouvez pas faire cette animation lorsque vous êtes au sol.")
        return false
    end

    if IsProne then
        EmoteChatMessage("Vous ne pouvez pas faire cette animation lorsque vous êtes allonger.")
        return false
    end

    if Name ~= nil then
        PlayerClass.pEmoteEnCours = Name
    end
    ChosenDict, ChosenAnimation, ename = table.unpack(EmoteName)
    ChosenAnimOptions = animOption
    AnimationDuration = -1

    if ConfigMenuEmote.DisarmPlayer then
        if IsPedArmed(PlayerPedId(), 7) then
            SetCurrentPedWeapon(PlayerPedId(), joaat('WEAPON_UNARMED'), true)
        end
    end

    if animOption and animOption.Prop and PlayerHasProp then
        DestroyAllProps()
    end

    if ChosenDict == "MaleScenario" or "Scenario" then
        CheckGender()
        if ChosenDict == "MaleScenario" then if InVehicle then return end
            if PlayerGender == "male" then
                ClearPedTasks(PlayerPedId())
                TaskStartScenarioInPlace(PlayerPedId(), ChosenAnimation, 0, true)
                DebugPrint("Playing scenario = (" .. ChosenAnimation .. ")")
                IsInAnimation = true
                RunAnimationThread()
            else
                EmoteChatMessage(ConfigMenuEmoteLanguages[lang]['maleonly'])
            end
            return
        elseif ChosenDict == "ScenarioObject" then if InVehicle then return end
            BehindPlayer = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0 - 0.5, -0.5);
            ClearPedTasks(PlayerPedId())
            TaskStartScenarioAtPosition(PlayerPedId(), ChosenAnimation, BehindPlayer['x'], BehindPlayer['y'], BehindPlayer['z'], GetEntityHeading(PlayerPedId()), 0, true, false)
            DebugPrint("Playing scenario = (" .. ChosenAnimation .. ")")
            IsInAnimation = true
            RunAnimationThread()
            return
        elseif ChosenDict == "Scenario" then if InVehicle then return end
            ClearPedTasks(PlayerPedId())
            TaskStartScenarioInPlace(PlayerPedId(), ChosenAnimation, 0, true)
            DebugPrint("Playing scenario = (" .. ChosenAnimation .. ")")
            IsInAnimation = true
            RunAnimationThread()
            return
        end
    end

    if animOption and animOption.StartDelay then
        Wait(animOption.StartDelay)
    end

    if not LoadAnim(ChosenDict) then
        EmoteChatMessage("'" .. ename .. "' " .. ConfigMenuEmoteLanguages[lang]['notvalidemote'] .. "")
        return
    end

    MovementType = 0

    if InVehicle == 1 then
        MovementType = 51
    elseif animOption then
        if animOption.EmoteMoving then
            MovementType = 51
        elseif animOption.EmoteLoop then
            MovementType = 1
        elseif animOption.EmoteStuck then
            MovementType = 50
        end
    end

    if animOption then
        if animOption.EmoteDuration == nil then
            animOption.EmoteDuration = -1
            AttachWait = 0
        else
            AnimationDuration = animOption.EmoteDuration
            AttachWait = animOption.EmoteDuration
        end

        if animOption.PtfxAsset then
            PtfxAsset = animOption.PtfxAsset
            PtfxName = animOption.PtfxName
            if animOption.PtfxNoProp then
                PtfxNoProp = animOption.PtfxNoProp
            else
                PtfxNoProp = false
            end
            Ptfx1, Ptfx2, Ptfx3, Ptfx4, Ptfx5, Ptfx6, PtfxScale = table.unpack(animOption.PtfxPlacement)
            PtfxBone = animOption.PtfxBone
            PtfxColor = animOption.PtfxColor
            PtfxInfo = animOption.PtfxInfo
            PtfxWait = animOption.PtfxWait
            PtfxCanHold = animOption.PtfxCanHold
            PtfxNotif = false
            PtfxPrompt = true

            TriggerServerEvent("esx_custom:ptfx:sync", PtfxAsset, PtfxName, vector3(Ptfx1, Ptfx2, Ptfx3), vector3(Ptfx4, Ptfx5, Ptfx6), PtfxBone, PtfxScale, PtfxColor)
        else
            DebugPrint("Ptfx = none")
            PtfxPrompt = false
        end
    end

    TaskPlayAnim(PlayerPedId(), ChosenDict, ChosenAnimation, 5.0, 5.0, AnimationDuration, MovementType, 0, false, false, false)
    RemoveAnimDict(ChosenDict)
    IsInAnimation = true
    RunAnimationThread()
    MostRecentDict = ChosenDict
    MostRecentAnimation = ChosenAnimation

    if animOption and animOption.Prop then
        PropName = animOption.Prop
        PropBone = animOption.PropBone
        PropPl1, PropPl2, PropPl3, PropPl4, PropPl5, PropPl6 = table.unpack(animOption.PropPlacement)
        if animOption.SecondProp then
            SecondPropName = animOption.SecondProp
            SecondPropBone = animOption.SecondPropBone
            SecondPropPl1, SecondPropPl2, SecondPropPl3, SecondPropPl4, SecondPropPl5, SecondPropPl6 = table.unpack(animOption.SecondPropPlacement)
            SecondPropEmote = true
        else
            SecondPropEmote = false
        end
        Wait(AttachWait)
        if not AddPropToPlayer(PropName, PropBone, PropPl1, PropPl2, PropPl3, PropPl4, PropPl5, PropPl6, textureVariation) then return end
        if SecondPropEmote then
        if not AddPropToPlayer(SecondPropName, SecondPropBone, SecondPropPl1, SecondPropPl2, SecondPropPl3, SecondPropPl4, SecondPropPl5, SecondPropPl6, textureVariation) then
                DestroyAllProps()
                return
            end
        end

        -- Ptfx is on the prop, then we need to sync it
        if animOption.PtfxAsset and not PtfxNoProp then
            TriggerServerEvent("esx_custom:ptfx:syncProp", ObjToNet(prop))
        end
    end
end


-----------------------------------------------------------------------------------------------------
------ Some exports to make the script more standalone! (by Clem76) ---------------------------------
-----------------------------------------------------------------------------------------------------

exports("EmoteCommandStart", function(emoteName, textureVariation)
        EmoteCommandStart(nil, {emoteName, textureVariation}, nil)
end)
exports("EmoteCancel", EmoteCancel)
exports("CanCancelEmote", function(State)
		CanCancel = State == true
end)
exports('IsPlayerInAnim', function()
	return IsInAnimation 
end)

local EmoteTable = {}
local FavEmoteTable = {}
local DanceTable = {}
local AnimalTable = {}
local PropETable = {}
local WalkTable = {}
local FaceTable = {}
local ShareTable = {}
local FavoriteEmote = ""

if ConfigMenuEmote.FavKeybindEnabled then
    RegisterCommand('emotefav', function() FavKeybind() end)
    RegisterKeyMapping("emotefav", ConfigMenuEmote.Key.DescriptionFavEmote, "keyboard", ConfigMenuEmote.FavKeybind)

    local doingFavoriteEmote = false

    function FavKeybind()
        if doingFavoriteEmote == false then
            doingFavoriteEmote = true
            if not IsPedSittingInAnyVehicle(PlayerPedId()) then
                if FavoriteEmote ~= "" and (not CanUseFavKeyBind or CanUseFavKeyBind()) then
                    EmoteCommandStart(nil, { FavoriteEmote, 0 })
                    Wait(500)
                end
            end
        else
            EmoteCancel()
            doingFavoriteEmote = false
        end
    end
end

lang = ConfigMenuEmote.MenuLanguage
OpenMenu = false

function OpenEmoteMenu()
    ClothesGestion = 1
    if OpenMenu then
        RageUI.CloseAll()
        OpenMenu = false
    else
        OpenMenu = true

        local favEmotes = {}
        local mainmenu = RageUI.CreateMenu(ConfigMenuEmote.MenuTitle or "", "Que voulez-vous faire ?")
        local mainmenu2 = RageUI.CreateSubMenu(mainmenu, ConfigMenuEmoteLanguages[lang]['moods2'], "Que voulez-vous faire ?")
        local mainmenu3 = RageUI.CreateSubMenu(mainmenu, ConfigMenuEmoteLanguages[lang]['walkingstyles2'], "Que voulez-vous faire ?")
        local mainmenu4 = RageUI.CreateSubMenu(mainmenu, ConfigMenuEmoteLanguages[lang]['emotes2'], "Que voulez-vous faire ?")
        local danceemotes = RageUI.CreateSubMenu(mainmenu4, ConfigMenuEmoteLanguages[lang]['danceemotes2'], "Que voulez-vous faire ?")
        local propemotes = RageUI.CreateSubMenu(mainmenu4, ConfigMenuEmoteLanguages[lang]['propemotes2'], "Que voulez-vous faire ?")
        local shareemotes =  RageUI.CreateSubMenu(mainmenu4, ConfigMenuEmoteLanguages[lang]['shareemotes2'], "Que voulez-vous faire ?")
        local favoriteemotes  =  RageUI.CreateSubMenu(mainmenu4, ConfigMenuEmoteLanguages[lang]['favoriteemotes2'], "Que voulez-vous faire ?")

        RageUI.Visible(mainmenu, not RageUI.Visible(mainmenu))

        mainmenu.Closed = function()
            OpenMenu = false
        end

        while mainmenu do
            Wait(0)
            RageUI.IsVisible(mainmenu, true, true, true, function()
                RageUI.ButtonWithStyle(ConfigMenuEmoteLanguages[lang]['emotes'], nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                end, mainmenu4)
                RageUI.ButtonWithStyle(ConfigMenuEmoteLanguages[lang]['cancelemote'], ConfigMenuEmoteLanguages[lang]['cancelemoteinfo'], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    if Selected then
                        EmoteCancel()
                        DestroyAllProps()
                    end
                end)
                if ConfigMenuEmote.WalkingStylesEnabled then
                    RageUI.ButtonWithStyle(ConfigMenuEmoteLanguages[lang]['walkingstyles'], nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    end, mainmenu3)
                end
                if ConfigMenuEmote.ExpressionsEnabled then
                    RageUI.ButtonWithStyle(ConfigMenuEmoteLanguages[lang]['moods'], nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    end, mainmenu2)
                end
            end)

            RageUI.IsVisible(mainmenu2, true, true, true, function()
                RageUI.ButtonWithStyle(ConfigMenuEmoteLanguages[lang]['normalreset'], ConfigMenuEmoteLanguages[lang]['resetdef'], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    if Selected then
                        ClearFacialIdleAnimOverride(PlayerPedId())
                    end
                end)

                for name, data in pairsByKeys(ESXCustomEmote.Expressions) do
                    RageUI.ButtonWithStyle(name, nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                        if Selected then
                            EmoteMenuStart(name, "expression")
                        end
                    end)
                end
            end)

            RageUI.IsVisible(mainmenu3, true, true, true, function()
                RageUI.ButtonWithStyle(ConfigMenuEmoteLanguages[lang]['normalreset'], ConfigMenuEmoteLanguages[lang]['resetdef'], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    if Selected then
                        ResetPedMovementClipset(PlayerPedId())
                        DeleteResourceKvp("walkstyle")
                    end
                end)

                RageUI.ButtonWithStyle("Injured", "/walk (injured)", {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    if Selected then
                        WalkMenuStart("move_m@injured")
                    end
                end)

                for name, data in pairsByKeys(ESXCustomEmote.Walks) do
                    RageUI.ButtonWithStyle(name, "/walk (" .. string.lower(name) .. ")", {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                        if Selected then
                            WalkMenuStart(data[1])
                        end
                    end)
                end
            end)

            RageUI.IsVisible(mainmenu4, true, true, true, function()
                RageUI.ButtonWithStyle(ConfigMenuEmoteLanguages[lang]['danceemotes'], nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                end, danceemotes)

                RageUI.ButtonWithStyle(ConfigMenuEmoteLanguages[lang]['propemotes'], nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                end, propemotes)

                if ConfigMenuEmote.SharedEmotesEnabled then
                    RageUI.ButtonWithStyle(ConfigMenuEmoteLanguages[lang]['shareemotes'], ConfigMenuEmoteLanguages[lang]['shareemotesinfo'], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    end, shareemotes)
                end

                if not ConfigMenuEmote.SqlKeybinding then
                    RageUI.ButtonWithStyle(ConfigMenuEmoteLanguages[lang]['favoriteemotes'], ConfigMenuEmoteLanguages[lang]['favoriteinfo'], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    end, favoriteemotes)
                else
                    RageUI.ButtonWithStyle(ConfigMenuEmoteLanguages[lang]['keybinds'], ConfigMenuEmoteLanguages[lang]['keybindsinfo'] .. " /emotebind [~y~num4-9~w~] [~g~emotename~w~]", {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    end)
                end

                for a, b in pairsByKeys(ESXCustomEmote.Emotes) do
                    x, y, z = table.unpack(b)
                    RageUI.ButtonWithStyle(z, "/e (" .. a .. ")", {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                        if Selected then
                            EmoteMenuStart(a, "emotes")
                        end
                    end)
                end
            end)

            RageUI.IsVisible(danceemotes, true, true, true, function()
                for a, b in pairsByKeys(ESXCustomEmote.Dances) do
                    x, y, z = table.unpack(b)
                    RageUI.ButtonWithStyle(z, "/e (" .. a .. ")", {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                        if Selected then
                            EmoteMenuStart(a, "dances")
                        end
                    end)
                end
            end)
            RageUI.IsVisible(propemotes, true, true, true, function()
                for a, b in pairsByKeys(ESXCustomEmote.PropEmotes) do
                    x, y, z = table.unpack(b)

                    if b.AnimationOptions.PropTextureVariations then
                        RageUI.List(z, b.AnimationOptions.PropTextureVariations, ClothesGestion, "/e (" .. a .. ")", {}, true, function(Hovered, Active, Selected, Index)
                            ClothesGestion = Index

                            if Selected then
                                for k, v in pairs(b.AnimationOptions.PropTextureVariations) do
                                    if Index - 1 == v.Value then
                                        EmoteMenuStart(a, "props", v.Value)
                                    end
                                end
                            end
                        end)
                    else
                        RageUI.ButtonWithStyle(z, "/e (" .. a .. ")", {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                            if Selected then
                                EmoteMenuStart(a, "props")
                            end
                        end)
                    end
                end
            end)
            RageUI.IsVisible(shareemotes, true, true, true, function()
                for a, b in pairsByKeys(ESXCustomEmote.Shared) do
                    x, y, z, otheremotename = table.unpack(b)
                    if otheremotename == nil then
                        RageUI.ButtonWithStyle(z, "/nearby (~g~" .. a .. "~w~)", {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                            if Selected then
                                target, distance = GetClosestPlayer()
                                if (distance ~= -1 and distance < 3) then
                                    _, _, rename = table.unpack(ESXCustomEmote.Shared[a])
                                    TriggerServerEvent("ServerEmoteRequest", GetPlayerServerId(target), a, 'Dances')
                                    ESX.ShowNotification(ConfigMenuEmoteLanguages[lang]['sentrequestto'] .. GetPlayerName(target))
                                else
                                    ESX.ShowNotification(ConfigMenuEmoteLanguages[lang]['nobodyclose'])
                                end
                            end
                        end)
                    else
                        RageUI.ButtonWithStyle(z, "/nearby (~g~" .. a .. "~w~) " .. ConfigMenuEmoteLanguages[lang]['makenearby'] .. " (~y~" .. otheremotename .. "~w~)", {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                            if Selected then
                                target, distance = GetClosestPlayer()
                                if (distance ~= -1 and distance < 3) then
                                    _, _, rename = table.unpack(ESXCustomEmote.Shared[a])
                                    TriggerServerEvent("ServerEmoteRequest", GetPlayerServerId(target), a, 'Dances')
                                    ESX.ShowNotification(ConfigMenuEmoteLanguages[lang]['sentrequestto'] .. GetPlayerName(target))
                                else
                                    ESX.ShowNotification(ConfigMenuEmoteLanguages[lang]['nobodyclose'])
                                end
                            end
                        end)
                    end
                end
            end)
            RageUI.IsVisible(favoriteemotes, true, true, true, function()
                RageUI.ButtonWithStyle(ConfigMenuEmoteLanguages[lang]['prop2info'], nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                end)
                RageUI.ButtonWithStyle(ConfigMenuEmoteLanguages[lang]['rfavorite'], ConfigMenuEmoteLanguages[lang]['rfavorite'], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    if Selected then
                        FavoriteEmote = ""
                        ESX.ShowNotification(ConfigMenuEmoteLanguages[lang]['rfavorite'], 2000)
                        return
                    end
                end)

                for a, b in pairsByKeys(ESXCustomEmote.Emotes) do
                    x, y, z = table.unpack(b)
                    RageUI.ButtonWithStyle(z, ConfigMenuEmoteLanguages[lang]['set'] .. z .. ConfigMenuEmoteLanguages[lang]['setboundemote'], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                        if Selected then
                            FavoriteEmote = a
                            ESX.ShowNotification("~o~" .. firstToUpper(FavoriteEmote) .. ConfigMenuEmoteLanguages[lang]['newsetemote'])
                        end
                    end)
                end

                for a, b in pairsByKeys(ESXCustomEmote.Dances) do
                    x, y, z = table.unpack(b)
                    RageUI.ButtonWithStyle(z, ConfigMenuEmoteLanguages[lang]['set'] .. z .. ConfigMenuEmoteLanguages[lang]['setboundemote'], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                        if Selected then
                            FavoriteEmote = a
                            ESX.ShowNotification("~o~" .. firstToUpper(FavoriteEmote) .. ConfigMenuEmoteLanguages[lang]['newsetemote'])
                        end
                    end)
                end

                if ConfigMenuEmote.SharedEmotesEnabled then
                    for a, b in pairsByKeys(ESXCustomEmote.Shared) do
                        x, y, z = table.unpack(b)
                        RageUI.ButtonWithStyle(z, ConfigMenuEmoteLanguages[lang]['set'] .. z .. ConfigMenuEmoteLanguages[lang]['setboundemote'], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                            if Selected then
                                FavoriteEmote = a
                                ESX.ShowNotification("~o~" .. firstToUpper(FavoriteEmote) .. ConfigMenuEmoteLanguages[lang]['newsetemote'])
                            end
                        end)
                    end
                end

                for a, b in pairsByKeys(ESXCustomEmote.PropEmotes) do
                    x, y, z = table.unpack(b)
            
                    if not b.AnimationOptions.PropTextureVariations then
                        RageUI.ButtonWithStyle(z, ConfigMenuEmoteLanguages[lang]['set'] .. z .. ConfigMenuEmoteLanguages[lang]['setboundemote'], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                            if Selected then
                                FavoriteEmote = a
                                ESX.ShowNotification("~o~" .. firstToUpper(FavoriteEmote) .. ConfigMenuEmoteLanguages[lang]['newsetemote'])
                            end
                        end)
                    end
                end
            end)
            if not RageUI.Visible(mainmenu) and not RageUI.Visible(mainmenu2) and not RageUI.Visible(mainmenu3) and not RageUI.Visible(mainmenu4) and not RageUI.Visible(danceemotes) and not RageUI.Visible(propemotes) and not RageUI.Visible(shareemotes) and not RageUI.Visible(favoriteemotes) then
                mainmenu = RMenu:DeleteType("mainmenu")
            end
        end
    end
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

RegisterNetEvent("esx_custom:OpenMenuEmote") -- For opening the emote menu from another resource.
AddEventHandler("esx_custom:OpenMenuEmote", function()
    OpenEmoteMenu()
end)

function SetPlayerPedExpression(expression, saveToKvp)
    SetFacialIdleAnimOverride(PlayerPedId(), expression, 0)
    if ConfigMenuEmote.PersistentExpression and saveToKvp then SetResourceKvp("expression", expression) end
end

local function DisplayExpressions()
    local moodsString = ""
    for name, _ in pairs(ESXCustomEmote.Expressions) do
        moodsString = moodsString..string.lower(name)..", "
    end

    EmoteChatMessage(moodsString)
    EmoteChatMessage("To reset do /mood reset")
end

if ConfigMenuEmote.ExpressionsEnabled then
    RegisterCommand('mood', function(_source, args, _raw)
        local expression = firstToUpper(string.lower(args[1]))
        if ESXCustomEmote.Expressions[expression] ~= nil then
            SetPlayerPedExpression(ESXCustomEmote.Expressions[expression][1], true)
        else
            EmoteChatMessage("'"..expression.."' is not a valid mood, do /moods to see all moods.")
        end
    end, false)

    RegisterCommand('moods', function()
        DisplayExpressions()
    end, false)

    -- Chat Suggestions
    TriggerEvent('chat:addSuggestion', '/mood', 'Set your current mood/expression.', { { name = "expression", help = "/moods for a list of valid moods" } })
    TriggerEvent('chat:addSuggestion', '/moods', 'List available walking moods/expressions.')

    -- Persistent Expressions
    if ConfigMenuEmote.PersistentExpression then
        AddEventHandler('playerSpawned', function()
            local expression = GetResourceKvpString("expression")
            if expression ~= nil then
                Wait(2500) -- Delay, to ensure the player ped has loaded in
                SetPlayerPedExpression(expression, false)
            end
        end)
    end
end

if ConfigMenuEmote.SqlKeybinding then
    local emob1 = ""
    local emob2 = ""
    local emob3 = ""
    local emob4 = ""
    local emob5 = ""
    local emob6 = ""
    local keyb1 = ""
    local keyb2 = ""
    local keyb3 = ""
    local keyb4 = ""
    local keyb5 = ""
    local keyb6 = ""
    local Initialized = false

    -----------------------------------------------------------------------------------------------------
    -- Commands / Events --------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------

    Citizen.CreateThread(function()
        while true do
            if NetworkIsPlayerActive(PlayerId()) and not Initialized then
                if not Initialized then
                    TriggerServerEvent("EmoteMenu:ServerKeybindExist")
                    Wait(5000)
                end
            end

            if not IsPedSittingInAnyVehicle(PlayerPedId()) then
                for k, v in pairs(ConfigMenuEmote.KeybindKeys) do
                    if IsControlJustReleased(0, v) then
                        if k == keyb1 then if emob1 ~= "" then EmoteCommandStart(nil, { emob1, 0 }) end end
                        if k == keyb2 then if emob2 ~= "" then EmoteCommandStart(nil, { emob2, 0 }) end end
                        if k == keyb3 then if emob3 ~= "" then EmoteCommandStart(nil, { emob3, 0 }) end end
                        if k == keyb4 then if emob4 ~= "" then EmoteCommandStart(nil, { emob4, 0 }) end end
                        if k == keyb5 then if emob5 ~= "" then EmoteCommandStart(nil, { emob5, 0 }) end end
                        if k == keyb6 then if emob6 ~= "" then EmoteCommandStart(nil, { emob6, 0 }) end end
                        Wait(1000)
                    end
                end
            end
            Citizen.Wait(1)
        end
    end)

    RegisterNetEvent("EmoteMenu:ClientKeybindExist")
    AddEventHandler("EmoteMenu:ClientKeybindExist", function(does)
        if does then
            TriggerServerEvent("EmoteMenu:ServerKeybindGrab")
        else
            TriggerServerEvent("EmoteMenu:ServerKeybindCreate")
        end
    end)

    RegisterNetEvent("EmoteMenu:ClientKeybindGet")
    AddEventHandler("EmoteMenu:ClientKeybindGet", function(k1, e1, k2, e2, k3, e3, k4, e4, k5, e5, k6, e6)
        keyb1 = k1
        emob1 = e1
        keyb2 = k2
        emob2 = e2
        keyb3 = k3
        emob3 = e3
        keyb4 = k4
        emob4 = e4
        keyb5 = k5
        emob5 = e5
        keyb6 = k6
        emob6 = e6
        Initialized = true
    end)

    RegisterNetEvent("EmoteMenu:ClientKeybindGetOne")
    AddEventHandler("EmoteMenu:ClientKeybindGetOne", function(key, e)
        ESX.ShowNotification(ConfigMenuEmoteLanguages[lang]['bound'] ..
            "~y~" .. e .. "~w~ " .. ConfigMenuEmoteLanguages[lang]['to'] .. " ~g~" .. firstToUpper(key) .. "~w~")
        if key == "num4" then emob1 = e
            keyb1 = "num4"
        elseif key == "num5" then emob2 = e
            keyb2 = "num5"
        elseif key == "num6" then emob3 = e
            keyb3 = "num6"
        elseif key == "num7" then emob4 = e
            keyb4 = "num7"
        elseif key == "num8" then emob5 = e
            keyb5 = "num8"
        elseif key == "num9" then emob6 = e
            keyb6 = "num9"
        end
    end)

    -----------------------------------------------------------------------------------------------------
    ------ Functions and stuff --------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------

    function EmoteBindsStart()
        EmoteChatMessage(ConfigMenuEmoteLanguages[lang]['currentlyboundemotes'] .. "\n"
            .. firstToUpper(keyb1) .. " = '^2" .. emob1 .. "^7'\n"
            .. firstToUpper(keyb2) .. " = '^2" .. emob2 .. "^7'\n"
            .. firstToUpper(keyb3) .. " = '^2" .. emob3 .. "^7'\n"
            .. firstToUpper(keyb4) .. " = '^2" .. emob4 .. "^7'\n"
            .. firstToUpper(keyb5) .. " = '^2" .. emob5 .. "^7'\n"
            .. firstToUpper(keyb6) .. " = '^2" .. emob6 .. "^7'\n")
    end

    function EmoteBindStart(source, args, raw)
        if #args > 0 then
            local key = string.lower(args[1])
            local emote = string.lower(args[2])
            if (ConfigMenuEmote.KeybindKeys[key]) ~= nil then
                if ESXCustomEmote.Emotes[emote] ~= nil or ESXCustomEmote.Dances[emote] ~= nil or ESXCustomEmote.PropEmotes[emote] ~= nil then
                    TriggerServerEvent("EmoteMenu:ServerKeybindUpdate", key, emote)
                else
                    EmoteChatMessage("'" .. emote .. "' " .. ConfigMenuEmoteLanguages[lang]['notvalidemote'] .. "")
                end
            else
                EmoteChatMessage("'" .. key .. "' " .. ConfigMenuEmoteLanguages[lang]['notvalidkey'])
            end
        else
            print("invalid")
        end
    end

end

Pointing = false

local function IsPlayerAiming(player)
    return IsPlayerFreeAiming(player) or IsAimCamActive() or IsAimCamThirdPersonActive()
end

local function CanPlayerPoint(playerId, playerPed)
    if not DoesEntityExist(playerPed) or not IsPedOnFoot(playerPed) or IsPlayerAiming(playerId) or IsPedFalling(playerPed) or IsPedInjured(playerPed) or IsPedInMeleeCombat(playerPed) or IsPedRagdoll(playerPed) then
        return false
    end

    return true
end

local function PointingStopped()
    local playerPed = PlayerPedId()

    RequestTaskMoveNetworkStateTransition(playerPed, 'Stop')
    SetPedConfigFlag(playerPed, 36, false)
    if not IsPedInjured(playerPed) then
        ClearPedSecondaryTask(playerPed)
    end
    RemoveAnimDict("anim@mp_point")
end

local function PointingThread()
    CreateThread(function()
        local playerId = PlayerId()
        local playerPed = PlayerPedId()

        while Pointing do
            Wait(0)

            if not CanPlayerPoint(playerId, playerPed) then
                Pointing = false
                break
            end

            local camPitch = GetGameplayCamRelativePitch()
            if camPitch < -70.0 then
                camPitch = -70.0
            elseif camPitch > 42.0 then
                camPitch = 42.0
            end

            camPitch = (camPitch + 70.0) / 112.0

            local camHeading = GetGameplayCamRelativeHeading()
            local cosCamHeading = math.cos(camHeading)
            local sinCamHeading = math.sin(camHeading)

            if camHeading < -180.0 then
                camHeading = -180.0
            elseif camHeading > 180.0 then
                camHeading = 180.0
            end

            camHeading = (camHeading + 180.0) / 360.0
            local coords = GetOffsetFromEntityInWorldCoords(playerPed, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
            local _rayHandle, blocked = GetShapeTestResult(StartShapeTestCapsule(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, playerPed, 7))

            SetTaskMoveNetworkSignalFloat(playerPed, 'Pitch', camPitch)
            SetTaskMoveNetworkSignalFloat(playerPed, 'Heading', (camHeading * -1.0) + 1.0)
            SetTaskMoveNetworkSignalBool(playerPed, 'isBlocked', blocked)
            SetTaskMoveNetworkSignalBool(playerPed, 'isFirstPerson', GetCamViewModeForContext(GetCamActiveViewModeContext()) == 4)
        end

        PointingStopped()
    end)
end

local function StartPointing()
    -- Don't start to point if we are prone
    if IsProne then
        EmoteChatMessage("You can't point while crawling.")
        return
    end

    local playerPed = PlayerPedId()
    if not CanPlayerPoint(PlayerId(), playerPed) then
        return
    end

    Pointing = not Pointing

    -- If we should point and the animation was loaded, then start pointing
    if Pointing and LoadAnim("anim@mp_point") then
        SetPedConfigFlag(playerPed, 36, true)
        TaskMoveNetworkByName(playerPed, 'task_mp_pointing', 0.5, false, 'anim@mp_point', 24)

        -- Start thread
        PointingThread()
    end
end


-- Commands & KeyMapping --
if ConfigMenuEmote.PointingEnabled then
    RegisterCommand('pointing', function()
        StartPointing()
    end, false)

    if ConfigMenuEmote.PointingKeybindEnabled then
        RegisterKeyMapping("pointing", ConfigMenuEmote.Key.DescriptionPointing, "keyboard", ConfigMenuEmote.PointingKeybind)
    end

    TriggerEvent('chat:addSuggestion', '/pointing', 'Finger pointing.')
end


-- Exports --
-- Returns if the player is pointing
---@return boolean
local function IsPlayerPointing()
    return Pointing
end

exports('IsPlayerPointing', IsPlayerPointing)

if ConfigMenuEmote.RagdollEnabled then
    RegisterCommand('+ragdoll', function() Ragdoll() end, false)
    RegisterCommand('-ragdoll', function() StopRagdoll() end, false)
    RegisterKeyMapping("+ragdoll", ConfigMenuEmote.Key.DescriptionRagdoll, "keyboard", ConfigMenuEmote.RagdollKeybind)

    local stop = true
    function Ragdoll()
        if IsInAnimation then return end

        local ped = PlayerPedId()
        if not IsPedOnFoot(ped) then return end

        if ConfigMenuEmote.RagdollAsToggle then
            stop = not stop
        else
            stop = false
        end

        while not stop do
            SetPedToRagdoll(ped, 1000, 1000, 0, false, false, false)
            Wait(0)
        end
    end

    function StopRagdoll()
        if ConfigMenuEmote.RagdollAsToggle then return end
        stop = true
    end
end

local isRequestAnim = false
local requestedemote = ''
local targetPlayerId = ''

-----------------------------------------------------------------------------------------------------
-- Commands / Events --------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
if ConfigMenuEmote.SharedEmotesEnabled then
    RegisterCommand('nearby', function(source, args, raw)
        if #args > 0 then
            local emotename = string.lower(args[1])
            target, distance = GetClosestPlayer()
            if (distance ~= -1 and distance < 3) then
                if ESXCustomEmote.Shared[emotename] ~= nil then
                    dict, anim, ename = table.unpack(ESXCustomEmote.Shared[emotename])
                    TriggerServerEvent("ServerEmoteRequest", GetPlayerServerId(target), emotename)
                    ESX.ShowNotification(ConfigMenuEmoteLanguages[lang]['sentrequestto'] ..GetPlayerName(target).. " ~w~(~g~" .. ename .. "~w~)")
                else
                    EmoteChatMessage("'" .. emotename .. "' " .. ConfigMenuEmoteLanguages[lang]['notvalidsharedemote'] .. "")
                end
            else
                ESX.ShowNotification(ConfigMenuEmoteLanguages[lang]['nobodyclose'])
            end
        else
            NearbysOnCommand()
        end
    end, false)
end

RegisterNetEvent("SyncPlayEmote")
AddEventHandler("SyncPlayEmote", function(emote, player)
    EmoteCancel()
    Wait(300)
    targetPlayerId = player
    -- wait a little to make sure animation shows up right on both clients after canceling any previous emote
    if ESXCustomEmote.Shared[emote] ~= nil then
        if ESXCustomEmote.Shared[emote].AnimationOptions and ESXCustomEmote.Shared[emote].AnimationOptions.Attachto then
            -- We do not want to attach the player if the target emote already is attached to player
            -- this would cause issue where both player would be attached to each other and fall under the map
            local targetEmote = ESXCustomEmote.Shared[emote][4]
            if not targetEmote or not ESXCustomEmote.Shared[targetEmote] or not ESXCustomEmote.Shared[targetEmote].AnimationOptions or
                not ESXCustomEmote.Shared[targetEmote].AnimationOptions.Attachto then
                local plyServerId = GetPlayerFromServerId(player)
                local ply = PlayerPedId()
                local pedInFront = GetPlayerPed(plyServerId ~= 0 and plyServerId or GetClosestPlayer())
                local bone = ESXCustomEmote.Shared[emote].AnimationOptions.bone or -1 -- No bone
                local xPos = ESXCustomEmote.Shared[emote].AnimationOptions.xPos or 0.0
                local yPos = ESXCustomEmote.Shared[emote].AnimationOptions.yPos or 0.0
                local zPos = ESXCustomEmote.Shared[emote].AnimationOptions.zPos or 0.0
                local xRot = ESXCustomEmote.Shared[emote].AnimationOptions.xRot or 0.0
                local yRot = ESXCustomEmote.Shared[emote].AnimationOptions.yRot or 0.0
                local zRot = ESXCustomEmote.Shared[emote].AnimationOptions.zRot or 0.0
                AttachEntityToEntity(ply, pedInFront, GetPedBoneIndex(pedInFront, bone), xPos, yPos, zPos, xRot, yRot, zRot, false, false, false, true, 1, true)
            end
        end

        OnEmotePlay(ESXCustomEmote.Shared[emote])
        return
    elseif ESXCustomEmote.Dances[emote] ~= nil then
        OnEmotePlay(ESXCustomEmote.Dances[emote])
        return
    end
end)

RegisterNetEvent("SyncPlayEmoteSource")
AddEventHandler("SyncPlayEmoteSource", function(emote, player)
    -- Thx to Poggu for this part!
    local ply = PlayerPedId()
    local plyServerId = GetPlayerFromServerId(player)
    local pedInFront = GetPlayerPed(plyServerId ~= 0 and plyServerId or GetClosestPlayer())

    local SyncOffsetFront = 1.0
    local SyncOffsetSide = 0.0
    local SyncOffsetHeight = 0.0
    local SyncOffsetHeading = 180.1

    local AnimationOptions = ESXCustomEmote.Shared[emote] and ESXCustomEmote.Shared[emote].AnimationOptions
    if AnimationOptions then
        if AnimationOptions.SyncOffsetFront then
            SyncOffsetFront = AnimationOptions.SyncOffsetFront + 0.0
        end
        if AnimationOptions.SyncOffsetSide then
            SyncOffsetSide = AnimationOptions.SyncOffsetSide + 0.0
        end
        if AnimationOptions.SyncOffsetHeight then
            SyncOffsetHeight = AnimationOptions.SyncOffsetHeight + 0.0
        end
        if AnimationOptions.SyncOffsetHeading then
            SyncOffsetHeading = AnimationOptions.SyncOffsetHeading + 0.0
        end

        -- There is a priority to the source attached, if it is not set, it will use the target
        if (AnimationOptions.Attachto) then
            local bone = AnimationOptions.bone or -1 -- No bone
            local xPos = AnimationOptions.xPos or 0.0
            local yPos = AnimationOptions.yPos or 0.0
            local zPos = AnimationOptions.zPos or 0.0
            local xRot = AnimationOptions.xRot or 0.0
            local yRot = AnimationOptions.yRot or 0.0
            local zRot = AnimationOptions.zRot or 0.0
            AttachEntityToEntity(ply, pedInFront, GetPedBoneIndex(pedInFront, bone), xPos, yPos, zPos, xRot, yRot, zRot,
                false, false, false, true, 1, true)
        end
    end
    local coords = GetOffsetFromEntityInWorldCoords(pedInFront, SyncOffsetSide, SyncOffsetFront, SyncOffsetHeight)
    local heading = GetEntityHeading(pedInFront)
    SetEntityHeading(ply, heading - SyncOffsetHeading)
    SetEntityCoordsNoOffset(ply, coords.x, coords.y, coords.z, 0)
    EmoteCancel()
    Wait(300)
    targetPlayerId = player
    if ESXCustomEmote.Shared[emote] ~= nil then
        OnEmotePlay(ESXCustomEmote.Shared[emote])
        return
    elseif ESXCustomEmote.Dances[emote] ~= nil then
        OnEmotePlay(ESXCustomEmote.Dances[emote])
        return
    end
end)

RegisterNetEvent("SyncCancelEmote")
AddEventHandler("SyncCancelEmote", function(player)
    if targetPlayerId and targetPlayerId == player then
        targetPlayerId = nil
        EmoteCancel()
    end
end)

function CancelSharedEmote(ply)
    if targetPlayerId then
        TriggerServerEvent("ServerEmoteCancel", targetPlayerId)
        targetPlayerId = nil
    end
end

RegisterNetEvent("ClientEmoteRequestReceive")
AddEventHandler("ClientEmoteRequestReceive", function(emotename, etype)
    isRequestAnim = true
    requestedemote = emotename

    if etype == 'Dances' then
        _, _, remote = table.unpack(ESXCustomEmote.Shared[requestedemote])
    else
        _, _, remote = table.unpack(ESXCustomEmote.Shared[requestedemote])
    end

    PlaySound(-1, "NAV", "HUD_AMMO_SHOP_SOUNDSET", 0, 0, 1)
    ESX.ShowNotification(ConfigMenuEmoteLanguages[lang]['doyouwanna'] .. remote .. "~w~)")

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(5)
            if IsControlJustPressed(1, 246) and isRequestAnim then
                target, distance = GetClosestPlayer()
                if (distance ~= -1 and distance < 3) then
                    if ESXCustomEmote.Shared[requestedemote] ~= nil then
                        _, _, _, otheremote = table.unpack(ESXCustomEmote.Shared[requestedemote])
                    elseif ESXCustomEmote.Dances[requestedemote] ~= nil then
                        _, _, _, otheremote = table.unpack(ESXCustomEmote.Dances[requestedemote])
                    end
                    if otheremote == nil then otheremote = requestedemote end
                    TriggerServerEvent("ServerValidEmote", GetPlayerServerId(target), requestedemote, otheremote)
                    isRequestAnim = false
                else
                    ESX.ShowNotification(ConfigMenuEmoteLanguages[lang]['nobodyclose'])
                end
            elseif IsControlJustPressed(1, 182) and isRequestAnim then
                ESX.ShowNotification(ConfigMenuEmoteLanguages[lang]['refuseemote'])
                isRequestAnim = false
            end
        end
    end)
end)

-----------------------------------------------------------------------------------------------------
------ Functions and stuff --------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

function GetPlayerFromPed(ped)
    for _, player in ipairs(GetActivePlayers()) do
        if GetPlayerPed(player) == ped then
            return player
        end
    end
    return -1
end

function GetPedInFront()
    local player = PlayerId()
    local plyPed = GetPlayerPed(player)
    local plyPos = GetEntityCoords(plyPed, false)
    local plyOffset = GetOffsetFromEntityInWorldCoords(plyPed, 0.0, 1.3, 0.0)
    local rayHandle = StartShapeTestCapsule(plyPos.x, plyPos.y, plyPos.z, plyOffset.x, plyOffset.y, plyOffset.z, 10.0, 12
        , plyPed, 7)
    local _, _, _, _, ped2 = GetShapeTestResult(rayHandle)
    return ped2
end

function NearbysOnCommand(source, args, raw)
    local NearbysCommand = ""
    for a in pairsByKeys(ESXCustomEmote.Shared) do
        NearbysCommand = NearbysCommand .. "" .. a .. ", "
    end
    EmoteChatMessage(NearbysCommand)
    EmoteChatMessage(ConfigMenuEmoteLanguages[lang]['emotemenucmd'])
end

function GetClosestPlayer()
    local players = GetPlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local ply = PlayerPedId()
    local plyCoords = GetEntityCoords(ply, 0)

    for index, value in ipairs(players) do
        local target = GetPlayerPed(value)
        if (target ~= ply) then
            local targetCoords = GetEntityCoords(GetPlayerPed(value), 0)
            local distance = GetDistanceBetweenCoords(targetCoords["x"], targetCoords["y"], targetCoords["z"],
                plyCoords["x"], plyCoords["y"], plyCoords["z"], true)
            if (closestDistance == -1 or closestDistance > distance) then
                closestPlayer = value
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end

function GetPlayers()
    local players = {}

    for i = 0, 255 do
        if NetworkIsPlayerActive(i) then
            table.insert(players, i)
        end
    end

    return players
end

function WalkMenuStart(name)
    if ConfigMenuEmote.PersistentWalk then SetResourceKvp("walkstyle", name) end
    RequestWalking(name)
    SetPedMovementClipset(PlayerPedId(), name, 0.2)
    RemoveAnimSet(name)
end

function RequestWalking(set)
    RequestAnimSet(set)
    while not HasAnimSetLoaded(set) do
        Citizen.Wait(1)
    end
end

function WalksOnCommand(source, args, raw)
    local WalksCommand = ""
    for a in pairsByKeys(ESXCustomEmote.Walks) do
        WalksCommand = WalksCommand .. "" .. string.lower(a) .. ", "
    end
    EmoteChatMessage(WalksCommand)
    EmoteChatMessage("To reset do /walk reset")
end

function WalkCommandStart(source, args, raw)
    local name = firstToUpper(string.lower(args[1]))

    if name == "Reset" then
        ResetPedMovementClipset(PlayerPedId())
        return
    end

    if tableHasKey(ESXCustomEmote.Walks, name) then
        local name2 = table.unpack(ESXCustomEmote.Walks[name])
        WalkMenuStart(name2)
    elseif name == "Injured" then
        WalkMenuStart("move_m@injured")
    else
        EmoteChatMessage("'" .. name .. "' is not a valid walk")
    end
end

function tableHasKey(table, key)
    return table[key] ~= nil
end

if ConfigMenuEmote.WalkingStylesEnabled and ConfigMenuEmote.PersistentWalk then
    AddEventHandler('playerSpawned', function()
        local kvp = GetResourceKvpString("walkstyle")

        if kvp ~= nil then
            WalkMenuStart(kvp)
        end
    end)
end
