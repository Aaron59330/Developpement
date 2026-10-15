/* HUD voix pickax — remplace l'interface Vue d'origine (mêmes messages NUI que pma-voice) */
(function () {
    'use strict';
    var app = document.getElementById('app');
    var S = { uiEnabled: true, voiceModes: [], voiceMode: 0, radioChannel: 0, radioEnabled: true, usingRadio: false, callInfo: 0, talking: false };

    var MIC = '<svg viewBox="0 0 24 24"><rect x="9" y="2" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0"/><path d="M12 18v4"/></svg>';
    var RADIO = '<svg viewBox="0 0 24 24"><path d="M4 9h16a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-9a1 1 0 0 1 1-1z"/><path d="m4 9 14-6"/><circle cx="9" cy="14.5" r="2.5"/><path d="M15 13h3M15 16h3"/></svg>';
    var PHONE = '<svg viewBox="0 0 24 24"><path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z"/></svg>';

    function pill(cls, icon, title, sub, bars) {
        var b = '';
        if (bars) { b = '<div class="bars">'; for (var i = 1; i <= bars.max; i++) b += '<i class="' + (i <= bars.on ? 'on' : '') + '"></i>'; b += '</div>'; }
        return '<div class="pill ' + cls + '"><div class="ico">' + icon + '</div><div class="txt"><b>' + title + '</b><small>' + sub + '</small></div>' + b + '</div>';
    }

    function esc(s) { return String(s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }

    var last = '';
    function render() {
        app.classList.toggle('hidden', !S.uiEnabled);
        if (!S.uiEnabled) return;
        var html = '';
        if (S.callInfo !== 0) html += pill('call' + (S.talking ? ' talking' : ''), PHONE, 'Appel en cours', 'Téléphone');
        if (S.radioEnabled && S.radioChannel !== 0) {
            html += pill('radio' + (S.usingRadio ? ' talking' : ''), RADIO, esc(S.radioChannel) + ' MHz', S.usingRadio ? 'Transmission' : 'Radio');
        }
        if (S.voiceModes.length) {
            var m = S.voiceModes[S.voiceMode] || S.voiceModes[0];
            var max = Math.max(1, Math.min(5, S.voiceModes.length - 1));
            var on = Math.min(max, S.voiceMode + 1);
            html += pill(S.talking && !S.usingRadio ? 'talking' : '', MIC, esc(m[1]), 'Portée de voix', { on: on, max: max });
        }
        if (html !== last) { app.innerHTML = html; last = html; }
    }

    window.addEventListener('message', function (e) {
        var n = e.data || {};
        if (n.uiEnabled !== undefined) S.uiEnabled = n.uiEnabled;
        if (n.voiceModes !== undefined) {
            try { var v = JSON.parse(n.voiceModes); v.push([0, 'Custom']); S.voiceModes = v; } catch (err) { }
        }
        if (n.voiceMode !== undefined) S.voiceMode = n.voiceMode;
        if (n.radioChannel !== undefined) S.radioChannel = n.radioChannel;
        if (n.radioEnabled !== undefined) S.radioEnabled = n.radioEnabled;
        if (n.callInfo !== undefined) S.callInfo = n.callInfo;
        if (n.usingRadio !== undefined && n.usingRadio !== S.usingRadio) S.usingRadio = n.usingRadio;
        if (n.talking !== undefined && !S.usingRadio) S.talking = n.talking;
        render();
        if (n.sound && S.radioEnabled && S.radioChannel !== 0) {
            var a = document.getElementById(n.sound);
            if (a) { a.load(); a.volume = n.volume; var p = a.play(); if (p && p.catch) p.catch(function () { }); }
        }
    });

    render();
    fetch('https://' + (typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pma-voice') + '/uiReady', { method: 'POST' });
})();
