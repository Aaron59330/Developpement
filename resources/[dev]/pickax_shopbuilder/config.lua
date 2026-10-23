Config = {}
-- Taille des blips par défaut : celle de tout le serveur (pickax_core/config.lua → Config.GlobalBlip.Scale), sinon la valeur donnée.
-- Un blip réglé en jeu dans un builder garde sa taille.
local function PK_BSF(default) return (PickaxTheme and PickaxTheme.blipScale) or default end

-- ─────────────────────────────── Général ───────────────────────────────
Config.AllowedGroups   = { '_dev', 'admin', 'superadmin' }   -- groupes ESX autorisés à ouvrir le builder
Config.AcePermission   = 'shopbuilder.admin'                 -- (optionnel) permission ACE alternative
Config.Command         = 'shopbuilder'                       -- /shopbuilder ouvre le builder

Config.DrawDistance     = 15.0   -- distance d'affichage des markers
Config.InteractDistance = 1.8    -- distance pour interagir (E)
Config.ServerDistance   = 12.0   -- tolérance côté serveur (anti-triche)
Config.PedDistance      = 60.0   -- distance d'apparition des vendeurs (PNJ)

Config.Inventory = 'auto'        -- 'auto' | 'ox' | 'esx'
Config.Target    = 'none'        -- 'none' (marker + touche E) | 'ox_target' (zone cliquable, en plus du marker)
-- Dialogue du vendeur (ressource pickax_dialog) : le PNJ écrit un message avec Accepter / Refuser avant d'ouvrir la boutique.
-- Activable pour tout le serveur ici, et boutique par boutique dans le builder (carte « Vendeur (PNJ) »).
Config.Dialog = {
    Enabled = true,
    Texts = {   -- texte par défaut selon le modèle de boutique (modifiable par boutique dans le builder)
        blackmarket = 'Psst… approche. Je vends de la marchandise qu\'on ne trouve pas en magasin. Ça t\'intéresse ?',
        default     = 'Bonjour, bienvenue ! Souhaitez-vous consulter ma boutique ?',
    },
}

Config.InteractKey = 38          -- E

Config.MaxShops          = 300
Config.MaxItemsPerShop   = 300
Config.MaxLocations      = 30
Config.MaxQtyPerPurchase = 100   -- plafond absolu par ligne du panier (modifiable par produit)
Config.MaxCartLines      = 40

