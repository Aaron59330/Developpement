-- ─────────────────────────────── Réglages du panel web (pickax_settings) ───────────────────────────────
-- Applique les réglages modifiés dans le panel (Réglages du serveur → Gangs) sur la configuration de cette ressource, en direct, sans redémarrage.
-- Rien ne change tant qu'un réglage n'est pas modifié ; remis à sa valeur par défaut, l'ancienne valeur du config.lua est restaurée.
-- Ajouter un réglage : une ligne dans pickax_settings/config.lua (Settings.Schema) + une ligne ci-dessous.
local MAP = {
    { 'gb_terr_enabled', 'Territories.Enabled' },
    { 'gb_capture_seconds', 'Territories.CaptureSeconds' },
    { 'gb_capture_members', 'Territories.MinMembers' },
    { 'gb_owner_blocks', 'Territories.OwnerBlocks' },
    { 'gb_protection_min', 'Territories.ProtectionMinutes' },
    { 'gb_income_interval', 'Territories.IncomeInterval' },
    { 'gb_income_reward', 'Territories.Reward' },
    { 'gb_income_account', 'Territories.RewardAccount' },
    { 'gb_min_defenders', 'Territories.MinDefenders' },
    { 'gb_max_per_gang', 'Territories.MaxPerGang' },
    { 'gb_alert_owner', 'Territories.AlertOwner' },
    { 'gb_racket_enabled', 'Territories.RacketEnabled' },
    { 'gb_racket_rate', 'Territories.RacketRate' },
    { 'gb_conf_enabled', 'Conflicts.Enabled' },
    { 'gb_conf_duration', 'Conflicts.Duration' },
    { 'gb_conf_cooldown', 'Conflicts.Cooldown' },
    { 'gb_conf_capture', 'Conflicts.WinnerCaptures' },
    { 'gb_conf_rep', 'Conflicts.RepWin' },
    { 'gb_turf_enabled', 'TurfWar.Enabled' },
    { 'gb_turf_prep', 'TurfWar.PrepSeconds' },
    { 'gb_turf_duration', 'TurfWar.Duration' },
    { 'gb_turf_attackers', 'TurfWar.MinAttackers' },
    { 'gb_turf_defenders', 'TurfWar.MinDefenders' },
    { 'gb_turf_cooldown', 'TurfWar.Cooldown' },
    { 'gb_turf_minkills', 'TurfWar.MinKillsToWin' },
    { 'gb_turf_repwin', 'TurfWar.RepWin' },
    { 'gb_turf_replose', 'TurfWar.RepLoss' },
    { 'gb_turf_protected', 'TurfWar.AllowProtected' },
    { 'gb_trib_enabled', 'Tribute.Enabled' },
    { 'gb_trib_auto', 'Tribute.AutoStart' },
    { 'gb_trib_interval', 'Tribute.Interval' },
    { 'gb_trib_gangs', 'Tribute.MinGangsOnline' },
    { 'gb_trib_minper', 'Tribute.MinPerGang' },
    { 'gb_trib_seconds', 'Tribute.CaptureSeconds' },
    { 'gb_trib_collect', 'Tribute.CollectWindow' },
    { 'gb_trib_reward', 'Tribute.Reward' },
    { 'gb_trib_account', 'Tribute.RewardAccount' },
    { 'gb_trib_rep', 'Tribute.RewardRep' },
    { 'gb_obj_enabled', 'Objectives.Enabled' },
    { 'gb_obj_auto', 'Objectives.AutoStart' },
    { 'gb_obj_interval', 'Objectives.Interval' },
    { 'gb_obj_hold', 'Objectives.Hold' },
    { 'gb_obj_reward', 'Objectives.Reward' },
    { 'gb_obj_rep', 'Objectives.RewardRep' },
    { 'gb_wars_enabled', 'Tablet.Wars.Enabled' },
    { 'gb_wars_stake', 'Tablet.Wars.MaxStake' },
    { 'gb_wars_cooldown', 'Tablet.Wars.Cooldown' },
    { 'gb_wars_repwin', 'Tablet.Wars.RepWin' },
    { 'gb_wars_replose', 'Tablet.Wars.RepLoss' },
    { 'gb_hq_enabled', 'HQ.Enabled' },
    { 'gb_hq_account', 'HQ.UpgradeAccount' },
    { 'gb_hq_cost2', 'HQ.Levels.2.cost' },
    { 'gb_hq_cost3', 'HQ.Levels.3.cost' },
    { 'gb_hq_cost4', 'HQ.Levels.4.cost' },
    { 'gb_tags_enabled', 'Tags.Enabled' },
    { 'gb_tags_max', 'Tags.MaxPerTerritory' },
    { 'gb_tags_income', 'Tags.IncomePercent' },
    { 'gb_tags_incomemax', 'Tags.IncomeMaxPercent' },
    { 'gb_tags_expire', 'Tags.ExpireDays' },
    { 'gb_raid_enabled', 'HQ.Raid.Enabled' },
    { 'gb_raid_hold', 'HQ.Raid.HoldSeconds' },
    { 'gb_raid_radius', 'HQ.Raid.Radius' },
    { 'gb_raid_max', 'HQ.Raid.MaxSeconds' },
    { 'gb_raid_att', 'HQ.Raid.MinAttackers' },
    { 'gb_raid_def', 'HQ.Raid.MinDefenders' },
    { 'gb_raid_pct', 'HQ.Raid.StealPercent' },
    { 'gb_raid_mindirty', 'HQ.Raid.MinDirty' },
    { 'gb_raid_maxsteal', 'HQ.Raid.MaxSteal' },
    { 'gb_raid_cool', 'HQ.Raid.Cooldown' },
    { 'gb_raid_acool', 'HQ.Raid.AttackerCooldown' },
    { 'gb_season_enabled', 'Season.Enabled' },
    { 'gb_season_days', 'Season.Days' },
    { 'gb_season_min', 'Season.MinPoints' },
    { 'gb_season_account', 'Season.RewardAccount' },
    { 'gb_season_r1', 'Season.Rewards.1.money' },
    { 'gb_season_r2', 'Season.Rewards.2.money' },
    { 'gb_season_r3', 'Season.Rewards.3.money' },
    { 'gb_season_rep1', 'Season.Rewards.1.rep' },
    { 'gb_season_rep2', 'Season.Rewards.2.rep' },
    { 'gb_season_rep3', 'Season.Rewards.3.rep' },
}
local ORIG = {}

local function walk(path, create)
    local t = Config
    local keys = {}
    for k in path:gmatch('[^%.]+') do keys[#keys + 1] = tonumber(k) or k end
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
