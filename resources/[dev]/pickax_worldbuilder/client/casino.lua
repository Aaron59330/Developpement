-- ─────────────────────────────── Casinos (client) ───────────────────────────────
-- Le World Builder gère le repère au sol, le PNJ, le blip et la touche ; l'interface de jeu est celle de pickax_casino.
Handlers.casino = function(node)
    if GetResourceState('pickax_casino') ~= 'started' then return Notify('Le casino est indisponible (ressource pickax_casino arrêtée).', 'error') end
    local tier
    for _, p in ipairs(node.entity.points or {}) do if p.i == node.pi then tier = p.tier break end end
    local ok = pcall(function() exports.pickax_casino:Open({ eid = node.eid, pi = node.pi, kind = node.kind, tier = tier, x = node.c.x, y = node.c.y, z = node.c.z }) end)
    if not ok then Notify('Le casino est indisponible.', 'error') end
end
