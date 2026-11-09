'use strict';
const IN_GAME = typeof GetParentResourceName === 'function';
const $ = s => document.querySelector(s);
const esc = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const stage = $('#stage');
function fit() { const k = Math.min(innerWidth / 1920, innerHeight / 1080); stage.style.transform = `scale(${k})`; stage.style.left = (innerWidth - 1920 * k) / 2 + 'px'; stage.style.top = (innerHeight - 1080 * k) / 2 + 'px'; }
addEventListener('resize', fit); fit();
const post = (n, d) => IN_GAME ? fetch(`https://${GetParentResourceName()}/${n}`, { method: 'POST', body: JSON.stringify(d || {}) }).then(r => r.json()).catch(() => null) : Promise.resolve(null);
const money = n => Math.round(n).toLocaleString('fr-FR').replace(/ | /g, ' ') + ' $';

const I = {
  sub: 'M3 14h18l-3 4H8l-5-4zm6-4h6V7h-6z', x: 'M6 6l12 12M18 6L6 18', target: 'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18zM12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8z', route: 'M5 19a2 2 0 1 0 0-4 2 2 0 0 0 0 4zM19 9a2 2 0 1 0 0-4 2 2 0 0 0 0 4zM7 17h6a3 3 0 0 0 0-6h-2a3 3 0 0 1 0-6h6',
  gear: 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3h0a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5h0a1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8v0a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z',
  users: 'M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM2 21c0-4 3-7 7-7s7 3 7 7M17 4a4 4 0 0 1 0 7M19 14c2 1 3 3 3 6', list: 'M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01', check: 'M5 12l5 5 9-10', pin: 'M12 21s7-6 7-11a7 7 0 0 0-14 0c0 5 7 11 7 11zM12 12a2 2 0 1 0 0-4 2 2 0 0 0 0 4z', warn: 'M12 3l10 18H2zM12 10v5M12 18h.01', play: 'M6 4l14 8-14 8z'
};
const ic = k => `<svg viewBox="0 0 24 24"><path d="${I[k]}"/></svg>`;

let CFG = null, ST = null, tab = 'obj', nearby = [];
const byId = (l, id) => (l || []).find(x => x.id === id);

// ───────── carte de l'île ─────────
const MAP = { x0: 4100, x1: 5400, y0: -6050, y1: -4300, W: 520, H: 420 };
const P = (x, y) => [((x - MAP.x0) / (MAP.x1 - MAP.x0) * MAP.W).toFixed(1), ((MAP.y1 - y) / (MAP.y1 - MAP.y0) * MAP.H).toFixed(1)];
const COAST = [[4380, -4400], [4700, -4420], [4900, -4650], [5050, -4900], [5200, -5100], [5260, -5300], [5200, -5550], [5120, -5800], [4950, -5900], [4800, -5800], [4850, -5600], [4700, -5400], [4600, -5200], [4450, -5000], [4300, -4800], [4250, -4550]];
function mapSvg() {
  const poly = COAST.map(([x, y]) => P(x, y).join(',')).join(' ');
  const pt = (o, col, lbl, r = 6, ring) => { const [x, y] = P(o.x, o.y); return `<g>${ring ? `<circle cx="${x}" cy="${y}" r="${r + 7}" fill="${col}" opacity=".22"/>` : ''}<circle cx="${x}" cy="${y}" r="${r}" fill="${col}" stroke="#08131a" stroke-width="2"/>${lbl ? `<text x="${+x + 11}" y="${+y + 4}" fill="#e6eef2" font-size="12" font-family="Figtree" font-weight="600" paint-order="stroke" stroke="#08131a" stroke-width="3">${esc(lbl)}</text>` : ''}</g>`; };
  const pl = ST.plan, inf = byId(CFG.infils, pl.infil), exf = byId(CFG.exfils, pl.exfil);
  const zones = CFG.zones.map(z => { const [x, y] = P(z.x, z.y); return `<circle cx="${x}" cy="${y}" r="${5 + z.count * 2.2}" fill="#e5484d" opacity=".16"/>`; }).join('');
  const V = (CFG.spots && CFG.spots[pl.target]) || CFG.vault;
  let route = '';
  if (inf && exf) { const a = P(inf.x, inf.y), b = P(V.x, V.y), c = P(exf.x, exf.y); route = `<polyline points="${a} ${b} ${c}" fill="none" stroke="#f0b323" stroke-width="2.4" stroke-dasharray="7 6" opacity=".9"/>`; }
  const sea = '<defs><pattern id="w" width="22" height="22" patternUnits="userSpaceOnUse"><path d="M0 11q5.5-5 11 0t11 0" stroke="#1a4a60" stroke-width="1" fill="none" opacity=".55"/></pattern></defs>';
  return `<svg viewBox="0 0 ${MAP.W} ${MAP.H}" preserveAspectRatio="xMidYMid slice">${sea}<rect width="${MAP.W}" height="${MAP.H}" fill="url(#w)"/><polygon points="${poly}" fill="#27404a" stroke="#5b8a99" stroke-width="2.2" stroke-linejoin="round"/><polygon points="${poly}" fill="#2f5a4a" opacity=".45" transform="translate(7 5) scale(.97)" style="transform-origin:center"/>${zones}${route}
    ${CFG.infils.map(o => pt(o, o.id === pl.infil ? '#3fb950' : '#6e8f9c', o.label, o.id === pl.infil ? 7 : 4, o.id === pl.infil)).join('')}
    ${CFG.exfils.map(o => o.id === pl.exfil ? pt(o, '#29c7b8', 'Extraction : ' + o.label, 7, true) : '').join('')}
    ${pt(V, '#f0b323', pl.target ? byId(CFG.targets, pl.target).label : 'Coffre', 8, true)}</svg>`;
}

