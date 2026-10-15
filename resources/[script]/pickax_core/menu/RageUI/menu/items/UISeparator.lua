---@type table
local SettingsButton = {
    Rectangle = { Y = 0, Width = 431, Height = 44 },
    Text = { X = 22, Y = 7, Scale = Config.RageUI.ScaleText },
}

function RageUI.Separator(Label)
    local CurrentMenu = RageUI.CurrentMenu
    if CurrentMenu ~= nil then
        if CurrentMenu() then
            local Option = RageUI.Options + 1
            if CurrentMenu.Pagination.Minimum <= Option and CurrentMenu.Pagination.Maximum >= Option then
                if (Label ~= nil) then
                    local y = CurrentMenu.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset + 20
                    local text = RageUIUtf8Upper(Label)
                    RenderThemeRectangle("Separator", CurrentMenu.X + 22, y + 7, 8, 2, 1)
                    RenderThemeText("SeparatorText", text, CurrentMenu.X + 40, y, RageUIStyle.Font, 0.25)
                    local labelWidth = MeasureStringWidth(text, 0, 0.25)
                    local lineX = 50 + labelWidth
                    local lineWidth = 431 + CurrentMenu.WidthOffset - lineX - 22
                    if lineWidth > 0 then
                        RenderThemeRectangle("SeparatorLine", CurrentMenu.X + lineX, y + 8, lineWidth, 1, 0)
                    end
                end
                RageUI.ItemOffset = RageUI.ItemOffset + SettingsButton.Rectangle.Height
                if (CurrentMenu.Index == Option) then
                    if (RageUI.LastControl) then
                        CurrentMenu.Index = Option - 1
                        if (CurrentMenu.Index < 1) then
                            CurrentMenu.Index = RageUI.CurrentMenu.Options
                        end
                    else
                        CurrentMenu.Index = Option + 1
                    end
                end
            end
            RageUI.Options = RageUI.Options + 1
        end
    end
end

