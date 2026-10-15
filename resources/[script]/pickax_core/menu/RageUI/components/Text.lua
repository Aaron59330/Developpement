
---MeasureStringWidth
---
--- Reference : Frazzle <3
---
---@param str string
---@param font number
---@param scale number
---@return _G
---@public
function MeasureStringWidth(str, font, scale)
    BeginTextCommandWidth("CELL_EMAIL_BCON")
    AddText(str)
    SetTextFont(font or 0)
    SetTextScale(1.0, scale or 0)
    return EndTextCommandGetWidth(true) * 1920
end

---GetCharacterCount
---
--- Reference : Frazzle <3
---
---@param Str string
---@return number
---@public
function GetCharacterCount(Str)
    ---@type number
    local Chars = 0

    for Char in Str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        Chars = Chars + 1
    end

    return Chars
end

---AddText
---
--- Reference : Frazzle <3
---
---@param Text string
---@return nil
---@public
function AddText(Text)
    Text = tostring(Text or "")
    local chunk = ""
    local index = 1
    while index <= #Text do
        local token
        -- Keep GTA formatting tokens and UTF-8 characters in one component.
        if Text:sub(index, index) == "~" then
            local finish = Text:find("~", index + 1, true)
            if finish and finish - index < 99 then
                token = Text:sub(index, finish)
            end
        end
        if not token then
            token = Text:match("^[%z\1-\127\194-\244][\128-\191]*", index)
                or Text:sub(index, index)
        end
        if #chunk + #token > 99 then
            AddTextComponentSubstringPlayerName(chunk)
            chunk = ""
        end
        chunk = chunk .. token
        index = index + #token
    end
    if chunk ~= "" or Text == "" then
        AddTextComponentSubstringPlayerName(chunk)
    end
end

function RageUIUtf8Prefix(Text, Count)
    local result, length = {}, 0
    for char in tostring(Text or ""):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if length >= Count then break end
        result[#result + 1] = char
        length = length + 1
    end
    return table.concat(result)
end

local frenchUpper = {
    ["à"]="À", ["â"]="Â", ["ä"]="Ä", ["æ"]="Æ",
    ["ç"]="Ç", ["é"]="É", ["è"]="È", ["ê"]="Ê", ["ë"]="Ë",
    ["î"]="Î", ["ï"]="Ï", ["ô"]="Ô", ["ö"]="Ö", ["œ"]="Œ",
    ["ù"]="Ù", ["û"]="Û", ["ü"]="Ü", ["ÿ"]="Ÿ",
}
function RageUIUtf8Upper(Text)
    local text = tostring(Text or ""):gsub("[%z\1-\127\194-\244][\128-\191]*", frenchUpper)
    return string.upper(text)
end

---GetLineCount
---
--- Reference : Frazzle <3
---
---@param Text string
---@param X number
---@param Y number
---@param Font number
---@param Scale number
---@param R number
---@param G number
---@param B number
---@param A number
---@param Alignment string
---@param DropShadow boolean
---@param Outline boolean
---@param WordWrap number
---@return function
---@public
function GetLineCount(Text, X, Y, Font, Scale, R, G, B, A, Alignment, DropShadow, Outline, WordWrap)

    ---@type table
    local Text, X, Y = tostring(Text), (tonumber(X) or 0) / 1920, (tonumber(Y) or 0) / 1080

    SetTextFont(Font or 0)
    SetTextScale(1.0, Scale or 0)
    SetTextColour(tonumber(R) or 255, tonumber(G) or 255, tonumber(B) or 255, tonumber(A) or 255)

    if DropShadow then
        SetTextDropShadow()
    end

    if Outline then
        SetTextOutline()
    end

    if Alignment ~= nil then
        if Alignment == 1 or Alignment == "Center" or Alignment == "Centre" then
            SetTextCentre(true)
        elseif Alignment == 2 or Alignment == "Right" then
            SetTextRightJustify(true)
        end
    end

    if tonumber(WordWrap) and tonumber(WordWrap) ~= 0 then
        if Alignment == 1 or Alignment == "Center" or Alignment == "Centre" then
            SetTextWrap(X - ((WordWrap / 1920) / 2), X + ((WordWrap / 1920) / 2))
        elseif Alignment == 2 or Alignment == "Right" then
            SetTextWrap(0, X)
        else
            SetTextWrap(X, X + (WordWrap / 1920))
        end
    else
        if Alignment == 2 or Alignment == "Right" then
            SetTextWrap(0, X)
        end
    end

    BeginTextCommandLineCount("CELL_EMAIL_BCON")
    AddText(Text)
    return GetTextScreenLineCount(X, Y)
end


---RenderText
---
--- Reference : https://github.com/iTexZoz/NativeUILua_Reloaded/blob/master/UIElements/UIResText.lua#L189
---
---@param Text string
---@param X number
---@param Y number
---@param Font number
---@param Scale number
---@param R number
---@param G number
---@param B number
---@param A number
---@param Alignment string
---@param DropShadow boolean
---@param Outline boolean
---@param WordWrap number
---@return nil
---@public
function RenderText(Text, X, Y, Font, Scale, R, G, B, A, Alignment, DropShadow, Outline, WordWrap)

    ---@type table
    local Text, X, Y = tostring(Text), (tonumber(X) or 0) / 1920, (tonumber(Y) or 0) / 1080

    SetTextFont(Font or 0)
    SetTextScale(1.0, Scale or 0)
    SetTextColour(tonumber(R) or 255, tonumber(G) or 255, tonumber(B) or 255, tonumber(A) or 255)

    if DropShadow then
        SetTextDropShadow()
    end

    if Outline then
        SetTextOutline()
    end

    if Alignment ~= nil then
        if Alignment == 1 or Alignment == "Center" or Alignment == "Centre" then
            SetTextCentre(true)
        elseif Alignment == 2 or Alignment == "Right" then
            SetTextRightJustify(true)
        end
    end

    if tonumber(WordWrap) and tonumber(WordWrap) ~= 0 then
        if Alignment == 1 or Alignment == "Center" or Alignment == "Centre" then
            SetTextWrap(X - ((WordWrap / 1920) / 2), X + ((WordWrap / 1920) / 2))
        elseif Alignment == 2 or Alignment == "Right" then
            SetTextWrap(0, X)
        else
            SetTextWrap(X, X + (WordWrap / 1920))
        end
    else
        if Alignment == 2 or Alignment == "Right" then
            SetTextWrap(0, X)
        end
    end

    BeginTextCommandDisplayText("CELL_EMAIL_BCON")
    AddText(Text)
    EndTextCommandDisplayText(X, Y)
end
