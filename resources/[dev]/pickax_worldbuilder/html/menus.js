/* ═══════════ Grands menus ═══════════
   Même gabarit que le garage (script.js › GaragePanel) : barre du haut, grande vue à gauche, cartes à droite, rail en bas.
   Fourrière, location, serrurier, occasion, essence, lavage, banque, auto-école, pôle emploi, zones PVP, course poursuite. */

const gxImg = (v, cls) => v && v.img
  ? `<img class="${cls}" src="vehicles/${esc(v.img)}.webp" data-fb="https://docs.fivem.net/vehicles/${esc(v.img)}.webp" alt="" draggable="false">`
  : `<span class="gx-noimg">${ic('car', 34)}</span>`;
const gxBar = (label, val, max = 100) => { const pc = Math.max(0, Math.min(100, Math.round((Number(val) || 0) / max * 100))); return `<div class="gx-stat"><span>${label}</span><b>${pc}</b><i><u style="width:${pc}%"></u></i></div>`; };
const gxKv = rows => `<div class="gx-kv">${rows.filter(Boolean).map(r => `<div><span>${r[0]}</span><b>${r[1]}</b></div>`).join('')}</div>`;
const gxCard = (title, body, small = '', cls = '') => `<div class="gx-card ${cls}">${title ? `<h3>${title}${small ? ` <small>${small}</small>` : ''}</h3>` : ''}${body}</div>`;
const gxTag = (text, cls = '') => `<span class="gx-tag ${cls}">${text}</span>`;
const gxCond = v => gxCard('État du véhicule', `<div class="gx-cond">${gxBar('Essence', v.fuel ?? 100, 100)}${gxBar('Moteur', v.engine ?? 1000, 1000)}${gxBar('Carrosserie', v.body ?? 1000, 1000)}</div>`);

function gxFrame({ icon, title, sub, tabs, active, main, empty, bottom }) {
  const seg = tabs && tabs.length > 1 ? `<div class="seg">${tabs.map(t => `<button class="${t[0] === active ? 'active' : ''}" data-a="tab" data-v="${esc(t[0])}">${t[2] ? ic(t[2], 14) + ' ' : ''}${esc(t[1])}</button>`).join('')}</div>` : '';
  return `<div class="gx"><div class="gx-top"><div class="gx-title">${ic(icon, 18)}<b>${esc(title)}</b>${sub ? `<small>${esc(sub)}</small>` : ''}</div>
    <div class="gx-tools">${seg}<button class="gx-x" data-a="close">Fermer <kbd>ESC</kbd></button></div></div>
    <div class="gx-main ${empty ? 'empty' : ''}">${main}</div>${bottom || ''}</div>`;
}
const gxTile = ({ key, thumb, title, sub, on }) => `<div class="gx-tile ${on ? 'on' : ''}" data-a="gsel" data-v="${esc(key)}">${thumb}<b>${esc(title)}</b><small>${esc(sub || '')}</small></div>`;
const gxRail = ({ count, total, tiles }) => `<div class="gx-bottom"><div class="gx-bar"><span>${count} / ${total}</span>
  <span class="gx-nav">Parcourir <button data-a="prev" aria-label="Précédent">${ic('chevL', 14)}</button><button data-a="next" aria-label="Suivant">${ic('chevR', 14)}</button></span></div>
  <div class="gx-rail" id="gx-rail">${tiles}</div></div>`;
const gxScroll = () => { const r = document.getElementById('gx-rail'), on = r && r.querySelector('.on'); if (on) on.scrollIntoView({ inline: 'center', block: 'nearest', behavior: 'smooth' }); };
const gxRing = (a, b, big, small) => `<div class="gx-ringwrap"><div class="gx-ring" id="gx-ring" style="--a:${a};--b:${b}"></div><div class="gx-ringtxt"><b id="gx-ringv">${big}</b><small>${small}</small></div></div>`;
const gxDisc = icon => `<div class="gx-art"><div class="gx-disc">${ic(icon)}</div></div>`;
const gxHero = (small, title, extra = '', art = '') => `<div class="gx-hero"><div class="gx-info"><small>${esc(small)}</small><h1>${esc(title)}</h1>${extra}</div>${art}</div>`;

/* Base : une grande vue de l'élément choisi + rail d'éléments en bas (← → pour parcourir) */
class Browser extends PanelBase {
  open(d) { this.i = 0; super.open(d); }
  list() { return []; }
  meta() { return { icon: 'grid', title: this.d.label }; }
  hero(v) { return { small: v.make || '' }; }
  side(v) { return ''; }
  empty() { return ''; }
  tile(x) { return { thumb: gxImg(x, 'gx-thumb'), title: x.name, sub: x.plate || x.make || '' }; }
  cur() { const l = this.list(); return l[Math.min(this.i, Math.max(0, l.length - 1))]; }
  heroHtml(v) {
    const h = this.hero(v);
    return `<div class="gx-hero"><div class="gx-info"><small>${esc(h.small || '')}</small><h1>${esc(v.name)}</h1>${h.plate ? `<div class="gx-plate">${esc(h.plate)}</div>` : ''}${h.tag || ''}</div><div class="gx-car">${gxImg(v, 'gx-big')}</div></div>`;
  }
  render() {
    const l = this.list();
    if (this.i >= l.length) this.i = Math.max(0, l.length - 1);
    const v = l[this.i], m = this.meta();
    const main = v ? this.heroHtml(v) + `<div class="gx-side">${this.side(v)}</div>` : `<div class="gx-emptybox">${this.empty()}</div>`;
    const bottom = l.length ? gxRail({ count: this.i + 1, total: l.length, tiles: l.map(x => { const t = this.tile(x); return gxTile({ key: x.key, thumb: t.thumb, title: t.title, sub: t.sub, on: v && x.key === v.key }); }).join('') }) : '';
    $root.innerHTML = gxFrame({ ...m, main, empty: !v, bottom });
    gxScroll();
  }
  move(dx) { const l = this.list(); if (!l.length) return; this.i = (this.i + dx + l.length) % l.length; this.render(); }
  async onA(el) {
    const a = el.dataset.a;
    if (a === 'pay') { this.method = el.dataset.v; return this.render(); }
    if (a === 'gsel') { this.i = Math.max(0, this.list().findIndex(x => x.key === el.dataset.v)); return this.render(); }
    if (a === 'prev') return this.move(-1);
    if (a === 'next') return this.move(1);
    if (a === 'tab') { this.tab = el.dataset.v; this.i = 0; return this.render(); }
    return this.onAction ? this.onAction(el, a) : undefined;
  }
}
document.addEventListener('keydown', e => {
  if (typeof Mod === 'undefined' || !(Mod instanceof Browser) || $root.classList.contains('hidden')) return;
  if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT')) return;
  if (e.key === 'ArrowLeft') { e.preventDefault(); Mod.move(-1); }
  else if (e.key === 'ArrowRight') { e.preventDefault(); Mod.move(1); }
  else if (e.key === 'Enter' && Mod.primary) { e.preventDefault(); Mod.primary(); }
});
document.addEventListener('wheel', e => { const r = e.target.closest && e.target.closest('#gx-rail'); if (r) { r.scrollLeft += e.deltaY; e.preventDefault(); } }, { passive: false });

