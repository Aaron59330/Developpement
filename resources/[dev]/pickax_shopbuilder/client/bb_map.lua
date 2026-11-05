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
    local key = opts.category or ''
    local cat = BB.Categories[BB.Alias[key] or key] or BB.Categories.default
    local blip
    if opts.entity then
        blip = AddBlipForEntity(opts.entity)
    else
        blip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, (coords.z or 0.0) + 0.0)
    end
    -- Nom : un texte PARTAGÉ par tous les blips de même nom. GTA regroupe alors ces blips en UNE ligne de légende « Garage 1/2 » ;
    -- les flèches gauche/droite de la carte passent d'un point à l'autre. Le regroupement exige le même nom, le même sprite et la même couleur :
    -- le premier blip d'un nom fixe l'apparence du groupe, les suivants la reprennent (même si leurs réglages diffèrent).
    local name = tostring((b.label and b.label ~= '') and b.label or opts.label or 'Point')
    -- les numéros de fin (« Station essence 03 », « Armurerie #2 ») sont retirés : tous les blips du même lieu se regroupent
    do
        local base = name:gsub('%s+[nN]°%s*%d+%s*$', ''):gsub('%s+#?%d+%s*$', '')
        if base ~= '' then name = base end
    end
    -- les codes de couleur GTA (~p~, ~s~, ~h~…) ne doivent pas séparer deux blips de même nom : ils sont retirés du nom du blip
    name = name:gsub('~[%w_]+~', ''):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then name = 'Point' end
    -- clé de groupe insensible à la casse et aux espaces multiples (« Garage », « garage », « Garage  »)
    local norm = name:lower()
    local key = ('PKBLIP_%x'):format(GetHashKey(norm))
    BB._groups = BB._groups or {}
    local g = BB._groups[key]
    if not (g and DoesBlipExist(g.blip)) then
        g = { blip = blip, sprite = tonumber(b.sprite) or cat.sprite, color = tonumber(b.color) or (PickaxTheme and PickaxTheme.blipColor) or cat.color, short = b.shortRange ~= false }
        BB._groups[key] = g
    end
    g.blips = g.blips or {}
    g.blips[#g.blips + 1] = blip
    g.name = name
    SetBlipSprite(blip, g.sprite)
    SetBlipColour(blip, g.color)
    -- taille : identique pour TOUS les blips (Config.GlobalBlip.Scale du core, 0.5 par défaut)
    SetBlipScale(blip, ((PickaxTheme and PickaxTheme.blipScale) or 0.5) + 0.0)
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, g.short)
    if not BB._names then BB._names = {} end
    if not BB._names[key] then AddTextEntry(key, name) BB._names[key] = true end
    BeginTextCommandSetBlipName(key)
    EndTextCommandSetBlipName(blip)
    return blip
end

-- Diagnostic : liste les groupes de blips de cette ressource (nom, icône, couleur, nombre de blips vivants).
-- Commande : <ressource>_blips (ex. pickax_worldbuilder_blips) ; résultat dans la console F8. Deux blips de même nom doivent être dans le même groupe.
CreateThread(function()
    RegisterCommand(GetCurrentResourceName() .. '_blips', function()
        local n = 0
        print(('^3[%s] groupes de blips (même nom + même icône + même couleur = une seule ligne de légende « Nom 1/N »)^0'):format(GetCurrentResourceName()))
        for key, g in pairs(BB._groups or {}) do
            local alive = 0
            for _, b in ipairs(g.blips or {}) do if DoesBlipExist(b) then alive = alive + 1 end end
            if alive > 0 then n = n + 1 print(('  « %s » : %d blip(s), icône %s, couleur %s [%s]'):format(tostring(g.name), alive, tostring(g.sprite), tostring(g.color), key)) end
        end
        print(('^3%d groupe(s)^0'):format(n))
    end, false)
end)
