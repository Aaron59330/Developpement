-- bb_map : système commun de blips et de markers des 4 builders (jobs, gangs, boutiques, monde).
-- Un seul code pour tous : mêmes champs, mêmes valeurs par défaut, même rendu.
-- Fichier identique dans chaque builder (client/bb_map.lua) — modifie-le dans builderhub puis recopie-le.
BB = BB or {}

-- Style par défaut de chaque catégorie : une même catégorie a le même blip dans tous les builders.
-- (utilisé uniquement quand le module / le point ne définit pas lui-même le champ)
BB.Categories = {
    garage      = { sprite = 357, color = 3,  scale = 0.5 },
    impound     = { sprite = 68,  color = 47, scale = 0.5 },
    rental      = { sprite = 225, color = 5,  scale = 0.5 },
    dealer      = { sprite = 225, color = 3,  scale = 0.5 },
    fuel        = { sprite = 361, color = 1,  scale = 0.5 },
    carwash     = { sprite = 100, color = 3,  scale = 0.5 },
    bank        = { sprite = 108, color = 2,  scale = 0.5 },
    atm         = { sprite = 277, color = 2,  scale = 0.5 },
    shop        = { sprite = 52,  color = 2,  scale = 0.5 },
    pharmacy    = { sprite = 51,  color = 2,  scale = 0.5 },
    weapons     = { sprite = 110, color = 1,  scale = 0.5 },
    hardware    = { sprite = 402, color = 17, scale = 0.5 },
    clothing    = { sprite = 73,  color = 47, scale = 0.5 },
    barber      = { sprite = 71,  color = 0,  scale = 0.5 },
    bar         = { sprite = 93,  color = 5,  scale = 0.5 },
    electronics = { sprite = 521, color = 3,  scale = 0.5 },
    police      = { sprite = 60,  color = 29, scale = 0.5 },
    ems         = { sprite = 61,  color = 1,  scale = 0.5 },
    mecano      = { sprite = 446, color = 5,  scale = 0.5 },
    taxi        = { sprite = 198, color = 5,  scale = 0.5 },
    realestate  = { sprite = 374, color = 2,  scale = 0.5 },
    government  = { sprite = 419, color = 5,  scale = 0.5 },
    school      = { sprite = 225, color = 3,  scale = 0.5 },
    locksmith   = { sprite = 402, color = 5,  scale = 0.5 },
    robbery     = { sprite = 52,  color = 1,  scale = 0.5 },
    drug        = { sprite = 140, color = 2,  scale = 0.5 },
    pvp         = { sprite = 311, color = 1,  scale = 0.5 },
    chase       = { sprite = 315, color = 3,  scale = 0.5 },
    gang        = { sprite = 310, color = 1,  scale = 0.5 },
    default     = { sprite = 1,   color = 0,  scale = 0.5 },
}

-- Noms de types propres à un builder -> catégorie commune
BB.Alias = { driving = 'school', carlot = 'dealer', general = 'shop', custom = 'default', blackmarket = 'default', station = 'fuel',
    cars = 'rental', lot = 'dealer', doorlock = 'default', garage_bike = 'garage', garage_boat = 'garage', garage_aircraft = 'garage' }

-- Marker par défaut commun (peut être remplacé par Config.Marker du builder, éditable en jeu)
-- Défaut = marker de tout le serveur (pickax_core/config.lua → Config.GlobalMarker, lu via PickaxTheme) ; sinon valeurs ci-dessous.
-- Ce que l'admin règle EN JEU dans un builder (module / point) reste prioritaire : voir BB.Style.
local GM = PickaxTheme and PickaxTheme.marker
BB.Marker = { marker = GM and GM.type or 23, color = GM and { GM.color[1], GM.color[2], GM.color[3] } or { 253, 194, 125 }, alpha = GM and GM.alpha or 150,
    scale = GM and { x = GM.scale.x, y = GM.scale.y, z = GM.scale.z } or { x = 1.0, y = 1.0, z = 0.5 }, offset = -0.95, bob = false, rotate = false, help = true }

local function cleanColor(c)
    if type(c) == 'table' and tonumber(c[1]) and tonumber(c[2]) and tonumber(c[3]) then return c end
end

-- Fusionne des couches de style : la dernière renseignée gagne (global → catégorie → module → point)
-- Accepte `marker` ou `type` pour le numéro de forme.
function BB.Style(...)
    local out = {}
    for k, v in pairs(BB.Marker) do out[k] = v end
    for _, layer in ipairs({ ... }) do
        if type(layer) == 'table' then
            local shape = tonumber(layer.marker) or tonumber(layer.type)
            if shape then out.marker = math.floor(shape) end
            if cleanColor(layer.color) then out.color = layer.color end
            if tonumber(layer.alpha) then out.alpha = math.floor(tonumber(layer.alpha)) end
            if type(layer.scale) == 'table' then
                local s = {}
                for k, def in pairs({ x = 0.9, y = 0.9, z = 0.6 }) do s[k] = tonumber((out.scale or {})[k]) or def end
                for k in pairs(s) do if tonumber(layer.scale[k]) then s[k] = tonumber(layer.scale[k]) end end
                out.scale = s
            end
            if tonumber(layer.offset) then out.offset = tonumber(layer.offset) end
            if layer.bob ~= nil then out.bob = layer.bob == true end
            if layer.rotate ~= nil then out.rotate = layer.rotate == true end
            if layer.help ~= nil then out.help = layer.help ~= false end
        end
    end
    return out
