Config = {}

-- ═════════════════════════════ GÉNÉRAL ═══════════════════════
Config.Key = 'C'          -- maintiens la touche : la roue s'ouvre ; relâche sur une case pour équiper l'arme
Config.OpenMinMs = 120           -- une pression plus courte que ça ferme la roue sans rien utiliser
Config.HideNativeWheel = true    -- masque la roue d'armes native de GTA
Config.ImageUrl = 'https://cfx-nui-ox_inventory/web/images/%s.png'   -- image d'une arme (%s = nom de l'objet)

-- ═════════════════════════════ APPARENCE ═════════════════════
Config.Colors = {
    aimed    = 'rgb(255, 170, 205)',   -- case visée (rose)
    equipped = 'rgb(64, 224, 208)',    -- arme en main (turquoise)
}

-- ═════════════════════════════ ARMES ═════════════════════════
-- 5 emplacements numérotés 1 à 5 (la case « mains nues » est fixe, en bas).
-- `groups` = groupes d'armes GTA ; `names` = armes précises (prioritaires). `category` = sous-titre affiché.
Config.WeaponSlots = {
    { category = 'Arme de poing',    groups = { 416676503 } },
    { category = 'Pistolet-mitrailleur', groups = { 3337201093 } },
    { category = 'Fusil',            groups = { 970310034, 1159398588, 3082541095, 860033945 } },
    { category = 'Corps à corps',    groups = { 2685387236 }, names = { 'WEAPON_KNIFE' } },
    { category = 'Équipement',       groups = { 1548507267 }, names = { 'WEAPON_FLASHLIGHT', 'WEAPON_STUNGUN', 'WEAPON_PETROLCAN' } },
}
