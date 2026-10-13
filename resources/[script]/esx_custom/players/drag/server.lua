local dragging = {}
local dragged = {}

RegisterServerEvent("esx_custom:DragPeople:sync")
AddEventHandler("esx_custom:DragPeople:sync", function(targetSrc)
    if targetSrc > 0 and #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(targetSrc))) < 20.0 then
        TriggerClientEvent("esx_custom:DragPeople:syncTarget", targetSrc, source)
        dragging[source] = targetSrc
        dragged[targetSrc] = source
    end
end)

RegisterServerEvent("esx_custom:DragPeople:stop")
AddEventHandler("esx_custom:DragPeople:stop", function(targetSrc)
	local source = source

	if dragging[source] then
	    TriggerClientEvent("esx_custom:DragPeople:cl_stop", targetSrc, source)
		dragging[source] = nil
		dragged[targetSrc] = nil
	end
end)

AddEventHandler('playerDropped', function(reason)
	local source = source
	dragging[source] = nil
	dragged[source]  = nil
end)