end

-- Aide « Appuie sur E » du marker : activable / désactivable par marker (réglage admin dans les builders, vrai par défaut)
function BB.HelpEnabled(...)
    return BB.Style(...).help ~= false
end

-- Affiche l'aide de la touche E seulement si elle est activée pour ce marker (le style suit les mêmes couches que BB.Style)
function BB.ShowHelp(msg, ...)
    if BB.HelpEnabled(...) then ESX.ShowHelpNotification(msg) end
end

-- Dessine un marker avec un style (voir BB.Style). `color` force la couleur (ex : couleur d'un gang / d'un module).
function BB.DrawMarker(style, c, color)
    local s = BB.Style(style)
    local sc, col = s.scale, cleanColor(color) or s.color
    DrawMarker(s.marker, c.x + 0.0, c.y + 0.0, c.z + s.offset, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        sc.x + 0.0, sc.y + 0.0, sc.z + 0.0, col[1], col[2], col[3], s.alpha, s.bob == true, true, 2, s.rotate == true, nil, nil, false)
end

-- Aperçu d'un marker devant le joueur (bouton « Aperçu en jeu » de l'éditeur)
function BB.Preview(def, seconds)
    if type(def) ~= 'table' then return end
    local c = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 3.0, 0.0)
    local untilT = GetGameTimer() + (seconds or 8) * 1000
    CreateThread(function()
        while GetGameTimer() < untilT do
            BB.DrawMarker(def, c)
            Wait(0)
        end
    end)
end

-- Crée un blip. `b` = { sprite, color, scale, shortRange, label } ; `opts` = { label = nom par défaut, category = clé de BB.Categories, entity = entité }
-- Règles identiques partout : affichage 4, visible à proximité seulement par défaut, nom par défaut = nom du module.
function BB.Blip(coords, b, opts)
    b, opts = b or {}, opts or {}
    -- pendant un lot (BB.BlipsBegin … BB.BlipsEnd) : on mémorise ; les lieux de même nom seront regroupés en UN seul blip
    if BB._batch and not opts.entity then BB._batch[#BB._batch + 1] = { coords = coords, b = b, opts = opts } return nil end
    return BB.BlipNow(coords, b, opts)
end

function BB.BlipNow(coords, b, opts)
    b, opts = b or {}, opts or {}
    local key = opts.category or ''
    local cat = BB.Categories[BB.Alias[key] or key] or BB.Categories.default
    local blip
    if opts.entity then
        blip = AddBlipForEntity(opts.entity)
    else
        blip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, (coords.z or 0.0) + 0.0)
    end
    SetBlipSprite(blip, tonumber(b.sprite) or cat.sprite)
    -- icône / couleur : réglage du point (en jeu) → global (Config.GlobalBlip.Color) → défaut de la catégorie
    SetBlipColour(blip, tonumber(b.color) or (PickaxTheme and PickaxTheme.blipColor) or cat.color)
    -- taille : identique pour TOUS les blips (Config.GlobalBlip.Scale du core, 0.5 par défaut)
    SetBlipScale(blip, ((PickaxTheme and PickaxTheme.blipScale) or 0.5) + 0.0)
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, b.shortRange ~= false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(tostring((b.label and b.label ~= '') and b.label or opts.label or 'Point'))
    EndTextCommandSetBlipName(blip)
    return blip
end


-- ─── Regroupement des blips de même nom ───
-- BB.BlipsBegin() puis des BB.Blip(...) puis BB.BlipsEnd() : renvoie les blips créés. Des lieux portant EXACTEMENT le même nom donnent un seul blip « Nom (N) »
-- placé sur le lieu le plus proche du joueur ; la liste des lieux est donnée à pickax_mapgroups (sélection sur la carte avec un point de passage).
function BB.BlipsBegin() BB._batch = {} end

function BB.BlipsEnd()
    local list = BB._batch or {}
    BB._batch = nil
    local byName, order, handles, groups = {}, {}, {}, {}
    for _, e in ipairs(list) do
        local name = tostring((e.b.label and e.b.label ~= '') and e.b.label or e.opts.label or 'Point')
        local g = byName[name]
        if not g then g = { name = name, items = {} } byName[name] = g order[#order + 1] = g end
        g.items[#g.items + 1] = e
    end
    for _, g in ipairs(order) do
        local first = g.items[1]
        if #g.items == 1 then
            handles[#handles + 1] = BB.BlipNow(first.coords, first.b, first.opts)
        else
            local b = {}
            for k, v in pairs(first.b) do b[k] = v end
            b.label = ('%s (%d)'):format(g.name, #g.items)
            local h = BB.BlipNow(first.coords, b, first.opts)
            handles[#handles + 1] = h
            local members = {}
            for _, e in ipairs(g.items) do members[#members + 1] = { x = e.coords.x + 0.0, y = e.coords.y + 0.0, z = (e.coords.z or 0.0) + 0.0 } end
            groups[#groups + 1] = { blip = h, name = g.name, members = members }
        end
    end
    BB._groups = groups
    if GetResourceState('pickax_mapgroups') == 'started' then pcall(function() exports.pickax_mapgroups:SetGroups(GetCurrentResourceName(), groups) end) end
    return handles
end

-- pickax_mapgroups démarré après nous : on lui renvoie nos groupes
AddEventHandler('pickax_mapgroups:ready', function()
    if BB._groups then pcall(function() exports.pickax_mapgroups:SetGroups(GetCurrentResourceName(), BB._groups) end) end
end)
