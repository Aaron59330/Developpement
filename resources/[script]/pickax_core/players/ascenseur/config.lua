ConfigAscenseur = {
    Items1 = {
        { Name = "Étage 1", Desc = "Aller a l'étage 1", Pose = {x = 139.03286743164, y = -762.58489990234, z = 45.75199508667}},
        { Name = "Étage 2", Desc = "Aller a l'étage 2", Pose = {x = 136.22494506836, y = -761.53790283203, z = 242.15216064453}},
        { Name = "Étage 3", Desc = "Aller a l'étage 3", Pose = {x = 452.76776123047, y = -974.58532714844, z = 34.971714019775}},
    },
    --Definisez tout !!!!! oublié pas les Items
    AllPosition = {
        --Items1 <3
        { Name = "Étage 1", Desc = "Aller a l'étage 1", JobsRequis = "police", Items = "Items1", Pose = {x = 139.03286743164, y = -762.58489990234, z = 45.75199508667}},--Pour aucun jobs requis enlever simplement : JobsRequis = "police"
        { Name = "Étage 2", Desc = "Aller a l'étage 2", JobsRequis = "police", Items = "Items1", Pose = {x = 136.22494506836, y = -761.53790283203, z = 242.15216064453}},
        { Name = "Étage 3", Desc = "Aller a l'étage 3", JobsRequis = "police", Items = "Items1", Pose = {x = 452.76776123047, y = -974.58532714844, z = 34.971714019775}},
    },
    Text = {
        AccesAscenseur = "Appuyez sur ~INPUT_CONTEXT~ pour accéder a l'ascenseur",
        Title = "Ascenseur",
        Subtitle = "Que voulez-vous faire ?"
    },
    Arrive = "~g~Vous êtes arrivé à ",
    EcranNoir = true,
    Vousetesla = "~r~Vous êtes déjà ici !",
    DrawMarker = {
        Marker = true,
        TypeMarker = 6,
        Color = {
            colorR = 160,
            colorG = 0,
            colorB = 255,
            colorA = 255
        },
        Size = {
            SizeX = 1.0,
            SizeY = 1.0,
            SizeZ = 1.0
        },
        Rotation = 270.0
    }
}