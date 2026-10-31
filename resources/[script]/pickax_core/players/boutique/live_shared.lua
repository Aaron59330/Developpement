-- Boutique à coins réglée depuis le panel web (document « boutique ») : remplace en mémoire les listes de config.lua.
-- Rien n'est modifié tant que le panel n'a rien enregistré : les valeurs de config.lua restent en vigueur.
local LISTS = { 'vehicle', 'Motos', 'Autres', 'weapon', 'caisse', 'pack', 'vip', 'Entreprise', 'boost' }
function BoutiqueApplyOverride(ov)
    if type(ov) ~= 'table' or type(ConfigBoutique) ~= 'table' then return end
    for _, k in ipairs(LISTS) do
        if type(ov[k]) == 'table' then ConfigBoutique[k] = ov[k] end
    end
    if type(ov.ESXCustom) == 'table' then ConfigBoutique.ESXCustom = ov.ESXCustom end
    if type(ov.chance) == 'table' then ConfigBoutique.chance = ov.chance end
    if type(ov.weaponCustom) == 'boolean' then ConfigBoutique.weaponCustom = ov.weaponCustom end
    if tonumber(ov.weaponCustomPrice) then ConfigBoutique.weaponCustomPrice = tonumber(ov.weaponCustomPrice) end
    if tonumber(ov.WeaponAmmoInWeapon) then ConfigBoutique.WeaponAmmoInWeapon = tonumber(ov.WeaponAmmoInWeapon) end
    if type(ov.LinkShop) == 'string' and ov.LinkShop ~= '' then ConfigBoutique.LinkShop = ov.LinkShop end
end
