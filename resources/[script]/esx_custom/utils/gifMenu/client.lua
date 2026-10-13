local banners = {}
local stopping = false

local function encodeUrl(value)
    return (tostring(value):gsub("([^%w%-_%.~])", function(char)
        return string.format("%%%02X", string.byte(char))
    end))
end

if ConfigMenuGIF.Active then
    Citizen.CreateThread(function()
        for index, entry in pairs(ConfigMenuGIF.AllTexture) do
            if entry.Active then
                RequestStreamedTextureDict(entry.dictionaryName, true)
                while not HasStreamedTextureDictLoaded(entry.dictionaryName) do
                    if stopping then return end
                    Wait(150)
                end
                local url = "https://cfx-nui-" .. GetCurrentResourceName()
                    .. "/utils/gifMenu/banner.html?image=" .. encodeUrl(entry.link)
                local dui = CreateDui(url, 512, 128)
                local banner = {dui = dui, dictionary = entry.dictionaryName, texture = entry.textureName}
                banners[#banners + 1] = banner
                while not IsDuiAvailable(dui) do
                    if stopping then return end
                    Wait(0)
                end
                local dictionary = "ESXCustomBanner_" .. tostring(index)
                local texture = "banner"
                CreateRuntimeTextureFromDuiHandle(CreateRuntimeTxd(dictionary), texture, GetDuiHandle(dui))
                AddReplaceTexture(entry.dictionaryName, entry.textureName, dictionary, texture)
                banner.replaced = true
            end
        end
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    stopping = true
    for _, banner in ipairs(banners) do
        if banner.replaced then RemoveReplaceTexture(banner.dictionary, banner.texture) end
        DestroyDui(banner.dui)
    end
end)
