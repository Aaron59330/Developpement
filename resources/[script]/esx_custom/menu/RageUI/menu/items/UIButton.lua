---@type table
local SettingsButton = {
    Rectangle = { Y = 0, Width = 431, Height = 44 },
    Text = { X = 22, Y = 7, Scale = Config.RageUI.ScaleText },
    LeftBadge = { Y = -2, Width = 40, Height = 40 },
    RightBadge = { X = 385, Y = -2, Width = 40, Height = 40 },
    RightText = { X = 405, Y = 7, Scale = Config.RageUI.ScaleText },
    SelectedSprite = { Dictionary = "commonmenu", Texture = "gradient_nav", Y = 0, Width = 431, Height = 44 },
}

---Button
---@param Label string
---@param Description string
---@param Enabled boolean
---@param Callback function
---@param Submenu table
---@return nil
---@public
function RageUI.Button(Label, Description, Enabled, Callback, Submenu)
    local CurrentMenu = RageUI.CurrentMenu
    if CurrentMenu ~= nil and CurrentMenu() then
        ---@type number
        local Option = RageUI.Options + 1

        if CurrentMenu.Pagination.Minimum <= Option and CurrentMenu.Pagination.Maximum >= Option then
            ---@type boolean
            local Active = CurrentMenu.Index == Option

            RageUI.ItemsSafeZone(CurrentMenu)

            if Active then
                RenderMenuSelection(CurrentMenu.X, CurrentMenu.Y + SettingsButton.SelectedSprite.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, SettingsButton.SelectedSprite.Width + CurrentMenu.WidthOffset, SettingsButton.SelectedSprite.Height)
            end

            local colorData = Enabled and (Active and { 255, 255, 255 } or { 255, 255, 255 }) or { 163, 159, 148 }
            RenderThemeText(Enabled and (Active and "SelectedText" or "Text") or "DisabledText", Label, CurrentMenu.X + SettingsButton.Text.X, CurrentMenu.Y + SettingsButton.Text.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, 0, SettingsButton.Text.Scale)

            if Submenu then
                RenderThemeText("Subtitle", ">", CurrentMenu.X + 405 + CurrentMenu.WidthOffset, CurrentMenu.Y + 7 + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, 0, 0.3, 2)
            end

            RageUI.ItemOffset = RageUI.ItemOffset + SettingsButton.Rectangle.Height

            RageUI.ItemsDescription(CurrentMenu, Description, Active);

            if Enabled then
                ---@type boolean
                local Hovered = CurrentMenu.EnableMouse and (CurrentMenu.CursorStyle == 0 or CurrentMenu.CursorStyle == 1) and RageUI.ItemsMouseBounds(CurrentMenu, Active, Option + 1, SettingsButton);
                local Selected = (CurrentMenu.Controls.Select.Active or (Hovered and CurrentMenu.Controls.Click.Active)) and Active

                if Callback then
                    Callback(Hovered, Active, Selected)
                end

                if Selected then
                    local Audio = RageUI.Settings.Audio
                    RageUI.PlaySound(Audio[Audio.Use].Select.audioName, Audio[Audio.Use].Select.audioRef)

                    if Submenu and Submenu() then
                        RageUI.NextMenu = Submenu
                    end
                end
            end
        end

        RageUI.Options = RageUI.Options + 1
    end
end