const payBlock = (d, method, show = true) => show ? payRow(d.payments, method) : '';

/* ── Fourrière ── */
const ImpoundPanel = new (class extends Browser {
  init() { this.reason = ''; this.fee = 0; }
  list() { return this.d.vehicles.map(v => ({ ...v, key: v.plate })); }
  meta() { const n = this.d.vehicles.length; return { icon: 'truck', title: this.d.label, sub: `${n} véhicule${n > 1 ? 's' : ''} à ton nom` }; }
  hero(v) { return { small: v.make || 'Fourrière', plate: v.plate, tag: v.reason ? gxTag(ic('shield', 13) + ' ' + esc(v.reason), 'warn') : '' }; }
  tile(x) { return { thumb: gxImg(x, 'gx-thumb'), title: x.name, sub: money(x.fee) }; }
  seize() {
    const d = this.d;
    return d.canImpound ? gxCard(ic('shield', 16) + ' Mise en fourrière', `<label class="f"><span>Raison</span><input data-path="reason" maxlength="150" placeholder="Stationnement gênant…" value="${esc(this.reason)}"></label>
      <label class="f"><span>Frais (${esc(CUR)})</span><input type="number" min="0" data-path="fee" value="${this.fee}"></label>
      <button class="primary" style="width:100%" data-a="seize" ${d.hasVehicle ? '' : 'disabled'}>${ic('truck', 16)} Mettre le véhicule proche en fourrière</button>`) : '';
  }
  side(v) {
    return gxCard('Frais de fourrière', `<div class="gx-price">${money(v.fee)}</div><p class="gx-mute" style="padding:0">${v.reason ? 'Motif : ' + esc(v.reason) : 'Aucun motif indiqué.'}</p>`)
      + gxCond(v)
      + gxCard(null, `${payBlock(this.d, this.method)}<button class="primary gx-take" data-a="take" data-v="${esc(v.key)}">Récupérer le véhicule · ${money(v.fee)}</button>`, '', 'gx-act')
      + this.seize();
  }
  empty() { return emptyState('truck', 'Rien en fourrière', 'Aucun de tes véhicules n\'est ici.') + this.seize(); }
  primary() { const v = this.cur(); if (v) this.onAction({ dataset: { v: v.key } }, 'take'); }
  async onAction(el, a) {
    if (a === 'take') { const r = await this.act('impound:take', el.dataset.v, this.method); if (r && r.ok) $root.classList.add('hidden'); }
    if (a === 'seize') { const r = await this.act('impound:seize', this.reason, this.fee); if (r && r.ok) $root.classList.add('hidden'); }
  }
})();

/* ── Location ── */
const RentalPanel = new (class extends Browser {
  list() { return this.d.fleet.map(f => ({ ...f, key: String(f.i) })); }
  meta() { const d = this.d; return { icon: 'key', title: d.label, sub: d.minutes ? `Durée : ${d.minutes} minutes` : 'Sans limite de durée' }; }
  hero(v) { return { small: v.make || 'Location', tag: gxTag(money(v.price) + ' + caution ' + money(v.deposit)) }; }
  tile(x) { return { thumb: gxImg(x, 'gx-thumb'), title: x.name, sub: money(x.price + x.deposit) }; }
  side(v) {
    const d = this.d;
    return (d.current ? gxCard('Location en cours', `<p class="gx-mute" style="padding:0">${esc(d.current.model)} (${esc(d.current.plate)}). Ramène-la au point de retour pour récupérer ta caution.</p>`, '', 'warn') : '')
      + gxCard('Tarif', `<div class="gx-price">${money(v.price + v.deposit)}</div>${gxKv([['Location', money(v.price)], ['Caution (rendue au retour)', money(v.deposit)], d.minutes ? ['Durée', d.minutes + ' min'] : null])}`)
      + gxCard('Performances', v.perf ? `<div class="gx-perf">${gxBar('Vitesse', v.perf.speed)}${gxBar('Accélération', v.perf.accel)}${gxBar('Freinage', v.perf.brake)}${gxBar('Adhérence', v.perf.grip)}</div>` : '<p class="gx-mute" style="padding:0">Modèle non répertorié.</p>', 'Notes sur 100')
      + gxCard(null, `${payBlock(d, this.method)}<button class="primary gx-take" data-a="rent" data-v="${esc(v.key)}" ${d.current ? 'disabled' : ''}>Louer · ${money(v.price + v.deposit)}</button>
        <p class="gx-mute" style="padding:0;margin-top:2px">La caution est rendue au retour du véhicule (réduite selon les dégâts).</p>`, '', 'gx-act');
  }
  empty() { return emptyState('key', 'Aucun véhicule', 'Aucun véhicule disponible à la location.'); }
  primary() { const v = this.cur(); if (v && !this.d.current) this.onAction({ dataset: { v: v.key } }, 'rent'); }
  async onAction(el, a) { if (a === 'rent') { const r = await this.act('rental:rent', Number(el.dataset.v), this.method); if (r && r.ok) $root.classList.add('hidden'); } }
})();

/* ── Serrurier ── */
const LocksmithPanel = new (class extends Browser {
  list() { return this.d.vehicles.map(v => ({ ...v, key: v.plate })); }
  meta() { return { icon: 'key', title: this.d.label, sub: 'Duplicata de clés' }; }
  hero(v) { return { small: v.make || 'Véhicule', plate: v.plate, tag: v.hasKey === true ? gxTag(ic('check', 13) + ' Clé possédée', 'ok') : v.hasKey === false ? gxTag('Sans clé', 'warn') : '' }; }
  tile(x) { return { thumb: gxImg(x, 'gx-thumb'), title: x.name, sub: x.nearby ? 'Près de l\'atelier' : x.plate }; }
  side(v) {
    const d = this.d;
    return gxCard('Duplicata de clé', `<div class="gx-price">${money(d.price)}</div>${gxKv([['Plaque', esc(v.plate)], ['Position', v.nearby ? 'Près de l\'atelier' : 'Absent'], ['Clé', v.hasKey === true ? 'Possédée' : v.hasKey === false ? 'Perdue' : 'Inconnue']])}`)
      + (d.requireNearby && !v.nearby ? gxCard('À savoir', '<p class="gx-mute" style="padding:0">Amène ton véhicule près de l\'atelier pour en refaire la clé.</p>', '', 'warn') : '')
      + gxCard(null, `${payBlock(d, this.method)}<button class="primary gx-take" data-a="make" data-v="${esc(v.plate)}" ${v.canMake ? '' : 'disabled'}>${ic('key', 16)} Refaire la clé · ${money(d.price)}</button>`, '', 'gx-act');
  }
  empty() { return emptyState('key', 'Aucun véhicule', 'Tu ne possèdes aucun véhicule.'); }
  primary() { const v = this.cur(); if (v && v.canMake) this.onAction({ dataset: { v: v.key } }, 'make'); }
  async onAction(el, a) { if (a === 'make') { const r = await this.act('locksmith:make', this.d.eid, this.d.pi, el.dataset.v, this.method); if (r && r.ok) toast(`Clé refaite (${money(r.paid)})`, 'ok'); } }
})();

