Config = {}

-- ═════════════════════════════ GÉNÉRAL ═════════════════════════════
Config.Key = 'TAB'                       -- maintiens la touche : la roue s'ouvre ; relâche pour utiliser l'élément survolé
Config.Tabs = { 'weapons', 'items', 'emotes', 'outfit', 'shortcuts' }   -- onglets affichés (retire-en pour les masquer)
Config.OpenMinMs = 120                   -- une pression plus courte que ça ferme la roue sans rien utiliser
Config.HideNativeWheel = true            -- masque la roue d'armes native de GTA

-- ═════════════════════════════ ARMES ═════════════════════════════
-- 8 emplacements autour du cercle (dans le sens des aiguilles d'une montre, le 1er en haut). `groups` = groupes d'armes GTA ; `names` = armes précises (prioritaires).
-- Plusieurs armes du même type : la molette de la souris change l'arme affichée (ex. 1/3).
Config.WeaponSlots = {
    { id = 'pistol',  label = 'Pistolet',          groups = { 416676503 } },
    { id = 'smg',     label = 'SMG',               groups = { 3337201093 } },
    { id = 'rifle',   label = 'Carabine',          groups = { 970310034, 1159398588 } },
    { id = 'sniper',  label = 'Fusil de précision', groups = { 3082541095 } },
    { id = 'shotgun', label = 'Fusil à pompe',     groups = { 860033945 } },
    { id = 'thrown',  label = 'Arme de jet',       groups = { 1548507267 }, names = { 'WEAPON_PETROLCAN' } },
    { id = 'melee',   label = 'Mêlée',             groups = { 2685387236 } },
    { id = 'tool',    label = 'Outil',             names = { 'WEAPON_FLASHLIGHT', 'WEAPON_HAMMER', 'WEAPON_WRENCH', 'WEAPON_FIREEXTINGUISHER', 'WEAPON_FLARE', 'WEAPON_STUNGUN', 'WEAPON_NIGHTSTICK' } },
}

-- ═════════════════════════════ OBJETS ═════════════════════════════
Config.Items = {
    Hide = { 'money', 'black_money' },   -- objets jamais proposés
    OnlyUsable = false,                  -- true = seulement les objets qui ont une action d'utilisation dans ox_inventory (client / consommable)
}

-- ═════════════════════════════ EMOTES ═════════════════════════════
-- command = commande de ton menu d'emotes (ex. 'e dance') ; sinon scenario = scénario GTA, ou dict + clip = animation.
Config.Emotes = {
    { label = 'Mains en l\'air', dict = 'random@mugging3', clip = 'handsup_standing_base', flag = 49 },
    { label = 'Applaudir',       scenario = 'WORLD_HUMAN_CHEERING' },
    { label = 'S\'asseoir',      scenario = 'PROP_HUMAN_SEAT_CHAIR' },
    { label = 'Fumer',           scenario = 'WORLD_HUMAN_SMOKING' },
    { label = 'Salut militaire', dict = 'anim@mp_player_intincarsalutestd@ds@', clip = 'idle_a', flag = 49 },
    { label = 'Croiser les bras', dict = 'anim@amb@nightclub@peds@', clip = 'rcmme_amanda1_stand_loop_cop', flag = 49 },
    { label = 'Pompes',          scenario = 'WORLD_HUMAN_PUSH_UPS' },
    { label = 'Arrêter',         stop = true },
}

-- ═════════════════════════════ TENUE ═════════════════════════════
-- type = 'prop' (accessoires) ou 'comp' (vêtements) ; id = indice GTA. « off » = valeur « rien » (homme / femme).
Config.Outfit = {
    { label = 'Chapeau',   type = 'prop', id = 0 },
    { label = 'Lunettes',  type = 'prop', id = 1 },
    { label = 'Oreilles',  type = 'prop', id = 2 },
    { label = 'Masque',    type = 'comp', id = 1, off = { 0, 0 } },
    { label = 'Haut',      type = 'comp', id = 11, off = { 15, 15 }, also = { { id = 3, off = { 15, 15 } }, { id = 8, off = { 15, 15 } } } },
    { label = 'Pantalon',  type = 'comp', id = 4, off = { 21, 15 } },
    { label = 'Chaussures', type = 'comp', id = 6, off = { 34, 35 } },
    { label = 'Montre',    type = 'prop', id = 6 },
}

-- ═════════════════════════════ RACCOURCIS ═════════════════════════════
-- type : 'command' (ExecuteCommand), 'event' (TriggerEvent client), 'export' (resource + fn), 'holster' (ranger l'arme), 'inventory'
Config.Shortcuts = {
    { label = 'Inventaire',      type = 'inventory' },
    { label = 'Ranger l\'arme',  type = 'holster' },
    { label = 'Niveau',          type = 'command', value = 'pickax_xp_ouvrir' },
    { label = 'Carnet',          type = 'command', value = 'carnet' },
    { label = 'Téléphone',       type = 'command', value = 'phone' },
    { label = 'Mes papiers',     type = 'command', value = 'papiers' },
    -- { label = 'Mon raccourci', type = 'event', value = 'monscript:event' },
    -- { label = 'Mon export',    type = 'export', resource = 'monscript', fn = 'Ouvrir' },
}
