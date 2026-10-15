-- ─────────────────────────────── Tablette médicale EMS (client) ───────────────────────────────
for _, n in ipairs({ 'emstab:open', 'emstab:live', 'emstab:createCall', 'emstab:stats', 'patients:search', 'patients:get', 'patients:save', 'patients:delete',
    'patients:addEntry', 'patients:delEntry', 'patients:fromNearest', 'care:send' }) do NuiRemote[n] = true end
