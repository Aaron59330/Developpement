PanelSync = {
    -- Adresse du panel et clé de licence : à renseigner ici OU dans server.cfg (set aero_panel_url "..." / set aero_panel_key "...")
    Url = '',                 -- ex. 'https://panel.aerofivem.site'
    Key = '',                 -- clé de licence AERO-XXXXXX-XXXXXX-XXXXXX-XXXXXX
    IntervalSec = 60,         -- fréquence de vérification (secondes)
    LogoFile = 'panel_logo',  -- nom du fichier écrit dans pickax_theme/logo/ (l'extension .png / .jpg est ajoutée)
    RestartCore = false,      -- true = relance aussi pickax_core à chaque changement (écran de chargement, chat…) : plus lourd
}