---ButtonWithStyle
---@param Label string
---@param Description string
---@param Style table
---@param Enabled boolean
---@param Callback function
---@param Submenu table
---@return nil
---@public
function RageUI.ButtonWithStyle(Label, Description, Style, Enabled, Callback, Submenu)
    local CurrentMenu = RageUI.CurrentMenu
    if CurrentMenu ~= nil and CurrentMenu() then
        ---@type number
        local Option = RageUI.Options + 1

        if CurrentMenu.Pagination.Minimum <= Option and CurrentMenu.Pagination.Maximum >= Option then
            ---@type boolean
            local Active = CurrentMenu.Index == Option

            RageUI.ItemsSafeZone(CurrentMenu)

            local haveLeftBadge = Style.LeftBadge and Style.LeftBadge ~= RageUI.BadgeStyle.None
            local haveRightBadge = (Style.RightBadge and Style.RightBadge ~= RageUI.BadgeStyle.None) or (not Enabled and Style.LockBadge ~= RageUI.BadgeStyle.None)

            local LeftBadgeOffset = haveLeftBadge and 27 or 0
            local RightBadgeOffset = haveRightBadge and 32 or 0

            if Style.Color and Style.Color.BackgroundColor then
                RenderRectangle(CurrentMenu.X, CurrentMenu.Y + SettingsButton.SelectedSprite.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, SettingsButton.SelectedSprite.Width + CurrentMenu.WidthOffset, SettingsButton.SelectedSprite.Height, Style.Color.BackgroundColor[1], Style.Color.BackgroundColor[2], Style.Color.BackgroundColor[3])
            end

            if Active then
                if Style.Color and Style.Color.HightLightColor then
                    RenderRectangle(CurrentMenu.X, CurrentMenu.Y + SettingsButton.SelectedSprite.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, SettingsButton.SelectedSprite.Width + CurrentMenu.WidthOffset, SettingsButton.SelectedSprite.Height, Style.Color.HightLightColor[1], Style.Color.HightLightColor[2], Style.Color.HightLightColor[3])
                else
                    RenderMenuSelection(CurrentMenu.X, CurrentMenu.Y + SettingsButton.SelectedSprite.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, SettingsButton.SelectedSprite.Width + CurrentMenu.WidthOffset, SettingsButton.SelectedSprite.Height)
                end
            end

            if Enabled then
                if haveLeftBadge then
                    local LeftBadge = Style.LeftBadge(Active)
                    RenderSprite(LeftBadge.BadgeDictionary or "commonmenu", LeftBadge.BadgeTexture or "", CurrentMenu.X, CurrentMenu.Y + SettingsButton.LeftBadge.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, SettingsButton.LeftBadge.Width, SettingsButton.LeftBadge.Height, 0, LeftBadge.BadgeColour and LeftBadge.BadgeColour.R or 255, LeftBadge.BadgeColour and LeftBadge.BadgeColour.G or 255, LeftBadge.BadgeColour and LeftBadge.BadgeColour.B or 255, LeftBadge.BadgeColour and LeftBadge.BadgeColour.A or 255)
                end

                if haveRightBadge then
                    local RightBadge = Style.RightBadge(Active)
                    RenderSprite(RightBadge.BadgeDictionary or "commonmenu", RightBadge.BadgeTexture or "", CurrentMenu.X + SettingsButton.RightBadge.X + CurrentMenu.WidthOffset, CurrentMenu.Y + SettingsButton.RightBadge.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, SettingsButton.RightBadge.Width, SettingsButton.RightBadge.Height, 0, RightBadge.BadgeColour and RightBadge.BadgeColour.R or 255, RightBadge.BadgeColour and RightBadge.BadgeColour.G or 255, RightBadge.BadgeColour and RightBadge.BadgeColour.B or 255, RightBadge.BadgeColour and RightBadge.BadgeColour.A or 255)
                end

                if Style.RightLabel then
                    RenderThemeText(Active and "SelectedText" or "Text", Style.RightLabel, CurrentMenu.X + SettingsButton.RightText.X - RightBadgeOffset + CurrentMenu.WidthOffset, CurrentMenu.Y + SettingsButton.RightText.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, 0, SettingsButton.RightText.Scale, 2)
                end

                RenderThemeText(Active and "SelectedText" or "Text", Label, CurrentMenu.X + SettingsButton.Text.X + LeftBadgeOffset, CurrentMenu.Y + SettingsButton.Text.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, 0, SettingsButton.Text.Scale)
            else
                if haveRightBadge then
                    local RightBadge = RageUI.BadgeStyle.Lock(Active)
                    RenderSprite(RightBadge.BadgeDictionary or "commonmenu", RightBadge.BadgeTexture or "", CurrentMenu.X + SettingsButton.RightBadge.X + CurrentMenu.WidthOffset, CurrentMenu.Y + SettingsButton.RightBadge.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, SettingsButton.RightBadge.Width, SettingsButton.RightBadge.Height, 0, RightBadge.BadgeColour and RightBadge.BadgeColour.R or 255, RightBadge.BadgeColour and RightBadge.BadgeColour.G or 255, RightBadge.BadgeColour and RightBadge.BadgeColour.B or 255, RightBadge.BadgeColour and RightBadge.BadgeColour.A or 255)
                end

                RenderThemeText("DisabledText", Label, CurrentMenu.X + SettingsButton.Text.X + LeftBadgeOffset, CurrentMenu.Y + SettingsButton.Text.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, 0, SettingsButton.Text.Scale)
            end

            if Submenu and not Style.RightLabel and not haveRightBadge then
                RenderThemeText("Subtitle", ">", CurrentMenu.X + 405 + CurrentMenu.WidthOffset, CurrentMenu.Y + 7 + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, 0, 0.3, 2)
            end

            RageUI.ItemOffset = RageUI.ItemOffset + SettingsButton.Rectangle.Height

            RageUI.ItemsDescription(CurrentMenu, Description, Active);

            if Enabled then
                ---@type boolean
                local Hovered = CurrentMenu.EnableMouse and (CurrentMenu.CursorStyle == 0 or CurrentMenu.CursorStyle == 1) and RageUI.ItemsMouseBounds(CurrentMenu, Active, Option + 1, SettingsButton);
                local Selected = (CurrentMenu.Controls.Select.Active or (Hovered and CurrentMenu.Controls.Click.Active)) and Active

                if Callback then
                    Callback(Hovered, Active, Selected)
                end

                if Selected then
                    local Audio = RageUI.Settings.Audio
                    RageUI.PlaySound(Audio[Audio.Use].Select.audioName, Audio[Audio.Use].Select.audioRef)

                    if Submenu and Submenu() then
                        RageUI.NextMenu = Submenu
                    end
                end
            end

        end

        RageUI.Options = RageUI.Options + 1
    end
end
