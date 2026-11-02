-- Écran de chargement : écrit loading/loading.json à partir de Config.Loading (pickax_core/config.lua).
-- Même nettoyage que l'ancien panel : textes courts, liens https:// uniquement, valeurs bornées.
local function str(v, max) v = tostring(v or ''):gsub('^%s+', ''):gsub('%s+$', '') return v:sub(1, max) end
local function url(v) v = str(v, 400) if v == '' then return '' end if v:match('^https://[%w%-%._~:/%?#@!%$&%(%)%*%+,;=%%]+$') then return v end end
local function num(v, lo, hi, d) v = tonumber(v) or d return math.max(lo, math.min(hi, math.floor(v))) end

local function build(c)
    local o = { tips = {}, links = {}, team = {}, updates = {}, stages = {}, music = {}, texts = {}, hide = {} }
    for _, t in ipairs(type(c.Tips) == 'table' and c.Tips or {}) do local x = str(t, 140) if x ~= '' and #o.tips < 12 then o.tips[#o.tips + 1] = x end end
    local L = type(c.Links) == 'table' and c.Links or {}
    for _, k in ipairs({ 'reglement', 'discord', 'boutique' }) do
        local u = url(L[k]) if u == nil then print(('^3[pickax_core] Config.Loading.Links.%s : lien invalide (https:// requis), ignoré^7'):format(k)) u = '' end
        o.links[k] = u
    end
    for _, m in ipairs(type(c.Team) == 'table' and c.Team or {}) do
        if type(m) == 'table' and #o.team < 12 and str(m.name, 40) ~= '' then o.team[#o.team + 1] = { name = str(m.name, 40), role = str(m.role, 60) } end
    end
    for _, u in ipairs(type(c.Updates) == 'table' and c.Updates or {}) do
        if type(u) == 'table' and #o.updates < 8 and str(u.title, 60) ~= '' then
            local items = {}
            for _, it in ipairs(type(u.items) == 'table' and u.items or {}) do local x = str(it, 120) if x ~= '' and #items < 6 then items[#items + 1] = x end end
            o.updates[#o.updates + 1] = { date = str(u.date, 20), title = str(u.title, 60), items = items }
        end
    end
    for i = 1, 4 do o.stages[i] = str((type(c.Stages) == 'table' and c.Stages[i]) or '', 40) end
    local M = type(c.Music) == 'table' and c.Music or {}
    o.music = { enabled = M.enabled ~= false, url = url(M.url) or '', volume = num(M.volume, 0, 100, 10), autoplay = M.autoplay ~= false }
    o.showTeam, o.showUpdates = c.ShowTeam ~= false, c.ShowUpdates ~= false
    local B = type(c.Background) == 'table' and c.Background or {}
    o.bg = { image = url(B.image) or '', dim = num(B.dim, 0, 100, 0), blur = num(B.blur, 0, 20, 0) }
    o.logo = url(c.Logo) or ''
    local n = 0
    for k, t in pairs(type(c.Texts) == 'table' and c.Texts or {}) do local kk, tt = str(k, 80), str(t, 140) if kk ~= '' and tt ~= '' and n < 80 then o.texts[kk] = tt n = n + 1 end end
    for _, k in ipairs({ 'logo', 'ticker', 'links', 'progress', 'name' }) do o.hide[k] = type(c.Hide) == 'table' and c.Hide[k] == true end
    return o
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    local c = Config and Config.Loading
    if type(c) ~= 'table' or c.Enabled == false then return end
    if GetResourceState('pickax_panel') ~= 'missing' then return end   -- panel web réinstallé : c'est lui qui écrit loading.json (voir _archive_panel/RESTAURER-LE-PANEL.md)
    local ok, raw = pcall(function() return json.encode(build(c)) end)
    if not ok then print('^1[pickax_core] Config.Loading illisible : ' .. tostring(raw) .. '^7') return end
    local current = LoadResourceFile(res, 'loading/loading.json')
    if current ~= raw then
        if SaveResourceFile(res, 'loading/loading.json', raw, -1) then print('^2[pickax_core] Écran de chargement mis à jour depuis Config.Loading^7')
        else print('^1[pickax_core] Écriture de loading/loading.json impossible^7') end
    end
end)