Config.Currency = '$'
Config.ImagePath = 'nui://ox_inventory/web/images/%s.png'   -- image des produits ('%s' = nom de l'item) ; laisse '' pour désactiver
Config.DefaultWeaponAmmo = 42    -- (inventaire ESX classique) munitions données avec une arme achetée


-- Moyens de paiement proposables (compte ESX correspondant)
Config.Payments = {
    cash        = { label = 'Espèces',       account = 'money' },
    bank        = { label = 'Carte bancaire', account = 'bank' },
    black_money = { label = 'Argent sale',   account = 'black_money' },
}

-- ─────────────────────────────── Apparence des points ───────────────────────────────
-- Marker par défaut : celui de tout le serveur (pickax_core/config.lua → Config.GlobalMarker) ; réglable ensuite en jeu (prioritaire)
local PK_MK = PickaxTheme and PickaxTheme.marker
Config.Marker = PK_MK and { type = PK_MK.type, color = { PK_MK.color[1], PK_MK.color[2], PK_MK.color[3] }, alpha = PK_MK.alpha, scale = { x = PK_MK.scale.x, y = PK_MK.scale.y, z = PK_MK.scale.z }, offset = -0.95 }
    or { type = 25, color = { 64, 224, 208 }, alpha = 140, scale = { x = 0.9, y = 0.9, z = 0.6 }, offset = -0.95 }

Config.UI = { Accent = (PickaxTheme and PickaxTheme.rgb) or { 0, 164, 255 } }   -- couleur d'accentuation (modifiable en jeu : Paramètres → Apparence)

-- ─────────────────────────────── Vendeurs (PNJ) ───────────────────────────────
Config.PedScenarios = {
    { id = 'WORLD_HUMAN_STAND_IMPATIENT', label = 'Debout, patient' },
    { id = 'WORLD_HUMAN_CLIPBOARD',       label = 'Bloc-notes' },
    { id = 'WORLD_HUMAN_AA_COFFEE',       label = 'Café' },
    { id = 'WORLD_HUMAN_SMOKING',         label = 'Fume' },
    { id = 'WORLD_HUMAN_GUARD_STAND',     label = 'Garde' },
    { id = 'WORLD_HUMAN_HANG_OUT_STREET', label = 'Appuyé' },
    { id = '',                            label = 'Aucune animation' },
}

-- ─────────────────────────────── Vêtements / coiffeur ───────────────────────────────
-- Parties du corps modifiables dans une boutique de vêtements (clés esx_skin / skinchanger)
Config.ClothingParts = {
    top      = { label = 'Hauts',        keys = { 'tshirt_1', 'tshirt_2', 'torso_1', 'torso_2', 'decals_1', 'decals_2', 'arms', 'arms_2' } },
    pants    = { label = 'Pantalons',    keys = { 'pants_1', 'pants_2' } },
    shoes    = { label = 'Chaussures',   keys = { 'shoes_1', 'shoes_2' } },
    hat      = { label = 'Chapeaux',     keys = { 'helmet_1', 'helmet_2' } },
    glasses  = { label = 'Lunettes',     keys = { 'glasses_1', 'glasses_2' } },
    mask     = { label = 'Masques',      keys = { 'mask_1', 'mask_2' } },
    chain    = { label = 'Chaînes',      keys = { 'chain_1', 'chain_2' } },
    ears     = { label = 'Oreilles',     keys = { 'ears_1', 'ears_2' } },
    watches  = { label = 'Montres',      keys = { 'watches_1', 'watches_2' } },
    bracelets = { label = 'Bracelets',   keys = { 'bracelets_1', 'bracelets_2' } },
    bags     = { label = 'Sacs',         keys = { 'bags_1', 'bags_2' } },
    bproof   = { label = 'Gilets',       keys = { 'bproof_1', 'bproof_2' } },
    hair     = { label = 'Cheveux',      keys = { 'hair_1', 'hair_2', 'hair_color_1', 'hair_color_2' } },
    beard    = { label = 'Barbe',        keys = { 'beard_1', 'beard_2', 'beard_3', 'beard_4' } },
    makeup   = { label = 'Maquillage',   keys = { 'makeup_1', 'makeup_2', 'makeup_3', 'makeup_4', 'lipstick_1', 'lipstick_2', 'lipstick_3', 'lipstick_4', 'blush_1', 'blush_2', 'blush_3' } },
}

-- Vêtements en items (ox_inventory) : à l'achat d'une tenue, chaque pièce modifiée est remise au joueur sous forme d'item dont les
-- métadonnées contiennent le look (clés skinchanger). C'est le format du script « vetements » (clothes_tshirt, clothes_torso, ...) :
-- sans ça, retirer puis remettre un vêtement de l'inventaire rétablit l'ANCIEN look. Ajoute tes propres items (chapeau, lunettes…) ici.
--   mode 'p_itemclothes' : tes vêtements portés SONT les items des emplacements de tenue de l'inventaire. Après l'achat, le script
--                          demande à p_itemclothes de resynchroniser ces emplacements avec le nouveau skin (aucun item en double).
--   mode 'items'         : (inventaire ox classique) chaque pièce modifiée est remise en item avec métadonnées (groupes ci-dessous).
--   mode 'none'          : seulement le skin est enregistré.
--   mode 'outfit'        : l'achat donne un item « Tenue » (ressource p_outfits) contenant les 14 pièces ; le joueur le glisse sur la
--                          case Tenue de l'inventaire pour l'équiper. Le look d'avant l'achat est restauré dans la cabine.
--   mode 'auto'          : outfit si p_outfits démarré, sinon p_itemclothes si démarré, sinon 'items' (si enabled et ox_inventory), sinon 'none'.
Config.ClothingItems = {
    mode = 'auto',
    enabled = true,       -- utilisé par le mode 'items'       -- seulement si ox_inventory est utilisé ; false = la tenue n'est enregistrée que dans le skin
    groups = {
        { item = 'clothes_tshirt', keys = { 'tshirt_1', 'tshirt_2' } },
        { item = 'clothes_torso',  keys = { 'torso_1', 'torso_2', 'arms', 'arms_2', 'decals_1', 'decals_2' } },
        { item = 'clothes_pants',  keys = { 'pants_1', 'pants_2' } },
        { item = 'clothes_shoes',  keys = { 'shoes_1', 'shoes_2' } },
        -- { item = 'clothes_helmet',  keys = { 'helmet_1', 'helmet_2' } },
        -- { item = 'clothes_glasses', keys = { 'glasses_1', 'glasses_2' } },
    },
}

-- Parties « esthétiques » (coiffeur, barbier, maquillage) : jamais de tenue ni de vêtement en item, le skin est simplement modifié et enregistré.
local COSMETIC = {}
for _, id in ipairs({ 'hair', 'beard', 'makeup' }) do
    for _, k in ipairs((Config.ClothingParts[id] or {}).keys or {}) do COSMETIC[k] = true end
end
function Config.CosmeticOnly(restrict)
    if type(restrict) ~= 'table' or #restrict == 0 then return false end
    for _, k in ipairs(restrict) do if not COSMETIC[k] then return false end end
    return true
end

-- restrict (optionnel) : clés modifiables dans la boutique ; uniquement du coiffeur / barbe / maquillage → mode 'none' (pas de tenue)
function Config.ClothingMode(restrict)
    if Config.CosmeticOnly(restrict) then return 'none' end
    local ci = Config.ClothingItems
    if ci.mode ~= 'auto' then return ci.mode end
    if GetResourceState('p_outfits') == 'started' then return 'outfit' end
    if GetResourceState('p_itemclothes') == 'started' then return 'p_itemclothes' end
    if ci.enabled and GetResourceState('ox_inventory') == 'started' then return 'items' end
    return 'none'
end

-- ─────────────────────────────── Modèles de boutiques ───────────────────────────────
-- mode : 'items' (catalogue de produits) | 'clothing' (cabine d'essayage payante)
-- Les produits proposés par défaut ne sont ajoutés que s'ils existent dans ton inventaire (items ox_inventory / table items ESX).
-- Chaque type est entièrement modifiable ensuite en jeu.
Config.ShopTypes = {
    general = {
        label = 'Supérette', icon = 'cart', mode = 'items',
        blip = { sprite = 52, color = 2 }, ped = 'mp_m_shopkeep_01',
        categories = { 'Nourriture', 'Boissons', 'Divers' },
        items = {
            { 'bread', 'Pain', 1, 'Nourriture' }, { 'sandwich', 'Sandwich', 4, 'Nourriture' }, { 'burger', 'Burger', 9, 'Nourriture' },
            { 'chips', 'Chips', 2, 'Nourriture' }, { 'water', 'Eau', 1, 'Boissons' }, { 'cola', 'Cola', 2, 'Boissons' },
            { 'coffee', 'Café', 2, 'Boissons' }, { 'phone', 'Téléphone', 600, 'Divers' }, { 'radio', 'Radio', 60, 'Divers' },
        },
    },
    weapons = {
        label = 'Armurerie', icon = 'target', mode = 'items',
        blip = { sprite = 110, color = 1 }, ped = 's_m_y_ammucity_01',
        categories = { 'Armes de poing', 'Armes blanches', 'Munitions', 'Accessoires' },
        items = {
            { 'WEAPON_PISTOL', 'Pistolet', 700, 'Armes de poing', 'weapon' }, { 'WEAPON_COMBATPISTOL', 'Pistolet de combat', 900, 'Armes de poing', 'weapon' },
            { 'WEAPON_KNIFE', 'Couteau', 40, 'Armes blanches' }, { 'WEAPON_BAT', 'Batte', 35, 'Armes blanches' }, { 'WEAPON_FLASHLIGHT', 'Lampe torche', 20, 'Accessoires' },
            { 'ammo-9', 'Munitions 9mm', 1, 'Munitions', 'weapon' }, { 'armor', 'Gilet pare-balles', 500, 'Accessoires', 'weapon' },
        },
    },
    clothing = {
        label = 'Boutique de vêtements', icon = 'shirt', mode = 'clothing',
        blip = { sprite = 73, color = 47 }, ped = 's_f_y_shop_mid',
        clothing = { price = 90, parts = { 'top', 'pants', 'shoes', 'hat', 'glasses', 'mask', 'chain', 'ears', 'watches', 'bracelets', 'bags' } },
    },
    barber = {
        label = 'Coiffeur', icon = 'user', mode = 'clothing',
        blip = { sprite = 71, color = 0 }, ped = 's_f_m_fembarber',
        clothing = { price = 30, parts = { 'hair', 'beard', 'makeup' } },
    },
    pharmacy = {
        label = 'Pharmacie', icon = 'heart', mode = 'items',
        blip = { sprite = 51, color = 2 }, ped = 's_f_y_scrubs_01',
        categories = { 'Soins', 'Médicaments' },
        items = { { 'bandage', 'Bandage', 4, 'Soins' }, { 'medikit', 'Kit de soin', 40, 'Soins' }, { 'painkillers', 'Antidouleurs', 3, 'Médicaments' } },
    },
    bar = {
        label = 'Bar / Restaurant', icon = 'utensils', mode = 'items',
        blip = { sprite = 93, color = 5 }, ped = 's_m_y_barman_01',
        categories = { 'Boissons', 'Plats' },
        items = { { 'beer', 'Bière', 5, 'Boissons' }, { 'whisky', 'Whisky', 8, 'Boissons' }, { 'vodka', 'Vodka', 8, 'Boissons' }, { 'burger', 'Burger', 12, 'Plats' }, { 'pizza', 'Pizza', 12, 'Plats' } },
    },
    hardware = {
        label = 'Bricolage / Outils', icon = 'wrench', mode = 'items',
        blip = { sprite = 402, color = 17 }, ped = 's_m_y_construct_01',
        categories = { 'Outils', 'Divers' },
        items = { { 'repairkit', 'Kit de réparation', 120, 'Outils' }, { 'lockpick', 'Crochet', 40, 'Outils' }, { 'jerrycan', 'Jerrican', 30, 'Divers' }, { 'rope', 'Corde', 12, 'Divers' } },
    },
    electronics = {
        label = 'Électronique', icon = 'tablet', mode = 'items',
        blip = { sprite = 521, color = 3 }, ped = 'a_m_y_business_02',
        categories = { 'Appareils', 'Accessoires' },
        items = { { 'phone', 'Téléphone', 700, 'Appareils' }, { 'radio', 'Radio', 60, 'Appareils' }, { 'tablet', 'Tablette', 350, 'Appareils' }, { 'powerbank', 'Batterie externe', 25, 'Accessoires' } },
    },
    blackmarket = {
        label = 'Marché noir', icon = 'lock', mode = 'items',
        blip = nil, ped = 'g_m_m_chigoon_01',
        payments = { cash = false, bank = false, black_money = true },
        categories = { 'Illégal' },
        items = { { 'lockpick', 'Crochet', 80, 'Illégal' }, { 'WEAPON_SWITCHBLADE', 'Cran d\'arrêt', 250, 'Illégal' } },
    },
    custom = {
        label = 'Boutique personnalisée', icon = 'tag', mode = 'items',
        blip = { sprite = 52, color = 0 }, ped = 'mp_m_shopkeep_01',
        categories = { 'Général' },
        items = {},
    },
}

-- ─────────────────────────────── Hooks (adapter à ton serveur) ───────────────────────────────
-- ─────────────────────────────── Permis de port d'arme (réglage par boutique dans le Shop Builder) ───────────────────────────────
-- Boutique → Réglages → « Armes : permis obligatoire » : sans le permis, aucune arme à feu ni munition n'est accessible ; seules les armes de corps à corps (liste ci-dessous) restent en vente.
Config.WeaponLicense = 'weapon'   -- nom de la licence esx_license par défaut
Config.MeleeWeapons = {
    weapon_knife = true, weapon_nightstick = true, weapon_hammer = true, weapon_bat = true, weapon_golfclub = true, weapon_crowbar = true, weapon_bottle = true,
    weapon_dagger = true, weapon_hatchet = true, weapon_knuckle = true, weapon_machete = true, weapon_flashlight = true, weapon_switchblade = true,
    weapon_poolcue = true, weapon_wrench = true, weapon_battleaxe = true, weapon_stone_hatchet = true,
}
-- Vrai pour une arme à feu / munition (donc soumise au permis) ; faux pour le corps à corps et tout autre produit
function Config.NeedsWeaponLicense(name)
    name = tostring(name or ''):lower()
    if name:find('^ammo') then return true end
    return name:find('^weapon_') ~= nil and not Config.MeleeWeapons[name]
end

-- Vérifie une licence côté serveur (ex : 'weapon'). Système de licences : esx_license OU pickax_core (qui expose les mêmes événements esx_license:*).
-- Le joueur doit avoir la licence : événement esx_license:checkLicense, puis table user_licenses en secours. Sans licence → false (accès refusé).
if IsDuplicityVersion() then
    local cache = {}   -- [src:licence] = { v, at } : le système de licences peut ne jamais répondre pour un joueur sans licence
    Config.HasLicense = function(src, license)
        local k = src .. ':' .. tostring(license)
        local c = cache[k]
        if c and GetGameTimer() - c.at < 8000 then return c.v end
        local has = false
        if GetResourceState('esx_license') == 'started' or GetResourceState('pickax_core') == 'started' then
            local p = promise.new()
            local ok = pcall(TriggerEvent, 'esx_license:checkLicense', src, license, function(h) p:resolve(h == true) end)
            if not ok then p:resolve(false) end
            SetTimeout(400, function() p:resolve(false) end)
            has = Citizen.Await(p)
        end
        if not has then
            local x = ESX and ESX.GetPlayerFromId(src)
            if x then
                local ok, row = pcall(function() return MySQL.scalar.await('SELECT 1 FROM user_licenses WHERE type = ? AND owner = ? LIMIT 1', { license, x.identifier }) end)
                has = ok and row ~= nil
            end
        end
        cache[k] = { v = has, at = GetGameTimer() }
        return has
    end
end

if not IsDuplicityVersion() then
    -- Système de vêtements :
    --   'auto'                 → illenium-appearance / fivem-appearance si démarré, sinon la cabine intégrée (skinchanger)
    --   'skinchanger'          → cabine d'essayage intégrée au Shop Builder (utilise skinchanger + esx_skin:save, comme esx_skin)
    --   'esx_skin_menu'        → menu d'esx_skin (esx_skin:openRestrictedMenu)
    --   'illenium-appearance' / 'fivem-appearance'
    Config.SkinSystem = 'auto'

    function Config.GetSkinSystem()
        if Config.SkinSystem ~= 'auto' then return Config.SkinSystem end
        for _, r in ipairs({ 'illenium-appearance', 'fivem-appearance' }) do
            if GetResourceState(r) == 'started' then return r end
        end
        return 'skinchanger'
    end

    -- Traduit la liste de clés esx_skin autorisées en options illenium / fivem-appearance
    local function appearanceConfig(restrict)
        local has = {}
        for _, k in ipairs(restrict or {}) do has[(k:gsub('_%d+$', ''))] = true end
        local props = has.helmet or has.glasses or has.ears or has.watches or has.bracelets
        local comps = has.tshirt or has.torso or has.pants or has.shoes or has.mask or has.bags or has.bproof or has.chain or has.arms or has.decals
        local face = has.hair or has.beard or has.makeup or has.lipstick or has.blush
        return { ped = false, headBlend = false, faceFeatures = false, headOverlays = face and true or false, components = comps and true or false, props = props and true or false, tattoos = false }
    end

    local backup
    -- Menus externes (tout sauf la cabine intégrée). `restrict` = clés de vêtements modifiables. submit() / cancel() à appeler.
    Config.OpenClothingMenu = function(restrict, submit, cancel)
        local sys = Config.GetSkinSystem()
        if sys == 'illenium-appearance' or sys == 'fivem-appearance' then
            backup = exports[sys]:getPedAppearance(PlayerPedId())
            exports[sys]:startPlayerCustomization(function(appearance) if appearance then submit() else cancel() end end, appearanceConfig(restrict))
        elseif sys == 'esx_skin_menu' then
            TriggerEvent('esx_skin:openRestrictedMenu', function() submit() end, function() cancel() end, restrict)
        else
            ESX.ShowNotification('~r~Système de vêtements inconnu : voir Config.SkinSystem.')
            cancel()
        end
    end

    -- Enregistre la tenue achetée (après paiement réussi)
    Config.SaveSkin = function()
        local sys = Config.GetSkinSystem()
        if sys == 'illenium-appearance' then
            TriggerServerEvent('illenium-appearance:server:saveAppearance', exports[sys]:getPedAppearance(PlayerPedId()))
        elseif sys == 'fivem-appearance' then
            TriggerServerEvent('fivem-appearance:save', exports[sys]:getPedAppearance(PlayerPedId()))
        else
            TriggerEvent('skinchanger:getSkin', function(skin) TriggerServerEvent('esx_skin:save', skin) end)
        end
    end

    -- Restaure la tenue d'avant (menus externes : annulation / paiement refusé)
    Config.RestoreSkin = function()
        local sys = Config.GetSkinSystem()
        if (sys == 'illenium-appearance' or sys == 'fivem-appearance') and backup then
            exports[sys]:setPlayerAppearance(backup)
        else
            ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin) TriggerEvent('skinchanger:loadSkin', skin) end)
        end
    end