/* ── Occasion ── */
const CarlotPanel = new (class extends Browser {
  init(d) { this.tab = d.focus ? 'focus' : 'buy'; this.sel = null; this.price = 0; this.desc = ''; this.phone = ''; this.edit = {}; }
  async call(name, ...a) {
    const r = await this.act(name, ...a);
    if (r && r.ok) { const keep = { eid: this.d.eid, pi: this.d.pi }; this.d = Object.assign(r, keep); if (this.tab === 'focus') this.tab = 'buy'; this.render(); }
    return r;
  }
  list() {
    const d = this.d;
    if (this.tab === 'sell') return d.vehicles.map(v => ({ ...v, key: v.plate }));
    let l = d.listings;
    if (this.tab === 'focus') l = l.filter(x => x.id === d.focus);
    else if (this.tab === 'mine') l = l.filter(x => x.mine);
    return l.map(x => ({ ...x, key: String(x.id) }));
  }
  meta() {
    const d = this.d, sell = d.kind === 'lot';
    return { icon: 'car', title: d.label, sub: sell ? 'Annonces de véhicules' : 'Annonce', tabs: sell ? [['buy', 'Annonces', 'list'], ['sell', 'Vendre', 'plus'], ['mine', 'Mes annonces', 'user']] : null, active: this.tab === 'focus' ? 'buy' : this.tab };
  }
  hero(v) {
    if (this.tab === 'sell') return { small: v.make || 'Ton véhicule', plate: v.plate };
    return { small: v.make || 'Occasion', plate: v.plate, tag: gxTag(money(v.price), v.mine ? '' : 'ok') };
  }
  tile(x) { return { thumb: gxImg(x, 'gx-thumb'), title: x.name, sub: this.tab === 'sell' ? x.plate : money(x.price) }; }
  side(v) {
    const d = this.d;
    if (this.tab === 'sell') {
      this.sel = v.key;
      const lim = [d.minPrice ? `min ${money(d.minPrice)}` : '', d.maxPrice ? `max ${money(d.maxPrice)}` : ''].filter(Boolean).join(' · ');
      const ok = this.price > 0 && d.freeSlots > 0 && d.mineCount < d.maxListings;
      return gxCard('Conditions', `<div class="gx-facts" style="margin:0">${[`Frais ${money(d.fee)}`, `Commission ${d.commission}%`, d.days ? `${d.days} jour(s)` : 'Sans limite', `Annonces ${d.mineCount}/${d.maxListings}`, `Places libres ${d.freeSlots}`].map(t => `<span class="chip">${t}</span>`).join('')}</div>`)
        + gxCard('Ton annonce', `<label class="f"><span>Prix (${esc(CUR)})${lim ? ' — ' + lim : ''}</span><input type="number" min="1" data-path="price" value="${this.price || ''}"></label>
          <label class="f"><span>Téléphone (optionnel)</span><input data-path="phone" maxlength="20" value="${esc(this.phone)}" placeholder="555-0123"></label>
          <label class="f"><span>Description</span><textarea data-path="desc" rows="2" maxlength="140" placeholder="Ex : très bon état, jamais accidentée…">${esc(this.desc)}</textarea></label>`)
        + gxCard(null, `${payBlock(d, this.method)}<button class="primary gx-take" data-a="list" ${ok ? '' : 'disabled'}>${ic('check', 16)} Mettre en vente${d.fee ? ' · ' + money(d.fee) : ''}</button>${d.freeSlots < 1 ? '<p class="gx-mute" style="padding:0">Aucune place d\'exposition libre pour le moment.</p>' : ''}`, '', 'gx-act');
    }
    const info = gxCard('Annonce', `<div class="gx-price">${money(v.price)}</div><p class="gx-mute" style="padding:0">${v.desc ? esc(v.desc) : 'Pas de description.'}</p>`)
      + gxCard('Vendeur', gxKv([['Nom', esc(v.seller)], v.phone ? ['Téléphone', esc(v.phone)] : null, v.plate ? ['Plaque', esc(v.plate)] : null]));
    if (this.tab === 'mine') {
      return info + gxCard('Gérer l\'annonce', `<div class="row"><input class="qty" style="width:130px" type="number" min="1" data-path="__edit" data-id="${v.id}" value="${this.edit[v.id] ?? v.price}"><button data-a="reprice" data-v="${v.id}">Changer le prix</button></div>`)
        + gxCard(null, `<button class="danger gx-store" data-a="cancel" data-v="${v.id}">Retirer l'annonce</button>`, '', 'gx-act');
    }
    return info + gxCard(null, v.mine
      ? `<div class="gx-ok" style="margin:0">${ic('check', 15)} Ton annonce</div><button class="danger gx-store" data-a="cancel" data-v="${v.id}">Retirer mon annonce</button>`
      : `${payBlock(d, this.method)}<button class="primary gx-take" data-a="buy" data-v="${v.id}">Acheter · ${money(v.price)}</button>`
        + (this.tab === 'focus' ? '<button class="gx-store" data-a="tab" data-v="buy">Voir toutes les annonces</button>' : ''), '', 'gx-act');
  }
  empty() {
    if (this.tab === 'sell') return emptyState('car', 'Aucun véhicule', 'Aucun véhicule rangé dans ton garage : range-le d\'abord dans un garage.');
    if (this.tab === 'focus') return emptyState('car', 'Annonce introuvable', 'Elle vient peut-être d\'être vendue.') + '<button class="gx-store" data-a="tab" data-v="buy">Voir toutes les annonces</button>';
    return emptyState('car', 'Aucune annonce', this.tab === 'mine' ? 'Tu n\'as aucun véhicule en vente.' : 'Aucun véhicule en vente pour le moment.');
  }
  afterInput(p, el) {
    if (p === '__edit') { this.edit[el.dataset.id] = Number(el.value); return; }
    if (p === 'price') { const b = $root.querySelector('[data-a="list"]'); if (b) b.disabled = !(this.price > 0 && this.d.freeSlots > 0 && this.d.mineCount < this.d.maxListings); }
  }
  async onAction(el, a) {
    const v = el.dataset.v;
    if (a === 'buy') { const r = await this.call('carlot:buy', Number(v), this.method); if (r && r.ok) toast('Véhicule acheté : il est dans ton garage', 'ok'); }
    if (a === 'list') { const r = await this.call('carlot:list', this.sel, this.price, this.desc, this.phone, this.method); if (r && r.ok) { this.sel = null; this.price = 0; this.desc = ''; this.tab = 'mine'; this.i = 0; this.render(); toast('Annonce publiée', 'ok'); } }
    if (a === 'cancel') { const r = await this.call('carlot:cancel', Number(v)); if (r && r.ok) toast('Annonce retirée : véhicule rendu à ton garage', 'ok'); }
    if (a === 'reprice') { const r = await this.call('carlot:price', Number(v), this.edit[v] ?? 0); if (r && r.ok) toast('Prix modifié', 'ok'); }
  }
})();

