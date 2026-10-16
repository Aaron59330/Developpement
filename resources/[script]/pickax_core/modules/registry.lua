-- Modules intégrés à pickax_core (sans interface NUI) : chargés par loader.lua, chacun dans son propre environnement Lua.
-- Les modules avec interface (builders, HUD, menu pause, CarPlay…) sont des ressources séparées : une ressource FiveM n'a qu'une page NUI.
return {
    { name = 'connectui', shared = { 'config.lua' }, server = { 'server.lua' } },
}