// ───────── pages ─────────
const card = (on, title, desc, extra, attrs) => `<div class="card ${on ? 'on' : ''}" ${attrs}><div class="ck">${ic('check')}</div><b>${esc(title)}</b>${desc ? `<p>${esc(desc)}</p>` : ''}${extra || ''}</div>`;
const isLead = () => ST.leader === ST.me;

function pageObj() {
  const pl = ST.plan;
  return `<h2>Objectifs du braquage</h2><div class="sub">Choisis la cible principale : elle est dans le coffre-fort du complexe d'El Rubio.</div>
  <div class="sec">Cible principale</div><div class="grid g3">${CFG.targets.map(t => card(pl.target === t.id, t.label, t.desc, `<div class="v">${money(t.value)}</div>`, `data-set="target" data-v="${t.id}"`)).join('')}</div>
  <div class="sec">Butin secondaire (à ramasser sur l'île)</div><div class="grid g4">${Object.entries(CFG.loot).map(([k, l]) => `<div class="card ro"><b>${esc(l.label)}</b><p>Prend ${l.units} / ${CFG.bag} du sac</p><div class="v">${money(l.value)}</div></div>`).join('')}</div>
  <div class="sec">Défi Élite</div><div class="grid"><div class="card ${pl.elite ? 'on' : ''}" data-set="elite" data-v="1"><div class="ck">${ic('check')}</div><b>Défi Élite</b><p>Prends la cible sans déclencher l'alarme, sans qu'aucun membre ne tombe, en moins de ${Math.round(CFG.elite.time / 60)} minutes.</p><div class="v">+ ${money(pl.difficulty === 'hard' ? CFG.elite.bonusHard : CFG.elite.bonus)}</div></div></div>
  <div class="sec">Difficulté</div><div class="diff">${Object.entries(CFG.difficulties).map(([k, d]) => `<div class="pill ${pl.difficulty === k ? 'on' : ''}" data-set="difficulty" data-v="${k}">${esc(d.label)}<small>${k === 'hard' ? 'Gardes plus nombreux et plus résistants · +' + Math.round(CFG.hardBonus * 100) + ' % de gains' : 'Gardes standards'}</small></div>`).join('')}</div>`;
}
function pageApp() {
  const pl = ST.plan;
  return `<h2>Approche</h2><div class="sub">Comment tu atteins l'île, où tu te poses et par où tu repars.</div>
  <div class="sec">Véhicule d'approche</div><div class="grid g3">${CFG.approaches.map(a => card(pl.approach === a.id, a.label, a.desc, '', `data-set="approach" data-v="${a.id}"`)).join('')}</div>
  <div class="sec">Point d'infiltration</div><div class="grid g4">${CFG.infils.map(a => card(pl.infil === a.id, a.label, '', '', `data-set="infil" data-v="${a.id}"`)).join('')}</div>
  <div class="sec">Point d'extraction</div><div class="grid g3">${CFG.exfils.map(a => card(pl.exfil === a.id, a.label, '', '', `data-set="exfil" data-v="${a.id}"`)).join('')}</div>`;
}
function pageEq() {
  const pl = ST.plan;
  return `<h2>Équipement</h2><div class="sub">L'armement est fourni au départ et repris à la fin. Le matériel doit être récupéré avant de partir (onglet Préparatifs).</div>
  <div class="sec">Armement</div><div class="grid g2">${CFG.loadouts.map(l => card(pl.loadout === l.id, l.label, l.desc, '', `data-set="loadout" data-v="${l.id}"`)).join('')}</div>
  <div class="sec">Matériel</div><div class="grid g3">${CFG.equipment.filter(e => e.group !== 'dis').map(e => card(pl.equipment[e.id], e.label, e.desc, ST.prep[e.id] ? '<div class="v" style="color:#6ee07f">Récupéré</div>' : (pl.equipment[e.id] ? '<div class="v" style="color:#ffb4b6">À récupérer</div>' : ''), `data-set="equipment" data-v="${e.id}"`)).join('')}</div>
  <div class="sec">Perturbations (affaiblissent la sécurité)</div><div class="grid g3">${CFG.equipment.filter(e => e.group === 'dis').map(e => card(pl.equipment[e.id], e.label, e.desc, ST.prep[e.id] ? '<div class="v" style="color:#6ee07f">Récupéré</div>' : (pl.equipment[e.id] ? '<div class="v" style="color:#ffb4b6">À récupérer</div>' : ''), `data-set="equipment" data-v="${e.id}"`)).join('')}</div>`;
}
function pageTeam() {
  const L = isLead();
  return `<h2>Équipe</h2><div class="sub">${CFG.players.min} à ${CFG.players.max} joueurs. Le total des parts doit faire 100 %.</div>
  <div class="sec">Membres</div>${ST.members.map(m => `<div class="line"><div class="av ${m.leader ? 'lead' : ''}">${esc(m.name.slice(0, 1).toUpperCase())}</div><div class="nm">${esc(m.name)}<small>${m.leader ? 'Chef d\'équipe' : 'Membre'}</small></div>${m.leader ? '<span class="tag lead">Chef</span>' : ''}<input class="cut" data-cut="${m.id}" value="${m.cut}" ${L ? '' : 'disabled'}><span style="color:var(--mu)">%</span></div>`).join('')}
  ${L ? '<div style="margin-top:12px"><span class="btn pri" data-act="cuts">Valider les parts</span></div>' : ''}
  ${L && ST.members.length < CFG.players.max ? `<div class="sec">Inviter un joueur proche</div>${nearby.length ? nearby.map(n => `<div class="line"><div class="av">${esc(String(n.name).slice(0, 1).toUpperCase())}</div><div class="nm">${esc(n.name)}<small>ID ${n.id}</small></div><span class="btn" data-invite="${n.id}">Inviter</span></div>`).join('') : '<div class="empty">Personne à proximité (40 m).</div>'}<span class="btn" data-act="refresh" style="margin-top:6px">Actualiser</span>` : ''}
  <div style="margin-top:22px"><span class="btn" data-act="leave" style="color:#ffb4b6">${L && ST.members.length > 1 ? 'Dissoudre l\'équipe' : 'Quitter'}</span></div>`;
}
function pagePrep() {
  const pl = ST.plan;
  const sc = CFG.scope.map(s => `<div class="line"><div class="nm">${esc(s.label)}<small>Survole l'île au drone et marque ${s.targets} repères (G) — depuis le poste de planification</small></div><span class="tag ${ST.scope[s.id] ? 'ok' : ''}">${ST.scope[s.id] ? 'Fait' : 'À faire'}</span><span class="btn pri" data-drone="${s.id}">${ic('play')}Lancer le drone</span></div>`).join('');
  const eq = CFG.equipment.filter(e => pl.equipment[e.id]).map(e => `<div class="line"><div class="nm">${esc(e.label)}<small>Récupère-le au point indiqué (des gardes surveillent le lieu)</small></div><span class="tag ${ST.prep[e.id] ? 'ok' : ''}">${ST.prep[e.id] ? 'Récupéré' : 'À faire'}</span><span class="btn" data-gps="equip:${e.id}">${ic('pin')}GPS</span></div>`).join('');
  return `<h2>Préparatifs</h2><div class="sub">À faire sur le continent avant le lancement. Les points apparaissent sur ta carte.</div>
  <div class="sec">Reconnaissances (${Object.keys(ST.scope).length} / ${CFG.scopeRequired} obligatoires)</div>${sc}
  <div class="sec">Matériel</div>${eq || '<div class="empty">Aucun matériel sélectionné (onglet Équipement).</div>'}`;
}
const PAGES = { obj: pageObj, app: pageApp, eq: pageEq, team: pageTeam, prep: pagePrep };