/* ── Station de lavage ── */
const CarwashPanel = new (class extends Browser {
  list() { return this.d.programs.map(g => ({ ...g, key: String(g.i) })); }
  meta() { return { icon: 'drop', title: this.d.label, sub: this.d.vehicle }; }
  tile(x) { return { thumb: `<span class="gx-noimg">${ic('drop', 30)}</span>`, title: x.label, sub: `${x.seconds} s · ${money(x.price)}` }; }
  heroHtml(v) {
    const clean = Math.max(0, Math.min(100, 100 - (Number(this.d.dirt) || 0)));
    return `<div class="gx-hero"><div class="gx-info"><small>Lavage</small><h1>${esc(v.label)}</h1><div class="gx-plate">${esc(this.d.vehicle || '')}</div></div>
      <div class="gx-ringbox">${gxRing(clean, 100, clean + '%', 'Propreté')}<div class="gx-legend"><span><i></i>Actuelle ${clean}%</span><span><i class="b"></i>Après lavage 100%</span></div></div></div>`;
  }
  side(v) {
    const d = this.d;
    return gxCard('Programme', `<div class="gx-price">${money(v.price)}</div>${gxKv([['Durée', v.seconds + ' secondes'], ['Saleté du véhicule', d.dirt + '%']])}`)
      + gxCard(null, `${payBlock(d, this.method)}<button class="primary gx-take" data-a="wash" data-v="${esc(v.key)}">${ic('drop', 16)} Laver · ${money(v.price)}</button>`, '', 'gx-act');
  }
  empty() { return emptyState('drop', 'Aucun programme', 'Cette station ne propose aucun lavage.'); }
  primary() { const v = this.cur(); if (v) this.onAction({ dataset: { v: v.key } }, 'wash'); }
  async onAction(el, a) { if (a === 'wash') { const r = await this.act('carwash:start', Number(el.dataset.v), this.method); if (r && r.ok) $root.classList.add('hidden'); } }
})();

/* ── Auto-école ── */
const DrivingPanel = new (class extends Browser {
  init() { this.view = 'list'; this.quiz = null; this.result = null; }
  list() { return this.d.licenses.map(l => ({ ...l, key: l.id })); }
  meta() { return { icon: 'book', title: this.d.label, sub: 'Passe tes permis' }; }
  tile(x) { return { thumb: `<span class="gx-noimg">${ic('key', 30)}</span>`, title: x.label, sub: x.owned ? 'Obtenu' : x.lock ? 'Verrouillé' : x.theory && x.theory.done ? 'Code réussi' : 'Disponible' }; }
  heroHtml(l) {
    const st = l.owned ? gxTag(ic('check', 13) + ' Obtenu', 'ok') : l.lock ? gxTag('Verrouillé', 'warn') : l.theory && l.theory.done ? gxTag('Code réussi') : gxTag('Disponible');
    const facts = [l.theory ? `Code : ${l.theory.count} questions · ${l.theory.passPercent}% requis` : '', l.practical ? `Conduite : ${l.practical.speedLimit} km/h max · ${l.practical.maxFaults} faute(s) max` : ''].filter(Boolean)
      .map(t => `<span class="chip">${esc(t)}</span>`).join('');
    return `<div class="gx-hero"><div class="gx-info"><small>Permis</small><h1>${esc(l.label)}</h1>${st}<div class="gx-facts">${facts}</div></div>${gxDisc('key')}</div>`;
  }
  side(l) {
    const d = this.d;
    return (l.lock ? gxCard('Verrouillé', `<p class="gx-mute" style="padding:0">${esc(l.lock)}</p>`, '', 'warn') : '')
      + gxCard('Épreuves', gxKv([l.theory ? ['Code', money(l.theory.price)] : null, l.practical ? ['Conduite', money(l.practical.price)] : null]) || '')
      + gxCard(null, `${payBlock(d, this.method)}
        ${l.theory ? `<button class="primary gx-take" data-a="theory" data-v="${esc(l.id)}" ${l.canTheory ? '' : 'disabled'}>Passer le code · ${money(l.theory.price)}</button>` : ''}
        ${l.practical ? `<button class="primary gx-take" data-a="practical" data-v="${esc(l.id)}" ${l.canPractical ? '' : 'disabled'}>Passer la conduite · ${money(l.practical.price)}</button>` : ''}`, '', 'gx-act');
  }
  empty() { return emptyState('book', 'Aucun permis', 'Cette auto-école ne propose aucun permis.'); }
  render() {
    if (this.view === 'quiz') return this.renderQuiz();
    if (this.view === 'result') return this.renderResult();
    super.render();
  }
  renderQuiz() {
    const q = this.quiz, cur = q.questions[q.i];
    const main = `<div class="gx-hero plain"><div class="gx-ph"><small>Question ${q.i + 1} / ${q.questions.length}</small></div><div class="segs">${q.questions.map((_, k) => `<i class="${k <= q.i ? 'on' : ''}"></i>`).join('')}</div><div class="gx-q">${esc(cur.q)}</div></div>
      <div class="gx-side">${cur.answers.map((a, k) => `<button class="gx-bigbtn" data-a="answer" data-v="${k + 1}"><kbd>${k + 1}</kbd> ${esc(a)}</button>`).join('')}</div>`;
    $root.innerHTML = gxFrame({ icon: 'book', title: q.label, sub: 'Code de la route', main });
  }
  renderResult() {
    const r = this.result;
    const main = `<div class="gx-hero"><div class="gx-info"><small>${r.passed ? 'Félicitations' : 'Dommage'}</small><h1>${r.passed ? 'Code réussi !' : 'Code raté'}</h1>
        <div class="gx-facts"><span class="chip">${r.right} / ${r.total} bonnes réponses</span><span class="chip">${r.need}% requis</span></div></div>
        <div class="gx-ringbox">${gxRing(r.percent, r.percent, r.percent + '%', r.passed ? 'Réussi' : 'Échec')}</div></div>
      <div class="gx-side">${gxCard(null, `<div class="gx-ok" style="${r.passed ? '' : 'color:var(--danger)'}">${ic(r.passed ? 'check' : 'x', 15)} ${r.passed ? (r.granted ? 'Permis délivré' : r.practical ? 'Tu peux passer la conduite' : 'Réussi') : 'Échec'}</div><button class="primary gx-take" data-a="back">Retour aux permis</button>`, '', 'gx-act')}</div>`;
    $root.innerHTML = gxFrame({ icon: 'book', title: this.d.label, sub: 'Résultat', main });
  }
  async onAction(el, a) {
    const v = el.dataset.v;
    if (a === 'back') { this.view = 'list'; const r = await rpc('driving:info'); if (r && r.ok) Object.assign(this.d, r); return this.render(); }
    if (a === 'theory') {
      const r = await this.act('driving:theoryStart', this.d.eid, this.d.pi, v, this.method);
      if (r && r.ok) { this.quiz = { questions: r.questions, i: 0, answers: [], label: r.label }; this.view = 'quiz'; this.render(); }
    }
    if (a === 'answer') {
      const q = this.quiz; q.answers.push(Number(v)); q.i++;
      if (q.i < q.questions.length) return this.render();
      const r = await this.act('driving:theorySubmit', q.answers);
      if (r && r.ok) { this.result = r; this.view = 'result'; this.render(); }
    }
    if (a === 'practical') { const r = await this.act('driving:practicalStart', v, this.method); if (r && r.ok) $root.classList.add('hidden'); }
  }
})();

