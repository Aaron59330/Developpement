# pickax_cayo — braquage de Cayo Perico

Ajoute `ensure pickax_cayo` au `server.cfg` (après `es_extended`, `ox_inventory` et `pickax_core`, qui charge l'île).

## Déroulement
1. Poste de planification (`Config.Planning`, `E` ou `/cayo`) : tablette « Kosatka ».
2. Onglets : Objectifs (cible, difficulté) · Approche (véhicule, infiltration, extraction) · Équipement (armement, matériel) · Équipe (parts, invitations `Y`) · Préparatifs (reconnaissances et matériel à récupérer sur le continent).
3. Le chef lance (frais `Config.LaunchFee`). L'équipe arrive en mer / en l'air, rejoint l'île, franchit les obstacles (matériel requis), prend le butin secondaire et la cible dans le coffre, puis quitte l'île au point d'extraction.
4. Gains : cible + butin des évadés, moins Pavel et recel, partagés selon les parts. Voir `Config.PayAccount`.

## À vérifier en jeu (staff)
Les coordonnées de l'île sont approximatives : `/cayotp <point>` pour s'y téléporter, `/cayopos` pour relever une position, puis corriger `config.lua`. `/cayoreset [id]` remet le délai de relance à zéro.
