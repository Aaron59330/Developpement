---@type table
local SettingsButton = {
    Rectangle = { Y = 0, Width = 431, Height = 44 },
    Text = { X = 22, Y = 7, Scale = Config.RageUI.ScaleText },
}

function RageUI.Line()
    local CurrentMenu = RageUI.CurrentMenu
    if CurrentMenu ~= nil then
        if CurrentMenu() then
            local Option = RageUI.Options + 1
            if CurrentMenu.Pagination.Minimum <= Option and CurrentMenu.Pagination.Maximum >= Option then
                RenderThemeRectangle("Separator", CurrentMenu.X + 22, CurrentMenu.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset + 21, 431 + CurrentMenu.WidthOffset - 44, 1, 0)
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