/* ── Pôle emploi : jobs en libre accès + quêtes ── */
const JobcenterPanel = new (class extends Browser {
  init(d) { this.tab = d.mode === 'quests' ? 'quests' : 'jobs'; }
  list() { const d = this.d; return (this.tab === 'jobs' ? d.jobs : d.quests).map(x => ({ ...x, key: x.id })); }
  meta() {
    const d = this.d;
    return { icon: 'users', title: d.label, sub: d.mode !== 'quests' ? 'Pôle emploi — petits jobs en libre accès' : `Quêtes · ${d.currentLabel}`,
      tabs: d.mode !== 'quests' && d.isSmall ? [['jobs', 'Jobs disponibles', 'users'], ['quests', 'Mes quêtes', 'list']] : null, active: this.tab };
  }
  tile(x) { return { thumb: `<span class="gx-noimg">${ic(this.tab === 'jobs' ? x.icon : 'flag', 30)}</span>`, title: x.label, sub: this.tab === 'jobs' ? (x.current ? 'Ton job' : `${x.quests} quêtes`) : (x.cooldownLeft > 0 ? x.cooldownLeft + ' s' : `${x.min}–${x.max} ${CUR}`) }; }
  heroHtml(x) {
    const jobs = this.tab === 'jobs';
    const facts = jobs ? `<span class="chip">${x.quests} quêtes</span><span class="chip">${x.min}–${x.max} ${esc(CUR)} par quête</span>` : `<span class="chip">${x.steps} étapes</span><span class="chip">${x.min}–${x.max} ${esc(CUR)}</span>`;
    return `<div class="gx-hero"><div class="gx-info"><small>${jobs ? 'Petit job' : 'Quête'}</small><h1>${esc(x.label)}</h1>${x.current ? gxTag('Ton job actuel', 'ok') : ''}<p>${esc(x.desc || '')}</p><div class="gx-facts">${facts}</div></div>${gxDisc(jobs ? x.icon : 'flag')}</div>`;
  }
  side(x) {
    const d = this.d, st = d.stats, jobs = this.tab === 'jobs';
    const cur = d.isSmall ? gxCard('Ton job', `<div class="gx-ok" style="margin-bottom:6px">${ic('check', 15)} ${esc(d.currentLabel)}</div>
      <p class="gx-mute" style="padding:0">${esc(d.gradeLabel || '')}${st ? ` · ${st.done} quête${st.done > 1 ? 's' : ''} terminée${st.done > 1 ? 's' : ''}${st.next ? ` · prochain grade à ${st.next}` : ''}${st.bonus ? ` · bonus +${st.bonus}%` : ''}` : ''}</p>
      <button class="gx-store" data-a="leave" style="width:100%;margin-top:10px">${ic('logout', 15)} Quitter ce job</button>`) : '';
    const act = jobs
      ? (x.current ? '<div class="gx-ok" style="margin:0">' + ic('check', 15) + ' C\'est ton job</div>' : `<button class="primary gx-take" data-a="take" data-v="${esc(x.id)}">Prendre ce job</button>`)
      : (x.cooldownLeft > 0 ? `<button class="gx-take" disabled>Disponible dans ${x.cooldownLeft} s</button>` : `<button class="primary gx-take" data-a="quest" data-v="${esc(x.id)}" ${d.active ? 'disabled' : ''}>Lancer la quête</button>`);
    return cur + (d.active ? gxCard('Quête en cours', `<p class="gx-mute" style="padding:0">${esc(d.active.label)} (étape ${d.active.idx}/${d.active.total})</p><button class="danger gx-store" data-a="cancelq" style="width:100%;margin-top:10px">Abandonner</button>`, '', 'warn') : '')
      + (jobs ? gxCard('Libre accès', '<p class="gx-mute" style="padding:0">Un clic et tu es embauché. Tu peux quitter ton job à tout moment (ici ou dans le menu F6 → Quitter le métier).</p>') : '')
      + gxCard(null, act, '', 'gx-act');
  }
  empty() { return this.tab === 'quests' ? emptyState('flag', 'Aucune quête', 'Prends d\'abord un petit job.') : emptyState('users', 'Aucun job', 'Aucun job disponible.'); }
  primary() { const x = this.cur(); if (!x) return; if (this.tab === 'jobs' && !x.current) this.onAction({ dataset: { v: x.key } }, 'take'); }
  async onAction(el, a) {
    const v = el.dataset.v, d = this.d;
    if (a === 'take') {
      const r = await this.act('jobcenter:take', d.eid || 0, d.pi || 0, v);
      if (r && r.ok) { toast(`Embauché : ${(r.jobs.find(j => j.id === r.current) || {}).label || ''}`, 'ok'); r.eid = d.eid; r.pi = d.pi; r.mode = 'desk'; this.d = r; this.tab = 'quests'; this.i = 0; this.render(); }
    }
    if (a === 'leave') {
      const r = await this.act('jobcenter:leave');
      if (r && r.ok) { toast('Tu as quitté ton job', 'ok'); const i = await this.act('jobcenter:info', d.eid || 0, d.pi || 0); if (i && i.ok) { i.eid = d.eid; i.pi = d.pi; i.mode = d.mode; this.d = i; this.tab = 'jobs'; this.i = 0; if (this.d.mode === 'quests') return rpc('close'); this.render(); } }
    }
    if (a === 'quest') { const r = await this.act('jcStart', v); if (r && r.ok) $root.classList.add('hidden'); }
    if (a === 'cancelq') { await this.act('jcCancel'); const i = await this.act('jobcenter:info', d.eid || 0, d.pi || 0); if (i && i.ok) { i.eid = d.eid; i.pi = d.pi; i.mode = d.mode; this.d = i; this.render(); } }
  }
})();

