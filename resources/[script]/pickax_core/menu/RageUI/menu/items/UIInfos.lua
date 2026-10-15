-- Existing API preserved: RightText is the left column, LeftText the right.
function RageUI.Info(Title, RightText, LeftText)
    RightText, LeftText = RightText or {}, LeftText or {}
    local menu = RageUI.CurrentMenu
    local width = 432
    local x = menu and (menu.X + 431 + menu.WidthOffset + 12) or (Config.RageUI.Width + 440)
    local y = menu and menu.Y or Config.RageUI.MenuPose.Y
    local count = math.max(#RightText, #LeftText)
    local rowHeight = math.max(24, RageUIStyle.InfoScale * 72)
    local offset = Title ~= nil and 52 or 18
    local height = offset + count * rowHeight + 14
    RenderThemeRectangle("Shadow", x, y + 2, width, height, 18)
    RenderThemeRectangle("Background", x, y, width, height, 18)
    if Title ~= nil then
        RenderThemeText("InfoTitle", "~h~" .. RageUIThemeText(Title) .. "~h~",
            x + 20, y + 12, RageUIStyle.Font, RageUIStyle.InfoTitleScale)
        RenderThemeRectangle("Separator", x + 20, y + 42, 28, 2, 1)
        RenderThemeRectangle("SeparatorLine", x + 58, y + 42, width - 78, 1, 0)
    end
    for i = 1, count do
        local rowY = y + offset + (i - 1) * rowHeight
        RenderThemeText("InfoLabel", RageUIThemeText(RightText[i]), x + 20, rowY,
            RageUIStyle.Font, RageUIStyle.InfoScale, nil, false, false, width - 40)
        RenderThemeText("InfoValue", RageUIThemeText(LeftText[i]), x + width - 20, rowY,
            RageUIStyle.Font, RageUIStyle.InfoScale, 2)
    end
end
