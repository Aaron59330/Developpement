IsVipPlayer = false
VipLevel = 0
VipExpiration = 0

RegisterNetEvent('CorePickax:Vip:updateVIP')
AddEventHandler('CorePickax:Vip:updateVIP', function(level, expiration)
    if type(level) == 'boolean' then level = level and 1 or 0 end -- ancien format
    VipLevel = tonumber(level) or 0
    VipExpiration = tonumber(expiration) or 0
    IsVipPlayer = VipLevel > 0
end)

function GetVIP() return IsVipPlayer end
function GetVIPLevel() return VipLevel end
exports('GetVIPLevel', GetVIPLevel)