function estimate() {
  const pl = ST.plan, t = byId(CFG.targets, pl.target);
  if (!t) return 0;
  let v = t.value;
  if (pl.difficulty === 'hard') v *= 1 + CFG.hardBonus;
  return v * (1 - (CFG.fees.pavel + CFG.fees.fence) / 100);
}
function render() {
  if (!CFG || !ST) return;
  const pl = ST.plan, ready = ST.missing.length === 0 && ST.cooldown === 0 && isLead();
  const me = ST.members.find(m => m.id === ST.me), cut = me ? me.cut : 100;
  const TABS = [['obj', 'Objectifs', 'target'], ['app', 'Approche', 'route'], ['eq', 'Équipement', 'gear'], ['team', 'Équipe', 'users'], ['prep', 'Préparatifs', 'list']];
  const badge = id => id === 'prep' ? (ST.missing.some(m => /Reconn|Matériel/.test(m)) ? '<em>!</em>' : '<em class="ok">✓</em>') : '';
  const scroll = $('.main') ? $('.main').scrollTop : 0;
  stage.innerHTML = `<div class="tab"><div class="scr">
    <div class="hd"><div class="logo"><i>${ic('sub')}</i><div><b>Kosatka</b><span>${esc(CFG.title || 'Planification — Cayo Perico')}</span></div></div>
      <div class="tabs">${TABS.map(([k, l, i]) => `<div class="tb ${tab === k ? 'on' : ''}" data-tab="${k}">${ic(i)}${l}${badge(k)}</div>`).join('')}</div><div class="sp"></div>
      <div class="crew">${ST.members.map(m => `<div class="av ${m.leader ? 'lead' : ''}" title="${esc(m.name)}">${esc(m.name.slice(0, 1).toUpperCase())}</div>`).join('')}</div><div class="x" data-act="close">${ic('x')}</div></div>
    <div class="bd"><div class="main">${PAGES[tab]()}</div>
      <div class="side"><div class="map"><div class="lbl">Cayo Perico</div>${mapSvg()}<div class="leg"><span><i style="background:#3fb950"></i>Infiltration</span><span><i style="background:#f0b323"></i>Coffre</span><span><i style="background:#29c7b8"></i>Extraction</span><span><i style="background:#e5484d"></i>Gardes</span></div></div>
        <div class="sum"><div class="row"><span>Cible</span><b>${pl.target ? esc(byId(CFG.targets, pl.target).label) : '—'}</b></div>
          <div class="row"><span>Approche</span><b>${pl.approach ? esc(byId(CFG.approaches, pl.approach).label) : '—'}</b></div>
          <div class="row"><span>Armement</span><b>${pl.loadout ? esc(byId(CFG.loadouts, pl.loadout).label) : '—'}</b></div>
          <div class="row"><span>Frais de lancement</span><b>${money(CFG.launchFee)}</b></div>
          <div class="row"><span>Estimation de ta part (cible seule)</span><span class="big">${money(estimate() * cut / 100)}</span></div>
          <div class="miss">${ST.cooldown ? `<div>${ic('warn')}Nouveau braquage possible dans ${Math.ceil(ST.cooldown / 60)} min</div>` : ''}${ST.missing.map(m => `<div>${ic('warn')}${esc(m)}</div>`).join('')}</div>
          <div class="go ${ready ? '' : 'off'}" data-act="launch">${ic('play')}${isLead() ? 'Lancer le braquage' : 'En attente du chef'}</div></div></div></div></div></div>`;
  stage.hidden = false;
  const m = $('.main'); if (m) m.scrollTop = scroll;
}

