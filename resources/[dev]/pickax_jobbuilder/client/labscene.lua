-- ─────────────────────────────── Laboratoire interactif : scène 3D ───────────────────────────────
-- Dessine de vrais objets 3D sur la table pendant les étapes (casserole, bols, spatule, contenu, flammes…). La logique reste dans html/labexp.js :
-- il publie l'état de chaque étape (labxScene, positions écran normalisées) ; ici on les projette sur le plateau de la table et on les dessine.
-- Les accessoires viennent de modèles du jeu (Config…Scene3D.Models, 1er modèle existant) ou, à défaut, de marqueurs 3D : la scène marche même sans modèle.
local X = Config.Real.Lab.Experience or {}
local S3 = X.Scene3D or {}
LabScene = {}
local st = nil

local sin, cos, tan, rad, floor, sqrt, abs, min, max = math.sin, math.cos, math.tan, math.rad, math.floor, math.sqrt, math.abs, math.min, math.max

local function hex(c, def)
    c = tostring(c or '')
    local r, g, b = c:match('^#(%x%x)(%x%x)(%x%x)$')
    if not r then return def or { 200, 200, 200 } end
    return { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) }
end
local function lerp(a, b, t) return a + (b - a) * t end
local function clamp(x, a, b) return min(b, max(a, x)) end

-- ─── projection : point écran (0..1) → point du plateau (plan z = surface) ───
local function basis(rot)
    local rx, rz = rad(rot.x), rad(rot.z)
    local f = { x = -sin(rz) * cos(rx), y = cos(rz) * cos(rx), z = sin(rx) }
    local r = { x = cos(rz), y = sin(rz), z = 0.0 }
    local u = { x = r.y * f.z, y = -r.x * f.z, z = r.x * f.y - r.y * f.x }
    return f, r, u
end
local function ray(nx, ny)
    local tx, ty = (nx * 2 - 1) * st.th * st.ar, (1 - ny * 2) * st.th
    return { x = st.f.x + st.r.x * tx + st.u.x * ty, y = st.f.y + st.r.y * tx + st.u.y * ty, z = st.f.z + st.r.z * tx + st.u.z * ty }
end
local function onPlane(nx, ny, z)
    local d = ray(nx, ny)
    if d.z > -0.0001 then return nil end
    local t = (z - st.cp.z) / d.z
    return { x = st.cp.x + d.x * t, y = st.cp.y + d.y * t, z = z }
end
local function W(p, dz)                                      -- {nx, ny} → monde, dz au-dessus du plateau
    local w = onPlane(p[1], p[2], st.surf + (dz or 0.0))
    return w or { x = st.q.x, y = st.q.y, z = st.surf + (dz or 0.0) }
end

-- ─── objets ───
local function loadFirst(list)
    for _, name in ipairs(list or {}) do
        local h = joaat(name)
        if IsModelInCdimage(h) and IsModelValid(h) then
            RequestModel(h)
            local t = GetGameTimer() + 2500
            while not HasModelLoaded(h) and GetGameTimer() < t do Wait(0) end
            if HasModelLoaded(h) then return name, h end
        end
    end
end

local function prop(key, i)
    local e = st.ents[key .. (i or 1)]
    if e then st.used[e] = true end
    return e
end
local function place(e, p, rx, ry, rz)
    if not e then return end
    SetEntityCoordsNoOffset(e, p.x, p.y, p.z, false, false, false)
    SetEntityRotation(e, rx or 0.0, ry or 0.0, rz or 0.0, 2, true)
    SetEntityVisible(e, true, false)
end

-- ─── primitives (marqueurs 3D) ───
local function disc(p, r, h, c, a) DrawMarker(1, p.x, p.y, p.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, r * 2, r * 2, h, c[1], c[2], c[3], a or 255, false, false, 2, false, nil, nil, false) end
local function ball(p, r, c, a) DrawMarker(28, p.x, p.y, p.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, r * 2, r * 2, r * 2, c[1], c[2], c[3], a or 255, false, false, 2, false, nil, nil, false) end
local function V(p, dx, dy, dz) return { x = p.x + (dx or 0), y = p.y + (dy or 0), z = p.z + (dz or 0) } end

