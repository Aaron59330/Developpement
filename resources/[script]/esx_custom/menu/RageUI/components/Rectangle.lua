---RenderRectangle
---
--- Reference : https://github.com/iTexZoz/NativeUILua_Reloaded/blob/master/UIElements/UIResRectangle.lua#L84
---
---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param R number
---@param G number
---@param B number
---@param A number
---@return nil
---@public
function RenderRectangle(X, Y, Width, Height, R, G, B, A)
    local X, Y, Width, Height = (tonumber(X) or 0) / 1920, (tonumber(Y) or 0) / 1080, (tonumber(Width) or 0) / 1920, (tonumber(Height) or 0) / 1080
    DrawRect(X + Width * 0.5, Y + Height * 0.5, Width, Height, tonumber(R) or 255, tonumber(G) or 255, tonumber(B) or 255, tonumber(A) or 255)
end


-- Load the sibling config regardless of the resource's RageUI folder path.
if RageUIStyle == nil and LoadResourceFile and GetCurrentResourceName then
    local source = debug.getinfo(1, "S").source
    local path = source:match("^@[^/]+/(.*)components/Rectangle%.lua$")
    local configPath = (path or "RageUI/") .. "config.lua"
    local content = LoadResourceFile(GetCurrentResourceName(), configPath)
    if content then
        local chunk, err = load(content, "@" .. configPath, "t", _ENV)
        if not chunk then error(err) end
        chunk()
    end
end
local styleDefaults = {
    Background = {82, 88, 98, 235},
    Shadow = {20, 25, 34, 85},
    Button = {55, 151, 255, 255},
    Text = {225, 229, 236, 255},
    SelectedText = {255, 255, 255, 255},
    DisabledText = {145, 151, 162, 255},
    Subtitle = {195, 202, 214, 255},
    CounterBackground = {35, 42, 55, 220},
    CounterText = {232, 238, 248, 255},
    Separator = {55, 151, 255, 255},
    SeparatorText = {165, 177, 195, 255},
    SeparatorLine = {165, 177, 195, 55},
    DescriptionBackground = {48, 55, 68, 235},
    DescriptionText = {222, 229, 240, 255},
    InfoBackground = {48, 55, 68, 235},
    InfoTitle = {255, 255, 255, 255},
    InfoLabel = {174, 193, 221, 255},
    InfoValue = {240, 244, 252, 255},
    Font = 0,
    DescriptionScale = 0.30,
    InfoScale = 0.30,
    InfoTitleScale = 0.36,
    KeepTextCodes = false,
    BannerGlare = false, -- GTA glare overlays the external banner.
}
RageUIStyle = RageUIStyle or {}
for key, value in pairs(styleDefaults) do
    if RageUIStyle[key] == nil then RageUIStyle[key] = value end
end

function RageUIThemeText(Text)
    if RageUIStyle.KeepTextCodes then return tostring(Text or "") end
    return tostring(Text or ""):gsub("~[rbgypocmuws]~", "")
end

function RenderThemeText(Key, Text, X, Y, Font, Scale, ...)
    local c = RageUIStyle[Key]
    RenderText(Text, X, Y, Font, Scale, c[1], c[2], c[3], c[4], ...)
end

function RenderThemeRectangle(Key, X, Y, Width, Height, Radius, SquareTop)
    local c = RageUIStyle[Key]
    RenderRoundedRectangle(X, Y, Width, Height, Radius, c[1], c[2], c[3], c[4], nil, SquareTop)
end