/* ── Zones PVP : menu (PNJ) ── */
const PvpPanel = new (class extends Browser {
  init() { this.tab = 'zones'; }
  list() { return this.tab === 'zones' ? this.d.zones.map(z => ({ ...z, key: String(z.pi) })) : []; }
  meta() { const s = this.d.stats; return { icon: 'target', title: this.d.label, sub: `${s.kills} kills · ${s.deaths} morts`, tabs: [['zones', 'Zones', 'target'], ['board', 'Classement', 'chart']], active: this.tab }; }
  tile(z) { return { thumb: `<span class="gx-noimg">${ic('target', 30)}</span>`, title: z.label, sub: `${z.players} joueur${z.players > 1 ? 's' : ''}` }; }
  stats() {
    const s = this.d.stats, kd = s.deaths ? (s.kills / s.deaths).toFixed(2) : Number(s.kills).toFixed(2);
    return gxCard('Mes stats', `<div class="gx-kv">${[['Kills', s.kills], ['Morts', s.deaths], ['K/D', kd], ['Meilleure série', s.best]].map(r => `<div><span>${r[0]}</span><b>${r[1]}</b></div>`).join('')}</div>`);
  }
  heroHtml(z) {
    const facts = [`Rayon ${Math.round(z.radius)} m`, z.giveWeapons ? `Armes : ${(z.weapons || []).join(', ') || 'aucune'}` : 'Tes armes', z.revive ? 'Revive automatique' : '', z.reward ? `${money(z.reward)} par kill` : ''].filter(Boolean).map(t => `<span class="chip">${esc(t)}</span>`).join('');
    return `<div class="gx-hero"><div class="gx-info"><small>Zone PVP</small><h1>${esc(z.label)}</h1>${gxTag(`${z.players} joueur${z.players > 1 ? 's' : ''} dans la zone`, z.players ? 'ok' : '')}<div class="gx-facts">${facts}</div></div>${gxDisc('target')}</div>`;
  }
  side(z) { return this.stats() + gxCard(null, `<button class="primary gx-take" data-a="gps" data-v="${z.pi}">${ic('map', 15)} Placer le GPS</button>`, '', 'gx-act'); }
  empty() { return emptyState('target', 'Aucune zone', 'Aucune zone PVP n\'est configurée.'); }
  render() {
    if (this.tab !== 'board') return super.render();
    const rows = this.d.leaderboard.map((r, i) => `<div class="item"><div class="tile">${i + 1}</div><div class="grow"><b>${esc(r.name)}</b><small>${r.deaths} morts · série max ${r.best_streak}</small></div><span class="price">${r.kills} kills</span></div>`).join('');
    const main = `<div class="gx-hero plain"><div class="gx-ph"><small>Classement</small><h1>Meilleurs combattants</h1></div>${rows || emptyState('chart', 'Aucun combat', 'Aucun combat enregistré.')}</div><div class="gx-side">${this.stats()}</div>`;
    $root.innerHTML = gxFrame({ ...this.meta(), main });
  }
  onAction(el, a) { if (a === 'gps') rpc('pvp:waypoint', Number(el.dataset.v)); }
})();

/* ── Station essence ── */
const FuelPanel = new (class extends PanelBase {
  init(d) { this.liters = Math.max(1, Math.min(100, 100 - (d.level || 0))); }
  cost() { return Math.ceil(this.liters * (this.d.price || 0)); }
  after() { return Math.min(100, (this.d.level || 0) + this.liters); }
  render() {
    const d = this.d, max = d.vehicle ? Math.max(1, 100 - (d.level || 0)) : 100, lvl = d.level || 0;
    if (this.liters > max) this.liters = max;
    const hero = d.vehicle
      ? `<div class="gx-hero"><div class="gx-info"><small>Station-service</small><h1>${esc(d.vehicle)}</h1></div>
          <div class="gx-ringbox">${gxRing(lvl, this.after(), lvl + '%', 'Réservoir')}<div class="gx-legend"><span><i></i>Actuel <span id="fl-now">${lvl}%</span></span><span><i class="b"></i>Après le plein <span id="fl-after">${this.after()}%</span></span></div></div></div>`
      : `<div class="gx-hero"><div class="gx-info"><small>Station-service</small><h1>${esc(d.label)}</h1></div><div class="gx-ringbox">${emptyState('car', 'Aucun véhicule', 'Approche ton véhicule de la pompe.')}</div></div>`;
    const tank = d.capacity > 0 ? ['Cuve de la station', `${Math.round(d.tank)} L (${Math.round(d.tank / d.capacity * 100)}%)`] : null;
    $root.innerHTML = gxFrame({ icon: 'fuel', title: d.label, sub: `${money(d.price)} le litre`, empty: false, main: hero + `<div class="gx-side">
      ${gxCard('Quantité', `<div class="gx-price"><span id="fl-l">${this.liters} L</span> <small style="font-size:16px;color:var(--muted)">· <span id="fl-c">${money(this.cost())}</span></small></div>
        <input type="range" style="width:100%" min="1" max="${max}" value="${this.liters}" data-path="liters" ${d.vehicle ? '' : 'disabled'}>
        <div class="row" style="margin-top:10px"><button class="sm" data-a="lit" data-v="10">10 L</button><button class="sm" data-a="lit" data-v="25">25 L</button><button class="sm" data-a="lit" data-v="${max}">Plein</button></div>`)}
      ${gxCard('Station', gxKv([['Prix au litre', money(d.price)], d.vehicle ? ['Réservoir', lvl + '%'] : null, tank]))}
      ${d.jerrycan ? gxCard('Jerricane', `<p class="gx-mute" style="padding:0 0 10px">Pour dépanner un véhicule en panne sèche.</p><button class="gx-store" style="width:100%" data-a="jerry">${ic('box', 15)} Acheter · ${money(d.jerrycan.price)}</button>`) : ''}
      ${gxCard(null, `${payBlock(d, this.method)}<button class="primary gx-take" data-a="fill" ${d.vehicle ? '' : 'disabled'}>${ic('fuel', 16)} Faire le plein</button>`, '', 'gx-act')}</div>` });
  }
  afterInput(p) {
    if (p !== 'liters') return;
    document.getElementById('fl-l').textContent = this.liters + ' L'; document.getElementById('fl-c').textContent = money(this.cost());
    const ring = document.getElementById('gx-ring'); if (ring) ring.style.setProperty('--b', this.after());
    const a = document.getElementById('fl-after'); if (a) a.textContent = this.after() + '%';
  }
  async onA(el) {
    const a = el.dataset.a;
    if (a === 'pay') { this.method = el.dataset.v; return this.render(); }
    if (a === 'lit') { this.liters = Math.max(1, Number(el.dataset.v)); return this.render(); }
    if (a === 'fill') { const r = await this.act('fuel:fill', this.liters, this.method); if (r && r.ok) $root.classList.add('hidden'); }
    if (a === 'jerry') { const r = await this.act('fuel:jerrycan', this.d.eid, this.d.pi, this.method); if (r && r.ok) toast('Jerricane acheté', 'ok'); }
  }
})();

