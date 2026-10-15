-- ─────────────────────────────── Création du personnage : tenues proposées ───────────────────────────────
-- Dans le menu de création, le joueur ne règle que son APPARENCE (visage, peau, cheveux, barbe, maquillage…).
-- Une fois l'apparence validée, il choisit l'un de ces styles de tenue (une version homme, une version femme).
-- Tu peux modifier, retirer ou ajouter des styles. Pour récupérer les valeurs d'une tenue : habille-toi (menu vêtements /
-- admin), puis tape /tenueinfo : la tenue actuelle s'affiche dans la console F8 (et le chat) au format de ce fichier.
-- ⚠ Les numéros ci-dessous sont des valeurs de départ : ajuste-les à ta guise avec /tenueinfo.
ConfigCreationOutfits = {
    Enabled = true,
    Title = 'Ta tenue',
    Hint = 'Choisis ton style',
    Styles = {
        {
            label = 'Décontracté', description = 'T-shirt, jean et baskets : simple et confortable.', icon = 'house',
            male = { tshirt_1 = 15, tshirt_2 = 0, torso_1 = 4,  torso_2 = 1, decals_1 = 0, decals_2 = 0, arms = 0,  pants_1 = 1,  pants_2 = 0, shoes_1 = 1,  shoes_2 = 0 },
            female = { tshirt_1 = 15, tshirt_2 = 0, torso_1 = 5,  torso_2 = 0, decals_1 = 0, decals_2 = 0, arms = 0,  pants_1 = 1,  pants_2 = 0, shoes_1 = 1,  shoes_2 = 0 },
        },
        {
            label = 'Classe', description = 'Chemise et pantalon habillé pour faire bonne impression.', icon = 'city',
            male = { tshirt_1 = 31, tshirt_2 = 0, torso_1 = 29, torso_2 = 0, decals_1 = 0, decals_2 = 0, arms = 1,  pants_1 = 10, pants_2 = 0, shoes_1 = 10, shoes_2 = 0 },
            female = { tshirt_1 = 38, tshirt_2 = 0, torso_1 = 25, torso_2 = 0, decals_1 = 0, decals_2 = 0, arms = 3,  pants_1 = 11, pants_2 = 0, shoes_1 = 13, shoes_2 = 0 },
        },
        {
            label = 'Streetwear', description = 'Sweat, pantalon large et sneakers : le look de la rue.', icon = 'pin',
            male = { tshirt_1 = 15, tshirt_2 = 0, torso_1 = 65, torso_2 = 0, decals_1 = 0, decals_2 = 0, arms = 0,  pants_1 = 5,  pants_2 = 0, shoes_1 = 12, shoes_2 = 0 },
            female = { tshirt_1 = 15, tshirt_2 = 0, torso_1 = 74, torso_2 = 0, decals_1 = 0, decals_2 = 0, arms = 0,  pants_1 = 7,  pants_2 = 0, shoes_1 = 5,  shoes_2 = 0 },
        },
    },
}
