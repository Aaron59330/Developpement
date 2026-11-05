-- Menu RageUI générique pour les ressources pickax_* : mêmes composants que le menu personnel (bannière, compteur x/y, séparateurs, flèches →→→, Retour = menu précédent).
local ctxRunning = false
local ctxMenu = nil

exports('ContextListEnabled', function() return ConfigContextList and ConfigContextList.Enabled ~= false end)

exports('ContextRunning', function() return ctxRunning end)

exports('CloseContext', function()
    if ctxMenu then pcall(function() RageUI.Visible(ctxMenu, false) end) end
    ctxRunning = false
end)

local function describe(o)
    local d = o.description and tostring(o.description) or ''
    if type(o.metadata) == 'table' then
        for _, m in ipairs(o.metadata) do
            if type(m) == 'table' and (m.label or m.value) then d = d .. ((d ~= '' and '\n') or '') .. tostring(m.label or '') .. ' : ' .. tostring(m.value or '')
            elseif type(m) == 'string' then d = d .. ((d ~= '' and '\n') or '') .. m end
        end
    end
    return d ~= '' and d or nil
end

-- Saisie au clavier natif de GTA (comme le menu personnel) : renvoie le texte validé ou nil
local function askText(f, cur)
    AddTextEntry('PK_CTXFORM', tostring(f.label or 'Valeur'))
    DisplayOnscreenKeyboard(1, 'PK_CTXFORM', '', tostring(cur or ''), '', '', '', tonumber(f.max) or 60)
    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end
    if UpdateOnscreenKeyboard() == 1 then
        local r = GetOnscreenKeyboardResult()
        if f.type == 'number' then r = tostring(r or ''):gsub('%D', '') end
        return r
    end
end

local function formValid(form, vals)
    for _, f in ipairs(form.fields or {}) do
        local v = vals[f.key]
        if f.required and (v == nil or v == '') then return false end
        if f.type == 'number' and v ~= nil and v ~= '' then
            local n = tonumber(v)
            if not n or n < (tonumber(f.min) or 0) or (f.maxValue and n > tonumber(f.maxValue)) then return false end
        end
    end
    return true
end

-- cfg = { id = 'racine', contexts = { [id] = { title, subtitle, options = { { title, description, metadata, disabled, readOnly, separator, menu = id_sous_menu, onSelect, event, serverEvent, args, arrow } } } } }
exports('ShowContext', function(cfg)
    if type(cfg) ~= 'table' or type(cfg.contexts) ~= 'table' or not cfg.contexts[cfg.id] then return end
    if ctxRunning then return end
    ctxRunning = true
    CreateThread(function()
        local menus, after = {}, nil
        local forms, vals = {}, {}   -- formulaires RageUI : forms[option] = sous-menu, vals[option] = valeurs saisies
        local function build(id, parent)
            local c = cfg.contexts[id]
            if not c or menus[id] then return end
            local sub = tostring(c.subtitle or ConfigContextList.Subtitle or '')
            menus[id] = parent and RageUI.CreateSubMenu(parent, tostring(c.title or ''), sub) or RageUI.CreateMenu(tostring(c.title or ''), sub)
            for _, o in ipairs(c.options or {}) do
                if o.menu then build(o.menu, menus[id])
                elseif type(o.form) == 'table' then
                    forms[o] = RageUI.CreateSubMenu(menus[id], tostring(o.form.title or o.title or ''), tostring(o.form.subtitle or ConfigContextList.Subtitle or ''))
                    vals[o] = {}
                    for _, f in ipairs(o.form.fields or {}) do vals[o][f.key] = f.default end
                end
            end
        end
        build(cfg.id, nil)
        local root = menus[cfg.id]
        local first = (cfg.start and menus[cfg.start]) or root      -- cfg.start : s'ouvre directement sur ce sous-menu (Retour mène au menu parent)
        ctxMenu = first
        RageUI.Visible(first, true)

        local function draw(id)
            RageUI.IsVisible(menus[id], true, true, true, function()
                for _, o in ipairs(cfg.contexts[id].options or {}) do
                    if o.separator then
                        RageUI.Separator(tostring(o.title or ''))
                    else
                        local enabled = not o.disabled and not o.readOnly
                        local style = {}
                        if o.menu or o.form then style.RightLabel = ConfigContextList.SubmenuArrow or '→→→' elseif o.arrow then style.RightLabel = '↗' end
                        RageUI.ButtonWithStyle(tostring(o.title or ''), describe(o), style, enabled, function(_, _, Selected)
                            if Selected and not o.menu and not o.form and (o.onSelect or o.event or o.serverEvent) then after = o end
                        end, (o.menu and menus[o.menu]) or (o.form and forms[o]) or nil)
                    end
                end
            end, function() end)
        end

        local function drawForm(o)
            local form = o.form
            RageUI.IsVisible(forms[o], true, true, true, function()
                for _, f in ipairs(form.fields or {}) do
                    local v = vals[o][f.key]
                    local shown = (v ~= nil and v ~= '') and (tostring(v) .. (f.suffix and (' ' .. f.suffix) or '')) or '—'
                    RageUI.ButtonWithStyle(tostring(f.label or f.key), f.description, { RightLabel = shown }, true, function(_, _, Selected)
                        if Selected then
                            local r = askText(f, v)
                            if r ~= nil then vals[o][f.key] = r end
                        end
                    end)
                end
                local okForm = formValid(form, vals[o])
                RageUI.ButtonWithStyle(tostring(form.submitLabel or 'Valider'), okForm and form.submitDescription or 'Remplis tous les champs pour continuer', {}, okForm, function(_, _, Selected)
                    if Selected and okForm and form.onSubmit then
                        local copy = {}
                        for k, v in pairs(vals[o]) do copy[k] = v end
                        after = { onSelect = function() form.onSubmit(copy) end }
                    end
                end)
            end, function() end)
        end

        while ctxRunning and not after do
            Wait(0)
            local any = false
            for id, m in pairs(menus) do
                draw(id)
                if RageUI.Visible(m) then any = true end
            end
            for o, m in pairs(forms) do
                drawForm(o)
                if RageUI.Visible(m) then any = true end
            end
            if not any then break end
        end
        ctxMenu = nil
        ctxRunning = false
        pcall(function() RageUI.CloseAll() end)
        if after then
            local o = after
            if o.onSelect then pcall(o.onSelect, o.args) end
            if o.event then TriggerEvent(o.event, o.args) end
            if o.serverEvent then TriggerServerEvent(o.serverEvent, o.args) end
        end
    end)
end)
