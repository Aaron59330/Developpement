for k, v in pairs(ConfigBasicNeeds.RegisterItemUsable) do
	ESX.RegisterUsableItem(v.name, function(source)
		if Config.Debug then
			print(v.name.." was used")
		end
		v.IsUsed(source)
	end)
end