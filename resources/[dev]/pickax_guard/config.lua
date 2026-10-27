Config = {}

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
--  PICKAX GUARD — protection de la base
--  Sans clé de licence valide, les ressources de la base ne démarrent pas (et sont arrêtées si la licence devient invalide).
--  Dans le server.cfg :  set aero_panel_url "https://panel.aerofivem.site"   et   set aero_panel_key "AERO-XXXXXX-XXXXXX-XXXXXX-XXXXXX"
--  Ce dossier doit être démarré EN PREMIER (resources.cfg : « ensure pickax_guard » avant tout le reste).
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

-- Clé PUBLIQUE de ton panel (panel web → Administration → Protection de la base). Sans elle, la base refuse de démarrer.
-- Ne mets jamais la clé privée ici : elle reste sur le VPS du panel.
Config.PublicKey = 'MCowBQYDK2VwAyEA3ygdLUgkYhpVm8Y7uOZQRyBbbjMZ8pAvWfCp0aAE0mU='

Config.Prefix   = 'pickax_'                      -- toutes les ressources dont le nom commence ainsi sont protégées…
Config.Exclude  = { 'pickax_guard', 'pickax_panel' }   -- …sauf celles-ci (le panel doit tourner pour afficher le statut)
Config.Protect  = {}                             -- ressources protégées en plus (ex : { 'esx_identity' })

Config.Interval      = 600                       -- secondes entre deux vérifications quand tout va bien
Config.RetryInterval = 30                        -- secondes entre deux tentatives quand la licence n'est pas (encore) valide
Config.Timeout       = 10000                     -- délai maximum d'une requête au panel (ms)

-- false (défaut) : les ressources démarrent normalement puis s'arrêtent d'elles-mêmes si la licence est refusée (console propre).
-- true : leur démarrage est annulé tant que la licence n'est pas validée (la console affiche alors « Couldn't start resource … » à chaque lancement).
Config.HoldStart = false
