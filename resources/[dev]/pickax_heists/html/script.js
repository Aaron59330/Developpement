const $ = (s, r = document) => r.querySelector(s);
const h = (tag, a, ...kids) => { const [t, ...cl] = tag.split('.'); const e = document.createElement(t); if (cl.length) e.className = cl.join(' '); for (const k in (a || {})) { if (a[k] == null) continue; if (k === 'html') e.innerHTML = a[k]; else if (k.startsWith('on')) e.addEventListener(k.slice(2), a[k]); else e.setAttribute(k, a[k]); } kids.flat().forEach(c => c != null && e.append(c.nodeType ? c : document.createTextNode(c))); return e; };
const post = (n, d) => (typeof GetParentResourceName === 'function' ? fetch(`https://${GetParentResourceName()}/${n}`, { method: 'POST', body: JSON.stringify(d || {}) }).catch(() => 0) : Promise.resolve());
const KIND = { prep: 'Préparatif', setup: 'Mise en place', finale: 'Finale' };
const ST = { ready: 'Disponible', done: 'Terminé', locked: 'Verrouillé' };
const PAY = { normal: 1282500, hard: 1603125 };
let S = { inCrew: false }, sel = null, timer = null;
const fmtT = ms => { const s = Math.max(0, Math.floor(ms / 1000)); return String(Math.floor(s / 60)).padStart(2, '0') + ':' + String(s % 60).padStart(2, '0'); };
const initials = n => (n || '?').split(' ').map(x => x[0]).slice(0, 2).join('').toUpperCase();

function toast(t, k) { const e = h('div.' + (k || 'ok'), null, t); $('#toast').append(e); setTimeout(() => e.remove(), 3200); }

function hero(heist) {
  const p = h('div.panel.single', null, h('div.hero', null,
    h('div.eyebrow', null, heist.act),
    h('h1', null, heist.label),
    h('p', null, heist.brief),
    h('div.chips', null, ['2 à 4 joueurs', '3 préparatifs · 4 mises en place', 'Finale en 2 équipes', 'Défi Élite'].map(c => h('div.chip', null, c))),
    h('div.row', null, h('button.btn.pri', { onclick: () => post('create', { heist: heist.id }) }, 'Créer l’équipe'), h('button.btn', { onclick: close }, 'Fermer'))));
  return p;
}

function missionCard(m) {
  const c = h('div.m.' + m.status + (m.finale ? '.finale' : '') + (sel === m.id ? '.on' : ''), { onclick: () => { sel = sel === m.id ? null : m.id; draw(); } },
    h('div.k', null, KIND[m.kind] || m.kind), h('b', null, m.label), h('p', null, m.brief), h('span.st.' + m.status, null, ST[m.status]));
  return c;
}

function detail(m) {
  const left = h('div', null, h('div.eyebrow', null, KIND[m.kind]), h('h2', null, m.label), h('div.br', null, m.brief));
  let right;
  if (m.teams) right = h('div.teams', null, m.teams.map(t => h('div.' + t.id, null, h('h4', null, t.label), h('ol.steps', null, (m.steps[t.id] || []).map(s => h('li', null, s))))));
  else right = h('ol.steps', null, (m.steps || []).map(s => h('li', null, s)));
  const need = m.finale ? S.min : Math.max(m.players ? m.players[0] : 1, 1);
  const can = S.leader && !S.running && m.status === 'ready' && S.crew.length >= need && !(m.finale && S.cooldown > 0);
  const hint = m.status === 'locked' ? 'Terminez d’abord les missions préalables.' : m.status === 'done' ? 'Mission déjà terminée.' : !S.leader ? 'Seul le chef peut lancer.' : S.crew.length < need ? `Il faut ${need} joueur(s).` : (m.finale && S.cooldown > 0 ? `Prochain finale dans ${Math.ceil(S.cooldown / 60)} min.` : '');
  left.append(h('div.go', null, h('button.btn.grn', { disabled: can ? null : 'disabled', onclick: () => post('start', { mission: m.id }) }, m.finale ? 'Lancer le finale' : 'Lancer la mission'), h('small', null, hint)));
  return h('div.detail', null, left, right);
}

