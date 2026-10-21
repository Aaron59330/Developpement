/* dlogs-ui : onglet « Logs Discord » commun à tous les builders (métier, gang, boutique, événement).
   Un seul fichier copié dans chaque builder. Le builder ajoute simplement :
     <div class="dl-host" data-ref="IDENTIFIANT"></div>
   et déclare une fois :  DLogs.config({ rpc: (name, ...args) => rpc(name, ...args), toast: (msg, type) => toast(msg, type) })
   Appels serveur attendus (déjà fournis par chaque builder) : dlogsGet(ref), dlogsSave(ref, data), dlogsTest(ref). */
(function () {
  'use strict';
  var CFG = { rpc: null, toast: null };
  var drafts = {};                 // brouillons non enregistrés, gardés quand le builder re-rend la page
  var esc = function (s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); };
  var say = function (m, t) { try { if (CFG.toast) CFG.toast(m, t); } catch (e) {} };

  var css = document.createElement('style');
  css.textContent = [
    '.dl{display:flex;flex-direction:column;gap:14px;user-select:none}',
    '.dl-card{background:var(--surface,var(--panel,rgba(255,255,255,.03)));border:1px solid var(--line,rgba(255,255,255,.08));border-radius:16px;padding:18px}',
    '.dl-h{display:flex;align-items:center;gap:12px;margin-bottom:12px}',
    '.dl-h b{font-size:14px;flex:1}',
    '.dl-h small{color:var(--muted,#8f93a0);font-size:12px}',
    '.dl-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}',
    '.dl label.dl-f{display:flex;flex-direction:column;gap:6px}',
    '.dl label.dl-f>span{font-size:10px;text-transform:uppercase;letter-spacing:.12em;color:var(--muted,#8f93a0);font-weight:700}',
    '.dl input[type=text],.dl select{width:100%;height:38px;padding:0 12px;border-radius:10px;border:1px solid var(--line,rgba(255,255,255,.1));background:rgba(255,255,255,.03);color:var(--text,#f4f4f5);font:inherit;outline:none;user-select:text}',
    '.dl input[type=color]{width:100%;height:38px;padding:3px;border-radius:10px;border:1px solid var(--line,rgba(255,255,255,.1));background:rgba(255,255,255,.03);cursor:pointer}',
    '.dl input[type=text]:focus,.dl select:focus{border-color:rgba(255,255,255,.4)}',
    '.dl select option{background:#151517}',
    '.dl-chk{display:flex;align-items:center;gap:9px;padding:7px 10px;border-radius:10px;border:1px solid var(--line,rgba(255,255,255,.08));cursor:pointer;font-size:13px;color:var(--text-2,#c9c9ce)}',
    '.dl-chk:hover{background:rgba(255,255,255,.04)}',
    '.dl-chk input{appearance:none;width:16px;height:16px;border-radius:5px;border:1px solid rgba(255,255,255,.3);display:grid;place-content:center;flex:none;cursor:pointer;margin:0}',
    '.dl-chk input:checked{background:var(--accent,var(--acc,#00a4ff));border-color:var(--accent,var(--acc,#00a4ff))}',
    '.dl-chk input:checked::after{content:"";width:8px;height:4px;border-left:2px solid #fff;border-bottom:2px solid #fff;transform:rotate(-45deg) translate(1px,-1px)}',
    '.dl-chk.on{border-color:rgba(255,255,255,.28);color:var(--text,#f4f4f5)}',
    '.dl-list{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:8px}',
    '.dl-gt{display:flex;align-items:center;gap:10px;margin:14px 0 8px;font-size:11px;text-transform:uppercase;letter-spacing:.12em;color:var(--muted,#8f93a0);font-weight:700}',
    '.dl-gt:first-child{margin-top:0}',
    '.dl-gt button{height:24px;padding:0 9px;font-size:11px;border-radius:7px;text-transform:none;letter-spacing:0}',
    '.dl-row{display:flex;gap:10px;align-items:center;flex-wrap:wrap}',
    '.dl-hint{font-size:12px;color:var(--muted,#8f93a0);line-height:1.5}',
    '.dl-hint b{color:var(--text-2,#c9c9ce)}',
    '.dl-sw{position:relative;width:42px;height:24px;flex:none}',
    '.dl .dl-sw input[type=checkbox]{appearance:none;position:absolute;inset:0;width:100%;height:100%;margin:0;padding:0;border-radius:24px;background:rgba(255,255,255,.14);border:0;cursor:pointer;transition:background .15s;display:block}',
    '.dl .dl-sw input[type=checkbox]:checked{background:#4ade80;border:0}',
    '.dl .dl-sw input[type=checkbox]::after{display:none!important}',
    '.dl-sw::after{content:"";position:absolute;top:3px;left:3px;width:18px;height:18px;border-radius:50%;background:#fff;pointer-events:none;transition:transform .15s}',
    '.dl-sw:has(input:checked)::after{transform:translateX(18px)}',
    '.dl-warn{border:1px solid rgba(251,191,36,.35);background:rgba(251,191,36,.06);color:#fbbf24;border-radius:12px;padding:11px 14px;font-size:12.5px;line-height:1.5}',
    '.dl-saved{color:#4ade80;font-size:12px}',
  ].join('');
  document.head.appendChild(css);

  var FIELDS = [['player', 'Nom du joueur'], ['identifier', 'Identifiant (licence)'], ['detail', 'Détail de l\'action'], ['amount', 'Montant'], ['entity', 'Nom de l\'élément'], ['time', 'Date et heure']];

  function dkey(host) { return (host.getAttribute('data-ref') || '') + '@' + (host.getAttribute('data-kind') || ''); }

  function draw(host, st) {
    var d = st.draft;
    var groups = st.groups.map(function (g) {
      var all = g.events.every(function (e) { return d.events[e.key]; });
      return '<div class="dl-gt"><span>' + esc(g.label) + '</span><button data-dl="grp" data-g="' + esc(g.label) + '">' + (all ? 'Tout décocher' : 'Tout cocher') + '</button></div><div class="dl-list">' +
        g.events.map(function (e) { return '<label class="dl-chk ' + (d.events[e.key] ? 'on' : '') + '"><input type="checkbox" data-dl="ev" data-key="' + esc(e.key) + '" ' + (d.events[e.key] ? 'checked' : '') + '> ' + esc(e.label) + '</label>'; }).join('') + '</div>';
    }).join('');
    var fields = FIELDS.map(function (f) { return '<label class="dl-chk ' + (d.fields[f[0]] ? 'on' : '') + '"><input type="checkbox" data-dl="fd" data-key="' + f[0] + '" ' + (d.fields[f[0]] ? 'checked' : '') + '> ' + f[1] + '</label>'; }).join('');
    host.innerHTML = '<div class="dl">' +
      '<div class="dl-card"><div class="dl-h"><b>Logs Discord</b><small>' + (d.enabled ? 'Actifs' : 'Désactivés') + '</small><span class="dl-sw"><input type="checkbox" data-dl="enabled" ' + (d.enabled ? 'checked' : '') + '></span></div>' +
        '<div class="dl-hint" style="margin-bottom:12px">Chaque ' + esc((st.title || 'élément').toLowerCase()) + ' envoie ses logs dans <b>son propre salon Discord</b> : crée un webhook (Paramètres du salon → Intégrations → Webhooks) et colle son lien ici.</div>' +
        '<div class="dl-grid"><label class="dl-f"><span>Lien du webhook</span><input type="text" data-dl="webhook" placeholder="' + (st.hasWebhook && !d.clearWebhook ? 'Lien enregistré — laisse vide pour le garder' : 'https://discord.com/api/webhooks/…') + '" value="' + esc(d.webhookNew) + '" maxlength="300" autocomplete="off" spellcheck="false"></label>' +
        '<label class="dl-f"><span>Nom du bot</span><input type="text" data-dl="name" value="' + esc(d.name) + '" maxlength="40" placeholder="Pickax Logs"></label>' +
        '<label class="dl-f"><span>Couleur du message</span><input type="color" data-dl="color" value="' + esc(d.color) + '"></label>' +
        '<label class="dl-f"><span>Mention (optionnel)</span><select data-dl="mention"><option value="">Aucune</option><option value="@here" ' + (d.mention === '@here' ? 'selected' : '') + '>@here</option><option value="@everyone" ' + (d.mention === '@everyone' ? 'selected' : '') + '>@everyone</option></select></label></div>' +
        (st.hasWebhook && !d.clearWebhook ? '<div class="dl-row" style="margin-top:10px"><span class="dl-hint">Lien actuel : <b>' + esc(st.maskedWebhook) + '</b></span><button class="sm" data-dl="clear">Retirer le lien</button></div>' : (d.clearWebhook ? '<div class="dl-hint" style="margin-top:10px">Le lien sera retiré à l\'enregistrement.</div>' : '')) + '</div>' +
      '<div class="dl-card"><div class="dl-h"><b>Informations envoyées</b></div><div class="dl-list">' + fields + '</div></div>' +
      '<div class="dl-card"><div class="dl-h"><b>Événements envoyés</b><small>' + Object.keys(d.events).filter(function (k) { return d.events[k]; }).length + ' sélectionné(s)</small></div>' + groups + '</div>' +
      '<div class="dl-row"><button class="primary pri" data-dl="save">Enregistrer</button><button data-dl="test">Envoyer un message de test</button>' + (st.dirty ? '<span class="dl-hint">Modifications non enregistrées</span>' : (st.justSaved ? '<span class="dl-saved">Enregistré</span>' : '')) + '</div></div>';
  }

  function mkDraft(cfg) {
    return { enabled: !!cfg.enabled, webhookNew: '', clearWebhook: false, name: cfg.name || '', color: cfg.color || '#00a4ff', mention: cfg.mention || '', events: Object.assign({}, cfg.events || {}), fields: Object.assign({}, cfg.fields || {}) };
  }

  function mount(host) {
    if (host.__dl) return;
    host.__dl = true;
    var ref = host.getAttribute('data-ref');
    if (!ref || ref === '0' || ref === 'null') { host.innerHTML = '<div class="dl-warn">Enregistre d\'abord cet élément : ses logs Discord se règlent ensuite ici.</div>'; return; }
    if (!CFG.rpc) { host.innerHTML = '<div class="dl-warn">Logs Discord indisponibles (DLogs.config manquant).</div>'; return; }
    var key = dkey(host), st = drafts[key];
    var finish = function (res) {
      if (!res || !res.ok) { host.innerHTML = '<div class="dl-warn">' + esc((res && res.error) || 'Impossible de charger les logs Discord') + '</div>'; return; }
      st = { title: res.title, groups: res.groups, hasWebhook: !!res.cfg.hasWebhook, maskedWebhook: res.cfg.webhook, saved: res.cfg, draft: st ? st.draft : mkDraft(res.cfg), dirty: st ? st.dirty : false };
      drafts[key] = st;
      draw(host, st);
    };
    host.innerHTML = '<div class="dl-hint">Chargement…</div>';
    Promise.resolve(CFG.rpc('dlogsGet', ref)).then(finish);

    var stop = function (e) { e.stopPropagation(); };
    host.addEventListener('input', stop); host.addEventListener('change', stop);

    host.addEventListener('input', function (e) {
      var t = e.target, k = t.getAttribute('data-dl'), s = drafts[key];
      if (!s) return;
      if (k === 'webhook') s.draft.webhookNew = t.value; else if (k === 'name') s.draft.name = t.value; else return;
      s.dirty = true;
    });
    host.addEventListener('change', function (e) {
      var t = e.target, k = t.getAttribute('data-dl'), s = drafts[key];
      if (!s || !k) return;
      if (k === 'enabled') s.draft.enabled = t.checked;
      else if (k === 'color') s.draft.color = t.value;
      else if (k === 'mention') s.draft.mention = t.value;
      else if (k === 'ev') s.draft.events[t.getAttribute('data-key')] = t.checked;
      else if (k === 'fd') s.draft.fields[t.getAttribute('data-key')] = t.checked;
      else return;
      s.dirty = true; s.justSaved = false;
      if (k !== 'color' && k !== 'mention') draw(host, s);
    });
    host.addEventListener('click', function (e) {
      var b = e.target.closest('[data-dl]');
      if (!b || b.tagName === 'INPUT' || b.tagName === 'SELECT') return;
      e.stopPropagation();
      var k = b.getAttribute('data-dl'), s = drafts[key];
      if (!s) return;
      if (k === 'clear') { s.draft.clearWebhook = true; s.draft.enabled = false; s.dirty = true; draw(host, s); return; }
      if (k === 'grp') {
        var g = s.groups.filter(function (x) { return x.label === b.getAttribute('data-g'); })[0];
        var all = g.events.every(function (ev) { return s.draft.events[ev.key]; });
        g.events.forEach(function (ev) { s.draft.events[ev.key] = !all; });
        s.dirty = true; draw(host, s); return;
      }
      var doSave = function () {
        var d = s.draft;
        return Promise.resolve(CFG.rpc('dlogsSave', ref, { enabled: d.enabled, webhook: d.webhookNew.trim(), clearWebhook: d.clearWebhook, name: d.name, color: d.color, mention: d.mention, events: d.events, fields: d.fields })).then(function (res) {
          if (!res || !res.ok) { say((res && res.error) || 'Enregistrement impossible', 'err'); return false; }
          s.hasWebhook = !!res.cfg.hasWebhook; s.maskedWebhook = res.cfg.webhook; s.saved = res.cfg; s.draft = mkDraft(res.cfg); s.dirty = false; s.justSaved = true;
          draw(host, s); return true;
        });
      };
      if (k === 'save') doSave().then(function (ok) { if (ok) say('Logs Discord enregistrés', 'ok'); });
      if (k === 'test') doSave().then(function (ok) {
        if (!ok) return;
        Promise.resolve(CFG.rpc('dlogsTest', ref)).then(function (r) { say(r && r.ok ? 'Message de test envoyé' : ((r && r.error) || 'Échec de l\'envoi'), r && r.ok ? 'ok' : 'err'); });
      });
    });
  }

  function scan(root) {
    var list = (root.querySelectorAll ? root.querySelectorAll('.dl-host') : []);
    for (var i = 0; i < list.length; i++) mount(list[i]);
    if (root.classList && root.classList.contains('dl-host')) mount(root);
  }
  new MutationObserver(function (muts) {
    for (var i = 0; i < muts.length; i++) for (var j = 0; j < muts[i].addedNodes.length; j++) { var n = muts[i].addedNodes[j]; if (n.nodeType === 1) scan(n); }
  }).observe(document.documentElement, { childList: true, subtree: true });

  window.DLogs = { config: function (c) { CFG = Object.assign(CFG, c || {}); scan(document); }, forget: function () { drafts = {}; } };
})();
