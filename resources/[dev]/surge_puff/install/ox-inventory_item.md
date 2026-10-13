# A mettre directement dans le fichier "items.lua" de votre ox-inventory

  ['puff'] = {
        label = 'Puff 60K',
        weight = 40,
        stack = false,
        close = true,
        consume = 0,
        description = 'Puff Bar. Utiliser pour la tenir, E pour une taffe, réutiliser ou /puffstop pour ranger.',
        client = {
            export = 'surge_puff.usePuff',
            image = 'nui://surge_puff/images/puff.png',
        },
},