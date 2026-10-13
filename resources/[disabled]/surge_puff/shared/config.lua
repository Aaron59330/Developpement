Config = {
    Debug = false,
    ItemName = 'puff',
    Command = 'puff',
    StopCommand = 'puffstop',
    InhaleKey = 'E',
    Dictionary = 'surge_puff',
    FacialDictionary = 'surge_puff_facial',
    Clips = { m = 'inhale_m', f = 'inhale_f' },
    HoldClips = { m = 'hold_m', f = 'hold_f' },
    PedModels = { m = 'mp_m_freemode_01', f = 'mp_f_freemode_01' },
    Model = 'surge_prop_razzbar_bw',
    LedModel = 'surge_prop_razzbar_led',
    DurationMs = 6000,
    LoadTimeoutMs = 10000,
    ViewDistance = 35.0,

    
    Attachment = {
        bone = 57005,
        position = { x = 0.066, y = -0.030, z = -0.023 },
        rotation = { x = -90.0, y = 0.0, z = -25.0 },
    },


    Led = {
        startFrame = 48,
        fullFrame = 53,
        fadeFrame = 99,
        endFrame = 105,
        range = 0.12,
        intensity = 0.25,
    },


    Smoke = {
        enabled = true,
        asset = 'core',
        effect = 'exp_grd_bzgas_smoke',
        bone = 31086,
        offset = { x = 0.0, y = 0.14, z = 0.02 },
        colour = { r = 1.0, g = 1.0, b = 1.0 },
        scale = 0.30,
        endScale = 0.54,
        alpha = 1.0,
        startPhase = 0.55,
        durationMs = 4000,
        fadeMs = 2200,
        intervalMs = 50,
        particlesPerTick = 2,
        particleLifeMs = 800,
        minForward = 0.14,
        maxForward = 1.20,
        maxTrail = 18,
    },
}
