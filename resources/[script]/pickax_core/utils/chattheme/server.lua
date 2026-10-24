-- Thème du chat aux couleurs du serveur : écrit chat/theme.css depuis Config.AccentColor (lu par le chat via chat_theme dans le manifest).
-- Le fichier est envoyé aux joueurs au démarrage de la ressource : si la couleur change, le fichier est réécrit ici et pris en compte au redémarrage suivant.
CreateThread(function()
    local h = tostring(Config.AccentColor or '#00a4ff')
    local r, g, b = h:match('^#?(%x%x)(%x%x)(%x%x)$')
    if not r then return end
    r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
    local css = ([[/* GÉNÉRÉ au démarrage de pickax_core depuis Config.AccentColor (%s) — ne pas modifier à la main. Après un changement de couleur : restart pickax_core puis reconnexion. */
.chat-input > div { background-color: rgba(%d,%d,%d,.55) !important; }
.chat-input textarea { color: #fff !important; caret-color: rgb(%d,%d,%d) !important; }
.chat-input .prefix { color: rgb(%d,%d,%d) !important; }
.suggestions { border-left: 3px solid rgb(%d,%d,%d) !important; }
.msg b, .msg > strong { color: rgb(%d,%d,%d); }
]]):format(h, r, g, b, r, g, b, r, g, b, r, g, b, r, g, b)
    local cur = LoadResourceFile(GetCurrentResourceName(), 'chat/theme.css')
    if cur ~= css then
        SaveResourceFile(GetCurrentResourceName(), 'chat/theme.css', css, -1)
        print('^3[chat] Couleur du chat mise à jour (' .. h .. ') : redémarre pickax_core une fois de plus pour l\'appliquer aux joueurs.^0')
    end
end)