local POT_H = 0.11
local function drawPot(p, level, col)
    local R = tonumber(S3.PotRadius) or 0.15
    local e = prop('pot', st.potI)
    st.potI = st.potI + 1
    if e then place(e, p, 0.0, 0.0, 0.0)
    else
        disc(V(p, 0, 0, POT_H / 2), R, POT_H, { 74, 79, 86 })                 -- corps
        disc(V(p, 0, 0, POT_H + 0.001), R * 0.97, 0.003, { 150, 156, 164 })   -- bord
    end
    disc(V(p, 0, 0, tonumber(S3.PotFillZ) or (POT_H - 0.004)), R * 0.9, 0.004, { 12, 13, 16 })     -- intérieur sombre
    if level and level > 0 then disc(V(p, 0, 0, (tonumber(S3.PotFillZ) or (POT_H - 0.004)) + 0.003 + level * 0.012), R * 0.86, 0.004, col or { 138, 122, 59 }) end
end
local function drawBowl(p, level, col, tilt, slot)
    local R = tonumber(S3.BowlRadius) or 0.10
    local e = prop('bowl', slot or 1)
    if e then place(e, p, tilt or 0.0, 0.0, 0.0)
    else
        disc(V(p, 0, 0, 0.022), R, 0.044, { 132, 132, 128 })
        disc(V(p, 0, 0, 0.046), R * 0.86, 0.003, { 38, 38, 36 })
    end
    if level and level > 0.02 then disc(V(p, 0, 0, 0.044 + level * 0.02), R * 0.78 * (0.35 + 0.65 * level), 0.006, col or { 124, 154, 75 }) end
end
local function tool(key, p, down, yaw)                      -- spatule / cuillère / sachet suivant la souris
    local e = prop(key)
    if e then place(e, V(p, 0, 0, down and 0.045 or 0.11), down and 62.0 or 38.0, 0.0, yaw or 35.0)
    else ball(V(p, 0, 0, down and 0.03 or 0.09), 0.014, { 200, 204, 210 }) end
end
local function drop(p, c, n, t)                             -- filet de gouttes/feuilles qui tombent
    for i = 1, n do
        local ph = (t * 2.2 + i / n) % 1.0
        ball(V(p, ((i * 37) % 11 - 5) * 0.003, ((i * 53) % 11 - 5) * 0.003, 0.2 - ph * 0.17), 0.007, c)
    end
end

-- ─── une scène par type d'étape ───
local R = {}

R.add = function(a, c, t)
    local b = W(a.bowl, 0.0)
    drawBowl(b, a.prog, c)
    local pp = W(a.p, 0.0)
    local e = prop('ingr')
    if e then place(e, V(pp, 0, 0, 0.17), a.hold == 1 and 70.0 or 15.0, 0.0, 20.0) else ball(V(pp, 0, 0, 0.17), 0.02, c) end
    if a.hold == 1 then drop(V(b, 0, 0, 0.0), c, 9, t) end
end

R.scrape = function(a, c, t)
    local p = W(a.pot, 0.0)
    drawPot(p, 0.0)
    local rows = tostring(a.mask or '')
    if #rows >= 144 then
        local key = tostring(a.pot[1]) .. tostring(a.pot[2]) .. tostring(a.rn)
        if st.cellKey ~= key then
            st.cellKey, st.cells = key, {}
            for gy = 0, 11 do for gx = 0, 11 do
                local u, v = (gx + 0.5) / 6 - 1, (gy + 0.5) / 6 - 1
                st.cells[gy * 12 + gx + 1] = W({ a.pot[1] + u * a.rn / st.ar, a.pot[2] + v * a.rn }, 0.0)
            end end
        end
        local cell = (tonumber(a.rm) or 0.1) / 6 * 1.25
        local z = (tonumber(S3.PotFillZ) or (POT_H - 0.004)) + 0.004
        for i = 1, 144 do
            if rows:byte(i) == 49 then local w = st.cells[i]; disc({ x = w.x, y = w.y, z = p.z + z }, cell, 0.006, c) end
        end
    end
    tool('spatula', W(a.p, 0.0), a.d == 1, 35.0)
