const $root = document.getElementById('root');
async function rpc(name, ...args) {
  try { const r = await fetch(`https://${GetParentResourceName()}/rpc`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name, args }) }); return await r.json(); }
  catch (e) { return { ok: false, error: 'Pas de réponse' }; }
}
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
function toast(msg, kind) { const t = document.createElement('div'); t.className = 'toast ' + (kind || ''); t.textContent = msg; document.getElementById('toasts').appendChild(t); setTimeout(() => t.remove(), 3600); }
function confirmBox(title, text, yes, danger) {
  return new Promise(ok => {
    const c = document.getElementById('confirm'); c.classList.remove('hidden');
    c.innerHTML = `<div class="box"><h3>${esc(title)}</h3><p>${text}</p><div class="row"><span style="flex:1"></span><button id="c-no">Annuler</button><button id="c-yes" class="${danger ? 'danger' : 'primary'}">${esc(yes)}</button></div></div>`;
    const done = v => { c.classList.add('hidden'); c.innerHTML = ''; ok(v); };
    document.getElementById('c-no').onclick = () => done(false); document.getElementById('c-yes').onclick = () => done(true);
  });
}
const ago = t => { const s = Math.max(0, Math.floor(Date.now() / 1000 - t)); if (s < 60) return 'à l\'instant'; if (s < 3600) return Math.floor(s / 60) + ' min'; if (s < 86400) return Math.floor(s / 3600) + ' h'; return Math.floor(s / 86400) + ' j'; };

