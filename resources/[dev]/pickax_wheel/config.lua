Config = {}

-- ═════════════════════════════ GÉNÉRAL ═══════════════════════
Config.Key = 'CAPSLOCK'          -- maintiens la touche : la roue s'ouvre ; relâche sur une arme pour la sortir
Config.OpenMinMs = 120           -- une pression plus courte que ça ferme la roue sans rien utiliser
Config.HideNativeWheel = true    -- masque la roue d'armes native de GTA

-- ═════════════════════════════ APPARENCE ═════════════════════
Config.Colors = {
    hover    = '#19d6c8',        -- arc + halo de l'emplacement survolé (turquoise)
    equipped = '#ff4d8d',        -- arc + halo de l'arme en main (rose)
    glass    = 'rgba(255,255,255,.11)',
    border   = 'rgba(255,255,255,.38)',
    text     = '#f4f5f7',
    muted    = '#9a9da5',
}
Config.Unarmed = { label = 'MAINS NUES', sub = 'CORPS À CORPS', icon = 'WEAPON_UNARMED' }   -- emplacement « poings »

-- ═════════════════════════════ ARMES ═════════════════════════
-- 6 emplacements autour du cercle (mains nues en bas, puis 1 à 5 dans le sens horaire en partant du bas gauche). `unarmed = true` = les poings.
-- `groups` = groupes d'armes GTA ; `names` = armes précises (prioritaires). Plusieurs armes du même type : la molette change l'arme affichée.
Config.WeaponSlots = {
    { id = 'unarmed', unarmed = true },
    { id = 'pistol',  label = 'Pistolet',      groups = { 416676503 } },
    { id = 'smg',     label = 'SMG',           groups = { 3337201093 } },
    { id = 'rifle',   label = 'Fusil d\'assaut', groups = { 970310034, 1159398588, 3082541095 } },
    { id = 'shotgun', label = 'Fusil à pompe', groups = { 860033945 } },
    { id = 'melee',   label = 'Mêlée & jet',   groups = { 2685387236, 1548507267 }, names = { 'WEAPON_FLASHLIGHT', 'WEAPON_STUNGUN', 'WEAPON_PETROLCAN' } },
}
