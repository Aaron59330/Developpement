-- Performances (FPS) : préréglages d'allègement du rendu + compteur de FPS, mémorisés par joueur
local KVP = 'corepickax:perf'

PickaxPerf = {
    Presets = {
        { id = 'normal',  name = 'Qualité normale', desc = 'Aucun allègement (réglages du jeu)' },
        { id = 'equilibre', name = 'Équilibré', desc = 'Réduit légèrement les véhicules et les lumières' },
        { id = 'performance', name = 'Performance', desc = 'Réduit véhicules, piétons, lumières et ombres' },
        { id = 'max', name = 'FPS maximum', desc = 'Allègement maximal du rendu (qualité réduite)' },
    },
}

local state = { preset = 'normal', fps = false }

local function load()
    local raw = GetResourceKvpString(KVP)
    if raw and raw ~= '' then
        local ok, t = pcall(json.decode, raw)
        if ok and type(t) == 'table' then
            if type(t.preset) == 'string' then state.preset = t.preset end
            state.fps = t.fps == true
        end
    end
end

local function save() SetResourceKvp(KVP, json.encode(state)) end

local PARAMS = {
    normal      = { ped = false, veh = false, distant = true,  flash = 10.0, cutoff = 0.0,  shadows = true,  rope = true },
    equilibre   = { ped = false, veh = true,  distant = true,  flash = 6.0,  cutoff = 0.0,  shadows = true,  rope = true },
    performance = { ped = true,  veh = true,  distant = false, flash = 4.0,  cutoff = 40.0, shadows = false, rope = false },
    max         = { ped = true,  veh = true,  distant = false, flash = 2.0,  cutoff = 25.0, shadows = false, rope = false },
}

local function apply()
    local p = PARAMS[state.preset] or PARAMS.normal
    pcall(SetReducePedModelBudget, p.ped)
    pcall(SetReduceVehicleModelBudget, p.veh)
    pcall(SetDistantCarsEnabled, p.distant)
    pcall(SetFlashLightFadeDistance, p.flash)
    pcall(SetLightsCutoffDistanceTweak, p.cutoff)
    pcall(RopeDrawShadowEnabled, p.rope)
    pcall(CascadeShadowsSetDynamicDepthMode, p.shadows)
    pcall(CascadeShadowsEnableEntityTracker, p.shadows)
end

function PickaxPerf.Get() return { preset = state.preset, fps = state.fps } end

function PickaxPerf.PresetIndex()
    for i = 1, #PickaxPerf.Presets do
        if PickaxPerf.Presets[i].id == state.preset then return i end
    end
    return 1
end

function PickaxPerf.SetPreset(id)
    if not PARAMS[id] then return end
    state.preset = id
    save()
    apply()
end

function PickaxPerf.SetFps(value)
    state.fps = value and true or false
    save()
end

CreateThread(function()
    load()
    Wait(5000)
    apply()
    local fps, last = 60, GetGameTimer()
    while true do
        if state.fps then
            local dt = GetFrameTime()
            if dt > 0 then fps = fps + ((1.0 / dt) - fps) * 0.05 end
            SetTextFont(4)
            SetTextScale(0.0, 0.34)
            SetTextColour(255, 255, 255, 230)
            SetTextOutline()
            SetTextRightJustify(true)
            SetTextWrap(0.0, 0.985)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(('%d FPS'):format(math.floor(fps + 0.5)))
            EndTextCommandDisplayText(0.0, 0.012)
            Wait(0)
        else
            Wait(500)
        end
    end
end)
