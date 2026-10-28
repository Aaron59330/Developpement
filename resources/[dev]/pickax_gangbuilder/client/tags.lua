-- ─────────────────────────────── Tags de gang (client) : marque colorée au sol, visible de près ───────────────────────────────
local tags = {}

RegisterNetEvent('gangbuilder:client:tags', function(list) tags = type(list) == 'table' and list or {} end)

CreateThread(function()
    Wait(4000)
    TriggerServerEvent('gangbuilder:server:tagsReady')
end)

local function rgb(t)
    local r, gg, b = tostring(t.color or ''):match('^#(%x%x)(%x%x)(%x%x)$')
    if r then return tonumber(r, 16), tonumber(gg, 16), tonumber(b, 16) end
    return 253, 194, 125
end

CreateThread(function()
    while true do
        if #tags == 0 or not (Config.Tags or {}).Enabled then Wait(1500) else
            Wait(0)
            local p = GetEntityCoords(PlayerPedId())
            local near = false
            for _, t in ipairs(tags) do
                if #(p - vector3(t.x, t.y, t.z)) < 30.0 then
                    near = true
                    local r, g, b = rgb(t)
                    DrawMarker(1, t.x + 0.0, t.y + 0.0, t.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.9, 0.9, 0.12, r, g, b, 235, false, false, 2, false, nil, nil, false)
                    DrawMarker(0, t.x + 0.0, t.y + 0.0, t.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, r, g, b, 235, false, true, 2, true, nil, nil, false)
                end
            end
            if not near then Wait(500) end
        end
    end
end)
