-- Conversion des 103 items SQL. Hypothèse : poids SQL en kg, poids ox_inventory en g.
-- rare et can_remove ne sont pas des champs standards ox_inventory.
-- pepperspray : can_remove = -1 dans le SQL ; aucune restriction de transfert ajoutée.
-- zetony : poids SQL -1 remplacé par 0.
-- Définitions seules : relier les utilisations et effets aux scripts du serveur.
return {
    -- Sacs (voir data/config_sacs.lua) : clic droit → Ouvrir le sac ; le contenu suit le sac
    ['portefeuille'] = { bag = true, openLabel = 'Ouvrir le portefeuille', label = 'Portefeuille', weight = 100, stack = false, close = false, consume = 0, description = "Range tes papiers : carte d'identité, permis de conduire, permis de port d'arme. Si tu le donnes, ses papiers partent avec." },
    ['sac_petit'] = { bag = true, label = 'Sacoche', weight = 300, stack = false, close = false, consume = 0, description = 'Un petit sac avec son propre rangement. Si tu le donnes, son contenu part avec.' },
    ['sac_moyen'] = { bag = true, label = 'Sac bandoulière', weight = 500, stack = false, close = false, consume = 0, description = 'Un sac avec son propre rangement. Si tu le donnes, son contenu part avec.' },
    ['sac_a_dos'] = { bag = true, label = 'Sac à dos', weight = 800, stack = false, close = false, consume = 0, description = 'Un grand sac avec son propre rangement. Si tu le donnes, son contenu part avec.' },
    ['sac_sport'] = { bag = true, label = 'Sac de sport', weight = 1000, stack = false, close = false, consume = 0, description = 'Un très grand sac avec son propre rangement. Si tu le donnes, son contenu part avec.' },

    ['money'] = { label = 'Argent', weight = 0, stack = true, close = false },
    ['black_money'] = { label = 'Argent sale', weight = 0, stack = true, close = false },
    ['armor'] = { label = 'Kevlar', weight = 3000, stack = true, close = true },
    ['bandage'] = { label = 'Bandage', weight = 200, stack = true, close = true },
    ['basic_cuff'] = { label = 'Menottes Basique', weight = 300, stack = true, close = true },
    ['basic_key'] = { label = 'Clefs de Menottes Basique', weight = 100, stack = true, close = true },
    ['beer'] = { label = 'Bière', weight = 100, stack = true, close = true },
    ['blowpipe'] = { label = 'Chalumeaux', weight = 1500, stack = true, close = true },
    ['bread'] = { label = 'Pain', weight = 100, stack = true, close = true },
    ['burger'] = { label = 'Burger', weight = 300, stack = true, close = true },
    ['carokit'] = { label = 'Kit carosserie', weight = 3000, stack = true, close = true },
    ['carotool'] = { label = 'Outils carosserie', weight = 4000, stack = true, close = true },
    ['chip'] = { label = 'Jeton', weight = 0, stack = true, close = true },
    ['cigarette'] = { label = 'Cigarette', weight = 100, stack = true, close = true },
    ['clip'] = { label = 'Chargeur', weight = 300, stack = true, close = true },
    ['coca'] = { label = 'Coca', weight = 100, stack = true, close = true },
    ['coke'] = { label = 'Coke', weight = 1000, stack = true, close = true },
    ['coke_pooch'] = { label = 'Pochon de coke', weight = 250, stack = true, close = true },
    ['cola'] = { label = 'Cola', weight = 200, stack = true, close = true },
    ['corde'] = { label = 'Corde', weight = 2000, stack = true, close = true },
    ['defibrillateur'] = { label = 'Défibrillateur', weight = 2000, stack = true, close = true },
    ['feuille_coca'] = { label = 'Feuille de coca', weight = 1000, stack = true, close = true },
    ['firstaidkit'] = { label = 'Trousse premier secours', weight = 1000, stack = true, close = true },
    ['fixkit'] = { label = 'Kit réparation', weight = 1500, stack = true, close = true },
    ['fixtool'] = { label = 'Outils réparation', weight = 2000, stack = true, close = true },
    ['gazbottle'] = { label = 'Bouteille de gaz', weight = 2000, stack = true, close = true },
    ['gitanes'] = { label = 'Gitanes', weight = 100, stack = true, close = true },
    ['grand_cru'] = { label = 'Grand cru', weight = 200, stack = true, close = true },
    ['grapperaisin'] = { label = 'Grappe de raisin', weight = 300, stack = true, close = true },
    ['handcuff'] = { label = 'Serre câble ', weight = 300, stack = true, close = true },
    ['ice'] = { label = 'Glaçon', weight = 100, stack = true, close = true },
    ['jager'] = { label = 'Jägermeister', weight = 500, stack = true, close = true },
    ['jagerbomb'] = { label = 'Jägermeister', weight = 500, stack = true, close = true },
    ['jagercerbere'] = { label = 'Jäger Cerbère', weight = 500, stack = true, close = true },
    ['jumelles'] = { label = 'Jumelles', weight = 250, stack = true, close = true },
    ['yusuf'] = { label = 'Skin de Luxe', weight = 4000, stack = true, close = true },
    ['grip'] = { label = 'Poignée', weight = 1000, stack = true, close = true },
    ['magazine'] = { label = 'Chargeur agrandi', weight = 2000, stack = true, close = true },
    ['silencieux'] = { label = 'Silencieux', weight = 1000, stack = true, close = true },
    ['flashlight'] = { label = 'Lampe', weight = 1000, stack = true, close = true },
    ['scope'] = { label = 'Viseur', weight = 1000, stack = true, close = true },
    ['jus_coca'] = { label = 'Jus de coca', weight = 500, stack = true, close = true },
    ['jus_raisin'] = { label = 'Jus de raisin', weight = 500, stack = true, close = true },
    ['jusfruit'] = { label = 'Jus de fruits', weight = 500, stack = true, close = true },
    ['limonade'] = { label = 'Limonade', weight = 500, stack = true, close = true },
    ['evidence_casing'] = { label = 'Douille (scellé)', weight = 10, stack = false, close = true, description = 'Pièce à conviction : à analyser au laboratoire de police.' },
    ['evidence_blood'] = { label = 'Prélèvement de sang (scellé)', weight = 10, stack = false, close = true, description = 'Pièce à conviction : à analyser au laboratoire de police.' },
    ['evidence_print'] = { label = 'Empreinte relevée (scellé)', weight = 10, stack = false, close = true, description = 'Pièce à conviction : à analyser au laboratoire de police.' },
    ['cleaning_kit'] = { label = 'Kit de nettoyage', weight = 800, stack = true, close = true, consume = 0, client = { event = 'pickax_forensics:useCleaning' }, description = 'Efface sang, douilles et empreintes à proximité.' },
    ['gsr_wipes'] = { label = 'Lingettes nettoyantes', weight = 100, stack = true, close = true, consume = 0, client = { event = 'pickax_forensics:useWipes' }, description = 'Retire les résidus de tir des mains.' },
    ['latex_gloves'] = { label = 'Gants en latex', weight = 50, stack = true, close = true, description = 'Aucune empreinte laissée sur les véhicules tant qu\'ils sont dans ton inventaire.' },
    ['engine_block'] = { label = 'Bloc moteur', weight = 12000, stack = true, close = true },
    ['spark_plugs'] = { label = 'Bougies d\'allumage', weight = 100, stack = true, close = true },
    ['engine_oil'] = { label = 'Huile moteur', weight = 900, stack = true, close = true },
    ['oil_filter'] = { label = 'Filtre à huile', weight = 300, stack = true, close = true },
    ['gearbox_kit'] = { label = 'Kit de boîte de vitesses', weight = 9000, stack = true, close = true },
    ['brake_pads'] = { label = 'Plaquettes de frein', weight = 800, stack = true, close = true },
    ['brake_fluid'] = { label = 'Liquide de frein', weight = 500, stack = true, close = true },
    ['tyre_set'] = { label = 'Jeu de pneus', weight = 8000, stack = true, close = true },
    ['suspension_kit'] = { label = 'Kit de suspension', weight = 6000, stack = true, close = true },
    ['body_panel'] = { label = 'Panneau de carrosserie', weight = 3000, stack = true, close = true },
    ['welding_wire'] = { label = 'Fil à souder', weight = 400, stack = true, close = true },
    ['toolbox'] = { label = 'Caisse à outils', weight = 4000, stack = true, close = true },
    ['suture_kit'] = { label = 'Kit de suture', weight = 150, stack = true, close = true },
    ['splint'] = { label = 'Attelle', weight = 200, stack = true, close = true },
    ['surgery_kit'] = { label = 'Kit de chirurgie', weight = 500, stack = true, close = true },
    ['blood_bag'] = { label = 'Poche de sang', weight = 250, stack = true, close = true },
    ['defibrillator'] = { label = 'Défibrillateur', weight = 1500, stack = true, close = true },
    ['hacking_laptop'] = { label = 'Ordinateur de piratage', weight = 2000, stack = true, close = true },
    ['usb_stick'] = { label = 'Clé USB chiffrée', weight = 20, stack = true, close = true },
    ['blank_card'] = { label = 'Carte vierge', weight = 10, stack = true, close = true },
    ['forgery_ink'] = { label = 'Encre de contrefaçon', weight = 50, stack = true, close = true },
    ['fake_id'] = { label = 'Faux papiers', weight = 10, stack = true, close = true },
    ['chop_tools'] = { label = 'Outils de désossage', weight = 3000, stack = true, close = true },
    ['stolen_door'] = { label = 'Portière volée', weight = 3000, stack = true, close = true },
    ['stolen_wheel'] = { label = 'Roue volée', weight = 1500, stack = true, close = true },
    ['stolen_hood'] = { label = 'Capot volé', weight = 2500, stack = true, close = true },
    ['stolen_trunk'] = { label = 'Coffre volé', weight = 2500, stack = true, close = true },
    ['stolen_engine'] = { label = 'Moteur volé', weight = 8000, stack = true, close = true },
    ['fishing_rod'] = { label = 'Canne à pêche', weight = 800, stack = true, close = true, consume = 0, client = { event = 'pickax_life:useRod' } },
    ['fishing_bait'] = { label = 'Appât', weight = 20, stack = true, close = true },
    ['fishing_license'] = { label = 'Permis de pêche', weight = 10, stack = true, close = true },
    ['hunting_license'] = { label = 'Permis de chasse', weight = 10, stack = true, close = true },
    ['hunting_knife'] = { label = 'Couteau de chasse', weight = 400, stack = true, close = true, consume = 0, client = { event = 'pickax_life:useKnife' } },
    ['fish_sardine'] = { label = 'Sardine', weight = 150, stack = true, close = true },
    ['fish_carp'] = { label = 'Carpe', weight = 900, stack = true, close = true },
    ['fish_bass'] = { label = 'Bar', weight = 1200, stack = true, close = true },
    ['fish_tuna'] = { label = 'Thon', weight = 3000, stack = true, close = true },
    ['fish_sword'] = { label = 'Espadon', weight = 6000, stack = true, close = true },
    ['meat_deer'] = { label = 'Viande de cerf', weight = 700, stack = true, close = true },
    ['meat_boar'] = { label = 'Viande de sanglier', weight = 600, stack = true, close = true },
    ['meat_rabbit'] = { label = 'Viande de lapin', weight = 300, stack = true, close = true },
    ['leather_deer'] = { label = 'Peau de cerf', weight = 900, stack = true, close = true },
    ['leather_boar'] = { label = 'Peau de sanglier', weight = 800, stack = true, close = true },
    ['cooking_oil'] = { label = 'Huile de cuisine', weight = 500, stack = true, close = true },
    ['dish_fish'] = { label = 'Poisson grillé', weight = 350, stack = true, close = true, client = { status = { hunger = 350000 }, anim = 'eating', usetime = 3500 } },
    ['dish_venison'] = { label = 'Ragoût de cerf', weight = 450, stack = true, close = true, client = { status = { hunger = 350000 }, anim = 'eating', usetime = 3500 } },
    ['dish_sandwich'] = { label = 'Sandwich', weight = 250, stack = true, close = true, client = { status = { hunger = 350000 }, anim = 'eating', usetime = 3500 } },
    ['burnt_food'] = { label = 'Plat brûlé', weight = 250, stack = true, close = true },
    ['flour'] = { label = 'Farine', weight = 500, stack = true, close = true, description = 'Ingrédient de cuisine' },
    ['egg'] = { label = 'Œuf', weight = 60, stack = true, close = true, description = 'Ingrédient de cuisine' },
    ['butter'] = { label = 'Beurre', weight = 250, stack = true, close = true, description = 'Ingrédient de cuisine' },
    ['tomato'] = { label = 'Tomate', weight = 150, stack = true, close = true, description = 'Ingrédient de cuisine' },
    ['lettuce'] = { label = 'Salade verte', weight = 200, stack = true, close = true, description = 'Ingrédient de cuisine' },
    ['cheese'] = { label = 'Fromage', weight = 250, stack = true, close = true, description = 'Ingrédient de cuisine' },
    ['potato'] = { label = 'Pomme de terre', weight = 200, stack = true, close = true, description = 'Ingrédient de cuisine' },
    ['rice'] = { label = 'Riz', weight = 500, stack = true, close = true, description = 'Ingrédient de cuisine' },
    ['onion'] = { label = 'Oignon', weight = 150, stack = true, close = true, description = 'Ingrédient de cuisine' },
    ['sugar'] = { label = 'Sucre', weight = 500, stack = true, close = true, description = 'Ingrédient de cuisine' },
    ['meat_beef'] = { label = 'Viande de bœuf', weight = 500, stack = true, close = true, description = 'Ingrédient de cuisine' },
    ['chicken_raw'] = { label = 'Poulet cru', weight = 700, stack = true, close = true, description = 'Ingrédient de cuisine' },
    ['pasta'] = { label = 'Pâtes', weight = 400, stack = true, close = true, description = 'Ingrédient de cuisine' },
    ['dish_omelet'] = { label = 'Omelette au fromage', weight = 250, stack = true, close = true, client = { status = { hunger = 300000 }, anim = 'eating', usetime = 3500 } },
    ['dish_salad'] = { label = 'Salade composée', weight = 250, stack = true, close = true, client = { status = { hunger = 200000 }, anim = 'eating', usetime = 3500 } },
    ['dish_fries'] = { label = 'Frites maison', weight = 250, stack = true, close = true, client = { status = { hunger = 300000 }, anim = 'eating', usetime = 3500 } },
    ['dish_burger'] = { label = 'Burger maison', weight = 350, stack = true, close = true, client = { status = { hunger = 450000 }, anim = 'eating', usetime = 3500 } },
    ['dish_steak'] = { label = 'Steak-frites', weight = 450, stack = true, close = true, client = { status = { hunger = 500000 }, anim = 'eating', usetime = 3500 } },
    ['dish_pizza'] = { label = 'Pizza', weight = 500, stack = true, close = true, client = { status = { hunger = 550000 }, anim = 'eating', usetime = 3500 } },
    ['dish_pasta'] = { label = 'Pâtes à la tomate', weight = 450, stack = true, close = true, client = { status = { hunger = 450000 }, anim = 'eating', usetime = 3500 } },
    ['dish_rice'] = { label = 'Riz au poulet', weight = 450, stack = true, close = true, client = { status = { hunger = 500000 }, anim = 'eating', usetime = 3500 } },
    ['dish_cake'] = { label = 'Gâteau maison', weight = 300, stack = true, close = true, client = { status = { hunger = 300000 }, anim = 'eating', usetime = 3500 } },
    ['evidence_bag'] = { label = 'Sachet de scellé', weight = 20, stack = true, close = true, description = 'Sachet pour recueillir une pièce à conviction.' },
    ['lockpick'] = { label = 'Pied de Biche', weight = 1000, stack = true, close = true, consume = 0, client = { event = 'pickax_crime:useLockpick' } },
    ['malbora'] = { label = 'Malboro', weight = 100, stack = true, close = true },
    ['martini'] = { label = 'Martini blanc', weight = 1000, stack = true, close = true },
    ['meat'] = { label = 'Viande', weight = 300, stack = true, close = true },
    ['medikit'] = { label = 'Medikit', weight = 2000, stack = true, close = true },
    ['menthe'] = { label = 'Feuille de menthe', weight = 1000, stack = true, close = true },
    ['meth'] = { label = 'Meth', weight = 1000, stack = true, close = true },
    ['meth_pooch'] = { label = 'Pochon de meth', weight = 250, stack = true, close = true },
    ['metreshooter'] = { label = 'Mètre de shooter', weight = 100, stack = true, close = true },
    ['mixapero'] = { label = 'Mix Apéritif', weight = 100, stack = true, close = true },
    ['mojito'] = { label = 'Mojito', weight = 100, stack = true, close = true },
    ['opium'] = { label = 'Opium', weight = 1000, stack = true, close = true },
    ['opium_pooch'] = { label = 'Pochon d\'opium', weight = 250, stack = true, close = true },
    ['orange'] = { label = 'Orange', weight = 100, stack = true, close = true },
    ['orange_juice'] = { label = 'Jus d\'orange', weight = 300, stack = true, close = true },
    ['oxygen_mask'] = { label = 'Masque à Oxygène', weight = 600, stack = true, close = true },
    ['pepperspray'] = { label = 'Gazeuse', weight = 1000, stack = true, close = true },
    ['piluleoubli'] = { label = 'GHB', weight = 1000, stack = true, close = true },
    ['police_cuff'] = { label = 'Menottes LSPD', weight = 300, stack = true, close = true },
    ['police_key'] = { label = 'Clefs de Menottes LSPD', weight = 100, stack = true, close = true },
    ['pomme'] = { label = 'Pomme', weight = 100, stack = true, close = true },
    ['radio'] = { label = 'Radio', weight = 500, stack = true, close = true },
    ['raisin'] = { label = 'Raisin', weight = 300, stack = true, close = true },
    ['redbull'] = { label = 'Redbull', weight = 300, stack = true, close = true },
    ['repairkit'] = { label = 'Repairkit', weight = 2000, stack = true, close = true },
    ['rhum'] = { label = 'Rhum', weight = 400, stack = true, close = true },
    ['rhumcoca'] = { label = 'Rhum-Coca', weight = 500, stack = true, close = true },
    ['rhumfruit'] = { label = 'Rhum-Jus de fruits', weight = 500, stack = true, close = true },
    ['tabac'] = { label = 'Tabac', weight = 500, stack = true, close = true },
    ['tabacblond'] = { label = 'Tabac Blond', weight = 500, stack = true, close = true },
    ['tabacblondsec'] = { label = 'Tabac Blond Séché', weight = 500, stack = true, close = true },
    ['tabacbrun'] = { label = 'Tabac Brun', weight = 500, stack = true, close = true },
    ['tabacbrunsec'] = { label = 'Tabac Brun Séché', weight = 500, stack = true, close = true },
    ['tarte_pomme'] = { label = 'Tarte aux Pommes', weight = 300, stack = true, close = true },
    ['teqpaf'] = { label = 'Teq\'paf', weight = 500, stack = true, close = true },
    ['tequila'] = { label = 'Tequila', weight = 500, stack = true, close = true },
    ['vine'] = { label = 'Vin', weight = 500, stack = true, close = true },
    ['vittvin'] = { label = 'Vin Blanc', weight = 500, stack = true, close = true },
    ['vodka'] = { label = 'Vodka', weight = 300, stack = true, close = true },
    ['vodkaenergy'] = { label = 'Vodka-Energy', weight = 400, stack = true, close = true },
    ['vodkafruit'] = { label = 'Vodka-Jus de fruits', weight = 300, stack = true, close = true },
    ['vodkaredbull'] = { label = 'Vodka-Redbull', weight = 300, stack = true, close = true },
    ['water'] = { label = 'Bouteille d\'eau', weight = 100, stack = true, close = true },
    ['weed'] = { label = 'Weed', weight = 1000, stack = true, close = true },
    ['launder_tablet'] = { label = 'Tablette de blanchiment', weight = 600, stack = false, close = true, description = 'Indique où blanchir ton argent sale et donne accès au blanchisseur.' },
    ['lab_catalyst'] = { label = 'Catalyseur de laboratoire', weight = 200, stack = true, close = true, description = 'Ingrédient optionnel : améliore la qualité de ta fabrication et réduit le risque d\'accident.' },
    ['dealer_tablet'] = { label = 'Tablette vendeur', weight = 600, stack = false, close = true, description = 'Indique où trouver l\'acheteur et permet de lui vendre ta marchandise.' },
    ['gofast_tablet'] = { label = 'Tablette Go Fast', weight = 600, stack = false, close = true, description = 'Indique où trouver le contact Go Fast et donne accès à ses livraisons.' },
    ['antidote'] = { label = 'Antidote', weight = 100, stack = true, close = true, description = 'Le seul remède contre l\'intoxication des laboratoires.' },
    ['weed_seed'] = { label = 'Graines de cannabis', weight = 10, stack = true, close = true, description = 'À planter dans une serre ou un champ.' },
    ['coke_seed'] = { label = 'Graines de coca', weight = 10, stack = true, close = true, description = 'À planter dans une plantation de coca.' },
    ['opium_seed'] = { label = 'Graines de pavot', weight = 10, stack = true, close = true, description = 'À planter dans un champ de pavot.' },
    ['wheat_seed'] = { label = 'Graines de blé', weight = 10, stack = true, close = true, description = 'À semer dans ton champ de ferme.' },
    ['corn_seed'] = { label = 'Graines de maïs', weight = 10, stack = true, close = true, description = 'À semer dans ton champ de ferme.' },
    ['wheat'] = { label = 'Blé', weight = 150, stack = true, close = true, description = 'Récolte à vendre au marché.' },
    ['corn'] = { label = 'Maïs', weight = 180, stack = true, close = true, description = 'Récolte à vendre au marché.' },
    ['weed_pooch'] = { label = 'Pochon de weed', weight = 250, stack = true, close = true },
    ['whisky'] = { label = 'Whisky', weight = 400, stack = true, close = true },
    ['whiskycoca'] = { label = 'Whisky-coca', weight = 500, stack = true, close = true },
    ['gym_membership'] = { label = 'Pass membre GYM', weight = 500, stack = true, close = true },
    ['fishingrod'] = { label = 'Canne à pêche', weight = 500, stack = true, close = true },
    ['macro'] = { label = 'Macro', weight = 500, stack = true, close = true },
    ['bar'] = { label = 'Bar', weight = 500, stack = true, close = true },
    ['dorade'] = { label = 'Dorade', weight = 500, stack = true, close = true },
    ['lieu'] = { label = 'Lieu', weight = 500, stack = true, close = true },
    ['raie'] = { label = 'Raie', weight = 500, stack = true, close = true },
    ['sardine'] = { label = 'Sardine', weight = 500, stack = true, close = true },
    ['saumon'] = { label = 'Saumon', weight = 500, stack = true, close = true },
    ['thon'] = { label = 'Thon', weight = 500, stack = true, close = true },
    ['requin'] = { label = 'Requin', weight = 2000, stack = true, close = true },
    ['zetony'] = { label = 'Jetons', weight = 0, stack = true, close = true },

    ['clothing'] = {
        label = 'Clothing',
        consume = 0,
    },

    -- Tenue complete (creee par shopbuilder). Glisse-la sur ton personnage (milieu de l'inventaire) pour equiper toutes les pieces.
    ['clothes_outfit'] = {
        label = 'Tenue',
        weight = 500,
        stack = false,
        close = false,
        description = 'Une tenue complete. Glisse-la sur ton personnage pour la porter.',
    },

    ['clothes_hat'] = {
        label = 'Hat',
        weight = 50,
        stack = false,
        close = false,
        buttons = {
            {
                label = 'Show/Hide Hair',
                action = function(slot)
                    TriggerEvent('p_itemclothes/client/toggleHair')
                end
            },
        },
        consume = 0,
        server = {
            export = 'p_itemclothes.useClothingItem'
        }
    },

    ['clothes_ears'] = {
        label = 'Ear Accessories',
        weight = 50,
        stack = false,
        close = false,
        consume = 0,
        server = {
            export = 'p_itemclothes.useClothingItem'
        }
    },

    ['clothes_tshirt'] = {
        label = 'T-Shirt',
        weight = 50,
        stack = false,
        close = false,
        consume = 0,
        server = {
            export = 'p_itemclothes.useClothingItem'
        }
    },

    ['clothes_torso'] = {
        label = 'Jacket',
        weight = 50,
        stack = false,
        close = false,
        consume = 0,
        server = {
            export = 'p_itemclothes.useClothingItem'
        }
    },

    ['clothes_arms'] = {
        label = 'Gloves',
        weight = 50,
        stack = false,
        close = false,
        consume = 0,
        server = {
            export = 'p_itemclothes.useClothingItem'
        }
    },

    ['clothes_pants'] = {
        label = 'Pants',
        weight = 50,
        stack = false,
        close = false,
        consume = 0,
        server = {
            export = 'p_itemclothes.useClothingItem'
        }
    },

    ['clothes_shoes'] = {
        label = 'Shoes',
        weight = 50,
        stack = false,
        close = false,
        consume = 0,
        server = {
            export = 'p_itemclothes.useClothingItem'
        }
    },

    ['clothes_mask'] = {
        label = 'Mask',
        weight = 50,
        stack = false,
        close = false,
        buttons = {
            {
                label = 'Show/Hide Face',
                action = function(slot)
                    TriggerEvent('p_itemclothes/client/toggleFace')
                end
            },
            {
                label = 'Show/Hide Hair',
                action = function(slot)
                    TriggerEvent('p_itemclothes/client/toggleHair')
                end
            },
        },
        consume = 0,
        server = {
            export = 'p_itemclothes.useClothingItem'
        }
    },

    ['clothes_glasses'] = {
        label = 'Glasses',
        weight = 50,
        stack = false,
        close = false,
        consume = 0,
        server = {
            export = 'p_itemclothes.useClothingItem'
        }
    },

    ['clothes_vest'] = {
        label = 'Vest',
        weight = 50,
        stack = false,
        close = false,
        consume = 0,
        server = {
            export = 'p_itemclothes.useClothingItem'
        }
    },

    ['clothes_bag'] = {
        bag = true,   -- sac porté (vêtement) : « Porter » l'équipe, « Ouvrir le sac » ouvre son rangement
        label = 'Bag',
        weight = 50,
        stack = false,
        close = false,
        consume = 0,
        server = {
            export = 'p_itemclothes.useClothingItem'
        }
    },

    ['clothes_watch'] = {
        label = 'Watch',
        weight = 50,
        stack = false,
        close = false,
        consume = 0,
        server = {
            export = 'p_itemclothes.useClothingItem'
        }
    },

    ['clothes_chain'] = {
        label = 'Chain',
        weight = 50,
        stack = false,
        close = false,
        consume = 0,
        server = {
            export = 'p_itemclothes.useClothingItem'
        }
    },

    ['clothes_bracelet'] = {
        label = 'Bracelet',
        weight = 50,
        stack = false,
        close = false,
        consume = 0,
        server = {
            export = 'p_itemclothes.useClothingItem'
        }
    },

    ['code'] = {
        label = 'Code de la route',
        weight = 0,
        stack = false,
        close = true,
        consume = 0,
    },

    ['drive'] = {
        label = 'Permis de conduire',
        weight = 0,
        stack = false,
        close = true,
        consume = 0,
    },

    ['drive_bike'] = {
        label = 'Permis moto',
        weight = 0,
        stack = false,
        close = true,
        consume = 0,
    },

    ['drive_truck'] = {
        label = 'Permis camion',
        weight = 0,
        stack = false,
        close = true,
        consume = 0,
    },

    ['weapon'] = {
        label = 'PPA',
        weight = 0,
        stack = false,
        close = true,
        consume = 0,
    },

    ['phone'] = {
        label = 'Téléphone',
        weight = 190,
        stack = false,
        consume = 0,
        close = true,
     -- Aura (pickax_phone) gère ox_inventory:usedItem (ouvre le téléphone).
    },

    -- Cartes / permis (CorePickax > players/jsfour-idcard)
    ['id_card'] = { label = "Carte d'identité", weight = 10, stack = false, close = true, description = "Carte nationale d'identité", server = { export = 'pickax_core.id_card' } },
    ['driver_license'] = { label = 'Permis de conduire', weight = 10, stack = false, close = true, description = 'Permis de conduire', server = { export = 'pickax_core.driver_license' } },
    ['weapon_license'] = { label = "Permis de port d'arme", weight = 10, stack = false, close = true, description = "Permis de port d'arme", server = { export = 'pickax_core.weapon_license' } },

    -- Items utilisés par les builders (braquages worldbuilder, boutique de vêtements shopbuilder)
    ['diamond'] = { label = 'Diamant', weight = 50, stack = true, close = true },
    ['goldbar'] = { label = "Lingot d'or", weight = 1000, stack = true, close = true },
    ['markedbills'] = { label = 'Billets marqués', weight = 0, stack = true, close = false },
    ['drill'] = { label = 'Perceuse', weight = 3000, stack = true, close = true },
    ['thermite'] = { label = 'Thermite', weight = 500, stack = true, close = true },
    ['clothes_helmet'] = { label = 'Casque / chapeau', weight = 200, stack = true, close = true },
    ['sandwich'] = { label = 'Sandwich', weight = 200, stack = true, close = true },
    ['chips'] = { label = 'Chips', weight = 100, stack = true, close = true },
    ['coffee'] = { label = 'Café', weight = 150, stack = true, close = true },
    ['painkillers'] = { label = 'Antidouleurs', weight = 100, stack = true, close = true },
    ['pizza'] = { label = 'Pizza', weight = 400, stack = true, close = true },
    ['jerrycan'] = { label = 'Jerrican', weight = 4000, stack = true, close = true },
    ['rope'] = { label = 'Corde', weight = 500, stack = true, close = true },
    ['tablet'] = { label = 'Tablette', weight = 600, stack = true, close = true },
    ['powerbank'] = { label = 'Batterie externe', weight = 300, stack = true, close = true },
    ['carplay'] = { label = 'Boîtier CarPlay', weight = 300, stack = false, close = true, description = 'Autoradio connecté : utilise-le dans un véhicule pour ouvrir CarPlay.', client = { event = 'carplay:client:open' } },
}
