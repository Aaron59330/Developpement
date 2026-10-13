Citizen.CreateThread(function()
	while true do
        local timer = 200

        for k, v in pairs(ConfigHolograms.Holograms) do
            if GetDistanceBetweenCoords(v.Position.x, v.Position.y, v.Position.z, GetEntityCoords(PlayerPedId())) < 5.0 then
                timer = 0
                ESXCustom_Function_ClientSide:Draw3DText(v.Position.x, v.Position.y, v.Position.z, v.Text, 4, 0.1, 0.1)
            end
        end
		Citizen.Wait(timer)
	end
end)