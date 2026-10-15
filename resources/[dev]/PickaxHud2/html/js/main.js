(function () {
    'use strict';
    var $ = function (id) { return document.getElementById(id); };
    var ui = $('ui');
    var fadeT = {};

var S = (p) => `<svg viewBox="0 0 24 24" aria-hidden="true">${p}</svg>`;
var NAMED_ICONS = {
    police: S('<path d="M12 3l7.5 3v5.5c0 4.5-3.2 8-7.5 9.5-4.3-1.5-7.5-5-7.5-9.5V6z"></path><path d="M9 12l2 2 4-4.2"></path>'),
    ems: S('<circle cx="12" cy="12" r="9"></circle><path d="M12 7.5v9M7.5 12h9"></path>'),
    mecano: S('<path d="M14.5 6.2a4 4 0 0 0-5.2 5.2L4 16.7 7.3 20l5.3-5.3a4 4 0 0 0 5.2-5.2l-2.6 2.6-2.4-.6-.6-2.4z"></path>'),
    taxi: S('<path d="M5 15l1.6-5A2 2 0 0 1 8.5 8.6h7a2 2 0 0 1 1.9 1.4L19 15"></path><path d="M4 15h16v3.5H4z"></path><path d="M10 6h4v2.6h-4z"></path><circle cx="7.5" cy="18.5" r="1"></circle><circle cx="16.5" cy="18.5" r="1"></circle>'),
    bank: S('<path d="M3.5 9.5L12 4l8.5 5.5z"></path><path d="M6 11v6M10 11v6M14 11v6M18 11v6"></path><path d="M3.5 19.5h17"></path>'),
    government: S('<path d="M12 3.5l8 3.8H4z"></path><path d="M6 10v7M10 10v7M14 10v7M18 10v7"></path><path d="M3.5 19.5h17M12 3.5V1.8"></path>'),
    realestate: S('<path d="M4 11l8-6.5 8 6.5"></path><path d="M6 10v9.5h12V10"></path><path d="M10 19.5v-5h4v5"></path>'),
    bar: S('<path d="M5 5h14l-6 8v6M9 19h6"></path><path d="M7.5 8.5h9"></path>'),
    dealer: S('<path d="M4 14.5l1.7-4.6A2 2 0 0 1 7.6 8.6h8.8a2 2 0 0 1 1.9 1.3L20 14.5"></path><path d="M3 14.5h18v3.5H3z"></path><circle cx="7" cy="18" r="1.2"></circle><circle cx="17" cy="18" r="1.2"></circle>'),
    garage: S('<path d="M3.5 10.5L12 5l8.5 5.5V19h-17z"></path><path d="M7.5 19v-5h9v5M7.5 16.5h9"></path>'),
    impound: S('<rect x="5" y="11" width="14" height="9" rx="2"></rect><path d="M8 11V8a4 4 0 0 1 8 0v3"></path>'),
    fuel: S('<path d="M5 20V5.5A1.5 1.5 0 0 1 6.5 4h6A1.5 1.5 0 0 1 14 5.5V20"></path><path d="M4 20h11M14 9h2.2a1.8 1.8 0 0 1 1.8 1.8v5.2a1.5 1.5 0 0 0 3 0V9l-2.5-2.5"></path><path d="M7.5 7.5h4"></path>'),
    carwash: S('<path d="M12 3.5s5.5 5.8 5.5 10A5.5 5.5 0 0 1 6.5 13.5c0-4.2 5.5-10 5.5-10z"></path>'),
    drug: S('<path d="M12 21V11"></path><path d="M12 12c-4.5 0-6.5-3-6.5-6.5C9.5 5.5 12 8 12 12z"></path><path d="M12 12c4.5 0 6.5-3 6.5-6.5C14.5 5.5 12 8 12 12z"></path>'),
    robbery: S('<path d="M5 8h14l-1.2 11H6.2z"></path><path d="M9 8V6.5a3 3 0 0 1 6 0V8"></path><path d="M12 11.5v4M10.3 13.5h3.4"></path>'),
    school: S('<path d="M2.5 9.5L12 5l9.5 4.5L12 14z"></path><path d="M6.5 11.5v4.2c0 1.2 2.5 2.3 5.5 2.3s5.5-1.1 5.5-2.3v-4.2"></path>'),
    gang: S('<path d="M6 21V4"></path><path d="M6 5h11.5l-2.5 3.8 2.5 3.7H6"></path>'),
    shop: S('<path d="M6 8h12l1 12H5z"></path><path d="M9 8a3 3 0 0 1 6 0"></path>'),
    world: S('<circle cx="12" cy="12" r="9"></circle><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"></path>'),
    job: S('<rect x="3.5" y="7.5" width="17" height="12" rx="2"></rect><path d="M9 7.5V6a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v1.5"></path><path d="M3.5 13h17"></path>')
};

    function fmt(v) { return String(v == null ? '' : v); }
    function num(v) { return parseInt(String(v).replace(/[^0-9\-]/g, ''), 10) || 0; }

    function setInfo(name, value) {
        var el = $(name);
        if (!el) return;
        var prev = num(el.textContent), next = num(value);
        el.textContent = fmt(value);
        if (prev !== next && el.dataset.init) {
            el.classList.remove('up', 'down');
            void el.offsetWidth;
            el.classList.add(next > prev ? 'up' : 'down');
            clearTimeout(fadeT[name]);
            fadeT[name] = setTimeout(function () { el.classList.remove('up', 'down'); }, 1600);
        }
        el.dataset.init = '1';
    }

    window.addEventListener('message', function (event) {
        var d = event.data || {};
        switch (d.action) {
            case 'setConfig': {
                var c = d.config || {};
                $('infos').style.display = c.hud === false ? 'none' : '';
                $('serverCard').style.display = c.server === false ? 'none' : '';
                $('jobCard').style.display = c.job === false ? 'none' : '';
                $('moneyCard').style.display = c.money === false ? 'none' : '';
                if (c.radius != null) document.documentElement.style.setProperty('--r', c.radius + 'px');
                if (c.scale != null) document.documentElement.style.setProperty('--s', String(c.scale / 100));
                break;
            }
            case 'setTheme': {
                var t = d.theme || {}, root = document.documentElement.style;
                var vars = { main: '--main', bg: '--bg', text: '--text', muted: '--muted', ok: '--ok', bad: '--bad' };
                Object.keys(vars).forEach(function (k) { if (t[k]) root.setProperty(vars[k], t[k]); else root.removeProperty(vars[k]); });
                if (t.server) $('servername').textContent = t.server;
                if (t.discord) $('discord').textContent = t.discord;
                break;
            }
            case 'hideUi': ui.style.display = d.value === true ? 'none' : ''; break;
            case 'fadeUi': ui.style.transition = 'opacity .4s'; ui.style.opacity = d.value === true ? '0' : '1'; break;
            case 'hideComponent': { var c = $(d.component); if (c) c.style.display = d.value === true ? 'none' : ''; break; }
            case 'setInfos': (d.infos || []).forEach(function (i) { setInfo(i.name, i.value); }); break;
            case 'setId': $('playerId').textContent = fmt(d.value); break;
            case 'setPlayers': $('players').textContent = d.max ? d.value + '/' + d.max : fmt(d.value); break;
            case 'setServer':
                if (d.name) $('servername').textContent = d.name;
                if (d.discord) $('discord').textContent = d.discord;
                break;
            case 'setJob':
                $('jobName').textContent = fmt(d.label || 'Chômeur');
                $('jobGrade').textContent = fmt(d.grade || '');
                $('jobIcon').innerHTML = NAMED_ICONS[d.icon] || NAMED_ICONS.job;
                var tag = $('jobTag');
                tag.textContent = d.civil ? 'Civil' : 'En poste';
                tag.classList.toggle('on', !d.civil);
                break;
        }
    });
})();
