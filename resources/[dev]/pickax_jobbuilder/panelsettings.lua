-- ─────────────────────────────── Réglages du panel web (pickax_settings) ───────────────────────────────
-- Applique les réglages modifiés dans le panel (Réglages du serveur → Drogues & labos) sur la configuration de cette ressource, en direct, sans redémarrage.
-- Rien ne change tant qu'un réglage n'est pas modifié ; remis à sa valeur par défaut, l'ancienne valeur du config.lua est restaurée.
-- Ajouter un réglage : une ligne dans pickax_settings/config.lua (Settings.Schema) + une ligne ci-dessous.
local MAP = {
    { 'jb_lab_enabled', 'Real.Lab.Experience.Enabled' },
    { 'jb_lab_yield', 'Real.Lab.Experience.YieldFromQuality' },
    { 'jb_lab_fail', 'Real.Lab.Experience.FailFromQuality' },
    { 'jb_lab_bonus_q', 'Real.Lab.Experience.PerfectBonus.quality' },
    { 'jb_lab_bonus_extra', 'Real.Lab.Experience.PerfectBonus.extra' },
    { 'jb_lab_minstep', 'Real.Lab.Experience.MinStepMs' },
    { 'jb_lab_3d', 'Real.Lab.Experience.Scene3D.Enabled' },
    { 'jb_lab_light', 'Real.Lab.Experience.Scene3D.Light' },
    { 'jb_lab_mat', 'Real.Lab.Experience.Scene3D.Mat' },
    { 'jb_lab_cam_dist', 'Real.Lab.Experience.Cam.distance' },
    { 'jb_lab_cam_pitch', 'Real.Lab.Experience.Cam.pitch' },
    { 'jb_lab_cam_fov', 'Real.Lab.Experience.Cam.fov' },
    { 'jb_toxic_enabled', 'Real.Lab.Toxic.Enabled' },
    { 'jb_toxic_gain', 'Real.Lab.Toxic.ExposureGain' },
    { 'jb_toxic_damage', 'Real.Lab.Toxic.DamageHealth' },
    { 'jb_toxic_kill', 'Real.Lab.Toxic.KillAt' },
}
local ORIG = {}

local function walk(path, create)
    local t = Config
    local keys = {}
    for k in path:gmatch('[^%.]+') do keys[#keys + 1] = k end
    for i = 1, #keys - 1 do
        if type(t[keys[i]]) ~= 'table' then if not create then return nil end t[keys[i]] = {} end
        t = t[keys[i]]
    end
    return t, keys[#keys]
end

local function applyAll(all, ov)
    if type(all) ~= 'table' or type(ov) ~= 'table' then return end
    local changed = false
    for _, m in ipairs(MAP) do
        local key, path = m[1], m[2]
        local t, k = walk(path, ov[key] ~= nil)
        if t then
            if ov[key] ~= nil then
                if ORIG[key] == nil then ORIG[key] = { t[k] } end
                if t[k] ~= all[key] then t[k] = all[key] changed = true end
            elseif ORIG[key] ~= nil then
                t[k] = ORIG[key][1]; ORIG[key] = nil; changed = true
            end
        end
    end
    if changed and PanelSettingsChanged then PanelSettingsChanged() end
end

AddEventHandler('pickax_settings:changed', applyAll)

-- si cette ressource démarre après pickax_settings : on récupère les réglages déjà en place
CreateThread(function()
    Wait(1500)
    if GetResourceState('pickax_settings') ~= 'started' then return end
    local ok, all = pcall(function() return exports.pickax_settings:GetAll() end)
    local ok2, ov = pcall(function() return exports.pickax_settings:Overrides() end)
    if ok and ok2 then applyAll(all, ov) end
end)
