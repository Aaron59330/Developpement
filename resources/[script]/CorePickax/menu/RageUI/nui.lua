-- Rendu NUI des menus RageUI : la logique (touches, pagination, callbacks, sous-menus) reste celle de RageUI,
-- seul l'affichage est envoyé à la ressource pickax_ui. Charger après tous les fichiers RageUI.

local UI = 'pickax_ui'
local frame = nil
local lastJson = nil
local lastFrame = 0
local shown = false

local BadgeIcon = { shop_lock = 'lock', shop_tick_icon = 'tick', shop_new_star = 'star' }

local function badgeName(badge, active)
    if badge == nil or badge == RageUI.BadgeStyle.None then return nil end
    local ok, data = pcall(badge, active)
    if not ok or type(data) ~= 'table' then return 'dot' end
    return BadgeIcon[data.BadgeTexture] or 'dot'
end

local function uiCall(name, ...)
    if GetResourceState(UI) ~= 'started' then return end
    exports[UI][name](exports[UI], ...)
end

local function hide()
    if not shown then return end
    shown = false
    lastJson = nil
    uiCall('Hide')
end

local function push(it)
    if frame then frame.i[#frame.i + 1] = it end
end

local function describe(Description, Active)
    if frame and Active then frame.ds = (Description ~= nil and Description ~= '') and Description or nil end
end

local function audio(name)
    local a = RageUI.Settings.Audio
    RageUI.PlaySound(a[a.Use][name].audioName, a[a.Use][name].audioRef)
end

-- Sons motion design : les sons natifs de RageUI sont remplacés par ceux de pickax_ui (réglage « Sons des menus »)
local NATIVE_TO_UI = { NAV_UP_DOWN = 'tab', NAV_LEFT_RIGHT = 'tab', SELECT = 'confirm', BACK = 'close', ERROR = 'error' }
local _PlaySound = RageUI.PlaySound
local function uiSound(name)
    if GetResourceState(UI) == 'started' then exports[UI]:Sound(name) return true end
    return false
end
function RageUI.PlaySound(Library, Sound, IsLooped)
    if IsLooped or not uiSound(NATIVE_TO_UI[Sound] or 'click') then return _PlaySound(Library, Sound, IsLooped) end
end

-- Saute les séparateurs pendant la navigation (comme RageUI d'origine)
local function skipIndex(menu, Option)
    if menu.Index == Option then
        if RageUI.LastControl then
            menu.Index = Option - 1
            if menu.Index < 1 then menu.Index = menu.Options end
        else
            menu.Index = Option + 1
        end
    end
end

local function inPage(menu, Option)
    return menu.Pagination.Minimum <= Option and menu.Pagination.Maximum >= Option
end

-- ============ Structure ============
function RageUI.Banner() end
function RageUI.Background() end
function RageUI.Navigation() end
function RageUI.Description() end
function RageUI.ItemsDescription() end
function RageUI.ItemsSafeZone(menu)
    if not menu.SafeZoneSize then menu.SafeZoneSize = { X = 0, Y = 0 } end
end
function RageUI.ItemsMouseBounds() return false end

function RageUI.Subtitle()
    local menu = RageUI.CurrentMenu
    if menu ~= nil and menu() then
        RageUI.ItemsSafeZone(menu)
        menu.SubtitleHeight = 0
        if menu.Index > menu.Options or menu.Index < 0 then menu.Index = 1 end
        RageUI.RefreshPagination()
    end
end

function RageUI.IsVisible(menu, header, glare, instructional, items, panels)
    if RageUI.Visible(menu) then
        local m = RageUI.CurrentMenu
        if m == nil then return end
        frame = { t = m.Title, s = m.Subtitle, i = {} }
        RageUI.Subtitle()
        if items ~= nil then items() end
        if panels ~= nil then panels() end
        if frame then
            frame.c = m.PageCounter or ((m.Index or 1) .. ' / ' .. (RageUI.Options or 0))
            local encoded = json.encode(frame)
            lastFrame = GetGameTimer()
            if encoded ~= lastJson then
                lastJson = encoded
                shown = true
                uiCall('Update', frame)
            end
        end
        frame = nil
        RageUI.Render(false)
    end
end

local _CloseAll = RageUI.CloseAll
function RageUI.CloseAll()
    _CloseAll()
    hide()
end

CreateThread(function()
    while true do
        Wait(60)
        if shown and GetGameTimer() - lastFrame > 450 then hide() end   -- tolérance : un chargement de skin/modèle peut bloquer le menu quelques frames (évite le clignotement)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then hide() end
end)

-- ============ Éléments ============
function RageUI.ButtonWithStyle(Label, Description, Style, Enabled, Callback, Submenu)
    local menu = RageUI.CurrentMenu
    if menu ~= nil and menu() then
        local Option = RageUI.Options + 1
        if inPage(menu, Option) then
            Style = Style or {}
            local Active = menu.Index == Option
            local it = { k = 'b', l = Label, act = Active, en = Enabled and true or false, sub = Submenu ~= nil }
            if Enabled then
                it.r = Style.RightLabel
                it.lb = badgeName(Style.LeftBadge, Active)
                it.rb = badgeName(Style.RightBadge, Active)
            end
            if Style.Color then
                it.bg = Style.Color.BackgroundColor
                it.hl = Style.Color.HightLightColor
            end
            push(it)
            describe(Description, Active)

            if Enabled then
                local Selected = menu.Controls.Select.Active and Active
                if Callback then Callback(false, Active, Selected) end
                if Selected then
                    audio('Select')
                    if Submenu and Submenu() then RageUI.NextMenu = Submenu end
                end
            end
        end
        RageUI.Options = RageUI.Options + 1
    end
end

function RageUI.Button(Label, Description, Enabled, Callback, Submenu)
    return RageUI.ButtonWithStyle(Label, Description, {}, Enabled, Callback, Submenu)
end

function RageUI.Separator(Label)
    local menu = RageUI.CurrentMenu
    if menu ~= nil and menu() then
        local Option = RageUI.Options + 1
        if inPage(menu, Option) then
            push({ k = 's', l = Label })
            skipIndex(menu, Option)
        end
        RageUI.Options = RageUI.Options + 1
    end
end

function RageUI.Line()
    local menu = RageUI.CurrentMenu
    if menu ~= nil and menu() then
        local Option = RageUI.Options + 1
        if inPage(menu, Option) then
            push({ k = 'ln' })
            skipIndex(menu, Option)
        end
        RageUI.Options = RageUI.Options + 1
    end
end

local function listText(Items, Index)
    local v = Items[Index]
    if type(v) == 'table' then return tostring(v.Name) end
    return v ~= nil and tostring(v) or 'NIL'
end

function RageUI.List(Label, Items, Index, Description, Style, Enabled, Callback, onListChange, Submenu)
    local menu = RageUI.CurrentMenu
    if menu ~= nil and menu() then
        local Option = RageUI.Options + 1
        if inPage(menu, Option) then
            Style = Style or {}
            local Selected = menu.Index == Option
            local on = Enabled == true or Enabled == nil
            push({ k = 'l', l = Label, v = listText(Items, Index), r = on and Style.RightLabel or nil, act = Selected, en = on,
                   lb = on and badgeName(Style.LeftBadge, Selected) or nil })
            describe(Description, Selected)

            local C = menu.Controls
            if Selected and C.Left.Active and not C.Right.Active then
                Index = Index - 1
                if Index < 1 then Index = #Items end
                if onListChange ~= nil then onListChange(Index, Items[Index]) end
                audio('LeftRight')
            elseif Selected and C.Right.Active and not C.Left.Active then
                Index = Index + 1
                if Index > #Items then Index = 1 end
                if onListChange ~= nil then onListChange(Index, Items[Index]) end
                audio('LeftRight')
            end

            if Selected and C.Select.Active then
                audio('Select')
                if Submenu ~= nil and type(Submenu) == 'table' then RageUI.NextMenu = Submenu[Index] end
            end

            if Enabled then
                Callback(false, Selected, C.Select.Active and Selected, Index)
            end
        end
        RageUI.Options = RageUI.Options + 1
    end
end

function RageUI.List2(Label, Items, Index, Description, Style, Enabled, Actions, Submenu)
    local menu = RageUI.CurrentMenu
    if menu ~= nil and menu() then
        local Option = RageUI.Options + 1
        if inPage(menu, Option) then
            Style = Style or {}
            Actions = Actions or {}
            local Selected = menu.Index == Option
            local on = Enabled == true or Enabled == nil
            push({ k = 'l', l = Label, v = listText(Items, Index), r = on and Style.RightLabel or nil, act = Selected, en = on,
                   lb = on and badgeName(Style.LeftBadge, Selected) or nil })
            describe(Description, Selected)

            local C = menu.Controls
            if Selected and C.Left.Active and not C.Right.Active then
                Index = Index - 1
                if Index < 1 then Index = #Items end
                if Actions.onListChange ~= nil then Actions.onListChange(Index, Items[Index]) end
                audio('LeftRight')
            elseif Selected and C.Right.Active and not C.Left.Active then
                Index = Index + 1
                if Index > #Items then Index = 1 end
                if Actions.onListChange ~= nil then Actions.onListChange(Index, Items[Index]) end
                audio('LeftRight')
            end

            if Selected and C.Select.Active then
                audio('Select')
                if Actions.onSelected ~= nil then Actions.onSelected(Index, Items[Index]) end
                if Submenu ~= nil and type(Submenu) == 'table' then RageUI.NextMenu = Submenu[Index] end
            elseif Selected then
                if Actions.onActive ~= nil then Actions.onActive() end
            end
        end
        RageUI.Options = RageUI.Options + 1
    end
end

local function checkbox(Label, Description, Checked, Style, Callback, onChecked, onUnchecked)
    local menu = RageUI.CurrentMenu
    if menu ~= nil and menu() then
        local Option = RageUI.Options + 1
        if inPage(menu, Option) then
            Style = Style or {}
            local Selected = menu.Index == Option
            local enabled = Style.Enabled == true or Style.Enabled == nil
            push({ k = 'c', l = Label, act = Selected, en = enabled, ck = Checked and true or false,
                   cs = (Style.Style == RageUI.CheckboxStyle.Cross) and 'cross' or 'tick', r = enabled and Style.RightLabel or nil,
                   lb = enabled and badgeName(Style.LeftBadge, Selected) or nil })
            describe(Description, Selected)

            if Selected and menu.Controls.Select.Active then
                if enabled then
                    Checked = not Checked
                    if not uiSound(Checked and 'on' or 'off') then audio('Select') end
                else
                    audio('Error')
                    Checked = false
                end
                if Checked then
                    if onChecked then onChecked() end
                else
                    if onUnchecked then onUnchecked() end
                end
            end
            Callback(false, Selected, menu.Controls.Select.Active and Selected, Checked)
        end
        RageUI.Options = RageUI.Options + 1
    end
end
RageUI.Checkbox = checkbox
RageUI.Checkbox1 = checkbox

function RageUI.Info(Title, RightText, LeftText)
    RightText, LeftText = RightText or {}, LeftText or {}
    if not frame then return end
    local rows = {}
    for i = 1, math.max(#RightText, #LeftText) do
        rows[i] = { RightText[i] or '', LeftText[i] or '' }
    end
    frame.inf = { t = Title, r = rows }
end
