'use strict';
/* ════════════════════════════ Tablette de gang ════════════════════════════ */
const TI = {
  home: '<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/>',
  flag: '<path d="M4 22V4"/><path d="M4 4h13l-2 4 2 4H4"/>',
  quest: '<rect x="5" y="3" width="14" height="18" rx="2"/><path d="m9 12 2 2 4-4"/><path d="M9 7h6"/>',
  war: '<path d="m14.5 17.5 6 3.5-1-4-5.5-5.5"/><path d="m9.5 17.5-6 3.5 1-4L10 11.5"/><path d="m5 3 7 7M19 3l-7 7"/>',
  trophy: '<path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0z"/><path d="M17 5h3v2a3 3 0 0 1-3 3M7 5H4v2a3 3 0 0 0 3 3"/>',
  news: '<path d="M4 4h13a2 2 0 0 1 2 2v14H6a2 2 0 0 1-2-2z"/><path d="M19 8h2v10a2 2 0 0 1-2 2"/><path d="M8 8h7M8 12h7M8 16h4"/>',
  log: '<path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5z"/><path d="M14 2v6h6M8 13h8M8 17h6"/>',
  pin: '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>',
  users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.9M16 3.1a4 4 0 0 1 0 7.8"/>',
  crown: '<path d="m2 8 4 4 6-8 6 8 4-4-2 12H4z"/>',
  coins: '<circle cx="8" cy="8" r="6"/><path d="M18.1 10.4A6 6 0 1 1 10.4 18"/><path d="M7 6h2v4"/>',
  skull: '<circle cx="9" cy="12" r="1.5"/><circle cx="15" cy="12" r="1.5"/><path d="M8 20v2h8v-2M12.5 17h-1M16 20a2 2 0 0 0 1.6-3.2 8 8 0 1 0-11.2 0A2 2 0 0 0 8 20"/>',
  box: '<path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><path d="M3.3 7 12 12l8.7-5M12 22V12"/>',
  x: '<path d="M18 6 6 18M6 6l12 12"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  clock: '<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>',
  bolt: '<path d="M13 2 3 14h9l-1 8 10-12h-9z"/>',
  gps: '<circle cx="12" cy="12" r="3"/><path d="M12 2v4M12 18v4M2 12h4M18 12h4"/>',
};
const ti = (n, s) => `<svg class="ic" viewBox="0 0 24 24" ${s ? `style="width:${s}px;height:${s}px"` : ''}>${TI[n] || TI.home}</svg>`;
const hexToRgbStr = h => { h = String(h || (window.PICKAX_ACCENT || '#fdc27d')); if (!/^#[0-9a-f]{6}$/i.test(h)) h = (window.PICKAX_ACCENT || '#fdc27d'); return [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16)).join(', '); };
const tbInit = n => String(n || '?').split(/\s+/).map(w => w[0]).join('').slice(0, 2).toUpperCase();
const tbTime = t => new Date(t * 1000).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
const METRIC_ICON = { harvested: 'box', processed: 'bolt', sold: 'coins', laundered: 'coins', capture: 'flag', conflict_win: 'skull', objective: 'box', war_win: 'war' };
const NEWS_ICON = { territory: 'flag', war: 'war', quest: 'quest', conflict: 'skull', objective: 'box', info: 'news' };
const NEWS_COLOR = { war: '#f87171', territory: (window.PICKAX_ACCENT || '#fdc27d'), quest: '#4ade80', conflict: '#fbbf24', objective: '#a78bfa' };
const TB_LOG = {
  territory_captured: 'Territoire capturé', territory_income: 'Revenu de territoire', conflict_win: 'Affrontement gagné', objective_delivered: 'Colis livré',
  quest_done: 'Quête terminée', war_propose: 'Défi lancé', war_win: 'Guerre gagnée', war_loss: 'Guerre perdue', treasury_deposit: 'Dépôt', treasury_withdraw: 'Retrait',
  recruit: 'Recrutement', fire: 'Exclusion', leave: 'Départ', set_grade: 'Changement de grade', harvest: 'Récolte', process: 'Traitement', sell: 'Vente', launder: 'Blanchiment',
};

const Tablet = {
  kind: 'tablet', d: null, page: 'home', sel: null, form: { target: '', kills: null, minutes: null, stake: 0 }, timer: null, tickTimer: null, at: 0,

  open(d) {
    this.d = d; this.at = Date.now();
    if (!this.page) this.page = 'home';
    $root.classList.add('tb');
    $root.innerHTML = '';   // nouvelle ouverture : l'animation d'entrée joue une fois
    this.render();
    clearInterval(this.timer); clearInterval(this.tickTimer);
    // plus de rafraîchissement automatique (l'écran se relançait toutes les 5 s) : les données se mettent à jour à l'ouverture, après une action et quand on change de page
    this.tickTimer = setInterval(() => this.tick(), 1000);
  },

  stop() { clearInterval(this.timer); clearInterval(this.tickTimer); $root.classList.remove('tb'); },

  async refresh(quiet) {
    if ($root.classList.contains('hidden') || Mod !== this) return this.stop();
    const r = await rpc('tablet:open');
    if (!r || !r.ok || !r.me) return;
    if (quiet && JSON.stringify(r) === JSON.stringify(this.d)) return;   // rien de nouveau : l'écran n'est pas redessiné
    const main = document.querySelector('.tb-main'), st = main ? main.scrollTop : 0;
    this.d = r; this.at = Date.now();
    this.render(st);
  },

  // compte à rebours local entre deux rafraîchissements
  tick() {
    if ($root.classList.contains('hidden') || Mod !== this) return;
    const dt = Math.floor((Date.now() - this.at) / 1000);
    document.querySelectorAll('[data-cd]').forEach(n => { n.textContent = fmtUntil(Math.max(0, Number(n.dataset.cd) - dt)); });
    const c = document.getElementById('tb-clock'); if (c) c.textContent = new Date().toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
  },

  cd(sec) { return `<span data-cd="${Math.max(0, Math.floor(sec || 0))}">${fmtUntil(sec || 0)}</span>`; },

  claimable() { return (this.d.quests || []).filter(q => !q.claimed && q.progress >= q.target).length; },

  render(scroll) {
    const d = this.d, me = d.me;
    const g = me.color || (window.PICKAX_ACCENT || '#fdc27d');
    const nav = [['home', 'home', 'Accueil'], ['terr', 'flag', 'Zones'], ['quest', 'quest', 'Quêtes'], ['war', 'war', 'Guerres'], ['rank', 'trophy', 'Classement'], ['news', 'news', 'Actus'], ['log', 'log', 'Journal']];
    const badge = { quest: this.claimable(), war: d.wars.incoming ? 1 : 0 };
    const inner = `
      <div class="tb-top"><div class="brand"><span class="dot"></span>${esc(me.label)}</div><span class="tb-chip inf">${esc(me.gradeLabel)}</span><div class="sp"></div>
        ${me.money != null ? `<div class="tb-pill ok">${ti('coins', 14)} <b>${money(me.money)}</b></div><div class="tb-pill dirty">${ti('skull', 14)} <b>${money(me.dirty)}</b></div>` : ''}
        <div class="tb-pill">${ti('crown', 14)} <b>${me.rep}</b> rép.</div><div class="tb-clock" id="tb-clock">${new Date().toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}</div>
        <button class="tb-x" data-a="close" title="Fermer">${ti('x', 16)}</button></div>
      <div class="tb-rail">${nav.map(([id, icon, l]) => `<button class="tb-nav ${this.page === id ? 'active' : ''}" data-a="tbnav" data-v="${id}">${ti(icon)}<span>${l}</span>${badge[id] ? `<i class="bdg">${badge[id]}</i>` : ''}</button>`).join('')}</div>
      <div class="tb-main">${this['p_' + this.page]()}</div>`;
    // l'appareil n'est créé qu'une fois : le redessiner entièrement rejouait son animation d'ouverture (clignotement à chaque clic)
    const dev = $root.querySelector('.tb-device');
    if (dev) { dev.style.setProperty('--g', g); dev.style.setProperty('--g-rgb', hexToRgbStr(g)); dev.querySelector('.tb-screen').innerHTML = inner; }
    else $root.innerHTML = `<div class="tb-device" style="--g:${esc(g)};--g-rgb:${hexToRgbStr(g)}"><div class="tb-cam"></div><div class="tb-screen">${inner}</div></div>`;
    if (scroll) { const m = document.querySelector('.tb-main'); if (m) m.scrollTop = scroll; }
  },

  head(title, sub, acts = '') { return `<div class="tb-h"><div><h2>${esc(title)}</h2>${sub ? `<p>${sub}</p>` : ''}</div><div class="sp"></div>${acts}</div>`; },

  /* ───────── Accueil ───────── */
  p_home() {
    const d = this.d, me = d.me, w = d.wars.current, o = d.objective;
    const alerts = [];
    if (d.wars.incoming && w) alerts.push(`<div class="tb-row"><span class="tb-ping"></span><div class="g"><b>${esc(w.aLabel)} vous défie !</b><small>Guerre à ${w.target} kills · mise ${money(w.stake)}</small></div><button class="tb-btn pri" data-a="tbnav" data-v="war">Répondre</button></div>`);
    else if (w && w.status === 'active') alerts.push(`<div class="tb-row"><span class="tb-chip bad">En guerre</span><div class="g"><b>${esc(w.aLabel)} ${w.killsA} – ${w.killsB} ${esc(w.bLabel)}</b><small>Objectif ${w.target} kills · reste ${this.cd(w.left)}</small></div><button class="tb-btn" data-a="tbnav" data-v="war">Détails</button></div>`);
    if (this.claimable()) alerts.push(`<div class="tb-row"><span class="tb-chip ok">${this.claimable()} quête(s) terminée(s)</span><div class="g"><small>Récupère les récompenses pour la trésorerie du gang.</small></div><button class="tb-btn pri" data-a="tbnav" data-v="quest">Voir</button></div>`);
    if (o && o.active) alerts.push(`<div class="tb-row"><span class="tb-chip warn">Colis</span><div class="g"><b>${esc(o.label)}</b><small>${o.carried ? `Porté par ${esc(o.carrierGang || '?')}` : 'Au sol, à prendre'} · récompense ${money(o.reward)}</small></div><button class="tb-btn" data-a="gps" data-x="${o.x}" data-y="${o.y}">${ti('gps', 14)} GPS</button></div>`);
    return `<div class="tb-hero"><div class="tb-badge">${esc(tbInit(me.label))}</div><div style="flex:1"><h1>${esc(me.label)}</h1><p>Bienvenue ${esc(me.player)} · ${esc(me.gradeLabel)}${me.motd ? ` · « ${esc(me.motd)} »` : ''}</p></div></div>
      <div class="tb-g4"><div class="tb-stat"><div class="l">Réputation</div><div class="v">${me.rep}</div><div class="s">${(d.ranking.findIndex(r => r.me) + 1) ? `#${d.ranking.findIndex(r => r.me) + 1} du classement` : ''}</div></div>
        <div class="tb-stat"><div class="l">Membres</div><div class="v">${me.members}</div><div class="s">${me.online.length} en ligne</div></div>
        <div class="tb-stat"><div class="l">Territoires</div><div class="v">${d.territoryCount}</div><div class="s">sur ${d.territories.length}</div></div>
        <div class="tb-stat"><div class="l">Trésorerie</div><div class="v" style="font-size:21px">${me.money != null ? money(me.money) : '—'}</div><div class="s">${me.dirty != null ? money(me.dirty) + ' sale' : 'réservé au bureau'}</div></div></div>
      <div class="tb-g2"><div class="tb-card"><h3>${ti('bolt', 15)} À surveiller</h3>${alerts.join('') || '<div class="tb-empty">Rien d\'urgent pour le moment.</div>'}</div>
        <div class="tb-card"><h3>${ti('users', 15)} En ligne (${me.online.length})</h3>${me.online.map(m => `<div class="tb-row"><div class="g"><b>${esc(m.name)}</b></div><span class="tb-chip">${esc(m.gradeLabel)}</span></div>`).join('') || '<div class="tb-empty">Personne.</div>'}</div></div>
      <div class="tb-card"><h3>${ti('news', 15)} Dernières actualités</h3>${this.newsList(d.news.slice(0, 4))}</div>`;
  },

  newsList(list) {
    return list.map(n => `<div class="tb-news"><div class="ic" style="color:${NEWS_COLOR[n.kind] || '#8c8f99'}">${ti(NEWS_ICON[n.kind] || 'news', 16)}</div><div>${esc(n.text)}<small>${tbTime(n.t)}</small></div></div>`).join('') || '<div class="tb-empty">Aucune actualité pour le moment.</div>';
  },

  /* ───────── Territoires ───────── */
  p_terr() {
    const d = this.d, list = d.territories;
    if (!list.length) return this.head('Territoires', 'Aucune zone créée.') + '<div class="tb-card tb-empty">Un administrateur doit créer des territoires dans le builder.</div>';
    const o = d.objective && d.objective.active ? d.objective : null;
    const pts = list.map(t => [t.x, t.y]).concat(o ? [[o.x, o.y]] : []);
    const xs = pts.map(p => p[0]), ys = pts.map(p => p[1]);
    const pad = 140, minX = Math.min(...xs) - pad, maxX = Math.max(...xs) + pad, minY = Math.min(...ys) - pad, maxY = Math.max(...ys) + pad;
    const W = 640, H = 460, sc = Math.min(W / (maxX - minX), H / (maxY - minY));
    const X = x => (x - minX) * sc + (W - (maxX - minX) * sc) / 2, Y = y => H - ((y - minY) * sc + (H - (maxY - minY) * sc) / 2);
    const sel = list.find(t => t.id === this.sel) || null;
    let svg = '';
    for (let i = 1; i < 8; i++) svg += `<line class="grid" x1="${W / 8 * i}" y1="0" x2="${W / 8 * i}" y2="${H}"/><line class="grid" x1="0" y1="${H / 8 * i}" x2="${W}" y2="${H / 8 * i}"/>`;
    for (const t of list) {
      const col = t.ownerColor || '#6b7280', r = Math.max(14, t.radius * sc);
      svg += `<g class="zone" data-a="tsel" data-v="${t.id}"><circle cx="${X(t.x)}" cy="${Y(t.y)}" r="${r}" fill="${col}" fill-opacity="${t.mine ? .38 : .24}" stroke="${t.id === this.sel ? '#fff' : col}" stroke-width="${t.id === this.sel ? 3 : 2}" ${t.attacker ? 'stroke-dasharray="6 4"' : ''}/>
        <text class="lbl" x="${X(t.x)}" y="${Y(t.y) + r + 15}" text-anchor="middle">${esc(t.label)}</text></g>`;
    }
    if (o) svg += `<g><circle cx="${X(o.x)}" cy="${Y(o.y)}" r="${Math.max(12, o.radius * sc)}" fill="#fbbf24" fill-opacity=".18" stroke="#fbbf24" stroke-width="2" stroke-dasharray="4 4"/><text class="lbl" x="${X(o.x)}" y="${Y(o.y) + 4}" text-anchor="middle">📦 ${esc(o.label)}</text></g>`;
    const row = t => `<div class="tb-row ${t.id === this.sel ? 'tb-sel' : ''}" style="cursor:pointer;border-radius:12px;padding:10px" data-a="tsel" data-v="${t.id}">
      <i style="width:12px;height:12px;border-radius:50%;background:${t.ownerColor || '#6b7280'};flex:none"></i>
      <div class="g"><b>${esc(t.label)}</b><small>${t.owner ? (t.mine ? 'À nous' : esc(t.ownerLabel)) : 'Libre'} · +${money(t.income)} / ${t.incomeEvery} min${t.nextIncome != null && t.mine ? ` · prochain dans ${this.cd(t.nextIncome)}` : ''}</small></div>
      ${t.protectedLeft > 0 ? `<span class="tb-chip inf">Protégé ${this.cd(t.protectedLeft)}</span>` : t.attacker ? `<span class="tb-chip bad">${esc(t.attacker)} ${Math.round(t.progress)} %</span>` : t.mine ? '<span class="tb-chip ok">À nous</span>' : '<span class="tb-chip">Capturable</span>'}</div>`;
    return this.head('Territoires', `${d.territoryCount} contrôlé(s) sur ${list.length} · reste dans la zone pour la capturer`) +
      `<div class="tb-terr"><div class="tb-map"><svg viewBox="0 0 ${W} ${H}" preserveAspectRatio="xMidYMid meet">${svg}</svg></div>
        <div class="tb-card" style="overflow:auto;max-height:460px">${sel ? `<div class="tb-card" style="margin-bottom:12px;border-color:${esc(sel.ownerColor || '#444')}"><b style="font-size:16px">${esc(sel.label)}</b><div style="color:var(--muted);font-size:12.5px;margin:4px 0 10px">${sel.owner ? 'Propriétaire : ' + esc(sel.ownerLabel) : 'Aucun propriétaire'} · rayon ${Math.round(sel.radius)} m</div><button class="tb-btn pri" data-a="gps" data-x="${sel.x}" data-y="${sel.y}">${ti('gps', 14)} Définir le GPS</button></div>` : ''}${list.map(row).join('')}</div></div>`;
  },

  /* ───────── Quêtes ───────── */
  p_quest() {
    const d = this.d, o = d.objective;
    const block = (title, period, resetSec) => {
      const qs = d.quests.filter(q => q.period === period);
      return `<div class="tb-card"><h3>${ti('quest', 15)} ${title}<span style="margin-left:auto;text-transform:none;letter-spacing:0">renouvellement dans ${this.cd(resetSec)}</span></h3>${qs.map(q => {
        const done = q.progress >= q.target, pct = Math.min(100, Math.round(q.progress / q.target * 100));
        const val = ['sold', 'laundered'].includes(q.metric) ? money(q.progress) + ' / ' + money(q.target) : q.progress + ' / ' + q.target;
        return `<div class="tb-quest ${done ? 'done' : ''}"><div class="ic">${ti(done ? 'check' : (METRIC_ICON[q.metric] || 'quest'), 22)}</div>
          <div><div class="t">${esc(q.label)}</div><div class="d">${esc(q.desc)}</div><div class="tb-bar ${done ? 'ok' : ''}"><i style="width:${pct}%"></i></div><small style="color:var(--muted);font-size:11.5px">${val}</small></div>
          <div class="r"><b>${money(q.reward)}</b>${q.claimed ? '<span class="tb-chip ok">Récupérée</span>' : `<button class="tb-btn pri" data-a="claim" data-q="${esc(q.qkey)}" data-id="${esc(q.id)}" ${done ? '' : 'disabled'}>Récupérer</button>`}<div style="margin-top:4px">+${q.rep} rép.</div></div></div>`;
      }).join('') || '<div class="tb-empty">Aucune quête.</div>'}</div>`;
    };
    const colis = o && o.active
      ? `<div class="tb-row"><span class="tb-chip warn">En cours</span><div class="g"><b>${esc(o.label)}</b><small>${o.carried ? `Porté par ${esc(o.carrierGang || '?')}` : 'Colis au sol : premier arrivé, premier servi'} · récompense ${money(o.reward)} · fin dans ${this.cd(Math.max(0, o.endsAt - o.now))}</small></div><button class="tb-btn pri" data-a="gps" data-x="${o.x}" data-y="${o.y}">${ti('gps', 14)} GPS</button></div>`
      : `<div class="tb-empty">Aucun colis pour le moment${o && o.auto ? ` · prochain tirage dans ${this.cd(o.nextIn)}` : ''}.</div>`;
    return this.head('Quêtes', 'Accomplis des objectifs pour remplir la trésorerie et monter en réputation') +
      `<div class="tb-card"><h3>${ti('box', 15)} Mission colis (tous les gangs)</h3>${colis}</div>` + block('Quêtes du jour', 'daily', d.resets.daily) + block('Quêtes de la semaine', 'weekly', d.resets.weekly);
  },

  /* ───────── Guerres ───────── */
  p_war() {
    const d = this.d, W = d.wars, w = W.current, me = d.me;
    let cur = '';
    if (w) {
      const mineIsA = w.a === me.name;
      const team = (lab, col, k) => `<div class="team"><div class="tb-badge" style="background:${esc(col || '#6b7280')}">${esc(tbInit(lab))}</div><div class="n">${esc(lab)}</div><div class="k">${k}</div></div>`;
      const pa = Math.min(100, w.killsA / w.target * 100), pb = Math.min(100, w.killsB / w.target * 100);
      cur = `<div class="tb-card" style="border-color:rgba(248,113,113,.4)"><h3>${ti('war', 15)} ${w.status === 'active' ? 'Guerre en cours' : w.status === 'pending' ? 'Défi en attente' : 'Guerre'}</h3>
        <div class="tb-vs">${team(w.aLabel, w.aColor, w.killsA)}<div class="mid">VS</div>${team(w.bLabel, w.bColor, w.killsB)}</div>
        <div class="tb-g2" style="margin-top:14px"><div class="tb-bar"><i style="width:${pa}%"></i></div><div class="tb-bar"><i style="width:${pb}%;background:#f87171"></i></div></div>
        <p style="text-align:center;color:var(--muted);font-size:12.5px;margin-top:12px">Premier à ${w.target} kills · mise ${money(w.stake)} chacun · ${w.status === 'active' ? `reste ${this.cd(w.left)}` : `expire dans ${this.cd(w.expiresIn)}`}</p>
        ${w.status === 'pending' ? `<div style="display:flex;gap:10px;justify-content:center;margin-top:12px">${W.incoming ? `<button class="tb-btn pri" data-a="warYes" data-id="${w.id}" ${me.isBureau ? '' : 'disabled'}>Accepter</button><button class="tb-btn dng" data-a="warNo" data-id="${w.id}" ${me.isBureau ? '' : 'disabled'}>Refuser</button>` : `<button class="tb-btn dng" data-a="warNo" data-id="${w.id}" ${me.isBureau ? '' : 'disabled'}>Annuler le défi</button>`}</div>${me.isBureau ? '' : '<p class="tb-empty">Réservé au bureau du gang.</p>'}` : ''}</div>`;
    }
    const f = this.form;
    if (!f.kills) f.kills = (W.targets || [10])[0]; if (!f.minutes) f.minutes = (W.durations || [20])[0];
    const free = (W.rivals || []).filter(r => !r.busy);
    const propose = !W.enabled ? '<div class="tb-card tb-empty">Les guerres sont désactivées.</div>' : w ? '' :
      `<div class="tb-card"><h3>${ti('skull', 15)} Défier un gang</h3>${me.isBureau ? `<div class="tb-form">
        <label>Gang adverse<select data-sk="target"><option value="">— choisir —</option>${free.map(r => `<option value="${esc(r.name)}" ${f.target === r.name ? 'selected' : ''} ${r.online ? '' : 'disabled'}>${esc(r.label)} (${r.online} en ligne)</option>`).join('')}</select></label>
        <label>Kills à atteindre<select data-sk="kills">${W.targets.map(k => `<option ${f.kills == k ? 'selected' : ''}>${k}</option>`).join('')}</select></label>
        <label>Durée (min)<select data-sk="minutes">${W.durations.map(k => `<option ${f.minutes == k ? 'selected' : ''}>${k}</option>`).join('')}</select></label>
        <label>Mise ($ sale, max ${W.maxStake})<input type="number" min="0" max="${W.maxStake}" step="500" data-sk="stake" value="${f.stake}"></label></div>
        <div style="margin-top:14px;display:flex;gap:12px;align-items:center"><button class="tb-btn pri" data-a="warSend" ${f.target ? '' : 'disabled'}>Envoyer le défi</button><span style="color:var(--muted);font-size:12.5px">Le gang a 5 min pour répondre. Les mises sont prélevées sur les trésoreries et gagnées en totalité par le vainqueur (égalité = remboursées).</span></div>` : '<div class="tb-empty">Seul le bureau du gang peut lancer un défi.</div>'}</div>`;
    const hist = `<div class="tb-card"><h3>${ti('log', 15)} Dernières guerres</h3>${W.history.map(h => `<div class="tb-row"><span class="tb-chip ${h.winner === me.name ? 'ok' : h.winner ? 'bad' : ''}">${h.winner === me.name ? 'Victoire' : h.winner ? 'Défaite' : 'Égalité'}</span><div class="g"><b>${esc(h.aLabel)} ${h.killsA} – ${h.killsB} ${esc(h.bLabel)}</b><small>Mise ${money(h.stake)} · objectif ${h.target} kills</small></div></div>`).join('') || '<div class="tb-empty">Aucune guerre jouée.</div>'}</div>`;
    return this.head('Guerres', 'Défie un autre gang : premier à N kills ou plus de kills au bout du temps') + cur + propose + hist;
  },

  /* ───────── Classement ───────── */
  p_rank() {
    const r = this.d.ranking;
    return this.head('Classement', 'Réputation des gangs de la ville') + `<div class="tb-card"><div class="tb-rank head"><span>#</span><span>Gang</span><span>Réputation</span><span>Territoires</span><span>Guerres</span><span>En ligne</span></div>
      ${r.map((g, i) => `<div class="tb-rank ${g.me ? 'me' : ''}"><span class="pos">${i + 1}</span><span class="nm"><i style="background:${esc(g.color)}"></i>${esc(g.label)}</span><b>${g.rep}</b><span>${g.territories}</span><span>${g.wars} gagnée(s)</span><span>${g.online}</span></div>`).join('')}</div>`;
  },

  p_news() { return this.head('Actualités', 'Ce qui se passe entre les gangs') + `<div class="tb-card">${this.newsList(this.d.news)}</div>`; },

  p_log() {
    return this.head('Journal', 'Activité récente de ton gang') + `<div class="tb-card">${this.d.logs.map(l => `<div class="tb-row"><div class="g"><b>${esc(TB_LOG[l.action] || LOG_LABEL[l.action] || l.action)}</b><small>${esc(l.player_name || 'système')}${l.detail ? ' — ' + esc(l.detail) : ''}</small></div><small>${tbTime(l.t)}</small></div>`).join('') || '<div class="tb-empty">Rien pour le moment.</div>'}</div>`;
  },

  /* ───────── Actions ───────── */
  async onA(el) {
    const a = el.dataset.a, done = (r, msg) => { if (!r || !r.ok) { toast((r && r.error) || 'Erreur', 'err'); return false; } if (msg) toast(msg, 'ok'); return true; };
    switch (a) {
      case 'tbnav': this.page = el.dataset.v; this.render(); return this.refresh(true);
      case 'tsel': this.sel = Number(el.dataset.v); return this.render();
      case 'gps': return rpc('waypoint', { x: Number(el.dataset.x), y: Number(el.dataset.y) });
      case 'claim': { const r = await rpc('tablet:claim', el.dataset.q, el.dataset.id); if (done(r, r && r.ok ? `+${money(r.reward)} dans la trésorerie` : '')) await this.refresh(); return; }
      case 'warSend': {
        const f = this.form; if (!f.target) return;
        if (!await confirmBox('Lancer le défi ?', `Guerre à ${f.kills} kills, mise ${money(f.stake)} (prélevée à l'acceptation).`, 'Envoyer')) return;
        const r = await rpc('tablet:warPropose', f.target, Number(f.kills), Number(f.minutes), Number(f.stake) || 0);
        if (done(r, 'Défi envoyé')) { f.target = ''; await this.refresh(); } return;
      }
      case 'warYes': { const r = await rpc('tablet:warRespond', Number(el.dataset.id), true); if (done(r, 'Guerre acceptée')) await this.refresh(); return; }
      case 'warNo': { const r = await rpc('tablet:warRespond', Number(el.dataset.id), false); if (done(r, 'Fait')) await this.refresh(); return; }
    }
  },

  onInput(el) {
    const k = el.dataset.sk; if (!k) return;
    this.form[k] = el.value;
    if (k === 'target') this.render(document.querySelector('.tb-main')?.scrollTop);
  },
};