// ───────── actions ─────────
stage.addEventListener('click', e => {
  const t = e.target.closest('[data-tab],[data-set],[data-act],[data-gps],[data-invite],[data-drone]');
  if (!t) return;
  const d = t.dataset;
  if (d.tab) { tab = d.tab; if (tab === 'team') loadNearby(); return render(); }
  if (d.set) return post('set', { field: d.set, value: d.v });
  if (d.invite) return post('invite', { id: +d.invite });
  if (d.drone) return post('drone', { id: d.drone });
  if (d.gps) { const [kind, id] = d.gps.split(':'); return post('gps', { kind, id }); }
  if (d.act === 'close') return post('close');
  if (d.act === 'leave') { post('leave'); return; }
  if (d.act === 'refresh') return loadNearby();
  if (d.act === 'cuts') { const cuts = {}; stage.querySelectorAll('[data-cut]').forEach(i => cuts[i.dataset.cut] = +i.value); return post('cuts', { cuts }); }
  if (d.act === 'launch') return post('launch').then(r => { if (r && r.err) toast(r.err); });
});
function toast(msg) { const t = document.createElement('div'); t.textContent = msg; t.style.cssText = 'position:absolute;left:50%;bottom:70px;transform:translateX(-50%);background:#e5484d;color:#fff;padding:12px 22px;border-radius:10px;font-weight:600;z-index:9'; stage.appendChild(t); setTimeout(() => t.remove(), 3500); }
function loadNearby() { post('nearby').then(r => { nearby = r || []; if (tab === 'team') render(); }); }
addEventListener('keydown', e => { if (e.key === 'Escape' && !stage.hidden) post('close'); });
addEventListener('message', e => {
  const m = e.data;
  if (m.a === 'open') { CFG = m.cfg; ST = m.state; tab = 'obj'; nearby = []; render(); }
  else if (m.a === 'state') { ST = m.state; render(); }
  else if (m.a === 'close') { stage.hidden = true; }
});

