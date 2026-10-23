local state = { inCrew = false }
local open = false

local function nui(a, d) d = d or {}; d.action = a; SendNUIMessage(d) end

local function setFocus(b) SetNuiFocus(b, b); open = b end

local function refresh()
    local s = lib.callback.await('pkh:state', false)
    state = s or state
    nui('state', { state = state })
end

RegisterNetEvent('pkh:state', function(s) state = s or state; nui('state', { state = state }) end)

-- ── blip + marker du tableau ──
CreateThread(function()
    local b = Config.Board.blip
    if b then
        local bl = AddBlipForCoord(Config.Board.coords.x, Config.Board.coords.y, Config.Board.coords.z)
        SetBlipSprite(bl, b.sprite); SetBlipColour(bl, b.color); SetBlipScale(bl, b.scale); SetBlipAsShortRange(bl, true)
        BeginTextCommandSetBlipName('STRING'); AddTextComponentString(b.name); EndTextCommandSetBlipName(bl)
    end
    while true do
        local sleep = 800
        local p = GetEntityCoords(PlayerPedId())
        local d = #(p - Config.Board.coords)
        if d < 25.0 and not open then
            sleep = 0
            DrawMarker(1, Config.Board.coords.x, Config.Board.coords.y, Config.Board.coords.z - 0.95, 0, 0, 0, 0, 0, 0, 1.2, 1.2, 0.6,
                (PickaxTheme and PickaxTheme.r) or 10, (PickaxTheme and PickaxTheme.g) or 132, (PickaxTheme and PickaxTheme.b) or 255, 120, false, false, 2, false)
            if d < Config.Board.radius + 0.5 then
                lib.showTextUI('[E] ' .. Config.Board.label)
                if IsControlJustReleased(0, Config.Keys.interact) then
                    lib.hideTextUI(); refresh(); setFocus(true); nui('open', { state = state })
                end
            else lib.hideTextUI() end
        else lib.hideTextUI() end
        Wait(sleep)
    end
end)

RegisterNUICallback('close', function(_, cb) setFocus(false); cb(1) end)
RegisterNUICallback('create', function(d, cb) local s = lib.callback.await('pkh:create', false, d.heist); if s then state = s; nui('state', { state = state }) end; cb(1) end)
RegisterNUICallback('leave', function(_, cb) lib.callback.await('pkh:leave', false); refresh(); cb(1) end)
RegisterNUICallback('difficulty', function(d, cb) lib.callback.await('pkh:difficulty', false, d.value); cb(1) end)
RegisterNUICallback('invite', function(d, cb)
    local ok, err = lib.callback.await('pkh:invite', false, d.id)
    nui('toast', { text = ok and 'Invitation envoyée.' or (err or 'Impossible.'), kind = ok and 'ok' or 'err' }); cb(1)
end)
RegisterNUICallback('start', function(d, cb)
    local ok, err = lib.callback.await('pkh:start', false, d.mission)
    if ok then setFocus(false); nui('close') else nui('toast', { text = err or 'Impossible.', kind = 'err' }) end
    cb(1)
end)
RegisterNUICallback('abort', function(_, cb) TriggerServerEvent('pkh:abort', 'abort'); cb(1) end)

RegisterNetEvent('pkh:invited', function(from, name, label)
    local a = lib.alertDialog({ header = 'Invitation au braquage', content = ('%s vous invite à rejoindre : %s'):format(name, label), centered = true, cancel = true,
        labels = { confirm = 'Rejoindre', cancel = 'Refuser' } })
    if a == 'confirm' then TriggerServerEvent('pkh:accept') end
end)

-- aide au calibrage des coordonnées
RegisterCommand('heistpos', function()
    local p, h = GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId())
    local s = ('vec4(%.1f, %.1f, %.1f, %.1f)'):format(p.x, p.y, p.z, h)
    print('^3[pickax_heists] ' .. s .. '^0'); lib.setClipboard(s)
    lib.notify({ title = 'Position copiée', description = s, type = 'success' })
end, false)
