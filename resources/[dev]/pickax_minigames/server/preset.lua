-- ─────────────────────────────── Pré-placement des mini-jeux ───────────────────────────────
-- Chaque disposition est calculée autour d'une ancre { x, y, z, h } : « avant » = direction du cap h, « droite » = perpendiculaire.

local function off(a, fwd, right, dz, hh)
    local r = math.rad(a.h)
    return { x = a.x + (-math.sin(r)) * fwd + math.cos(r) * right, y = a.y + math.cos(r) * fwd + math.sin(r) * right, z = a.z + (dz or 0.0), h = ((hh or a.h) % 360.0) }
end

local function prop(a, model, fwd, right, dz, hdg, mode)
    local c = off(a, fwd, right, dz, hdg)
    return { model = model, x = c.x, y = c.y, z = c.z, h = c.h, rx = 0.0, ry = 0.0, freeze = true, collision = true, mode = mode or 'match' }
end

local L = {}

L.basket = function(a, d)
    d.points.lobby = off(a, 0, 0)
    d.points.spawns = { off(a, 4, -1.5), off(a, 4, 1.5) }
    d.points.hoop = off(a, 13, 0, 3.05, a.h + 180.0)
    d.settings.hoopSpawn = true
end

L.penalty = function(a, d)
    d.points.lobby = off(a, 0, 0)
    d.points.spawns = { off(a, 3, 0) }
    d.points.ball = off(a, 9, 0, 0.1)
    d.points.zones = {
        (function() local c = off(a, 20, 0, 1.0) c.r, c.pts = 1.3, 10 return c end)(),
        (function() local c = off(a, 20, -3.0, 1.9) c.r, c.pts = 1.0, 30 return c end)(),
        (function() local c = off(a, 20, 3.0, 1.9) c.r, c.pts = 1.0, 30 return c end)(),
        (function() local c = off(a, 20, -3.0, 0.6) c.r, c.pts = 1.0, 20 return c end)(),
        (function() local c = off(a, 20, 3.0, 0.6) c.r, c.pts = 1.0, 20 return c end)(),
    }
    d.props = { prop(a, 'prop_goal_posts_01', 20, 0, 0, a.h + 180.0, 'always') }
end

L.darts = function(a, d)
    d.points.lobby = off(a, 0, 0)
    d.points.spawns = { off(a, 2.5, 0) }
    local function z(f, r, dz, rad, pts) local c = off(a, 8, r, 1.7 + dz) c.r, c.pts = rad, pts return c end
    d.points.zones = { z(8, 0, 0, 0.14, 50), z(8, 0.28, 0, 0.14, 25), z(8, -0.28, 0, 0.14, 25), z(8, 0, 0.28, 0.14, 25), z(8, 0, -0.28, 0.14, 25),
        z(8, 0.55, 0, 0.2, 10), z(8, -0.55, 0, 0.2, 10), z(8, 0, 0.55, 0.2, 10), z(8, 0, -0.55, 0.2, 10) }
    d.props = { prop(a, 'prop_dart_bd_01', 8.2, 0, 1.2, a.h + 180.0, 'always') }
end

L.bowling = function(a, d)
    d.points.lobby = off(a, 0, 0)
    d.points.spawns = { off(a, 1.5, 0) }
    d.points.ball = off(a, 3.0, 0, 0.1)
    d.points.pinhead = off(a, 21, 0)
end

L.tennis = function(a, d)
    d.points.lobby = off(a, 0, 0)
    d.points.spawns = { off(a, 4, 0) }
    d.points.machine = off(a, 24, 0, 0.5)
    local function z(f, r, pts) local c = off(a, f, r) c.r, c.pts = 2.2, pts return c end
    d.points.zones = { z(15, 0, 10), z(18, -3.5, 30), z(18, 3.5, 30), z(21, 0, 20), z(14, -4, 15), z(14, 4, 15) }
    d.props = { prop(a, 'prop_tennis_net_01', 12, 0, 0, a.h, 'always') }
end

