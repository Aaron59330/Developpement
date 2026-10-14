
---- event from server to show notification
RegisterNetEvent("RageUI:Popup")
AddEventHandler("RageUI:Popup", function(array)
    RageUI.Popup(array)
end)

---Popup
---@param array table
---@public
function RageUI.Popup(array)
    if (array.message == nil) then error("Missing arguments, message") end
    ESX.ShowNotification(tostring(array.message))
    if (array.sound ~= nil and array.sound.audio_name ~= nil and array.sound.audio_ref ~= nil) then
        PlaySoundFrontend(-1, array.sound.audio_name, array.sound.audio_ref, true)
    end
end


---PopupChar
---@param array table
---@public
function RageUI.PopupChar(array)
    if (array.message == nil) then error("Missing arguments, message") end
    ESX.ShowAdvancedNotification(tostring(array.title or array.Title or ''), tostring(array.subtitle or array.Subject or ''), tostring(array.message), array.icon or 'CHAR_DEFAULT', array.iconType or 1)
end

---Text
---@param array table
---@public
function RageUI.Text(array)
    if (array.message == nil) then error("Missing arguments, message") end
    exports['pickax_notify']:ShowNotification(tostring(array.message), nil, array.time_display and math.ceil(tonumber(array.time_display) * 1000) or nil)
    if (array.sound ~= nil and array.sound.audio_name ~= nil and array.sound.audio_ref ~= nil) then
        PlaySoundFrontend(-1, array.sound.audio_name, array.sound.audio_ref, true)
    end
end
