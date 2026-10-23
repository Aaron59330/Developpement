-- Pulse (micro-blog), Snapgram (photos & stories), Match (rencontres), Photos
local APPS = { pulse = true, snap = true }

local function acctOf(app, id)
    return MySQL.single.await('SELECT id, app, identifier, handle, display, avatar, banner, bio, verified, created FROM aura_accounts WHERE app = ? AND identifier = ?', { app, id })
end
local function acctByHandle(app, handle)
    return MySQL.single.await('SELECT id, app, identifier, handle, display, avatar, banner, bio, verified, created FROM aura_accounts WHERE app = ? AND handle = ?', { app, handle })
end

local function isVerifiedJob(src)
    local x = ESX.GetPlayerFromId(src)
    return x and x.job and Config.Social.verifiedJobs[x.job.name] or false
end

local function notify(identifier, app, title, body)
    Aura.Push(identifier, 'notify', { app = app, title = title, body = body })
end

lib.callback.register('aura:acctGet', function(src, app)
    local id = Aura.ident[src]
    if not id or not APPS[app] then return nil end
    local a = acctOf(app, id)
    if a and isVerifiedJob(src) and a.verified == 0 then
        MySQL.update('UPDATE aura_accounts SET verified = 1 WHERE id = ?', { a.id }); a.verified = 1
    end
    return a
end)

lib.callback.register('aura:acctCreate', function(src, app, handle, display, avatar)
    local id = Aura.ident[src]
    if not id or not APPS[app] then return false end
    handle = tostring(handle or ''):lower():gsub('^@', '')
    if not handle:match('^[a-z0-9_]+$') or #handle < 3 or #handle > 20 then return false, 'Identifiant : 3 à 20 caractères (a-z, 0-9, _)' end
    if acctOf(app, id) then return false, 'Compte déjà existant' end
    if acctByHandle(app, handle) then return false, 'Identifiant déjà pris' end
    display = Aura.Clamp(Aura.Trim(display), 40); if display == '' then display = handle end
    local ok = MySQL.insert.await('INSERT INTO aura_accounts (app, identifier, handle, display, avatar, verified, created) VALUES (?,?,?,?,?,?,?)',
        { app, id, handle, display, avatar and Aura.Clamp(avatar, 500) or nil, isVerifiedJob(src) and 1 or 0, Aura.Now() })
    return ok and acctOf(app, id) or false
end)

lib.callback.register('aura:acctUpdate', function(src, app, patch)
    local id = Aura.ident[src]
    if not id or not APPS[app] or type(patch) ~= 'table' then return false end
    local a = acctOf(app, id); if not a then return false end
    MySQL.update.await('UPDATE aura_accounts SET display = ?, avatar = ?, banner = ?, bio = ? WHERE id = ?', {
        Aura.Clamp(patch.display ~= nil and Aura.Trim(patch.display) or a.display, 40), patch.avatar ~= nil and Aura.Clamp(patch.avatar, 500) or a.avatar,
        patch.banner ~= nil and Aura.Clamp(patch.banner, 500) or a.banner, patch.bio ~= nil and Aura.Clamp(patch.bio, 200) or a.bio, a.id })
    return acctOf(app, id)
end)

local POST_SELECT = [[
    SELECT p.id, p.app, p.handle, p.kind, p.body, p.images, p.parent, p.repost, p.created, a.display, a.avatar, a.verified,
        (SELECT COUNT(*) FROM aura_likes l WHERE l.app = p.app AND l.post = p.id) AS likes,
        (SELECT COUNT(*) FROM aura_posts r WHERE r.parent = p.id) AS replies,
        (SELECT COUNT(*) FROM aura_posts r2 WHERE r2.repost = p.id) AS reposts,
        EXISTS(SELECT 1 FROM aura_likes l2 WHERE l2.app = p.app AND l2.post = p.id AND l2.handle = ?) AS liked,
        EXISTS(SELECT 1 FROM aura_posts r3 WHERE r3.repost = p.id AND r3.handle = ?) AS reposted
    FROM aura_posts p JOIN aura_accounts a ON a.app = p.app AND a.handle = p.handle ]]