-- Antialiased PNGs embedded in Lua: no fxmanifest additions or external assets.
local smoothImages = {
    tl = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAADz0lEQVR4nOWbTasURxSGn6qZXDUK2ahoQKLGXGKCC0PQjcQPNBIC2YgEkWyyyjKbbPQPRIL+BsEQAoFkm0UkhAR040YRssg/uTP9ZnFO3amZ23Md752e/nph6Krp7pl6T52vOtUdaBkkBSACIYQwKjl/AHgHeB94DzgBHAMOAkeBobeHAGE1w94dMtKEEMYz594FPgLOAWcx0keAtUV+u9ECkBSBmM+0pP3ABeBT4ArwIfBGye0FIG+HOcdmCkDSAFAIofD+XuAycAO4iql4jjFGdlNTWJBbowTgxIsQgrx/GvgKuAmcyi4t/BMxDjvm0QgBSBrkti3pGvAN8Dmwx7/OScctP9JGSIpu56l/Q9LfmsaGpLEqQl3Eg6Rh1r8m6Z9sXGNJI0lFVcRrE4DMzlP7jKRfs/GMVOFsl2FlPsD/K4YQxpL2AXeA7zAbL/yyldv2SgQgKWYh7TpwH4vfYCFsMO/eqlG5xCUNQwiFpD2SHgC/Y+RHWOyujTxUrAFOfiSL5w+xdLU2dS9DJYOQefno5G8DTzDyIxoWx5c+ECcuV/vvgR+BtzBbH25/9+qxVBOQZ3SS3sRU/iY264Nl/9eysLRBZeQPA78AnwAblK/UGoOlCCAjfwT4A/PyjScPSxDADPnHwAeY2jfO3suwKyfYdvKwCw1I2Z2kg8BftJA87FAD0hrCc/rfaCl52IEAnPzAc/tHWH1ugxaSh51pwMAzvHtYja4V3n4eXssHZLn9LeAnWk4eXkMAmdNbB54B+5gUJVuLhUzA7T5IWgN+Bg74qVaTh8V9QKra3sN2X1J+33q8cgazZOcKluy0MtzNw7YCSKqP7bM9xzYnRIPW87vFq4ikWt5dbNNxvMA9rcJcDZBtWAhYB14wWdO33vHl2G42g+/R/YDF+rT52CmUEsoc3yXgT2ouXVeJeQJI6v8UK2Z2VgBbTMBnvwC+oOPkodwHpA3DO1m7s5gSgPzJDLf9czRg56ZqbNEA9/zfereYPd81bDrBbLV3CnjJZJnbudCXI5a0v8ZS3zEdJw/TGpBy/n+B40yex+k0ImyGPgEX6RF52EryS8zzd975JQRJIYQgL3H/B7xNzzQgEb1Az8jDdFHzM3qm/mACGHsEuMr0s7a9QHTvfxw47d91PvbnSLP9MVbo7EXykyMJ4LwfO7/6m0USwFk/9mr2AaLsDYz11K9zMHUgYm9fHK57IHUhYm9XrWHxv38mwET9e+cAwQRwsu5B1InkA3qLiL1FCT20fzABHPJ2bwWw0CumXUWQ1NpH3JaBSI/JQw9T31n8D576ysRpomNAAAAAAElFTkSuQmCC",
    tr = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAD00lEQVR4nOWaT4scRRyGn3dmskEUvKhILgbREA0RgrK5BFSMBy9eggh6CX4CwZvexSXgl1BQkOjViImiASEHPa2RuKJB0CA5qomZnn49VNV2bzsbd7I9O9NdLwzdO9Oz3fXM+/vTVS3bJqgArsft73H/V+Bn4EfgB+CqpD9pyPYIMFBKcvPzZZZqAP5Pt4BrBBjfAZeAbyX9VD/I9jDudgJGE4C32QoYTPn+GFgHLgCfARcl/bX5z4IzSkllq1fdomZxQDqujPsCho1jrgKfA2eBLyTdBLA9ACRpsvtLblezAJgmx1dJcEjdJRvAR8B7ki4D2BYwWCoQblcT2+O4Tbpp+6zt5xvnbbpnMWoZwDQYdX1t+1Tt3AOH8Fic5gggqbRdeKsrLrrmCNsjh/DoJYC6JhFG0se2j9auZc/DYrdJ8E6VyuIA+Ac4A7wt6UaEsGc9xKIAJE2oSuk68IakcxDyw170D4tNQGHwJrTfR4BPbb9re7+k0qGRmqsW7YC66mFxCTgt6bLtkaRiXiddtAPqSo1UAawC39h+VVLhUC7nUiWWCUDSiJAb7gXet/2OpFKSPYeeYZlCoCkTQIwILfVpSX/bHrbZSi8zgKQxsA/4CnhJ0h9tQugCAKggrAMnJV1rC8Iy5oBp2kdVKs/bflDSpI3OsSsAIOSCAnicFiF0JQTqKggwvgeelnR9N11jlxyQVHfCJ7bvgs3JlpnVRQAQIIyBE4QZpxIY3gmErgKAkBjHwCnba7FdnjkfdDEHNJVK5CuSPpj13qEPANKk7A3gSUlXZkmKXQ6BpBT39wAf2l4h/LA7ygd9AAAh9gvgGLAWO8Qd5YM+hEBdqUd4TtKFnbTLfQNQEkJiA3iCsJ7p280v9iUEkgaEW+hHgbdiIrztGPvmAKiW6ybAUeAKYV1yalXomwMghIAJvcGZaP9tK0IfHZCUKsGzkr7cLiH20QFNrcWeYOoP3WcAQ4ILVoEX4zrDf3qDPgNIMvBmbX+L+g4grTyt2n6GsBa8xQV9BwDVitPr0xqiPleBpDS+MXBE0kb9bjEHB4iQDFeA1+J7m+POwQFQPcT1C3AYuJXCIQcHQBhnCRwkzCRvJsNcAED1fOPL9TdzCQGowuA34JH4OI5yckAKgwOE6XSAQU4AoAqDF+LfWTkAggsEnIw3SJPcAKR5gceAg5IW/Jjq3is1RSPgKcirDCalqncc8gSQwuAY5AkgjfmQ7btzBJD0APBQjgBE6AdWgMM5AoAqER7KFUDSw7kDyDIHQFUK78sdwP25AkhayWlCZJqK3B0wyh0A/wJIj3YrEpZZBwAAAABJRU5ErkJggg==",
    bl = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAD3ElEQVR4nOWbz29UVRTHP+fOVGk0cdOFmBgkVAISF5jIypCoFGJYNroxbA3/gCHhDzDRxOjGvbuGaNiwgBhiBF20CYYEgmjTENgRhCUoMjPHxTm3czPMtNN25t3347t5982bNz33++75nh/3VVRVaTBCbgNyIwCd3EbkRAAe+biRrhCA/3IbkRMB+NvHjV0BD33cWALu5TYiJwJwJ7cRORGAVR9LTkNyIQB/YpEg0EAdiBrwILchuRBE5DF9N+jlNCYHYi1w3Y+NdAGAFT82TggjAdewoqhFw1ZBUFUB7gK3/bNmEQC0RESBy9jkGyWEaey/iGlAo5okoqoiIqqqs8Aa8Bq2ChpBRPDJt0TkH+ASDXODwad8joa5wXrc92jwAlYbvEFD3CCdYEtEngJLft4IN0hXQBCRnqrOA7eAmcHv1BHrK8An3xKRNfohsZvNsoLwnI+7Fnw76nrd8NzyTlxhBXgX04JW4ZYVhGFPOJLyBTX3fxgxQVWNKfIycATTglquglE+Ll4gnSnSmBwYSoCIdD0i/AJcwJ5+LSPCSB9P3GA/cBMjQTa6p4oYGeZEpIcVS38BX/p3a7cKNnyanhPEGuEGMI+titrkBxtOxIVQRORf4DRGRq1qhE2fpAtiW0R+xjLENjV6q2QsQXNXCJgQLgOHqUluMLaiJynyfuB3YBYjpdJRYWwx88m3RWQV+Ax7+pV3hS2puYh0nIQl4CusZ/BsKpYVhC0vX9eDlpPxI7CIkTCz8Z3lxLb8N8kPXgR+At7D3KE9OdOKwbYFLBHFOeAK8BYVJGHbGV3SQnsIfAj8QQVzhB2ltEnVeJ+KkrDjnH4ICbcwEioRHSZS1AyQ8AFwlYqEyIlVdQkJD4CPgB8wEjqU+J2DiZa1TkIQkSci8gnWR2hT4j2GqeTxMU/wSPEp8B3wCiUMk1MtZDxt7qjqQeB7rMMc+wmlaKpM1YikdrgNHAW+8b8Z/1MluzYUUsrGrNHHJ4CvgUN+OWtfobBaPjZVXChngbPA51g9USq3mCpUtZWM31bV89pHR1W7WiBykSCq2k7OF1T1t8SurpPRqyUBycSD2gZMPF9U1V8HbHymU1wVpejnqWWQ3eR8AWvDn8Q0Akwn4ntLk8tgJ/VDk4CaPvR8PwK1/OEU8DG2KRORkrGj7bpSERDhRGgSOncB72Ptt2PAnoFbulhOkb7iN9bcSklAhOtDEJFO8tlLWAvuOFZ5HmJ4P7JHP9GSEcdyExCh/Y0ZUq3wa/uAd7A0+zDwJvAqtp+5KSpBQIqEDElXRnL9ZcxFDmBk7AVeB+aA3VgxNudH/geilL9/QptnrAAAAABJRU5ErkJggg==",
    br = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAADg0lEQVR4nOWazY8MURTFf6e7/ScWEhlbVhaExFKIWFqJxNLCfyDBgv9BRETGxsJHBGE2PsKKYQxmImHCWEgwH93V1+K9y9O6x/Tome6qd5JOdVdXquqce+69r94rmZmRMWrDvoFhI3cBWrkK4Gn/JVcBHMu5CuAO+Jy7APO5CuCYzV2At7kKoLidylEAI4x/loGXOQrg+ESmNaAdt1OSvucogLfAZ5Dns4AXwIeQnwAG1IEW8ATyFABgEpgxM+UmQJsgwm1JBtRzE6BGqAHX429TRlNibYIAH4DNkhZySwG3/41Ivi7JchLA7X853ZlLCrj9Z4AtwHIsgtm0QR/+XpK0RBgLAHk4wPk1ga2Sps2sJqkNeTigILa+SL7u5CEPAZzjeTNT559VT4GCIMBjSdtT6ztycICAU8n3P/+ssAMKQrV/BOwA1Bl9yMMBJ2PP/yv6UF0BPPrXJN2Llb/odmAVU8DipwDGgCl62B+q6QCv/KclvQL+qvwpquaANiHXp4FthLl/83F/N1TNAS7AMUmLBOuvGOAqCdACGsB5SXfMrNGr8KWoSgp41X9G6PkF0P5X9KEaDnCS34DDkv6Z9ymqIECLEP2jkqai9XtW/U6UXYAmsAk4I+lSJN/q5wRlrgFOflzSQTNrAMVqre8oqwBe8SeAvcASfeR9ijKmgJN/AeyXtACwFvJQPgFS8rslzXdOcfWLMgnQSX5upae81aIsAjQJ5J8zQPJQDgG82t8Hdg2SPIy2AEaw/SbgCrBP0qdBkofRFcDn8huE5/pDkn7EWd2BkSdeYNTgxe4rcFzSRTOrEfr8mqt9L4ySAE6uQZjJPSJpci3D234wCinguV6Ln3PAzo0gD8MfCvtzPIQWd0LSTYBuqzjrgWGlgBOrE8bxZ4FT/uYGYTJj3ckDYBuLwsxaye+rZjaW3Et9pXstqwDtSLpI9k2Y2Z7kHhrWZeW27AIUZtbs2PfAzA4k166ZDfk9pXUinUZ70czGLYl4vO7G270L/rcL+DKUv4SURnOaMIS9IGkSwILNBz6a+x/0I4Af5+/bieRlo4hZ4DYwDtyNixNEm2uUiDs626D12Irf0U1JNwn9+w5wC5iQ9P3XycI83ca1tDWgHwcsA3PAa8ICxCPgqaQ36UFJbq9qYWLYSB3QAubj9mP8/h54RyD9EpiV9K3zJDHSRiA9cjZfCT8B1dlO79VDbCMAAAAASUVORK5CYII=",
    selection = "data:image/png;base64,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",
}
local smoothDictionary = nil
local function EnsureSmoothTextures()
    if not smoothDictionary then
        smoothDictionary = "rageui_smooth_" .. GetCurrentResourceName()
        local txd = CreateRuntimeTxd(smoothDictionary)
        for name, data in pairs(smoothImages) do
            CreateRuntimeTextureFromImage(txd, name, data)
        end
    end
    return smoothDictionary