end

R.stir = function(a, c, t)
    local p = W(a.pot, 0.0)
    drawPot(p, 1.0, c)
    local Rp = (tonumber(S3.PotRadius) or 0.15) * 0.62
    for i = 1, 6 do
        local ang = (a.swirl or 0) * (1.0 + i * 0.15) + i * 1.05
        local rr = Rp * (0.3 + 0.12 * i)
        ball({ x = p.x + cos(ang) * rr, y = p.y + sin(ang) * rr, z = p.z + (tonumber(S3.PotFillZ) or POT_H - 0.004) + 0.018 }, 0.009, { 235, 235, 235 }, 110)
    end
    tool('spoon', W(a.p, 0.0), a.d == 1, 0.0)
end

R.heat = function(a, c, t)
    local p = W(a.pot, 0.0)
    local temp = clamp(a.temp or 0, 0, 1)
    disc(V(p, 0, 0, 0.002), (tonumber(S3.PotRadius) or 0.15) * 0.8, 0.004, { 255, floor(70 + 90 * (1 - temp)), 20 }, floor(60 + 190 * temp))   -- brûleur
    drawPot(p, 1.0, c)
    if S3.Light ~= false then DrawLightWithRange(p.x, p.y, p.z + 0.04, 255, 120, 30, 0.6 + 0.9 * temp, 0.6 + 5.5 * temp) end
    if temp > 0.5 then
        for i = 1, 4 do
            local ph = (t * 0.8 + i / 4) % 1.0
            ball(V(p, ((i * 29) % 7 - 3) * 0.012, ((i * 41) % 7 - 3) * 0.012, 0.13 + ph * 0.25), 0.012 + ph * 0.02, { 235, 235, 240 }, floor(120 * (1 - ph)))
        end
    end
end

R.pour = function(a, c, t)
    local pots, bowls = a.pots or {}, a.bowls or {}
    st.potI = 1
    for i, it in ipairs(pots) do drawPot(W(it.p, 0.0), it.f, c) end
    for i, b in ipairs(bowls) do
        local pos = W(b.p, (a.drag == 1 and i == (a.cur or 0) + 1) and 0.12 or 0.0)
        local tilt = (a.drag == 1 and i == (a.cur or 0) + 1 and b.pour and b.pour > 0) and 55.0 or 0.0
        drawBowl(pos, b.f, c, tilt, i)
        if tilt > 0 then                                         -- filet versé
            local pt = pots[i] and W(pots[i].p, 0.0) or pos
            for k = 1, 6 do
                local f = (t * 2 + k / 6) % 1.0
                ball({ x = lerp(pos.x, pt.x, f), y = lerp(pos.y, pt.y, f), z = lerp(pos.z, pt.z + POT_H, f * f) }, 0.009, c)
            end
        end
    end
end

R.timing = function(a, c, t)
    local p = W(a.pos, 0.0)
    if (a.nc or 0) ~= st.lastClicks then st.lastClicks, st.press = a.nc or 0, GetGameTimer() end
    local k = clamp((GetGameTimer() - (st.press or -9999)) / 320.0, 0.0, 1.0)
    local down = k < 0.4 and (k / 0.4) or (1.0 - (k - 0.4) / 0.6)         -- descente rapide puis remontée
    local e = prop('block')
    if e then place(e, V(p, 0, 0, 0.0), 0.0, 0.0, 0.0) else disc(V(p, 0, 0, 0.03), 0.07, 0.06, { 232, 236, 232 }) end
    local base = { x = p.x, y = p.y, z = p.z + 0.32 - 0.24 * down }
    disc(V(base, 0, 0, 0.0), 0.085, 0.02, { 90, 96, 104 })
    disc(V(base, 0, 0, 0.12), 0.02, 0.24, { 60, 64, 70 })
    if (a.flash or 0) > 0 then ball(V(p, 0, 0, 0.1), 0.05, { 61, 214, 140 }, floor(160 * (a.flash / 0.35))) end