// ───────── démonstration (navigateur seulement) ─────────
if (!IN_GAME) {
  CFG = {
    title: 'Planification — Cayo Perico', launchFee: 25000, scopeRequired: 2, bag: 100, hardBonus: 0.1, fees: { pavel: 2, fence: 10 }, players: { min: 1, max: 4 }, vault: { x: 5006.7, y: -5754.2 },
    targets: [['tequila', 'Tequila Sinsimito', 630000, 'Une bouteille rare dans le bureau d\'El Rubio.'], ['ruby', 'Collier de rubis', 700000, 'Dans le coffre de la salle de sécurité.'], ['bonds', 'Bons au porteur', 770000, 'Une mallette dans le coffre de la villa.'], ['diamond', 'Diamant rose', 1300000, 'Exposé dans la vitrine de la salle de réception.'], ['files', 'Dossiers Madrazo', 1100000, 'Archives compromettantes d\'El Rubio.'], ['panther', 'Statue de la panthère', 1900000, 'La pièce maîtresse de la collection.']].map(([id, label, value, desc]) => ({ id, label, value, desc })),
    loot: { cash: { label: 'Liquide', units: 18, value: 90000 }, weed: { label: 'Cannabis', units: 25, value: 140000 }, coke: { label: 'Cocaïne', units: 25, value: 220000 }, gold: { label: 'Or', units: 33, value: 330000 }, art: { label: 'Tableaux', units: 20, value: 190000 }, jewel: { label: 'Bijoux', units: 12, value: 80000 } },
    approaches: [['kosatka', 'Kosatka (sous-marin)', 'Insertion discrète à la nage depuis le sous-marin.'], ['longfin', 'Longfin', 'Bateau rapide : accoste sur la plage.'], ['patrol', 'Patrouilleur', 'Bateau armé : arrivée au port principal.'], ['annihilator', 'Annihilator Stealth', 'Hélicoptère furtif : dépose sur les côtes.'], ['alkonost', 'Alkonost', 'Avion : largage en parachute au-dessus de l\'île.'], ['velum', 'Velum', 'Avion léger : largage près de l\'aérodrome.']].map(([id, label, desc]) => ({ id, label, desc })),
    infils: [{ id: 'airstrip', label: 'Aérodrome', x: 4458, y: -4466 }, { id: 'dock', label: 'Port principal', x: 5124, y: -5134 }, { id: 'beach', label: 'Plage', x: 4886, y: -5176 }, { id: 'drain', label: 'Canal d\'évacuation', x: 5057, y: -5785 }],
    exfils: [{ id: 'dock', label: 'Port principal', x: 5136, y: -5140 }, { id: 'airstrip', label: 'Aérodrome', x: 4476, y: -4496 }, { id: 'beach', label: 'Plage', x: 4884, y: -5170 }],
    equipment: [['grapple', 'Grappin', 'Escalader la clôture et les toits.'], ['cutters', 'Pince coupante', 'Couper les grillages et les portails.'], ['torch', 'Chalumeau', 'Découper la porte blindée du coffre.'], ['cloner', 'Cloneur d\'empreintes', 'Ouvrir la salle de sécurité sans alarme.'], ['uniform', 'Uniforme de garde', 'Les gardes mettent plus de temps à vous repérer.'], ['silencer', 'Silencieux', 'Les tirs ne déclenchent pas l\'alarme.'], ['glasscutter', 'Coupe-verre', 'Ouvrir les vitrines sans les briser.']].map(([id, label, desc]) => ({ id, label, desc })).concat([['dis_weapons', 'Perturbation : armes', 'Les gardes n\'ont que des pistolets.'], ['dis_armor', 'Perturbation : gilets', 'Gardes sans gilet pare-balles.'], ['dis_air', 'Perturbation : aérien', 'Aucun hélicoptère de renforts.']].map(([id, label, desc]) => ({ id, label, desc, group: 'dis' }))),
    loadouts: [['aggressor', 'Agresseur', 'Carabine et fusil à pompe : puissance de feu.'], ['conspirator', 'Conspirateur', 'SMG et pistolet : mobile et polyvalent.'], ['crackshot', 'Tireur d\'élite', 'Fusil de précision et pistolet.'], ['saboteur', 'Saboteur', 'Micro-SMG et explosifs légers.']].map(([id, label, desc]) => ({ id, label, desc })),
    difficulties: { normal: { label: 'Normal' }, hard: { label: 'Difficile' } },
    scope: [{ id: 'airstrip', label: 'Aérodrome', targets: 3 }, { id: 'dock', label: 'Port principal', targets: 3 }, { id: 'compound', label: 'Complexe d\'El Rubio', targets: 3 }], elite: { time: 1200, bonus: 50000, bonusHard: 100000 }, spots: { panther: { x: 5006.7, y: -5754.2 }, diamond: { x: 5012, y: -5730 } },
    zones: [{ x: 5006, y: -5745, count: 5 }, { x: 4985, y: -5715, count: 3 }, { x: 5124, y: -5134, count: 4 }, { x: 4460, y: -4470, count: 4 }, { x: 4886, y: -5176, count: 3 }, { x: 5130, y: -5520, count: 3 }, { x: 4510, y: -4560, count: 3 }]
  };
  ST = { me: 1, leader: 1, phase: 'plan', cooldown: 0, members: [{ id: 1, name: 'Maly Pablo', cut: 60, leader: true }, { id: 2, name: 'Jean Dupont', cut: 40 }],
    plan: { elite: true, target: 'panther', approach: 'longfin', infil: 'dock', exfil: 'beach', loadout: 'conspirator', difficulty: 'hard', equipment: { grapple: true, cutters: true, torch: true } },
    scope: { airstrip: true }, prep: { grapple: true }, missing: ['Reconnaissances : 1 / 2', 'Matériel à récupérer : Pince coupante', 'Matériel à récupérer : Chalumeau'] };
  const q = new URLSearchParams(location.search); tab = q.get('tab') || 'obj';
  nearby = [{ id: 7, name: 'Lucas Martin' }];
  render();
}