end

local function SmoothSprite(name, X, Y, Width, Height, R, G, B, A)
    if Width <= 0 or Height <= 0 then return end
    DrawSprite(EnsureSmoothTextures(), name, (X + Width / 2) / 1920,
        (Y + Height / 2) / 1080, Width / 1920, Height / 1080,
        0, R or 255, G or 255, B or 255, A or 255)
end

function RenderRoundedRectangle(X, Y, Width, Height, Radius, R, G, B, A, Bottom, SquareTop)
    if Width <= 0 or Height <= 0 then return end
    Radius = math.max(0, math.min(Radius, Width / 2, Height / 2))
    -- Disjoint regions keep translucent joins at the same opacity.
    if Radius == 0 then
        RenderRectangle(X, Y, Width, Height, R, G, B, A)
        return
    end
    if Width > Radius * 2 then
        RenderRectangle(X + Radius, Y, Width - Radius * 2, Height, R, G, B, A)
    end
    if Height > Radius * 2 then
        RenderRectangle(X, Y + Radius, Radius, Height - Radius * 2, R, G, B, A)
        RenderRectangle(X + Width - Radius, Y + Radius, Radius, Height - Radius * 2, R, G, B, A)
    end
    if SquareTop then
        RenderRectangle(X, Y, Radius, Radius, R, G, B, A)
        RenderRectangle(X + Width - Radius, Y, Radius, Radius, R, G, B, A)
    else
        SmoothSprite("tl", X, Y, Radius, Radius, R, G, B, A)
        SmoothSprite("tr", X + Width - Radius, Y, Radius, Radius, R, G, B, A)
    end
    SmoothSprite("bl", X, Y + Height - Radius, Radius, Radius, R, G, B, A)
    SmoothSprite("br", X + Width - Radius, Y + Height - Radius, Radius, Radius, R, G, B, A)
end

function RenderMenuSelection(X, Y, Width, Height)
    RenderRoundedRectangle(X + 8, Y + 4, Width - 16, Height - 8, 14, 16, 35, 58, 70)
    local c = RageUIStyle.Button
    SmoothSprite("selection", X + 8, Y + 2, Width - 16, Height - 8, c[1], c[2], c[3], c[4])
end