local function enrich(rows, app, me)
    local need = {}
    for _, r in ipairs(rows) do
        r.images = Aura.Unjson(r.images, {})
        r.liked = r.liked == 1 or r.liked == true
        r.reposted = r.reposted == 1 or r.reposted == true
        if r.repost then need[#need + 1] = r.repost end
    end
    if #need > 0 then
        local orig = MySQL.query.await(POST_SELECT .. ' WHERE p.id IN (' .. table.concat(need, ',') .. ')', { me, me }) or {}
        local map = {}
        for _, o in ipairs(orig) do o.images = Aura.Unjson(o.images, {}); o.liked = o.liked == 1; o.reposted = o.reposted == 1; map[o.id] = o end
        for _, r in ipairs(rows) do if r.repost then r.original = map[r.repost] end end
    end
    return rows
end

lib.callback.register('aura:feed', function(src, app, mode, before)
    local id = Aura.ident[src]
    if not id or not APPS[app] then return {} end
    local a = acctOf(app, id)
    local me = a and a.handle or ''
    local cond, args = 'p.app = ? AND p.parent IS NULL', { me, me, app }
    if before and tonumber(before) then cond = cond .. ' AND p.id < ?'; args[#args + 1] = tonumber(before) end
    mode = tostring(mode or 'explore')
    if app == 'snap' then
        if mode == 'stories' then cond = cond .. " AND p.kind = 'story' AND p.created > " .. ((os.time() - Config.Social.storyHours * 3600) * 1000)
        else cond = cond .. " AND p.kind <> 'story'" end
    else cond = cond .. " AND p.kind = 'post'" end
    if mode == 'following' and a then
        cond = cond .. ' AND (p.handle = ? OR p.handle IN (SELECT followee FROM aura_follows WHERE app = ? AND follower = ?))'
        args[#args + 1] = me; args[#args + 1] = app; args[#args + 1] = me
    elseif mode:sub(1, 5) == 'user:' then cond = cond .. ' AND p.handle = ?'; args[#args + 1] = mode:sub(6)
    elseif mode:sub(1, 4) == 'tag:' then cond = cond .. ' AND p.body LIKE ?'; args[#args + 1] = '%#' .. mode:sub(5):gsub('[%%_]', '') .. '%' end
    local rows = MySQL.query.await(POST_SELECT .. ' WHERE ' .. cond .. ' ORDER BY p.id DESC LIMIT 30', args) or {}
    return enrich(rows, app, me)
end)

lib.callback.register('aura:comments', function(src, app, pid)
    local id = Aura.ident[src]
    if not id or not APPS[app] then return {} end
    local a = acctOf(app, id)
    local me = a and a.handle or ''
    local rows = MySQL.query.await(POST_SELECT .. ' WHERE p.app = ? AND p.parent = ? ORDER BY p.id ASC LIMIT 100', { me, me, app, tonumber(pid) or 0 }) or {}
    return enrich(rows, app, me)
end)

lib.callback.register('aura:postGet', function(src, app, pid)
    local id = Aura.ident[src]
    if not id or not APPS[app] then return nil end
    local a = acctOf(app, id); local me = a and a.handle or ''
    local rows = MySQL.query.await(POST_SELECT .. ' WHERE p.app = ? AND p.id = ?', { me, me, app, tonumber(pid) or 0 }) or {}
    return enrich(rows, app, me)[1]
end)

local lastPost = {}
lib.callback.register('aura:post', function(src, app, data)
    local id = Aura.ident[src]
    if not id or not APPS[app] or type(data) ~= 'table' then return false end
    local a = acctOf(app, id); if not a then return false, 'Crée un compte d\'abord' end
    if lastPost[src] and GetGameTimer() - lastPost[src] < 1500 then return false, 'Trop rapide' end
    lastPost[src] = GetGameTimer()
    local body = Aura.Clamp(Aura.Trim(data.body), Config.Social.postMaxLength)
    local images = {}
    for _, u in ipairs(data.images or {}) do
        if type(u) == 'string' and u:match('^https?://') and #images < Config.Social.maxImages then images[#images + 1] = Aura.Clamp(u, 500) end
    end
    local kind = 'post'
    if app == 'snap' then
        kind = data.kind == 'story' and 'story' or 'post'
        if #images == 0 then return false, 'Une photo est requise' end
    elseif body == '' and #images == 0 and not data.repost then return false, 'Message vide' end
    local parent = tonumber(data.parent)
    local repost = tonumber(data.repost)
    local pid = MySQL.insert.await('INSERT INTO aura_posts (app, handle, kind, body, images, parent, repost, created) VALUES (?,?,?,?,?,?,?,?)',
        { app, a.handle, kind, body, Aura.Json(images), parent, repost, Aura.Now() })
    local target = parent or repost
    if target then
        local o = MySQL.single.await('SELECT a.identifier, a.handle FROM aura_posts p JOIN aura_accounts a ON a.app = p.app AND a.handle = p.handle WHERE p.id = ?', { target })
        if o and o.handle ~= a.handle then
            notify(o.identifier, app, a.display, parent and ('a répondu : ' .. body) or 'a partagé votre publication')
        end
    end
    for h in body:gmatch('@([%w_]+)') do
        local m = acctByHandle(app, h:lower())
        if m and m.handle ~= a.handle then notify(m.identifier, app, a.display, 'vous a mentionné : ' .. body) end
    end
    return pid
end)

lib.callback.register('aura:postDelete', function(src, app, pid)
    local id = Aura.ident[src]
    if not id or not APPS[app] then return false end
    local a = acctOf(app, id)
    local p = MySQL.single.await('SELECT handle FROM aura_posts WHERE id = ? AND app = ?', { tonumber(pid) or 0, app })
    if not p then return false end
    if not ((a and a.handle == p.handle) or Aura.IsAdmin(src)) then return false end
    MySQL.update.await('DELETE FROM aura_posts WHERE id = ? OR parent = ?', { pid, pid })
    MySQL.update.await('DELETE FROM aura_likes WHERE app = ? AND post = ?', { app, pid })
    return true
end)

lib.callback.register('aura:like', function(src, app, pid, like)
    local id = Aura.ident[src]
    if not id or not APPS[app] then return false end
    local a = acctOf(app, id); if not a then return false end
    pid = tonumber(pid)
    if like then
        local ins = MySQL.insert.await('INSERT IGNORE INTO aura_likes (app, post, handle) VALUES (?,?,?)', { app, pid, a.handle })
        if ins and ins ~= 0 then
            local o = MySQL.single.await('SELECT a2.identifier, a2.handle FROM aura_posts p JOIN aura_accounts a2 ON a2.app = p.app AND a2.handle = p.handle WHERE p.id = ?', { pid })
            if o and o.handle ~= a.handle then notify(o.identifier, app, a.display, 'a aimé votre publication') end
        end
    else MySQL.update.await('DELETE FROM aura_likes WHERE app = ? AND post = ? AND handle = ?', { app, pid, a.handle }) end
    return true
end)

lib.callback.register('aura:follow', function(src, app, handle, follow)
    local id = Aura.ident[src]
    if not id or not APPS[app] then return false end
    local a = acctOf(app, id); if not a or a.handle == handle then return false end
    local t = acctByHandle(app, handle); if not t then return false end
    if follow then
        local ins = MySQL.insert.await('INSERT IGNORE INTO aura_follows (app, follower, followee) VALUES (?,?,?)', { app, a.handle, handle })
        if ins and ins ~= 0 then notify(t.identifier, app, a.display, 'a commencé à vous suivre') end
    else MySQL.update.await('DELETE FROM aura_follows WHERE app = ? AND follower = ? AND followee = ?', { app, a.handle, handle }) end
    return true
end)

lib.callback.register('aura:profile', function(src, app, handle)
    local id = Aura.ident[src]
    if not id or not APPS[app] then return nil end
    local me = acctOf(app, id)
    local t = acctByHandle(app, tostring(handle or ''):lower())
    if not t then return nil end
    t.identifier = nil
    t.posts = MySQL.scalar.await("SELECT COUNT(*) FROM aura_posts WHERE app = ? AND handle = ? AND parent IS NULL AND kind <> 'story'", { app, t.handle }) or 0
    t.followers = MySQL.scalar.await('SELECT COUNT(*) FROM aura_follows WHERE app = ? AND followee = ?', { app, t.handle }) or 0
    t.following = MySQL.scalar.await('SELECT COUNT(*) FROM aura_follows WHERE app = ? AND follower = ?', { app, t.handle }) or 0
    t.isFollowing = me and MySQL.scalar.await('SELECT 1 FROM aura_follows WHERE app = ? AND follower = ? AND followee = ?', { app, me.handle, t.handle }) ~= nil or false
    t.isMe = me and me.handle == t.handle or false
    return t
end)

lib.callback.register('aura:socialSearch', function(src, app, q)
    local id = Aura.ident[src]
    if not id or not APPS[app] then return { accounts = {}, tags = {} } end
    q = tostring(q or ''):gsub('[%%_]', ''):gsub('^[@#]', '')
    if #q < 1 then
        -- tendances : hashtags les plus utilisés récemment
        local posts = MySQL.query.await('SELECT body FROM aura_posts WHERE app = ? AND created > ? AND body LIKE "%#%" ORDER BY id DESC LIMIT 300', { app, (os.time() - 7 * 86400) * 1000 }) or {}
        local c = {}
        for _, p in ipairs(posts) do for t in (p.body or ''):gmatch('#([%w_À-ÿ]+)') do t = t:lower(); c[t] = (c[t] or 0) + 1 end end
        local list = {}
        for t, n in pairs(c) do list[#list + 1] = { tag = t, count = n } end
        table.sort(list, function(a, b) return a.count > b.count end)
        while #list > 10 do table.remove(list) end
        return { accounts = {}, tags = list }
    end
    local acc = MySQL.query.await('SELECT handle, display, avatar, verified FROM aura_accounts WHERE app = ? AND (handle LIKE ? OR display LIKE ?) LIMIT 20', { app, q .. '%', '%' .. q .. '%' }) or {}
    return { accounts = acc, tags = {} }
end)

lib.callback.register('aura:socialNotifs', function(src, app) return {} end)

RegisterCommand('phone_verify', function(src, args)
    if src ~= 0 and not Aura.IsAdmin(src) then return end
    MySQL.update('UPDATE aura_accounts SET verified = ? WHERE handle = ?', { (args[3] == '0') and 0 or 1, tostring(args[2] or ''):lower() })
end, false)

-- ═════════════════ MATCH ═════════════════
local function matchProfile(id) return MySQL.single.await('SELECT identifier, name, age, gender, looking, bio, photos, active FROM aura_match WHERE identifier = ?', { id }) end

lib.callback.register('aura:matchMe', function(src)
    local id = Aura.ident[src]; if not id then return nil end
    local p = matchProfile(id); if p then p.photos = Aura.Unjson(p.photos, {}); p.identifier = nil end
    return p
end)

lib.callback.register('aura:matchSave', function(src, d)
    local id = Aura.ident[src]; if not id or type(d) ~= 'table' then return false end
    local photos = {}
    for _, u in ipairs(d.photos or {}) do if type(u) == 'string' and u:match('^https?://') and #photos < 5 then photos[#photos + 1] = Aura.Clamp(u, 500) end end
    if #photos == 0 then return false, 'Ajoute au moins une photo' end
    local name = Aura.Clamp(Aura.Trim(d.name), 40); if name == '' then return false, 'Prénom requis' end
    local age = math.max(18, math.min(99, tonumber(d.age) or 25))
    local gender = ({ homme = true, femme = true, autre = true })[d.gender] and d.gender or 'autre'
    local looking = ({ homme = true, femme = true, tous = true })[d.looking] and d.looking or 'tous'
    MySQL.query.await('INSERT INTO aura_match (identifier, name, age, gender, looking, bio, photos, active) VALUES (?,?,?,?,?,?,?,1) ON DUPLICATE KEY UPDATE name=VALUES(name), age=VALUES(age), gender=VALUES(gender), looking=VALUES(looking), bio=VALUES(bio), photos=VALUES(photos), active=1',
        { id, name, age, gender, looking, Aura.Clamp(d.bio, 250), Aura.Json(photos) })
    return true
end)

lib.callback.register('aura:matchDelete', function(src)
    local id = Aura.ident[src]; if not id then return false end
    MySQL.update.await('DELETE FROM aura_match WHERE identifier = ?', { id })
    MySQL.update.await('DELETE FROM aura_swipes WHERE identifier = ? OR target = ?', { id, id })
    return true
end)

lib.callback.register('aura:matchDeck', function(src)
    local id = Aura.ident[src]; if not id then return {} end
    local me = matchProfile(id); if not me then return {} end
    local rows = MySQL.query.await([[SELECT identifier, name, age, gender, bio, photos FROM aura_match
        WHERE active = 1 AND identifier <> ? AND identifier NOT IN (SELECT target FROM aura_swipes WHERE identifier = ?)
        AND (? = 'tous' OR gender = ?) AND (looking = 'tous' OR looking = ?) ORDER BY RAND() LIMIT 20]], { id, id, me.looking, me.looking, me.gender }) or {}
    local out = {}
    for _, r in ipairs(rows) do
        out[#out + 1] = { key = r.identifier:sub(-8) .. ':' .. r.identifier:len(), ref = r.identifier, name = r.name, age = r.age, bio = r.bio, photos = Aura.Unjson(r.photos, {}) }
    end
    -- l'identifiant réel ne quitte jamais le serveur : on renvoie un jeton opaque
    local tokens = {}
    for i, o in ipairs(out) do tokens[#tokens + 1] = o.ref; o.token = i; o.ref = nil; o.key = nil end
    Aura._deck = Aura._deck or {}; Aura._deck[src] = tokens
    return out
end)

lib.callback.register('aura:matchSwipe', function(src, token, like)
    local id = Aura.ident[src]; if not id then return false end
    local tokens = Aura._deck and Aura._deck[src]
    local target = tokens and tokens[tonumber(token) or 0]
    if not target then return false end
    MySQL.query.await('INSERT INTO aura_swipes (identifier, target, liked, created) VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE liked = VALUES(liked)', { id, target, like and 1 or 0, Aura.Now() })
    if like then
        local mutual = MySQL.scalar.await('SELECT 1 FROM aura_swipes WHERE identifier = ? AND target = ? AND liked = 1', { target, id })
        if mutual then
            local mine, theirs = matchProfile(id), matchProfile(target)
            local p1, p2 = Aura.phones[id], Aura.phones[target]
            if p1 and p2 then
                Aura.EnsureDirectConv(p1.number, p2.number)
                Aura.Push(target, 'notify', { app = 'match', title = 'C\'est un match !', body = 'Vous avez matché avec ' .. (mine and mine.name or '?') })
                return { match = true, name = theirs and theirs.name, number = p2.number, photo = theirs and Aura.Unjson(theirs.photos, {})[1] }
            end
        end
    end
    return { match = false }
end)

lib.callback.register('aura:matchList', function(src)
    local id = Aura.ident[src]; if not id then return {} end
    local rows = MySQL.query.await([[SELECT m.identifier, m.name, m.age, m.bio, m.photos FROM aura_swipes a
        JOIN aura_swipes b ON b.identifier = a.target AND b.target = a.identifier AND b.liked = 1
        JOIN aura_match m ON m.identifier = a.target WHERE a.identifier = ? AND a.liked = 1 ORDER BY a.created DESC]], { id }) or {}
    local out = {}
    for _, r in ipairs(rows) do
        local p = Aura.phones[r.identifier]
        out[#out + 1] = { name = r.name, age = r.age, bio = r.bio, photos = Aura.Unjson(r.photos, {}), number = p and p.number }
    end
    return out
end)

-- ═════════════════ PHOTOS ═════════════════
lib.callback.register('aura:photos', function(src)
    local id = Aura.ident[src]; if not id then return {} end
    return MySQL.query.await('SELECT id, url, kind, favorite, created FROM aura_photos WHERE owner = ? ORDER BY id DESC LIMIT ?', { id, Config.Camera.maxPhotos }) or {}
end)

lib.callback.register('aura:photoAdd', function(src, url, kind)
    local id = Aura.ident[src]; if not id then return false end
    url = Aura.Clamp(url, 500)
    if not url:match('^https?://') then return false, 'Adresse invalide' end
    local n = MySQL.scalar.await('SELECT COUNT(*) FROM aura_photos WHERE owner = ?', { id }) or 0
    if n >= Config.Camera.maxPhotos then return false, 'Galerie pleine' end
    local pid = MySQL.insert.await('INSERT INTO aura_photos (owner, url, kind, created) VALUES (?,?,?,?)', { id, url, kind == 'video' and 'video' or 'photo', Aura.Now() })
    return { id = pid, url = url, kind = kind or 'photo', favorite = 0, created = Aura.Now() }
end)
Aura.AddPhoto = function(identifier, url)
    MySQL.insert.await('INSERT INTO aura_photos (owner, url, kind, created) VALUES (?,?, "photo", ?)', { identifier, url, Aura.Now() })
end

lib.callback.register('aura:photoDelete', function(src, ids)
    local id = Aura.ident[src]; if not id then return false end
    for _, pid in ipairs(type(ids) == 'table' and ids or { ids }) do MySQL.update.await('DELETE FROM aura_photos WHERE id = ? AND owner = ?', { tonumber(pid) or 0, id }) end
    return true
end)

lib.callback.register('aura:photoFav', function(src, pid, fav)
    local id = Aura.ident[src]; if not id then return false end
    MySQL.update.await('UPDATE aura_photos SET favorite = ? WHERE id = ? AND owner = ?', { fav and 1 or 0, tonumber(pid) or 0, id })
    return true
end)
