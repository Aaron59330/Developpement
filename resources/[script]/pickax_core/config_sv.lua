-- Les logs Discord globaux ont été retirés.
-- Les logs Discord se règlent maintenant depuis chaque builder (onglet « Logs Discord » d'un métier, gang, boutique ou événement), ressource pickax_dlogs.
-- Cette table reste pour que les anciens appels ConfigSV.Logs["…"] du core continuent de fonctionner : ils renvoient simplement « pas de webhook », donc rien n'est envoyé.
ConfigSV = {
	Logs = setmetatable({}, { __index = function() return '' end }),
}
