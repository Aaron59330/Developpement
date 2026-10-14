-- ─────────────────────────────── Tablette bancaire (client) ───────────────────────────────
for _, n in ipairs({ 'bank:open', 'bank:dash', 'bank:live', 'bank:clients', 'bank:client', 'bank:saveClient', 'bank:deleteClient', 'bank:note', 'bank:delEntry', 'bank:nearest',
    'bank:loans', 'bank:offerLoan', 'bank:forgive', 'bank:remind', 'bank:collect', 'bank:op', 'bank:fee' }) do NuiRemote[n] = true end
