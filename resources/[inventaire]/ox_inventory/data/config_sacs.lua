-- Sacs du serveur : chaque sac possède son PROPRE inventaire (clic droit → « Ouvrir le sac »).
-- Le contenu suit le sac : si le joueur le donne, le jette, le range dans un coffre ou se le fait voler, tout ce qu'il contient part avec.
-- slots = nombre de cases du sac · maxWeight = poids maximum du contenu en grammes (5000 = 5 kg)
-- Le poids du sac + son contenu compte dans l'inventaire du joueur. Un sac ne peut pas être rangé dans un autre sac.
-- Pour donner un sac en jeu : /additem <id> sac_petit 1   (ou le vendre dans un shop du Shop Builder / une boutique)
return {
    sac_petit  = { slots = 5,  maxWeight = 5000 },    -- Sacoche
    sac_moyen  = { slots = 12, maxWeight = 15000 },   -- Sac bandoulière
    sac_a_dos  = { slots = 20, maxWeight = 30000 },   -- Sac à dos
    sac_sport  = { slots = 30, maxWeight = 50000 },   -- Sac de sport
}
