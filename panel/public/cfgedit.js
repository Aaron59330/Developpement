'use strict';
// ───────── Tous les réglages des scripts : chaque prix, durée, activation et texte des fichiers de configuration ─────────
// Lit le fichier de configuration du script sur ton serveur, affiche chaque valeur simple, et ne remplace que la valeur modifiée
// (commentaires et mise en forme conservés, historique des versions, vérification de la syntaxe Lua).
PAGES.cfg = async function () {
  const s = curServer(); if (!s) return needServer();
  const CAT = window.CFG_CATALOG || [], root = el('div');
  const PRICE = /price|prix|cost|cout|coût|amount|montant|salary|salaire|reward|recompense|récompense|fee|amende|fine|tax|taxe|money|argent|cash|bonus|gain|pay|paie|caution|bail|rent|loyer|commission|fare|tarif|buy|sell|vente|achat|stock|cap/i;
  const TIME = /time|duration|delay|cooldown|minute|second|interval|wait|timer|duree|durée|temps|heure|hour|day|jour|expire|ttl/i;
  const human = k => String(k).replace(/([a-z0-9])([A-Z])/g, '$1 $2').replace(/[_\-]+/g, ' ').replace(/^./, c => c.toUpperCase());
  let cur = null, ents = [], mods = new Map(), filter = 'all', q = '', open = new Set(), catq = '';
  const kindOf = e => e.k === 'boolean' ? 'bool' : e.k === 'string' ? 'text' : PRICE.test(e.p.join('.')) ? 'price' : TIME.test(e.p.join('.')) ? 'time' : 'num';
  const FIL = [['all', 'Tout'], ['price', 'Prix et montants'], ['time', 'Durées et délais'], ['bool', 'Activations'], ['text', 'Textes']];
  const side = el('div', { class: 'cfg-side card' }), main = el('div', { class: 'cfg-main' }), bar = el('div');
  const drawSide = () => {
    const t = catq.toLowerCase(), groups = {};
    CAT.filter(f => !t || (f.name + ' ' + f.path).toLowerCase().includes(t)).forEach(f => (groups[f.cat] = groups[f.cat] || []).push(f));
    side.replaceChildren(el('input', { placeholder: 'Rechercher un script…', value: catq, oninput: e => { catq = e.target.value; drawSide(); }, style: 'margin-bottom:10px' }),
      ...Object.entries(groups).flatMap(([c, list]) => [el('div', { class: 'cfg-cat' }, c), ...list.map(f => el('a', { href: '#', class: 'cfg-f' + (cur && cur.path === f.path ? ' on' : ''), onclick: ev => { ev.preventDefault(); load(f); } }, el('span', {}, f.name), el('small', {}, `${f.n} valeurs${f.price ? ' · ' + f.price + ' prix' : ''}`)))]));
  };
  const setVal = (e, v) => { const key = e.s + ':' + e.e; if (JSON.stringify(v) === JSON.stringify(e.v)) mods.delete(key); else mods.set(key, { e, v }); updBar(); };
  const rowEl = e => {
    const key = e.s + ':' + e.e, kd = kindOf(e); const m = () => mods.get(key); const val = () => (m() ? m().v : e.v);
    let inp;
    if (e.k === 'boolean') inp = el('input', { type: 'checkbox', class: 'sw', checked: !!val(), onchange: ev => { setVal(e, ev.target.checked); mark(); } });
    else if (e.k === 'number') inp = el('input', { type: 'number', step: 'any', value: val(), style: 'max-width:200px', oninput: ev => { if (ev.target.value !== '') setVal(e, Number(ev.target.value)); mark(); } });
    else inp = el('input', { value: val(), oninput: ev => { setVal(e, ev.target.value); mark(); } });
    const dot = el('span', { class: 'pill acc', style: 'margin-left:8px;display:none' }, 'modifié'), rs = el('button', { class: 'btn s', title: 'Remettre la valeur d’origine', style: 'visibility:hidden', onclick: () => { mods.delete(key); updBar(); if (e.k === 'boolean') inp.checked = !!e.v; else inp.value = e.v; mark(); } }, el('span', {}, '↺'));
    const mark = () => { const on = mods.has(key); dot.style.display = on ? '' : 'none'; rs.style.visibility = on ? 'visible' : 'hidden'; row.classList.toggle('unsaved', on); };
    const path = e.p.slice(1); const last = human(path[path.length - 1]); const label = (e.l ? e.l + ' — ' : '') + last;
    const row = el('div', { class: 'setrow cfg-row' }, el('div', { class: 'row' }, el('b', {}, label), dot, el('span', { class: 'cfg-kind k-' + kd }, { price: 'prix', time: 'durée', bool: 'activation', text: 'texte', num: 'nombre' }[kd])), el('div', { class: 'muted', style: 'font-size:12px;margin:2px 0 6px' }, e.c || '', el('span', { class: 'cfg-path' }, ' ' + e.p.join(' › '))), el('div', { class: 'row' }, inp, rs));
    mark(); return row;
  };
  const visible = () => { const t = q.toLowerCase(); return ents.filter(e => (filter === 'all' || kindOf(e) === filter) && (!t || (e.p.join(' ') + ' ' + (e.c || '') + ' ' + (e.l || '') + ' ' + (typeof e.v === 'string' ? e.v : '')).toLowerCase().includes(t))); };
  const groupKey = e => { const segs = e.p.slice(0, -1).filter(x => typeof x !== 'number'); return (segs.slice(0, 2).join(' › ') || e.p[0]); };
  const drawBody = () => {
    if (!cur) return main.replaceChildren(el('div', { class: 'card empty' }, el('h2', {}, 'Choisis un script à gauche'), el('p', {}, 'Tu peux modifier chacun de ses prix, durées, activations et textes. Le fichier d’origine est sauvegardé dans l’historique à chaque enregistrement.')));
    const list = visible(), groups = new Map(); list.forEach(e => { const k = groupKey(e); (groups.get(k) || groups.set(k, []).get(k)).push(e); });
    const search = q !== '' ; const parts = [];
    for (const [k, rows] of groups) {
      const isOpen = open.has(k) || search || groups.size === 1; const nm = rows.filter(e => mods.has(e.s + ':' + e.e)).length;
      parts.push(el('div', { class: 'card cfg-grp' }, el('div', { class: 'cfg-gh', onclick: () => { if (open.has(k)) open.delete(k); else open.add(k); drawBody(); } }, el('b', {}, human(k.replace(/ › /g, ' › '))), el('span', { class: 'muted' }, `${rows.length} valeur${rows.length > 1 ? 's' : ''}${nm ? ' · ' + nm + ' modifiée' + (nm > 1 ? 's' : '') : ''}`)), isOpen ? el('div', {}, ...rows.slice(0, 300).map(rowEl), rows.length > 300 ? el('p', { class: 'muted', style: 'padding:10px' }, `+ ${rows.length - 300} autres : utilise la recherche pour les afficher.`) : null) : null));
    }
    main.replaceChildren(el('div', { class: 'ex-chips' }, ...FIL.map(([k, l]) => el('button', { class: 'btn s' + (filter === k ? ' p' : ''), onclick: () => { filter = k; drawBody(); } }, el('span', {}, l + (k === 'all' ? '' : ' (' + ents.filter(e => kindOf(e) === k).length + ')'))))),
      el('input', { placeholder: 'Rechercher une valeur (prix, nom, mot du commentaire)…', value: q, oninput: ev => { q = ev.target.value; clearTimeout(drawBody.t); drawBody.t = setTimeout(() => { drawBody(); const i = main.querySelector('input[placeholder^=Rech]'); if (i) { i.focus(); i.setSelectionRange(q.length, q.length); } }, 250); }, style: 'margin:8px 0 12px;max-width:520px' }),
      ...(parts.length ? parts : [el('div', { class: 'card empty' }, 'Aucune valeur ne correspond.')]));
  };
  const resName = () => (cur.path.match(/^\[[^\]]+\]\/([^\/]+)\//) || [])[1];
  const restartBox = el('input', { type: 'checkbox', style: 'width:auto' });
  const saveBtn = el('button', { class: 'btn p', onclick: async () => {
    if (!mods.size) return toast('Aucune modification', 'bad');
    const edits = [...mods.values()].map(({ e, v }) => ({ s: e.s, e: e.e, r: e.r, v }));
    const r = await api('POST', `/api/servers/${s.id}/cfg/save`, { path: cur.path, edits, restart: restartBox.checked }); if (!r.ok) return toast(r.error, 'bad');
    toast(`${r.count} valeur${r.count > 1 ? 's' : ''} enregistrée${r.count > 1 ? 's' : ''}${r.restarted ? ' : ' + r.resource + ' redémarre' : ' : redémarre ' + (r.resource || 'la ressource') + ' pour les appliquer'}`, 'ok'); mods.clear(); await load(cur, true);
  } }, el('span', {}, 'Enregistrer'));
  const updBar = () => { saveBtn.firstChild.textContent = mods.size ? `Enregistrer (${mods.size})` : 'Enregistrer'; };
  async function load(f, keep) {
    if (!keep && mods.size && !confirm('Des modifications ne sont pas enregistrées : les abandonner ?')) return;
    cur = f; mods.clear(); q = ''; open = new Set(); main.replaceChildren(el('div', { class: 'card empty' }, 'Lecture du fichier sur le serveur…')); drawSide();
    const r = await api('GET', `/api/servers/${s.id}/cfg/read?path=${encodeURIComponent(f.path)}`);
    if (!r.ok) { ents = []; return main.replaceChildren(el('div', { class: 'card empty' }, el('h2', {}, 'Lecture impossible'), el('p', {}, r.error), el('p', { class: 'muted' }, 'Le serveur doit être en ligne avec pickax_panel démarré.'))); }
    ents = r.entries; restartBox.checked = resName() !== 'pickax_core'; updBar();
    bar.replaceChildren(el('div', { class: 'cfg-bar' }, el('div', {}, el('b', {}, f.name), el('div', { class: 'muted', style: 'font-size:12px' }, f.path + ' · ' + ents.length + ' valeurs' + (r.truncated ? ' (liste tronquée)' : ''))), el('div', { class: 'grow' }),
      el('label', { style: 'display:flex;gap:6px;align-items:center;text-transform:none;letter-spacing:0;margin:0;font-size:13px' }, restartBox, 'Redémarrer ' + (resName() || 'la ressource') + ' après', resName() === 'pickax_core' ? el('b', { style: 'color:#e5a23c' }, ' (coupe les menus quelques secondes)') : null), saveBtn));
    drawBody();
  }
  drawSide(); drawBody();
  root.append(head('Tous les réglages des scripts'),
    el('div', { class: 'pg-intro' }, el('b', {}, 'À quoi sert cette page ? '), `Elle ouvre le fichier de configuration de n’importe quel script (${CAT.length} fichiers, ${CAT.reduce((a, x) => a + x.n, 0).toLocaleString('fr-FR')} valeurs dont ${CAT.reduce((a, x) => a + x.price, 0).toLocaleString('fr-FR')} prix et montants) et te laisse modifier chaque prix, durée, activation ou texte sans toucher au code. Seule la valeur change : les commentaires et le reste du fichier restent intacts, avec un historique de versions. Le script doit être redémarré pour appliquer (case à cocher).`),
    bar, el('div', { class: 'cfg-wrap' }, side, main));
  return root;
};