function board() {
  const heist = S.heists.find(x => x.id === S.heist) || S.heists[0];
  const bySec = k => S.missions.filter(m => m.kind === k);
  const done = S.missions.filter(m => m.status === 'done').length;
  const side = h('div.side', null,
    h('div', null, h('div.eyebrow', null, heist.act), h('h1', null, heist.label)),
    h('div', null, h('div.lbl', null, 'Difficulté'), h('div.seg', null, ['normal', 'hard'].map(d => h('button' + (S.difficulty === d ? '.on' : ''), { onclick: () => S.leader && !S.running && post('difficulty', { value: d }) }, d === 'normal' ? 'Normal' : 'Difficile')))),
    h('div', null, h('div.lbl', null, `Équipe (${S.crew.length}/${S.max})`),
      S.crew.map(c => h('div.member', null, h('div.av', null, initials(c.name)), h('div', null, h('b', null, c.name), h('small', null, c.leader ? 'Chef' : 'Membre')), c.team ? h('span.tag.' + c.team, null, c.team === 'sub' ? 'Sous-marin' : c.team === 'air' ? 'Air' : c.team) : (c.leader ? h('span.tag', null, 'Chef') : null))),
      S.leader && !S.running ? h('div.invite', null, h('input', { id: 'inv', placeholder: 'ID du joueur', inputmode: 'numeric' }), h('button.btn.pri', { onclick: () => { const v = $('#inv').value; if (v) post('invite', { id: v }); $('#inv').value = ''; } }, 'Inviter')) : null),
    h('div.stats', null, h('div.stat', null, h('small', null, 'Progression'), h('b', null, `${done}/${S.missions.length}`)), h('div.stat', null, h('small', null, 'Finales'), h('b', null, S.finales || 0)),
      h('div.stat', null, h('small', null, 'Gain'), h('b', null, '$' + ((S.payout || PAY[S.difficulty]) * (S.mult || 0.02)).toLocaleString('fr-FR', { maximumFractionDigits: 0 }))), h('div.stat', null, h('small', null, 'Défi Élite'), h('b', null, '15:00'))),
    S.running ? h('button.btn.red', { onclick: () => post('abort') }, 'Annuler la mission en cours') : null,
    h('button.btn', { onclick: () => post('leave') }, S.leader ? 'Dissoudre l’équipe' : 'Quitter l’équipe'));
  const sect = (t, list) => list.length ? h('div.sect', null, h('h3', null, t), h('div.grid', null, list.map(missionCard))) : null;
  const m = S.missions.find(x => x.id === sel);
  const main = h('div.main', null, h('div.top', null, h('div', null, h('div.eyebrow', null, 'Tableau de planification'), h('div.act', null, 'Réalisez les préparatifs et les mises en place, puis lancez le finale.')), h('button.x', { onclick: close }, '✕')),
    m ? detail(m) : null, sect('Préparatifs', bySec('prep')), sect('Mises en place', bySec('setup')), sect('Finale', bySec('finale')));
  return h('div.panel', null, side, main);
}

function draw() {
  const root = $('#board'); if (root.classList.contains('hidden')) return;
  const scroll = $('.main', root) ? $('.main', root).scrollTop : 0; root.innerHTML = '';
  if (!S.inCrew) root.append(hero(S.heists[0])); else root.append(board());
  const mn = $('.main', root); if (mn) mn.scrollTop = scroll;
}
function close() { $('#board').classList.add('hidden'); post('close'); }

function hud(d) {
  const el = $('#hud'); clearInterval(timer);
  if (!d.show) { el.classList.add('hidden'); return; }
  el.classList.remove('hidden'); el.innerHTML = '';
  const t0 = Date.now() - (d.elapsed || 0);
  const tm = h('span', null, '00:00'); const pct = ((d.step - 1) / d.total) * 100;
  el.append(h('div.h1', null, h('span', null, d.mission), tm), h('div.t', null, d.label), h('div.s', { id: 'hs' }, ''),
    h('div.bar', null, h('i', { style: `width:${Math.max(6, pct)}%` })),
    d.team ? h('span.team' + (/a[ée]rienne/i.test(d.team) ? '.air' : ''), null, d.team) : null,
    h('div.s', { style: 'margin-top:8px' }, `Objectif ${d.step} / ${d.total}`));
  const tick = () => { tm.textContent = fmtT(Date.now() - t0); }; tick(); timer = setInterval(tick, 1000);
}

window.addEventListener('message', e => {
  const d = e.data || {};
  if (d.action === 'open') { S = d.state; $('#board').classList.remove('hidden'); draw(); }
  else if (d.action === 'state') { S = d.state; draw(); }
  else if (d.action === 'close') $('#board').classList.add('hidden');
  else if (d.action === 'toast') toast(d.text, d.kind);
  else if (d.action === 'hud') hud(d);
  else if (d.action === 'hudSub') { const s = $('#hs'); if (s) s.textContent = d.text || ''; }
  else if (d.action === 'briefing') { const b = $('#brief'); b.innerHTML = ''; b.append(h('div.e', null, d.team || 'Nouvelle mission'), h('b', null, d.title), h('p', null, d.text)); b.classList.remove('hidden'); setTimeout(() => b.classList.add('hidden'), 9000); }
  else if (d.action === 'result') { const r = $('#result'); r.innerHTML = ''; r.append(h('div', null, h('small', null, 'Braquage'), h('b.' + (d.ok ? 'ok' : 'ko'), null, d.text))); r.classList.remove('hidden'); setTimeout(() => r.classList.add('hidden'), 4500); }
});
document.addEventListener('keydown', e => { if (e.key === 'Escape' && !$('#board').classList.contains('hidden')) close(); });