end

-- ─── cycle de vie ───
local function frame()
    if not st or not st.a then return end
    local a = st.a
    st.ar = tonumber(a.ar) or st.ar
    local fn = R[a.t]
    if not fn then return end
    st.used, st.potI = {}, 1
    local c = hex(a.c, nil)
    if not a.c or a.c == '' then c = nil end
    if S3.Mat ~= false then disc(V(st.q, 0, 0, st.surf + 0.001), 0.46, 0.002, { 14, 15, 18 }, 235) end
    fn(a, c or { 138, 122, 59 }, GetGameTimer() / 1000.0)
    for _, e in pairs(st.ents) do if not st.used[e] then SetEntityVisible(e, false, false) end end
end

function LabScene.init(q, cam, camCfg)
    LabScene.stop()
    if S3.Enabled == false then return nil end
    local rot = GetCamRot(cam, 2)
    local cp = GetCamCoord(cam)
    local fov = tonumber(camCfg.fov) or 45.0
    local f, r, u = basis(rot)
    local surf = q.z + (tonumber(S3.Surface) or 0.92)
    st = { q = { x = q.x, y = q.y, z = q.z }, surf = surf, cp = { x = cp.x, y = cp.y, z = cp.z }, f = f, r = r, u = u,
        th = tan(rad(fov) / 2), ar = 16 / 9, ents = {}, used = {}, potI = 1, active = true, models = {} }
    local D = sqrt((q.x - cp.x) ^ 2 + (q.y - cp.y) ^ 2 + (surf - cp.z) ^ 2)
    local rel = 1.0 / (2.0 * D * st.th)                      -- fraction de la hauteur d'écran par mètre, au niveau de la table
    -- objets (créés une fois, cachés tant qu'inutilisés)
    for key, list in pairs(S3.Models or {}) do
        local name, h = loadFirst(list)
        if name then
            st.models[key] = name
            local n = tonumber((S3.Pool or {})[key]) or 1
            for i = 1, n do
                local e = CreateObject(h, q.x, q.y, surf, false, false, false)
                if e and e ~= 0 then
                    SetEntityCollision(e, false, false); FreezeEntityPosition(e, true); SetEntityVisible(e, false, false)
                    st.ents[key .. i] = e
                end
            end
            SetModelAsNoLongerNeeded(h)
        end
    end
    CreateThread(function()
        local mine = st
        local fails = 0
        while mine and mine == st and mine.active do
            Wait(0)
            local ok, err = pcall(frame)
            if not ok then fails = fails + 1; if fails == 1 then print(('[jobbuilder] scène 3D du labo : %s'):format(tostring(err))) end end
        end
    end)
    return { rel = rel, potR = tonumber(S3.PotRadius) or 0.15 }
end

function LabScene.set(a) if st then st.a = a end end

function LabScene.stop()
    if not st then return end
    st.active = false
    for _, e in pairs(st.ents) do if DoesEntityExist(e) then DeleteEntity(e) end end
    st = nil
end

LabScene._ray, LabScene._onPlane = ray, onPlane      -- tests

RegisterNUICallback('labxScene', function(data, cb) LabScene.set(data); cb({}) end)

RegisterCommand('labprops', function()
    local n = 0
    for key, list in pairs(S3.Models or {}) do
        local found
        for _, name in ipairs(list) do if IsModelInCdimage(joaat(name)) and IsModelValid(joaat(name)) then found = name break end end
        print(('[jobbuilder] labo 3D · %s : %s'):format(key, found or (#list == 0 and 'dessiné par le jeu' or 'aucun modèle trouvé → repli dessiné par le jeu')))
        n = n + 1
    end
    if n == 0 then print('[jobbuilder] labo 3D : aucun modèle configuré') end
end, false)