/* ── Banque ── */
const BankPanel = new (class extends PanelBase {
  init() { this.amount = 100; this.target = ''; }
  render() {
    const d = this.d, f = d.fees, atm = d.kind === 'atm';
    const note = (l, p) => p > 0 ? `${l} ${p}%` : '';
    const fees = [note('Frais de retrait', f.withdraw), d.canDeposit ? note('Frais de dépôt', f.deposit) : '', note('Frais de virement', f.transfer), d.max ? `Max par opération : ${money(d.max)}` : '', d.left >= 0 ? `Retrait restant aujourd'hui : ${money(d.left)}` : ''].filter(Boolean);
    const main = `<div class="gx-hero plain"><div class="gx-ph"><small>${atm ? 'Distributeur' : 'Guichet'}</small><h1>${esc(d.label)}</h1></div>
        <div class="gx-bal"><div><small>${ic('dollar', 15)} Espèces</small><b>${money(d.money)}</b></div><div><small>${ic('card', 15)} Compte bancaire</small><b>${money(d.bank)}</b></div></div>
        <div class="gx-facts">${(fees.length ? fees : ['Aucun frais']).map(t => `<span class="chip">${esc(t)}</span>`).join('')}</div></div>
      <div class="gx-side">
        ${gxCard('Opération', `<label class="f"><span>Montant</span><input type="number" min="1" data-path="amount" value="${this.amount}"></label>
          <div class="row">${[100, 500, 1000, 5000].map(n => `<button class="sm" data-a="amt" data-v="${n}">${money(n)}</button>`).join('')}<button class="sm" data-a="amt" data-v="bank">Tout le compte</button>${d.canDeposit ? '<button class="sm" data-a="amt" data-v="cash">Toutes les espèces</button>' : ''}</div>`)}
        ${gxCard(null, `<div class="row"><button class="primary grow-i" data-a="withdraw">Retirer</button>${d.canDeposit ? '<button class="primary grow-i" data-a="deposit">Déposer</button>' : ''}</div>`)}
        ${gxCard(ic('users', 16) + ' Virement', `<div class="row"><input type="number" min="1" placeholder="ID du joueur" data-path="target" value="${esc(this.target)}" style="width:140px"><button class="grow-i" data-a="transfer">Virer le montant</button></div>`)}</div>`;
    $root.innerHTML = gxFrame({ icon: atm ? 'card' : 'dollar', title: d.label, sub: atm ? 'Distributeur' : 'Guichet', main });
  }
  async run(name, ...a) {
    const r = await this.act(name, this.d.eid, this.d.pi, ...a);
    if (r && r.ok) { Object.assign(this.d, r); toast('Opération effectuée', 'ok'); this.render(); }
  }
  onA(el) {
    const a = el.dataset.a, v = el.dataset.v;
    if (a === 'amt') { this.amount = v === 'bank' ? this.d.bank : v === 'cash' ? this.d.money : Number(v); return this.render(); }
    if (a === 'withdraw') return this.run('bank:withdraw', this.amount);
    if (a === 'deposit') return this.run('bank:deposit', this.amount);
    if (a === 'transfer') return this.run('bank:transfer', this.amount, this.target);
  }
})();