L.ring = function(a, d)
    d.points.lobby = off(a, -9, 0)
    d.points.spawns = { off(a, -2.5, 0, 0, a.h), off(a, 2.5, 0, 0, a.h + 180.0) }
    d.points.center = off(a, 0, 0)
    d.props = {}
    for _, c in ipairs({ { -4, -4 }, { -4, 4 }, { 4, -4 }, { 4, 4 } }) do d.props[#d.props + 1] = prop(a, 'prop_roadcone02a', c[1], c[2], 0, 0, 'always') end
end

-- Arène d'équipes : deux camps face à face + abris
L.arena = function(a, d)
    d.points.lobby = off(a, 0, 0)
    d.points.center = off(a, 30, 0)
    d.points.spawns = {}
    for i = -2, 2 do
        local c1 = off(a, 8, i * 4) c1.team = 1
        local c2 = off(a, 52, i * 4, 0, a.h + 180.0) c2.team = 2
        d.points.spawns[#d.points.spawns + 1] = c1
        d.points.spawns[#d.points.spawns + 1] = c2
    end
    d.props = {}
    local models = { 'prop_barrier_work05', 'prop_skip_08a', 'prop_conc_sacks_02a', 'prop_pallet_01a' }
    local cover = { { 18, -12 }, { 18, 12 }, { 22, 0 }, { 30, -20 }, { 30, 20 }, { 30, -6 }, { 30, 6 }, { 38, 0 }, { 42, -12 }, { 42, 12 }, { 26, -28 }, { 34, 28 } }
    for i, c in ipairs(cover) do d.props[#d.props + 1] = prop(a, models[(i % #models) + 1], c[1], c[2], 0, (i * 37) % 180) end
end

-- Chacun pour soi : 6 points autour du centre
L.ffa = function(a, d)
    d.points.lobby = off(a, 0, 0)
    d.points.center = off(a, 22, 0)
    d.points.spawns = {}
    for _, c in ipairs({ { 8, -10 }, { 8, 10 }, { 22, -20 }, { 22, 20 }, { 36, -10 }, { 36, 10 } }) do d.points.spawns[#d.points.spawns + 1] = off(a, c[1], c[2], 0, a.h + 180.0) end
    d.props = {}
    local cover = { { 16, 0 }, { 22, -10 }, { 22, 10 }, { 28, 0 }, { 14, -14 }, { 14, 14 }, { 30, -14 }, { 30, 14 } }
    for i, c in ipairs(cover) do d.props[#d.props + 1] = prop(a, i % 2 == 0 and 'prop_skip_08a' or 'prop_barrier_work05', c[1], c[2], 0, (i * 53) % 180) end
end

-- Sprint en ligne droite : départ, 4 jalons tous les 25 m
L.sprint = function(a, d)
    d.points.lobby = off(a, -6, 0)
    d.points.spawns = { off(a, 0, -2), off(a, 0, 0), off(a, 0, 2), off(a, 0, 4) }
    d.points.checkpoints = {}
    for i = 1, 4 do local c = off(a, 25 * i, 1) c.r = 4.0 d.points.checkpoints[#d.points.checkpoints + 1] = c end
end

local function build(p)
    local T = Config.Types[p.type]
    local s = {}
    for _, f in ipairs(Config.Common) do s[f.key] = f.def end
    for _, f in ipairs(T.fields) do s[f.key] = f.def end
    local desc = ''
    for _, t in ipairs(T.templates or {}) do
        if t.id == p.tpl then for k, v in pairs(t.settings) do s[k] = v end desc = t.desc end
    end
    for k, v in pairs(p.settings or {}) do s[k] = v end
    local d = { type = p.type, name = p.name, description = desc, enabled = true, settings = s, points = {}, props = {}, blip = { enabled = true, shortRange = true, label = p.name }, marker = { help = true } }
    local fn = L[p.layout]
    if fn then fn(p.anchor, d) end
    return d
end

local function seed(force)
    if not Config.AutoSeed and not force then return 0 end
    local row = MySQL.single.await("SELECT v FROM minigames_settings WHERE k = 'seeded_games'")
    local done = row and MG.decode(row.v, {}) or {}
    local made = 0
    for _, p in ipairs(Config.PresetGames) do
        if (force or not done[p.id]) and Config.Types[p.type] then
            local exists = false
            for _, e in pairs(MG.Defs) do if e.name == p.name then exists = true break end end
            if not exists then
                local d, err = MG.sanitize(build(p))
                if d then
                    d.enabled = #MG.problems(d) == 0
                    MySQL.insert.await('INSERT INTO minigames_defs (id, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)', { d.id, json.encode(d) })
                    MG.Defs[d.id] = d
                    made = made + 1
                    if not d.enabled then print(('^3[minigames] Pré-placement : « %s » créé mais incomplet.^0'):format(d.name)) end
                else print(('^3[minigames] Pré-placement : « %s » ignoré (%s).^0'):format(p.name, tostring(err))) end
            end
            done[p.id] = true
        end
    end
    MySQL.insert.await("INSERT INTO minigames_settings (k, v) VALUES ('seeded_games', ?) ON DUPLICATE KEY UPDATE v = VALUES(v)", { json.encode(done) })
    if made > 0 then MG.sync() print(('^2[minigames] Pré-placement : %d mini-jeu(x) créé(s) et activé(s).^0'):format(made)) end
    return made
end

CreateThread(function()
    while not MG.ready do Wait(500) end
    Wait(2000)
    seed(false)
end)

RegisterCommand('mgseed', function(src)
    if src ~= 0 and not MG.isAdmin(src) then return end
    local n = seed(true)
    local msg = n > 0 and (n .. ' mini-jeu(x) créé(s).') or 'Rien à créer : tout est déjà en place.'
    if src == 0 then print('[minigames] ' .. msg) else MG.notify(src, msg) end
end, false)
