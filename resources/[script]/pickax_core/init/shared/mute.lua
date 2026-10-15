-- Aucun print dans la console F8 (côté client uniquement ; la console serveur n'est pas touchée)
if not IsDuplicityVersion() then
    print = function() end
end