end

-- ═══════════════════════════════ Réglages modifiables en jeu ═══════════════════════════════
-- Les valeurs ci-dessus sont les DÉFAUTS. L'apparence (couleur) se modifie en jeu via /shopbuilder → Paramètres.


-- ─────────────────────────────── Supérettes de GTA V (import en un clic) ───────────────────────────────
-- Builder → « Nouvelle boutique » → « Importer les supérettes GTA » : crée 3 boutiques (24/7, LTD Gasoline, Rob's Liquor)
-- avec tous leurs emplacements déjà placés (marker + blip), activées. Coordonnées = position du joueur au comptoir.
-- Les vendeurs (PNJ) sont désactivés par défaut : active-les et place-les depuis chaque boutique si tu veux.
-- { nom du lieu, x, y, z, cap }
Config.Superettes = {
    { id = '247', label = '24/7', type = 'general', blip = { sprite = 52, color = 2 }, locations = {
        { 'Strawberry', 24.47, -1346.62, 29.5, 271.66 }, { 'Banham Canyon', -3039.54, 584.38, 7.91, 17.27 }, { 'Chumash', -3242.97, 1000.01, 12.83, 357.57 },
        { 'Paleto Bay', 1728.07, 6415.63, 35.04, 242.95 }, { 'Sandy Shores', 1959.82, 3740.48, 32.34, 301.57 }, { 'Harmony', 549.13, 2670.85, 42.16, 99.39 },
        { 'Grand Senora', 2677.47, 3279.76, 55.24, 335.08 }, { 'Tataviam', 2556.66, 380.84, 108.62, 356.67 }, { 'Vinewood', 372.66, 326.98, 103.57, 253.73 },
    } },
    { id = 'ltd', label = 'LTD Gasoline', type = 'general', blip = { sprite = 361, color = 1, label = 'Station essence' }, locations = {
        { 'Davis', -47.02, -1758.23, 29.42, 45.05 }, { 'Little Seoul', -706.06, -913.97, 19.22, 88.04 }, { 'Richman Glen', -1820.02, 794.03, 138.09, 135.45 },
        { 'Mirror Park', 1164.71, -322.94, 69.21, 101.72 }, { 'Grapeseed', 1697.87, 4922.96, 42.06, 324.71 },
    } },
    { id = 'liquor', label = "Rob's Liquor", type = 'bar', blip = { sprite = 93, color = 5 }, locations = {
        { 'Del Perro', -1221.58, -908.15, 12.33, 35.49 }, { 'Morningwood', -1486.59, -377.68, 40.16, 139.51 }, { 'Pacific Bluffs', -2966.39, 391.42, 15.04, 87.48 },
        { 'Grand Senora', 1165.17, 2710.88, 38.16, 179.43 }, { 'Murrieta Heights', 1134.2, -982.91, 46.42, 277.24 },
    } },
}

-- ─────────────────────────────── Pré-placement : toutes les boutiques déjà sur la carte ───────────────────────────────
-- Au premier démarrage, les supérettes (ci-dessus) et les boutiques ci-dessous sont créées, placées (blip + marker) et activées
-- automatiquement, UNE seule fois (si tu en supprimes une, elle ne revient pas). Tout reste modifiable dans le builder.
-- /sbseed (groupe admin) recrée celles qui manquent. Mets Config.AutoSeed = false pour tout désactiver.
Config.AutoSeed = false   -- false = aucune boutique créée toute seule ; /sbseed (admin) les crée à la demande
Config.PresetShops = {
    { id = 'ammu', label = 'Ammu-Nation', type = 'weapons', blip = { sprite = 110, color = 1 }, locations = {
        { 'Little Seoul', -661.96, -933.53, 21.83, 177.05 }, { 'Cypress Flats', 809.68, -2159.13, 29.62, 1.43 }, { 'Sandy Shores', 1692.67, 3761.38, 34.71, 227.65 },
        { 'Paleto Bay', -331.23, 6085.37, 31.45, 228.02 }, { 'Hawick', 253.63, -51.02, 69.94, 72.91 }, { 'Pillbox Hill', 23.00, -1105.67, 29.80, 162.91 },
        { 'Tataviam', 2567.48, 292.59, 108.73, 349.68 }, { 'Route 68', -1118.59, 2700.05, 18.55, 221.89 }, { 'La Mesa', 841.92, -1035.32, 28.19, 1.56 },
        { 'Morningwood', -1304.19, -395.12, 36.70, 75.03 }, { 'Chumash', -3173.31, 1088.85, 20.84, 244.18 },
    } },
    { id = 'clothes', label = 'Magasin de vêtements', type = 'clothing', blip = { sprite = 73, color = 47 }, locations = {
        { 'Grapeseed', 1693.32, 4823.48, 42.06 }, { 'Hawick', -712.22, -155.35, 38.42 }, { 'Vespucci', -1192.94, -772.69, 18.33 }, { 'Downtown Vinewood', 425.24, -806.01, 29.49 },
        { 'Rockford Hills', -162.66, -303.40, 39.73 }, { 'Davis', 75.95, -1392.89, 29.38 }, { 'Del Perro', -822.19, -1074.13, 11.33 }, { 'Morningwood', -1450.71, -236.83, 49.81 },
        { 'Paleto Bay', 4.25, 6512.81, 31.88 }, { 'Harmony', 615.18, 2762.93, 42.09 }, { 'Grand Senora', 1196.79, 2709.56, 38.22 }, { 'Chumash', -3171.45, 1043.86, 20.86 },
        { 'Route 68', -1100.96, 2710.21, 19.11 }, { 'Vespucci Canals', -1207.65, -1456.88, 5.38 }, { 'Hawick Ouest', 121.76, -224.60, 54.56 },
    } },
    { id = 'barber', label = 'Coiffeur', type = 'barber', blip = { sprite = 71, color = 0 }, locations = {
        { 'Hawick', -814.30, -183.80, 37.60 }, { 'Davis', 136.80, -1708.40, 29.30 }, { 'Vespucci', -1282.60, -1116.80, 7.00 }, { 'Sandy Shores', 1931.50, 3729.70, 32.80 },
        { 'Mirror Park', 1212.80, -472.90, 66.20 }, { 'Rockford Hills', -32.90, -152.30, 57.10 }, { 'Paleto Bay', -278.10, 6228.50, 31.70 },
    } },
    { id = 'hardware', label = 'Quincaillerie', type = 'hardware', blip = { sprite = 402, color = 17 }, locations = {
        { 'Strawberry', 45.68, -1749.04, 29.61, 53.13 }, { 'Grand Senora', 2747.71, 3472.85, 55.67, 255.08 }, { 'Paleto Bay', -421.83, 6136.13, 31.88, 228.20 },
    } },
}
