-- Catalogue des événements que chaque builder peut envoyer sur Discord.
-- key = nom de l'action enregistrée par le builder ; une clé finissant par * couvre toute une famille (ex : bank_* = bank_loan, bank_fee…).
-- Pour ajouter un événement : une ligne { 'cle', 'Libellé affiché' } dans le bon groupe. Rien d'autre à modifier.
DLogsCatalog = {
    job = {
        title = 'Métier',
        groups = {
            { 'Société & État', {
                { 'society_deposit', 'Dépôt dans le coffre société' }, { 'society_withdraw', 'Retrait du coffre société' },
                { 'treasury_*', 'Trésor public (dépôt / retrait)' }, { 'taxes_set', 'Taxes modifiées' }, { 'grant', 'Subvention versée' }, { 'prime', 'Prime versée' },
                { 'bank_*', 'Banque (clients, prêts, frais)' }, { 'invoice_paid', 'Facture payée' },
            } },
            { 'Employés', {
                { 'recruit', 'Recrutement' }, { 'set_grade', 'Changement de grade' }, { 'fire', 'Licenciement' }, { 'set_salary', 'Salaire modifié' },
            } },
            { 'Activité', {
                { 'harvest', 'Récolte' }, { 'cook', 'Cuisine / traitement' }, { 'mission_done', 'Mission terminée' }, { 'shop_buy', 'Achat à la boutique du métier' },
                { 'armory_take', 'Armurerie : objet pris' }, { 'vehicle_out', 'Véhicule sorti' }, { 'vehicle_in', 'Véhicule rentré' }, { 'vehicle_sold', 'Véhicule vendu' }, { 'tuning', 'Tuning appliqué' },
                { 'job_announce', 'Annonce du métier' }, { 'announce', 'Annonce officielle' }, { 'catalog_saved', 'Catalogue modifié' },
            } },
            { 'Police & santé', {
                { 'panic', 'Bouton panique' }, { 'pursuit_start', 'Poursuite lancée' }, { 'record_*', 'Casier (création / suppression / recherché)' }, { 'fine_sent', 'Amende envoyée' },
                { 'action_*', 'Actions RP (menottes, soin…)' }, { 'ems_call', 'Appel EMS' }, { 'ems_take', 'Appel EMS pris en charge' }, { 'revive', 'Réanimation' }, { 'revive_command', 'Réanimation par commande' },
                { 'care', 'Soin facturé' }, { 'patient_*', 'Dossiers patients' }, { 'hospital_fee', 'Frais d\'hôpital' },
            } },
            { 'Gestion (builder)', { { 'job_created', 'Métier créé' }, { 'job_updated', 'Métier modifié' } } },
        },
    },
    gang = {
        title = 'Gang',
        groups = {
            { 'Trésorerie', {
                { 'treasury_deposit', 'Dépôt trésorerie' }, { 'treasury_withdraw', 'Retrait trésorerie' }, { 'dirty_deposit', 'Dépôt argent sale' }, { 'dirty_withdraw', 'Retrait argent sale' }, { 'salary_skipped', 'Salaires non versés' },
            } },
            { 'Membres', {
                { 'recruit', 'Recrutement' }, { 'set_grade', 'Changement de grade' }, { 'fire', 'Exclusion' }, { 'leave', 'Départ volontaire' }, { 'set_salary', 'Salaire modifié' }, { 'action_*', 'Actions RP' },
            } },
            { 'Activités', {
                { 'harvest', 'Récolte' }, { 'process', 'Traitement' }, { 'launder', 'Blanchiment' }, { 'sell', 'Vente' }, { 'quest_done', 'Quête terminée' }, { 'objective_delivered', 'Objectif livré' },
                { 'shop_buy', 'Achat à la boutique' }, { 'armory_take', 'Armurerie : objet pris' }, { 'vehicle_out', 'Véhicule sorti' }, { 'vehicle_in', 'Véhicule rentré' },
            } },
            { 'Territoires & guerres', {
                { 'territory_captured', 'Territoire capturé' }, { 'territory_income', 'Revenu de territoire' }, { 'territory_set_owner', 'Propriétaire modifié (staff)' }, { 'conflict_start', 'Conflit lancé' }, { 'conflict_win', 'Conflit gagné' },
                { 'war_propose', 'Guerre proposée' }, { 'war_win', 'Guerre gagnée' }, { 'war_loss', 'Guerre perdue' },
            } },
            { 'Gestion (builder)', { { 'gang_created', 'Gang créé' }, { 'gang_updated', 'Gang modifié' } } },
        },
    },
    shop = {
        title = 'Boutique',
        groups = {
            { 'Ventes', { { 'buy', 'Achat client' }, { 'clothing', 'Achat de tenue' } } },
            { 'Gestion', { { 'create', 'Boutique créée' }, { 'save', 'Boutique modifiée' }, { 'toggle', 'Activée / désactivée' }, { 'restock', 'Réapprovisionnement' }, { 'duplicate', 'Dupliquée' }, { 'delete', 'Supprimée' } } },
        },
    },
    event = {
        title = 'Événement',
        groups = {
            { 'Déroulement', { { 'start', 'Événement lancé' }, { 'end', 'Événement terminé' }, { 'reward', 'Récompense donnée' }, { 'breach', 'Portes ouvertes (effraction)' } } },
            { 'Gestion', { { 'create', 'Événement créé' }, { 'save', 'Événement modifié' }, { 'delete', 'Événement supprimé' } } },
        },
    },
}