/* ── Course poursuite : lobbies ── */
const ChasePanel = new (class extends PanelBase {
  init(d) { this.state = null; this.tab = 'lobbies'; this.board = null; this.pickEnd = 0; this.form = { name: '', map: d.maps[0] ? d.maps[0].id : null, duration: d.cfg.duration.default, maxChasers: Math.min(2, d.cfg.maxChasers), role: 'runner' }; this.vehCat = null; this.stopTimer(); }
  stopTimer() { if (this.timer) { clearInterval(this.timer); this.timer = null; } }
  setState(s) {
    if (Mod !== this || $root.classList.contains('hidden')) return;
    this.state = s;
    // fenêtre de choix du véhicule (10 s après l'arrivée d'un joueur) : le serveur envoie le temps restant
    this.pickEnd = (s.current && s.current.pickLeft > 0) ? Date.now() + s.current.pickLeft : 0;
    if (s.current) this.tab = 'lobby'; else if (this.tab === 'lobby') this.tab = 'lobbies';
    this.render();
    this.stopTimer();
    if (this.pickEnd) this.timer = setInterval(() => this.tick(), 200);
  }
  pickLeft() { return Math.max(0, this.pickEnd - Date.now()); }
  tick() {
    if (Mod !== this || $root.classList.contains('hidden')) return this.stopTimer();
    const left = this.pickLeft();
    if (left <= 0) { this.pickEnd = 0; this.stopTimer(); return this.render(); }
    const t = document.getElementById('pickcd'), b = document.getElementById('pickbar');
    if (t) t.textContent = Math.ceil(left / 1000);
    if (b) b.style.width = Math.min(100, left / (this.d.cfg.pickTime * 10)) + '%';
  }
  stats(s) { return s ? `${s.matches} parties · ${s.wins_runner + s.wins_chaser} victoires` : ''; }
  rules() { const c = this.d.cfg; return gxCard('Règle de victoire', `<p class="gx-mute" style="padding:0">Les poursuivants gagnent s'ils restent collés (${c.catchDistance} m) au fugitif pendant ${c.catchTime} s ; sinon le fugitif gagne au bout du temps.</p>`); }
  render() {
    const d = this.d, s = this.state, cur = s && s.current;
    let hero, side;
    if (!s) { hero = '<div class="gx-hero plain"><div class="hint">Chargement…</div></div>'; side = ''; }
    else if (this.tab === 'board') ({ hero, side } = this.viewBoard());
    else if (this.tab === 'lobby' && cur) ({ hero, side } = this.viewLobby(cur));
    else ({ hero, side } = this.viewLobbies(s));
    const tabs = [['lobbies', 'Parties', 'grid'], ...(cur ? [['lobby', 'Mon lobby', 'car']] : []), ['board', 'Classement', 'chart']];
    $root.innerHTML = gxFrame({ icon: 'flag', title: d.label, sub: s ? `${s.name} · ${this.stats(s.stats)}` : '', tabs, active: this.tab, main: `${hero}<div class="gx-side">${side}</div>` });
  }
  roleBtns(sel, act) { return `<div class="row">${[['runner', 'Fugitif'], ['chaser', 'Poursuivant']].map(r => `<button class="grow-i ${sel === r[0] ? 'primary' : ''}" data-a="${act}" data-v="${r[0]}">${r[1]}</button>`).join('')}</div>`; }
  viewLobbies(s) {
    const d = this.d, f = this.form;
    const lobbies = s.lobbies.map(l => `<div class="item"><div class="tile">${ic('flag')}</div><div class="grow"><b>${esc(l.name)}</b><small>${esc(l.mapLabel)} · ${l.duration} min · ${l.runners}/1 fugitif · ${l.chasers}/${l.maxChasers} poursuivants${l.fee > 0 ? ` · mise ${money(l.fee)}` : ''}</small></div>
      ${l.state === 'lobby' ? `<button class="sm" data-a="join" data-v="${l.id}:runner" ${l.runners >= 1 ? 'disabled' : ''}>Fugitif</button><button class="primary sm" data-a="join" data-v="${l.id}:chaser" ${l.chasers >= l.maxChasers ? 'disabled' : ''}>Poursuivant</button>` : chip('En cours', 'warn')}</div>`).join('');
    const hero = `<div class="gx-hero plain"><div class="gx-ph"><small>Course poursuite</small><h1>Parties ouvertes</h1></div>${lobbies || emptyState('flag', 'Aucune partie', 'Crée la première partie à droite.')}</div>`;
    const side = gxCard(ic('plus', 16) + ' Créer une partie', `<label class="f"><span>Nom</span><input data-path="form.name" maxlength="28" placeholder="Course de ${esc(s.name)}" value="${esc(f.name)}"></label>
        <label class="f"><span>Carte</span><select data-path="form.map" data-t="n">${d.maps.map(m => `<option value="${m.id}" ${m.id === f.map ? 'selected' : ''}>${esc(m.label)}</option>`).join('')}</select></label>
        <label class="f"><span>Durée : <b>${f.duration} min</b></span><input type="range" min="${d.cfg.duration.min}" max="${d.cfg.duration.max}" value="${f.duration}" data-path="form.duration"></label>
        <label class="f"><span>Poursuivants max : <b>${f.maxChasers}</b></span><input type="range" min="1" max="${d.cfg.maxChasers}" value="${f.maxChasers}" data-path="form.maxChasers"></label>
        <div class="lbl">Ton rôle</div>${this.roleBtns(f.role, 'formRole')}
        <p class="gx-mute" style="padding:10px 0 0">${d.cfg.reward.fee > 0 ? `Mise d'entrée : <b>${money(d.cfg.reward.fee)}</b> par joueur, débitée au lancement. Le gagnant empoche les mises.` : 'Course gratuite.'}</p>`)
      + gxCard(null, `<button class="primary gx-take" data-a="create" ${d.maps.length ? '' : 'disabled'}>${ic('check', 16)} Créer la partie</button>`, '', 'gx-act') + this.rules();
    return { hero, side };
  }
  viewLobby(m) {
    const d = this.d, me = m.players.find(p => p.src === this.state.you) || {}, host = me.host;
    const cats = [...new Set(d.vehicles.map(v => v.category || 'Autre'))];
    const cat = this.vehCat || (d.vehicles.find(v => v.model === me.vehicle) || {}).category || cats[0];
    const bar = (l, v) => `<div class="mini"><span>${l}</span><div class="bar"><i style="width:${v}%"></i></div></div>`;
    const left = this.pickLeft(), picking = left > 0;
    const players = m.players.map(p => `<div class="item"><div class="tile">${ic(p.role === 'runner' ? 'target' : 'car')}</div><div class="grow"><b>${esc(p.name)}${p.host ? ' ★' : ''}</b><small>${esc((d.vehicles.find(v => v.model === p.vehicle) || {}).label || p.vehicle)}</small></div>${chip(p.role === 'runner' ? 'Fugitif' : 'Poursuivant', p.role === 'runner' ? 'warn' : 'info')}</div>`).join('');
    const banner = picking ? `<div class="pickbanner"><div><b>Choisis ton véhicule !</b><small>La partie ne peut pas être lancée pendant ce temps.</small></div><span id="pickcd">${Math.ceil(left / 1000)}</span><div class="pickbar"><i id="pickbar" style="width:${Math.min(100, left / (d.cfg.pickTime * 10))}%"></i></div></div>` : '';
    const canStart = m.runners === 1 && m.chasers >= 1 && !picking;
    const hero = `<div class="gx-hero plain">${banner}<div class="gx-ph"><small>Ton véhicule</small></div>
        <div class="seg wrap" style="margin:0">${cats.map(c => `<button class="${c === cat ? 'active' : ''}" data-a="vcat" data-v="${esc(c)}">${esc(c)}</button>`).join('')}</div>
        <div class="veh-grid">${d.vehicles.filter(v => (v.category || 'Autre') === cat).map(v => `<div class="item click" data-a="setVehicle" data-v="${esc(v.model)}" style="${v.model === me.vehicle ? 'border-color:var(--accent-line);background:var(--accent-soft)' : ''}"><div class="tile">${ic('car')}</div><div class="grow"><b>${esc(v.label)}${v.model === me.vehicle ? ' ' + chip('Choisi', 'ok') : ''}</b><div class="minis">${bar('Vitesse', v.speed)}${bar('Accél.', v.accel)}${bar('Tenue', v.handling)}</div></div></div>`).join('')}</div></div>`;
    const side = gxCard(ic('flag', 16) + ' ' + esc(m.name), `${chip(m.state === 'lobby' ? 'En attente' : 'Lancement…', m.state === 'lobby' ? 'mute' : 'ok')}
        <p class="gx-mute" style="padding:8px 0 0">${esc(m.mapLabel)} · ${m.duration} min · ${m.runners}/1 fugitif · ${m.chasers}/${m.maxChasers} poursuivants${m.fee > 0 ? ` · mise ${money(m.fee)} / joueur (cagnotte ${money(m.fee * m.players.length)})` : ''}</p>`)
      + gxCard('Joueurs', `<div class="list">${players}</div>`) + gxCard('Ton rôle', this.roleBtns(me.role, 'setRole'))
      + gxCard(null, (host ? `<button class="primary gx-take" data-a="start" ${canStart ? '' : 'disabled'}>${ic('check', 16)} ${picking ? 'Choix du véhicule…' : 'Lancer la partie'}</button>` : '<p class="gx-mute" style="padding:0">En attente de l\'hôte…</p>') + '<button class="danger gx-store" data-a="leave">Quitter</button>', '', 'gx-act');
    return { hero, side };
  }
  viewBoard() {
    const rows = (this.board || []).map((r, i) => `<div class="item"><div class="tile">${i + 1}</div><div class="grow"><b>${esc(r.name)}</b><small>${r.matches} parties (F ${r.wins_runner} / P ${r.wins_chaser})</small></div><span class="price">${r.wins} victoire${r.wins > 1 ? 's' : ''}</span></div>`).join('');
    const hero = `<div class="gx-hero plain"><div class="gx-ph"><small>Classement</small><h1>Les meilleurs pilotes</h1></div>${this.board ? (rows || emptyState('chart', 'Aucune partie', 'Aucune partie jouée.')) : '<div class="hint">Chargement…</div>'}</div>`;
    return { hero, side: this.rules() };
  }
  afterInput(p, el) {
    if (!p || !p.startsWith('form.')) return;
    const k = p.slice(5);
    this.form[k] = (k === 'name') ? el.value : Number(el.value);
    if (k === 'duration' || k === 'maxChasers') { const l = el.closest('label').querySelector('b'); if (l) l.textContent = k === 'duration' ? `${this.form.duration} min` : this.form.maxChasers; }
  }
  onInput(el) {
    const p = el.dataset.path;
    if (p && p.startsWith('form.')) return this.afterInput(p, el);
  }
  async onA(el) {
    const a = el.dataset.a, v = el.dataset.v;
    if (a === 'nav' || a === 'tab') {
      if (v === 'lobby' && !(this.state && this.state.current)) return;
      this.tab = v;
      if (v === 'board') { this.board = null; this.render(); const r = await rpc('chase:leaderboard'); this.board = (r && r.rows) || []; }
      return this.render();
    }
    if (a === 'formRole') { this.form.role = v; return this.render(); }
    if (a === 'create') { rpc('chase:create', { name: this.form.name, map: this.form.map, duration: this.form.duration, maxChasers: this.form.maxChasers, role: this.form.role }); return; }
    if (a === 'join') { const [id, role] = v.split(':'); rpc('chase:join', { id: Number(id), role }); return; }
    if (a === 'setRole') { rpc('chase:setRole', v); return; }
    if (a === 'setVehicle') { rpc('chase:setVehicle', v); return; }
    if (a === 'vcat') { this.vehCat = v; return this.render(); }
    if (a === 'leave') { rpc('chase:leave'); this.tab = 'lobbies'; return; }
    if (a === 'start') { rpc('chase:start'); return; }
  }
})();

Object.assign(Panels, { jobcenter: JobcenterPanel, pvp: PvpPanel, chase: ChasePanel, carlot: CarlotPanel, locksmith: LocksmithPanel, carwash: CarwashPanel, driving: DrivingPanel, bank: BankPanel, impound: ImpoundPanel, rental: RentalPanel, fuel: FuelPanel });
