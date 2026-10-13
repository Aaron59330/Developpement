local dragging = {}
local dragged = {}

RegisterServerEvent("CorePickax:DragPeople:sync")
AddEventHandler("CorePickax:DragPeople:sync", function(targetSrc)
    if targetSrc > 0 and #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(targetSrc))) < 20.0 then
        TriggerClientEvent("CorePickax:DragPeople:syncTarget", targetSrc, source)
        dragging[source] = targetSrc
        dragged[targetSrc] = source
    end
end)

RegisterServerEvent("CorePickax:DragPeople:stop")
AddEventHandler("CorePickax:DragPeople:stop", function(targetSrc)
	local source = source

	if dragging[source] then
	    TriggerClientEvent("CorePickax:DragPeople:cl_stop", targetSrc, source)
		dragging[source] = nil
		dragged[targetSrc] = nil
	end
end)

AddEventHandler('playerDropped', function(reason)
	local source = source
	dragging[source] = nil
	dragged[source]  = nil
end)