const App = {
  tab: 'health', audit: null, backups: null, info: null, busy: false, theme: null, themeHist: [], eco: null,
  async open() { this.tab = 'health'; $root.classList.remove('hidden'); this.render(); this.runAudit(); },
  close() { $root.classList.add('hidden'); },
  async runAudit() { this.busy = true; this.render(); const r = await rpc('audit'); this.busy = false; if (r && r.ok) this.audit = r; else toast((r && r.error) || 'Erreur', 'err'); this.render(); },
  async loadBackups() { const r = await rpc('backups'); if (r && r.ok) { this.backups = r.list; this.render(); } },
  async loadInfo() { const r = await rpc('info'); if (r && r.ok) { this.info = r; this.render(); } },
  async loadTheme() { const r = await rpc('themeGet'); if (r && r.ok) { this.theme = r.values; this.themeHist = r.history || []; this.render(); } else toast((r && r.error) || 'Erreur', 'err'); },
  async loadEco() { const r = await rpc('ecoGet'); if (r && r.ok) { this.eco = r; } else { this.eco = { markets: [], error: (r && r.error) || 'Erreur' }; } this.render(); },
  go(t) { this.tab = t; if (t === 'eco') this.loadEco(); if (t === 'theme' && !this.theme) this.loadTheme(); if (t === 'backups' && !this.backups) this.loadBackups(); if ((t === 'news' || t === 'guide') && !this.info) this.loadInfo(); this.render(); },

  renderHealth() {
    const a = this.audit;
    if (!a) return `<div class="card muted">${this.busy ? 'Analyse en cours…' : 'Aucun audit lancé.'}</div>`;
    const col = a.score >= 85 ? 'var(--ok)' : a.score >= 60 ? 'var(--warn)' : 'var(--err)';
    const errs = a.checks.filter(c => c.status === 'err').length, warns = a.checks.filter(c => c.status === 'warn').length;
    const sym = { ok: '✓', warn: '!', err: '✕' };
    return `<div class="card score"><div class="ring" style="background:conic-gradient(${col} ${a.score * 3.6}deg, rgba(255,255,255,.08) 0)"><i>${a.score}<small>/ 100</small></i></div>
      <div><h3>${errs ? errs + ' problème(s) à corriger' : warns ? 'Quelques points à surveiller' : 'Tout est en ordre'}</h3><p>${errs} erreur(s) · ${warns} avertissement(s) · ${a.checks.length - errs - warns} contrôle(s) OK — ${ago(a.at)}</p></div></div>
      <div class="grid2">${a.checks.map(c => `<div class="card chk"><div class="dot ${c.status}">${sym[c.status]}</div><div><b>${esc(c.title)}</b><div class="d">${esc(c.detail)}</div>${c.items.length ? `<ul>${c.items.slice(0, 12).map(i => `<li>${esc(i)}</li>`).join('')}${c.items.length > 12 ? `<li>+${c.items.length - 12}</li>` : ''}</ul>` : ''}</div></div>`).join('')}</div>`;
  },
  renderBackups() {
    const l = this.backups;
    const head = `<div class="card"><b>Nouvelle sauvegarde</b><p class="muted" style="margin:4px 0 12px">Configuration des builders (métiers, points, concessions, propriétés, gangs, boutiques, monde). Les logs et les données joueurs ne sont pas inclus.</p>
      <div class="row"><input id="bk-l" placeholder="Nom (optionnel) — ex. avant la mise à jour" style="flex:1" maxlength="60"><button class="primary" data-a="backup">Sauvegarder maintenant</button></div></div>`;
    if (!l) return head + '<div class="card muted">Chargement…</div>';
    return head + (l.length ? l.map(b => `<div class="card bk"><div style="flex:1"><b>${esc(b.label || 'Sauvegarde')}</b><small>${esc(b.id)} · ${b.tables} tables · ${b.rows} lignes · par ${esc(b.by || '?')} · ${ago(b.at)}</small></div><button class="danger" data-a="restore" data-id="${esc(b.id)}">Restaurer</button></div>`).join('') : '<div class="card muted">Aucune sauvegarde pour le moment.</div>');
  },
  themeInput(k, label, ph, extra) { const v = this.theme[k] ?? ''; return `<label class="f"><span>${label}</span><input data-th="${k}" value="${esc(v)}" placeholder="${esc(ph || '')}" ${extra || ''}></label>`; },
  renderTheme() {
    const t = this.theme; if (!t) return '<div class="card muted">Chargement…</div>';
    const acc = /^#[0-9a-f]{6}$/i.test(t.AccentColor) ? t.AccentColor : '#fdc27d';
    const logo = /^https:/.test(t.ServerLogo || '') ? t.ServerLogo : 'https://cfx-nui-pickax_theme/logo/' + (t.ServerLogo || 'logo.png');
    return `<div class="th"><div class="card"><div class="grid2">
        <label class="f"><span>Couleur principale</span><div class="row"><input type="color" id="th-pick" value="${acc}" style="width:54px;height:42px;padding:3px"><input data-th="AccentColor" value="${esc(t.AccentColor)}" maxlength="7" style="flex:1"></div></label>
        <label class="f"><span>Couleur de l'inventaire (vide = identique)</span><input data-th="InventoryColor" value="${esc(t.InventoryColor)}" maxlength="7" placeholder="#dc2626"></label>
        ${this.themeInput('ServerName', 'Nom du serveur', 'Aero Roleplay')}${this.themeInput('ServerShortName', 'Nom court', 'AERO')}
        ${this.themeInput('ServerTagline', 'Slogan', 'RP sérieux · Free-Access')}${this.themeInput('ServerDiscord', 'Discord', 'discord.gg/…')}
        </div>${this.themeInput('ServerLogo', 'Logo (fichier dans pickax_theme/logo/ ou lien https)', 'logo.png')}
        <div class="row" style="margin-top:14px"><button class="primary" data-a="themeSave">Enregistrer et appliquer à tous les joueurs</button></div>
        <p class="muted" style="margin:10px 0 0;font-size:12px">Écrit dans <b>pickax_core/config.lua</b> (une copie de l'ancien fichier est conservée) puis relance <b>pickax_theme</b>. Les interfaces changent pour tout le monde à leur prochaine ouverture. Les couleurs des markers / blips (côté Lua) suivent au prochain redémarrage de pickax_core.</p></div>
      <div><div class="card pv" style="--c:${acc}"><div class="pvh"><img src="${esc(logo)}" onerror="this.style.display='none'"><div><b id="pv-n">${esc(t.ServerName)}</b><small id="pv-t">${esc(t.ServerTagline)}</small></div></div>
        <div class="pvb"><span class="pvchip">${esc(t.ServerShortName)}</span><span class="pvchip off">Discord · ${esc(t.ServerDiscord)}</span></div>
        <div class="pvbar"><i></i></div><div class="row" style="gap:8px;margin-top:12px"><button class="pvbtn">Bouton principal</button><button>Secondaire</button></div></div>
      ${this.themeHist.length ? `<div class="card" style="margin-top:12px"><b>Revenir à une version précédente</b>${this.themeHist.map((h, i) => `<div class="bk" style="padding:8px 0"><span class="sw" style="background:${esc(h.values.AccentColor)}"></span><div style="flex:1"><b>${esc(h.values.ServerName)}</b><small>${esc(h.values.AccentColor)} · ${esc(h.by || '?')} · ${ago(h.at)}</small></div><button data-a="themeRevert" data-i="${i}">Charger</button></div>`).join('')}</div>` : ''}</div></div>`;
  },
  renderEco() {
    const e = this.eco; if (!e) return '<div class="card muted">Chargement…</div>';
    if (e.error) return `<div class="card"><b>Économie indisponible</b><p class="muted" style="margin:6px 0 0">${esc(e.error)}</p></div>`;
    if (!e.markets.length) return '<div class="card muted">Aucun marché actif pour le moment : ils apparaissent dès que les joueurs achètent en boutique ou vendent leurs récoltes.</div>';
    const name = k => { const [t, n] = k.split(':'); return ({ shop: 'Boutique', crop: 'Récolte' }[t] || t) + ' · ' + n; };
    return `<p class="muted" style="margin:0">Les prix suivent l'offre et la demande : les ventes des joueurs les font baisser, les achats les font monter, puis tout revient à la normale tout seul. Prix de base × multiplicateur.</p>` +
      e.markets.map(m => { const pct = Math.round((m.mult - 1) * 100), left = Math.max(2, Math.min(98, 50 + (m.mult - 1) * 100)); const up = m.mult > 1.005, down = m.mult < 0.995;
        return `<div class="card eco"><div class="eh"><b>${esc(name(m.key))}</b><span class="ev ${up ? 'up' : down ? 'dn' : ''}">×${m.mult.toFixed(2)} <small>(${pct > 0 ? '+' : ''}${pct} %)</small></span>${m.trend > 0.004 ? '<span class="tr up">▲</span>' : m.trend < -0.004 ? '<span class="tr dn">▼</span>' : '<span class="tr">–</span>'}
          ${m.event ? `<span class="tag">${m.event.swing > 0 ? 'Pénurie' : 'Surplus'} · ${Math.max(1, Math.round((m.event.ends - e.now) / 3600))} h</span>` : ''}<span style="flex:1"></span>
          <button data-a="ecoEv" data-k="${esc(m.key)}" data-s="0.2">Pénurie</button><button data-a="ecoEv" data-k="${esc(m.key)}" data-s="-0.2">Surplus</button><button data-a="ecoReset" data-k="${esc(m.key)}">Normal</button></div>
          <div class="gauge"><i class="mid"></i><b style="left:${left}%"></b></div></div>`; }).join('') +
      `<div class="row" style="justify-content:flex-end"><button class="danger" data-a="ecoReset" data-k="">Tout remettre à la normale</button></div>`;
  },
  renderNews() {
    const i = this.info; if (!i) return '<div class="card muted">Chargement…</div>';
    return `<div class="tl">${i.changelog.map((c, k) => `<div class="v"><h4>${esc(c.title)}<span>v${esc(c.version)} · ${esc(c.date)}</span>${k === 0 ? '<span class="tag">Dernière</span>' : ''}</h4><ul>${c.items.map(x => `<li>${esc(x)}</li>`).join('')}</ul></div>`).join('')}</div>`;
  },
  renderGuide() {
    const cmd = (this.info && this.info.command) || 'aerotools';
    const sec = (t, body) => `<div class="card guide"><h4>${t}</h4>${body}</div>`;
    return sec('Raccourcis en jeu', `<ul><li><kbd>F6</kbd> menu du métier (en service) · <kbd>F7</kbd> menu du gang · <kbd>F10</kbd> ou <kbd>/decorer</kbd> meubles et laboratoire (dans sa propriété)</li><li><kbd>/builders</kbd> ouvre le hub des builders · <kbd>/${esc(cmd)}</kbd> ouvre ce panneau</li></ul>`)
      + sec('Créer un métier ou un point', `<p>Hub des builders → Job Builder → choisis le type (concessionnaire, agent immobilier, jobs actifs…), ajoute des points et règle l'onglet <b>Personnaliser</b> (blip, marker, couleur du menu).</p>`)
      + sec('Après une mise à jour', `<ul><li>Fais une <b>sauvegarde</b> avant de modifier quoi que ce soit.</li><li><code>refresh</code> puis <code>restart</code> de la ressource modifiée.</li><li>Lance un <b>audit</b> : il signale tables SQL ou objets manquants.</li></ul>`)
      + sec('Sécurité', `<ul><li>Garde le dépôt GitHub en privé et limite les accès FTP / panel.</li><li>Ne mets jamais de clé de licence, de mot de passe ou de webhook dans un fichier versionné.</li></ul>`);
  },
  render() {
    const titles = { health: ['Santé de la base', 'Ressources, SQL, objets et données des builders'], backups: ['Sauvegardes', 'Configuration des builders : sauvegarde et restauration'], news: ['Nouveautés', 'Journal des modifications de ta base'], guide: ['Guide', 'Raccourcis et bonnes pratiques'], theme: ['Thème du serveur', 'Couleur, nom et logo de toutes les interfaces'], eco: ['Économie dynamique', 'Prix selon l\'offre et la demande'] };
    const issues = this.audit ? this.audit.checks.filter(c => c.status === 'err').length : 0;
    const nav = (id, ico, label, n) => `<div class="nav ${this.tab === id ? 'on' : ''}" data-a="go" data-id="${id}"><span>${ico}</span>${label}${n ? `<span class="n">${n}</span>` : ''}</div>`;
    const body = this.tab === 'health' ? this.renderHealth() : this.tab === 'backups' ? this.renderBackups() : this.tab === 'news' ? this.renderNews() : this.tab === 'theme' ? this.renderTheme() : this.tab === 'eco' ? this.renderEco() : this.renderGuide();
    $root.innerHTML = `<div class="shell"><div class="side"><div class="brand logo-only" title="Outils de la base"><img class="plogo" data-pk-logo src="${window.PICKAX_LOGO || 'https://cfx-nui-pickax_theme/logo/logo.png'}" alt="" onerror="this.style.visibility='hidden'"><b class="pname">Outils de la base</b></div>
      ${nav('health', '🩺', 'Santé', issues)}${nav('backups', '💾', 'Sauvegardes')}${nav('theme', '🎨', 'Thème')}${nav('eco', '📈', 'Économie')}${nav('news', '✨', 'Nouveautés')}${nav('guide', '📘', 'Guide')}<div class="spacer"></div><button data-a="close">Fermer</button></div>
      <div class="main"><div class="head"><div style="flex:1"><h2>${titles[this.tab][0]}</h2><p>${titles[this.tab][1]}</p></div>${this.tab === 'health' ? `<button class="primary" data-a="audit" ${this.busy ? 'disabled' : ''}>${this.busy ? 'Analyse…' : 'Relancer l\'audit'}</button>` : ''}<button class="x" data-a="close">✕</button></div>
      <div class="body">${body}</div></div></div>`;
  },
  pvUpdate() {   // aperçu sans re-rendre (garde le focus du champ)
    const t = this.theme, pv = document.querySelector('.pv'); if (!pv) return;
    if (/^#[0-9a-f]{6}$/i.test(t.AccentColor)) pv.style.setProperty('--c', t.AccentColor);
    const n = document.getElementById('pv-n'), g = document.getElementById('pv-t'); if (n) n.textContent = t.ServerName; if (g) g.textContent = t.ServerTagline;
    const chips = pv.querySelectorAll('.pvchip'); if (chips[0]) chips[0].textContent = t.ServerShortName; if (chips[1]) chips[1].textContent = 'Discord · ' + t.ServerDiscord;
  },
  async onA(el) {
    const a = el.dataset.a;
    if (a === 'go') return this.go(el.dataset.id);
    if (a === 'close') { this.close(); return rpc('close'); }
    if (a === 'audit') return this.runAudit();
    if (a === 'ecoEv') { const r = await rpc('ecoEvent', el.dataset.k, Number(el.dataset.s), 3); if (r && r.ok) { toast(Number(el.dataset.s) > 0 ? 'Pénurie lancée (3 h)' : 'Surplus lancé (3 h)', 'ok'); return this.loadEco(); } return toast((r && r.error) || 'Erreur', 'err'); }
    if (a === 'ecoReset') { if (!el.dataset.k && !await confirmBox('Tout remettre à la normale ?', 'Tous les prix reviennent à leur valeur de base.', 'Réinitialiser', true)) return; const r = await rpc('ecoReset', el.dataset.k); if (r && r.ok) { toast('Marché réinitialisé', 'ok'); return this.loadEco(); } return toast((r && r.error) || 'Erreur', 'err'); }
    if (a === 'themeRevert') { this.theme = { ...this.themeHist[Number(el.dataset.i)].values }; toast('Version chargée : clique sur Enregistrer pour l\'appliquer', 'ok'); return this.render(); }
    if (a === 'themeSave') {
      if (!await confirmBox('Appliquer ce thème ?', 'Couleur, nom et logo changent pour <b>tous les joueurs</b>. L\'ancien fichier de configuration est sauvegardé.', 'Appliquer', false)) return;
      const r = await rpc('themeSave', this.theme);
      if (r && r.ok) { this.theme = r.values; this.themeHist = r.history || []; toast('Thème enregistré : pickax_theme redémarre', 'ok'); this.render(); } else toast((r && r.error) || 'Erreur', 'err'); return;
    }
    if (a === 'backup') { const r = await rpc('backup', document.getElementById('bk-l').value); if (r && r.ok) { this.backups = r.list; toast('Sauvegarde créée', 'ok'); this.render(); } else toast((r && r.error) || 'Erreur', 'err'); return; }
    if (a === 'restore') {
      if (!await confirmBox('Restaurer cette sauvegarde ?', `La configuration actuelle des builders sera <b>remplacée</b> par celle de <b>${esc(el.dataset.id)}</b>, puis les builders redémarrent.<br>Une sauvegarde de sécurité est créée automatiquement avant, pour pouvoir annuler.`, 'Restaurer', true)) return;
      const r = await rpc('restore', el.dataset.id);
      if (r && r.ok) { this.backups = r.list; toast(`Restauré (${r.rows} lignes). Sécurité : ${r.safety}`, 'ok'); this.render(); } else toast((r && r.error) || 'Erreur', 'err');
    }
  },
};
document.addEventListener('input', e => {
  const el = e.target; if (!App.theme) return;
  if (el.id === 'th-pick') { App.theme.AccentColor = el.value; const h = document.querySelector('[data-th=AccentColor]'); if (h) h.value = el.value; App.pvUpdate(); return; }
  if (el.dataset && el.dataset.th) { App.theme[el.dataset.th] = el.value; if (el.dataset.th === 'AccentColor' && /^#[0-9a-f]{6}$/i.test(el.value)) { const p = document.getElementById('th-pick'); if (p) p.value = el.value; } App.pvUpdate(); }
});
document.addEventListener('click', e => { const el = e.target.closest('[data-a]'); if (el) App.onA(el); });
window.addEventListener('message', e => { const d = e.data || {}; if (d.action === 'open') App.open(); else if (d.action === 'close') App.close(); });
document.addEventListener('keydown', e => { if (e.key === 'Escape' && !$root.classList.contains('hidden')) { App.close(); rpc('close'); } });
