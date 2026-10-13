ConfigAdmin = {
    Commande = {
        {
            commande = "tpm",
            groupAcces = {
                "_dev",
                "superadmin"
            },
            IsUsed = function(source, args)
                TeleportMarker(source)
            end
        }
    },
    FunctionClientSide = {
        {
            name = "esx_custom:TPM",
            IsUsed = function()
                TeleportMarkerClientSide()
            end
        }
    }
}