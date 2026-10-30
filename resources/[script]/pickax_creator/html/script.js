'use strict';
/* ═════ pickax_creator : écrans plein format (identité · apparence · apparition · bienvenue · animations) ═════ */
const $ = (s, r) => (r || document).querySelector(s);
const root = $('#root');
const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_creator';
const post = (n, d) => { if (window.__MOCK) return Promise.resolve(window.__MOCK(n, d || {})); return fetch(`https://${RES}/${n}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(d || {}) }).then(r => r.json()).catch(() => ({})); };
const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const I = {
  pencil: '<path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z"/>', wand: '<path d="m15 4 1.5-1.5M5 20 18 7l-2-2L3 18z"/><path d="M19 3v2M20 4h-2M8 3v2M9 4H7"/>', check: '<path d="M20 6 9 17l-5-5"/>', x: '<path d="M18 6 6 18M6 6l12 12"/>',
  left: '<path d="m15 18-6-6 6-6"/>', right: '<path d="m9 18 6-6-6-6"/>', refresh: '<path d="M21 12a9 9 0 1 1-3-6.7L21 8"/><path d="M21 3v5h-5"/>', pin: '<path d="M12 22s7-6.5 7-12a7 7 0 0 0-14 0c0 5.500 7 12 7 12z"/><circle cx="12" cy="10" r="2.500" fill="currentColor"/>',
  note: '<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>', prev: '<path d="M19 20 9 12l10-8zM5 19V5"/>', next: '<path d="m5 4 10 8-10 8zM19 5v14"/>', play: '<path d="m6 4 14 8-14 8z"/>', pause: '<path d="M6 4h4v16H6zM14 4h4v16h-4z"/>', vol: '<path d="M11 5 6 9H2v6h4l5 4zM15.500 8.500a5 5 0 0 1 0 7"/>',
  heart: '<path d="M20.800 4.600a5.500 5.500 0 0 0-7.800 0L12 5.600l-1-1a5.500 5.500 0 0 0-7.800 7.800l1 1L12 21l7.800-7.600 1-1a5.500 5.500 0 0 0 0-7.800z"/>',
  grid: '<rect x="3" y="3" width="7" height="7" rx="1.500"/><rect x="14" y="3" width="7" height="7" rx="1.500"/><rect x="3" y="14" width="7" height="7" rx="1.500"/><rect x="14" y="14" width="7" height="7" rx="1.500"/>',
  run: '<circle cx="14" cy="4" r="2"/><path d="m5 12 4-3 3 2 3-1 3 3M9 21l3-7-3-3M14 11l1 10"/>', box: '<path d="m21 8-9-5-9 5v8l9 5 9-5zM3 8l9 5 9-5M12 13v8"/>', duo: '<circle cx="8" cy="5" r="2"/><circle cx="16" cy="5" r="2"/><path d="m4 20 3-9 3 2 2-2 2 2 3-2 3 9"/>', smile: '<circle cx="12" cy="12" r="9"/><path d="M8 14s1.500 2 4 2 4-2 4-2M9 9h.01M15 9h.01"/>', walk: '<circle cx="13" cy="4" r="2"/><path d="m8 21 3-7 3 2v5M11 14l-1-5 4-1 2 4M3 9h3M2 13h4"/>',
};
const ic = (n, s) => `<svg viewBox="0 0 24 24" ${s ? `style="width:${s}px;height:${s}px"` : ''}>${I[n] || ''}</svg>`;
const sep = '<div class="sep"><i></i></div>';
let view = null;
/* Réglages venus du panel web (textes, images de fond, couleurs) : cfg = { texts: { 'texte d\'origine': 'nouveau texte' }, bg: { identity|skin|spawn|welcome|emotes: 'https://…', dim: 0-100 } } */
let CFG = {};
const applyCfg = () => {
  const T = CFG.texts || {}, B = CFG.bg || {};
  if (Object.keys(T).length) {
    const w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT); let n; const list = [];
    while ((n = w.nextNode())) list.push(n);
    list.forEach(t => { const k = t.nodeValue.trim(); if (k && Object.prototype.hasOwnProperty.call(T, k) && T[k] !== '') t.nodeValue = t.nodeValue.replace(k, T[k]); });
    root.querySelectorAll('[placeholder]').forEach(i => { const k = i.getAttribute('placeholder'); if (Object.prototype.hasOwnProperty.call(T, k) && T[k] !== '') i.setAttribute('placeholder', T[k]); });
  }
  const img = B[view];
  if (img && /^(https?:\/\/|nui:|places\/|bg\/)/.test(img)) {
    const dim = Math.min(100, Math.max(0, +B.dim || 0)) / 100, css = `background-image:linear-gradient(rgba(0,0,0,${dim}),rgba(0,0,0,${dim})),url('${esc(img)}');background-size:cover;background-position:center`;
    if (view === 'spawn') { const m = $('.map'); if (m) m.style.cssText += ';' + css; }
    else root.insertAdjacentHTML('afterbegin', `<div class="cfgbg" style="${css}"></div>`);
  }
};
const show = html => { const was = !root.classList.contains('hidden'); root.innerHTML = html; root.classList.remove('hidden'); root.classList.toggle('static', was); applyCfg(); };   // 1re ouverture animée ; les redessins (Aléatoire, flèches…) ne rejouent pas l'animation
const close = () => { root.classList.add('hidden'); root.classList.remove('static'); root.innerHTML = ''; Music.stop(); view = null; };

/* ─────────── lecteur de musique ─────────── */
const Music = {
  cfg: null, i: 0, aud: $('#aud'), on: false,
  html() { return this.cfg && this.cfg.enabled && this.cfg.tracks.length ? `<div class="panel music" id="music"><div class="cover" id="mcover">${ic('note')}</div><div class="mi"><b id="mt">—</b><small id="ma"></small><div class="prog"><span id="mc">00:00</span><span id="md">00:00</span></div><div class="bar" id="mb"><i id="mp"></i></div><div class="ctl"><button data-m="prev">${ic('prev')}</button><button data-m="play" class="play">${ic('pause')}</button><button data-m="next">${ic('next')}</button></div></div><div class="vol"><input type="range" id="mv" min="0" max="100" orient="vertical">${ic('vol', 14)}</div></div>` : ''; },
  start(cfg) {
    if (cfg) this.cfg = cfg; if (!this.html()) return;
    const v = $('#mv'); if (v) { v.value = Math.round((this.cfg.volume != null ? this.cfg.volume : .35) * 100); v.style.setProperty('--p', v.value + '%'); v.oninput = () => { this.aud.volume = v.value / 100; v.style.setProperty('--p', v.value + '%'); }; this.aud.volume = v.value / 100; }
    if (!this.running) { this.running = true; this.load(this.i); this.play(); } else { this.load(this.i, false, true); this.icon(); }
    root.querySelectorAll('[data-m]').forEach(b => b.onclick = () => { const a = b.dataset.m; if (a === 'play') this.toggle(); else this.load(this.i + (a === 'next' ? 1 : -1), true); });
    const mb = $('#mb'); if (mb) mb.onclick = e => { const r = mb.getBoundingClientRect(); if (this.aud.duration) this.aud.currentTime = this.aud.duration * (e.clientX - r.left) / r.width; };
    this.aud.ontimeupdate = () => { const d = this.aud.duration || 0; const f = s => `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(Math.floor(s % 60)).padStart(2, '0')}`; if ($('#mp')) { $('#mp').style.width = d ? (this.aud.currentTime / d * 100) + '%' : '0'; $('#mc').textContent = f(this.aud.currentTime); $('#md').textContent = f(d); } };
    this.aud.onended = () => this.load(this.i + 1, true);
  },
  load(i, autoplay, ui) { const t = this.cfg.tracks; if (!t.length) return; this.i = (i + t.length) % t.length; const k = t[this.i]; if (!ui) this.aud.src = k.file; if ($('#mt')) { $('#mt').textContent = k.title || ''; $('#ma').textContent = k.artist || ''; const c = $('#mcover'); if (k.cover) { c.style.backgroundImage = `url('${k.cover}')`; c.innerHTML = ''; } else { c.style.backgroundImage = ''; c.innerHTML = ic('note'); } } if (autoplay) this.play(); },
  play() { this.aud.play().then(() => { this.on = true; this.icon(); }).catch(() => {}); },
  toggle() { if (this.aud.paused) this.play(); else { this.aud.pause(); this.on = false; this.icon(); } },
  icon() { const b = $('[data-m=play]'); if (b) b.innerHTML = ic(this.aud.paused ? 'play' : 'pause'); },
  stop() { this.running = false; try { this.aud.pause(); this.aud.removeAttribute('src'); } catch (e) {} },
};

/* ─────────── IDENTITÉ ─────────── */
const NAT = ['Américaine', 'Française', 'Britannique', 'Allemande', 'Italienne', 'Espagnole', 'Portugaise', 'Belge', 'Suisse', 'Néerlandaise', 'Canadienne', 'Mexicaine', 'Brésilienne', 'Argentine', 'Colombienne', 'Cubaine', 'Jamaïcaine', 'Haïtienne', 'Marocaine', 'Algérienne', 'Tunisienne', 'Sénégalaise', 'Ivoirienne', 'Camerounaise', 'Nigériane', 'Russe', 'Polonaise', 'Ukrainienne', 'Turque', 'Libanaise', 'Chinoise', 'Japonaise', 'Coréenne', 'Indienne', 'Australienne'];
const MONTHS = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
const FN = ['Maly', 'Lucas', 'Emma', 'Noah', 'Chloé', 'Marcus', 'Sofia', 'Tony', 'Léa', 'Yanis', 'Camille', 'Nolan'], LN = ['Pablo', 'Martin', 'Dupont', 'Rivera', 'Lopez', 'Moreau', 'Bernard', 'Silva', 'Carter', 'Rossi', 'Dubois', 'Costa'];
const rnd = a => a[Math.floor(Math.random() * a.length)];
function identity(d) {
  view = 'identity'; Music.i = 0; Music.cfg = d.music; Music.running = false;
  const S = { first: '', last: '', month: 0, year: 1995, day: 1, height: 175, nat: 0, sex: 'm' };
  const daysIn = () => new Date(S.year, S.month + 1, 0).getDate();
  const draw = () => { show(`<div id="v-identity">
    <div class="panel left"><div class="ptitle">${ic('pencil')}Enregistrement du Personnage</div><div class="scroll">
      <div class="sec"><div class="sec-h">Prénom & Nom<span class="pill gold" data-r="name">Aléatoire</span></div><p class="hint">Écrivez le prénom et le nom de votre personnage. Vous pouvez le générer aléatoirement.</p>
        <div class="row2"><input class="field" id="fn" placeholder="Prénom" maxlength="25" value="${esc(S.first)}"><input class="field" id="ln" placeholder="Nom" maxlength="25" value="${esc(S.last)}"></div></div>${sep}
      <div class="sec"><div class="sec-h">Date de Naissance<span class="pill gold" data-r="dob">Aléatoire</span></div><p class="hint">Sélectionnez la date de naissance de votre personnage.</p>
        <div class="row2"><div class="sel"><button data-a="mm">${ic('left', 14)}</button><b>${MONTHS[S.month]}</b><button data-a="mp">${ic('right', 14)}</button></div><div class="sel"><button data-a="ym">${ic('left', 14)}</button><b>${S.year}</b><button data-a="yp">${ic('right', 14)}</button></div></div>
        <div class="days">${Array.from({ length: daysIn() }, (_, i) => `<button data-day="${i + 1}" class="${S.day === i + 1 ? 'on' : ''}">${i + 1}</button>`).join('')}</div></div>${sep}
      <div class="sec"><div class="sec-h">Taille<span class="pill gold" data-r="h">Aléatoire</span></div><p class="hint">Choisissez la taille de votre personnage (140 – 200 cm).</p><div class="sl" style="grid-template-columns:1fr 60px"><input type="range" id="hh" min="140" max="200" value="${S.height}" style="--p:${(S.height - 140) / .6}%"><b>${S.height} cm</b></div></div>${sep}
      <div class="sec"><div class="sec-h">Nationalité<span class="pill gold" data-r="nat">Aléatoire</span></div><p class="hint">Choisissez la nationalité de votre personnage.</p><div class="sel"><button data-a="np">${ic('left', 14)}</button><b>${NAT[S.nat]}</b><button data-a="nn">${ic('right', 14)}</button></div></div>${sep}
      <div class="sec"><div class="sec-h">Genre<span class="pill gold" data-r="sex">Aléatoire</span></div><div class="seg2"><button data-sex="m" class="${S.sex === 'm' ? 'on' : ''}">Homme</button><button data-sex="f" class="${S.sex === 'f' ? 'on' : ''}">Femme</button></div></div>
    </div></div>
    ${Music.html()}<div class="actions"><button class="go" id="go">${ic('check', 16)}Créer</button><button class="no" id="no">Annuler</button></div></div>`);
    Music.start();
    const keep = () => { S.first = $('#fn').value; S.last = $('#ln').value; };
    root.onclick = e => {
      const t = e.target.closest('button,.pill'); if (!t) return; keep();
      const a = t.dataset.a, r = t.dataset.r;
      if (a === 'mm') S.month = (S.month + 11) % 12; else if (a === 'mp') S.month = (S.month + 1) % 12; else if (a === 'ym') S.year = Math.max(1940, S.year - 1); else if (a === 'yp') S.year = Math.min(new Date().getFullYear() - 18, S.year + 1);
      else if (a === 'np') S.nat = (S.nat + NAT.length - 1) % NAT.length; else if (a === 'nn') S.nat = (S.nat + 1) % NAT.length;
      else if (t.dataset.day) S.day = +t.dataset.day; else if (t.dataset.sex) { S.sex = t.dataset.sex; post('idSex', { sex: S.sex }); }
      else if (r === 'name') { S.first = rnd(FN); S.last = rnd(LN); } else if (r === 'dob') { S.month = Math.floor(Math.random() * 12); S.year = 1960 + Math.floor(Math.random() * 40); S.day = 1 + Math.floor(Math.random() * 28); } else if (r === 'h') S.height = 150 + Math.floor(Math.random() * 45); else if (r === 'nat') S.nat = Math.floor(Math.random() * NAT.length); else if (r === 'sex') { S.sex = Math.random() < .5 ? 'm' : 'f'; post('idSex', { sex: S.sex }); }
      else if (t.id === 'go') return submit(); else if (t.id === 'no') return post('idCancel'); else return;
      if (S.day > daysIn()) S.day = daysIn(); const sc = $('.scroll').scrollTop; draw(); $('.scroll').scrollTop = sc;
    };
    const hh = $('#hh'); if (hh) hh.oninput = () => { S.height = +hh.value; hh.style.setProperty('--p', (S.height - 140) / .6 + '%'); hh.nextElementSibling.textContent = S.height + ' cm'; };
  };
  const submit = async () => {
    const dob = `${String(S.day).padStart(2, '0')}/${String(S.month + 1).padStart(2, '0')}/${S.year}`;
    const r = await post('idRegister', { firstname: S.first.trim(), lastname: S.last.trim(), dateofbirth: dob, sex: S.sex, height: String(S.height), nationality: NAT[S.nat] });
    if (r && r.ok === false) toast(r.error || 'Informations invalides');
  };
  draw();
}
function toast(m) { let t = $('#toast'); if (!t) { t = document.createElement('div'); t.id = 'toast'; t.style.cssText = 'position:fixed;left:50%;top:40px;transform:translateX(-50%);padding:12px 22px;border-radius:10px;background:rgba(14,14,15,.92);border:1px solid rgba(var(--pk-accent-rgb,243,213,138),.5);font-size:13px;z-index:9'; document.body.appendChild(t); } t.textContent = m; t.style.display = 'block'; clearTimeout(t._t); t._t = setTimeout(() => t.style.display = 'none', 3500); }

/* ─────────── APPARENCE ─────────── */
const FATHERS = ['Benjamin', 'Daniel', 'Joshua', 'Noah', 'Andrew', 'Juan', 'Alex', 'Isaac', 'Evan', 'Ethan', 'Vincent', 'Angel', 'Diego', 'Adrian', 'Gabriel', 'Michael', 'Santiago', 'Kevin', 'Louis', 'Samuel', 'Anthony', 'Claude', 'Niko', 'John'];
const MOTHERS = ['Hannah', 'Aubrey', 'Jasmine', 'Gisele', 'Amelia', 'Isabella', 'Zoe', 'Ava', 'Camila', 'Violet', 'Sophia', 'Evelyn', 'Nicole', 'Ashley', 'Gracie', 'Brianna', 'Natalie', 'Olivia', 'Elizabeth', 'Charlotte', 'Emma', 'Misty'];
const EYES = ['#6f8f28', '#2f8a5a', '#8cc4e8', '#4a86c5', '#d58a3f', '#6b4a3a', '#a68a64', '#7d7f84', '#a9a9ad', '#e46fa0', '#e0aa22', '#7a62d6', '#2b2b2f', '#8a9db5', '#f0c419', '#5fe035', '#6b8a2e', '#3fd0c0', '#a8d4e6', '#2d4fb0', '#d9a722', '#5a3a2b', '#c6c6c9', '#e98a3a', '#7d4b3c', '#cbb890', '#3a6ea5', '#b5446e', '#2e6b4f', '#9a9a3a', '#555a66', '#e8e0cf'];
const HAIR = Array.from({ length: 64 }, (_, i) => `hsl(${[30, 28, 24, 20, 40, 45, 15, 8, 0, 210, 260, 320, 50, 120, 190, 280][i % 16]} ${[20, 35, 50, 60, 70][i % 5]}% ${[10, 18, 26, 34, 44, 56, 70, 85][Math.floor(i / 8)]}%)`);
const TRAIT = /^(nose|cheeks|lip_|jaw|chin|neck|eye_squint|eyebrow_(high|forward)|age_|blemishes|complexion|sun_|moles|blush_[12]|face_md|skin_md)/;
const HAIRTAB = /^(hair_|beard_|eyebrows_|makeup_|lipstick_|chest_|bodyb_)/;
const CLOTH = /^(tshirt|torso|decals|arms|pants|shoes|mask|bproof|chain|helmet|glasses|watches|bracelets|bags|ears)/;
function skin(d) {
  view = 'skin'; Music.cfg = d.music; Music.running = false; const C = {}; d.comps.forEach(c => C[c.name] = c);
  const S = { tab: 'apparence', her: 'face' }; const clothes = !d.opts.hideClothes;
  const set = (n, v) => { const c = C[n]; if (!c) return; const lo = c.min != null ? c.min : 0; v = Math.max(lo, Math.min(c.max, v)); c.value = v; post('skinChange', { name: n, value: v }); };
  const sw = (n, pal) => { const c = C[n]; if (!c) return ''; const lo = c.min != null ? c.min : 0; return `<div class="swatches">${Array.from({ length: Math.min(c.max - lo + 1, pal.length) }, (_, i) => `<button data-set="${n}:${lo + i}" class="${c.value === lo + i ? 'on' : ''}" style="background:${pal[(lo + i) % pal.length]}"></button>`).join('')}</div>`; };
  const selr = (n) => { const c = C[n]; if (!c) return ''; return `<div class="sel"><span style="flex:0 0 130px;color:#cfcfd4;font-size:12px">${esc(c.label)}</span><button data-step="${n}:-1">${ic('left', 13)}</button><b>${c.value}</b><button data-step="${n}:1">${ic('right', 13)}</button></div>`; };
  const slider = (n) => { const c = C[n]; if (!c) return ''; const lo = c.min != null ? c.min : 0, p = c.max > lo ? (c.value - lo) / (c.max - lo) * 100 : 0; return `<div class="sl"><span>${esc(c.label)}</span><b>${Math.round(p)}</b><input type="range" data-sl="${n}" min="${lo}" max="${c.max}" value="${c.value}" style="--p:${p}%"></div>`; };
  const head = (t, n, reset) => `<div class="sec-h">${t}<span class="btns"><span class="pill gold" data-rand="${n}">Aléatoire</span><span class="pill dark" data-reset="${n}">${ic('refresh', 12)} Réinitialiser</span></span></div>`;
  const faceBig = (n, label, names) => { const c = C[n]; if (!c) return ''; return `<div class="face-big ${S.her === n ? 'on' : ''}" data-her="${n}"><div class="im">${(names[c.value] || '?')[0]}</div><span>${esc(names[c.value] || label + ' ' + c.value)}</span></div>`; };
  const left = () => {
    if (S.tab === 'apparence') {
      const traits = d.comps.filter(c => TRAIT.test(c.name) && !/md_weight/.test(c.name) && c.max > 0);
      return `<div class="sec">${head('Visage', 'faces')}<p class="hint">Créez votre personnage selon vos envies.</p><div class="faces2">${faceBig('face', 'Père', FATHERS)}${faceBig('skin', 'Mère', MOTHERS)}</div></div>${sep}
        ${C.eye_color ? `<div class="sec">${head('Couleur des yeux', 'eye_color')}<p class="hint">Choisissez la couleur des yeux de votre personnage.</p>${sw('eye_color', EYES)}</div>${sep}` : ''}
        ${traits.length ? `<div class="sec">${head('Traits', 'traits')}<p class="hint">Ajustez les caractéristiques faciales de votre personnage.</p>${traits.map(c => slider(c.name)).join('')}</div>` : ''}`;
    }
    if (S.tab === 'coiffure') {
      const names = d.comps.filter(c => HAIRTAB.test(c.name) && c.max > 0).map(c => c.name);
      const col = names.filter(n => /color|_[34]$|hair_color/.test(n) || /^(hair_color|beard_[34]|eyebrows_[34]|makeup_[34]|lipstick_[34]|chest_3)/.test(n)), sel = names.filter(n => !col.includes(n));
      return `<div class="sec">${head('Cheveux & pilosité', 'hair')}<p class="hint">Style, couleur, barbe, sourcils et maquillage.</p>${sel.map(selr).join('')}</div>${sep}<div class="sec"><div class="sec-h">Couleurs</div>${col.map(n => `<p class="hint" style="margin:8px 0 0">${esc(C[n].label)}</p>${sw(n, HAIR)}`).join('')}</div>`;
    }
    const cl = d.comps.filter(c => CLOTH.test(c.name) && c.max >= 0 && (c.max > 0 || (c.min != null && c.min < 0)));
    return `<div class="sec">${head('Vêtements', 'cloth')}<p class="hint">Haut, bas, chaussures et accessoires.</p>${cl.map(c => selr(c.name)).join('') || '<p class="hint">Aucune pièce disponible.</p>'}</div>`;
  };
  const right = () => { const n = S.her, c = C[n]; if (S.tab !== 'apparence' || !c) return ''; const names = n === 'face' ? FATHERS : MOTHERS; const lo = c.min != null ? c.min : 0;
    return `<div class="panel right"><div class="sec-h" style="font-size:15px">Hérédité ${n === 'face' ? 1 : 2}<span class="btns"><span class="pill gold" data-rand="${n}">Aléatoire</span><span class="pill dark" data-reset="${n}">${ic('refresh', 12)} Réinitialiser</span></span></div><p class="hint">Sélectionnez un visage parmi les options disponibles.</p>
      <div class="scroll" style="flex:1"><div class="herolist">${Array.from({ length: c.max - lo + 1 }, (_, i) => `<div class="hero ${c.value === lo + i ? 'on' : ''}" data-set="${n}:${lo + i}"><i>${(names[lo + i] || String(lo + i))[0]}</i>${esc(names[lo + i] || ('#' + (lo + i)))}</div>`).join('')}</div>${sep}${slider('face_md_weight')}${slider('skin_md_weight')}<div class="seg2" style="grid-template-columns:1fr;margin-top:8px"><button data-rand="${n}" style="background:rgba(255,255,255,.07)">Aléatoire</button></div></div></div>`; };
  const draw = () => { const sc = $('.scroll') ? $('.scroll').scrollTop : 0; show(`<div id="v-skin"><div class="tabs">${['apparence', 'coiffure'].concat(clothes ? ['vetements'] : []).map(t => `<button data-tab="${t}" class="${S.tab === t ? 'on' : ''}">${{ apparence: 'Apparence', coiffure: 'Coiffure', vetements: 'Vêtements' }[t]}</button>`).join('')}</div>
    <div class="panel left"><div class="ptitle">${ic('wand')}${{ apparence: 'Apparence', coiffure: 'Coiffure', vetements: 'Vêtements' }[S.tab]}</div><div class="scroll">${left()}</div></div>${right()}
    ${Music.html()}<button class="finish" id="fin">${ic('check', 16)}Terminer</button></div>`);
    if ($('.scroll')) $('.scroll').scrollTop = sc; Music.start(); };
  draw();
  const rand = n => { const c = C[n]; if (!c) return; const lo = c.min != null ? c.min : 0; set(n, lo + Math.floor(Math.random() * (c.max - lo + 1))); };
  root.onclick = e => {
    const t = e.target.closest('[data-tab],[data-set],[data-step],[data-rand],[data-reset],[data-her],#fin'); if (!t) return;
    if (t.id === 'fin') return post('skinDone');
    if (t.dataset.tab) { S.tab = t.dataset.tab; return draw(); }
    if (t.dataset.her) S.her = t.dataset.her;
    if (t.dataset.set) { const [n, v] = t.dataset.set.split(':'); set(n, +v); }
    if (t.dataset.step) { const [n, v] = t.dataset.step.split(':'); set(n, C[n].value + +v); }
    if (t.dataset.rand) { const k = t.dataset.rand; if (k === 'faces') { rand('face'); rand('skin'); } else if (k === 'traits') d.comps.filter(c => TRAIT.test(c.name)).forEach(c => rand(c.name)); else if (k === 'hair') d.comps.filter(c => HAIRTAB.test(c.name)).forEach(c => rand(c.name)); else if (k === 'cloth') d.comps.filter(c => CLOTH.test(c.name)).forEach(c => rand(c.name)); else rand(k); }
    if (t.dataset.reset) { const k = t.dataset.reset; const names = k === 'faces' ? ['face', 'skin'] : k === 'traits' ? d.comps.filter(c => TRAIT.test(c.name)).map(c => c.name) : k === 'hair' ? d.comps.filter(c => HAIRTAB.test(c.name)).map(c => c.name) : k === 'cloth' ? d.comps.filter(c => CLOTH.test(c.name)).map(c => c.name) : [k]; names.forEach(n => set(n, C[n].min != null ? Math.max(0, C[n].min) : 0)); }
    draw();
  };
  root.oninput = e => { const r = e.target.dataset.sl; if (!r) return; const c = C[r], lo = c.min != null ? c.min : 0; set(r, +e.target.value); const p = (c.value - lo) / (c.max - lo) * 100; e.target.style.setProperty('--p', p + '%'); e.target.parentElement.querySelector('b').textContent = Math.round(p); };
  let drag = null; root.onmousedown = e => { if (!e.target.closest('.panel,.tabs,button,.hints,.finish')) drag = e.clientX; };
  window.onmouseup = () => { drag = null; }; window.onmousemove = e => { if (drag != null && view === 'skin') { post('camRotate', { dx: e.clientX - drag }); drag = e.clientX; } };
  root.onwheel = e => { if (view === 'skin' && !e.target.closest('.scroll')) post('camZoom', { dy: e.deltaY }); };
}

/* ─────────── POINT D'APPARITION ─────────── */
function spawn(d) {
  view = 'spawn'; const spots = d.spots; let sel = 0, page = 0;
  const m = d.map || { minX: -4100, maxX: 4500, minY: -4200, maxY: 8000 };
  const xy = s => [((s.x - m.minX) / (m.maxX - m.minX)) * 100, ((m.maxY - s.y) / (m.maxY - m.minY)) * 100];
  const draw = () => {
    const others = spots.map((s, i) => [s, i]).filter(([, i]) => i !== sel), per = 4, pages = Math.max(1, Math.ceil(others.length / per)); if (page >= pages) page = 0;
    const s0 = spots[sel], vis = others.slice(page * per, page * per + per);
    const card = (s, i, on) => `<div class="card ${on ? 'on' : ''}" data-i="${i}"><div class="ph" style="${s.image ? `background-image:url('${esc(s.image)}')` : ''}"></div><div class="bd"><div class="ic">${ic('pin', 26)}</div><div><b>${esc(s.label)}</b><span class="loc">${ic('pin', 11)}${esc(s.place || s.desc || '')}</span></div>${on ? `<div class="tick">${ic('check', 16)}</div>` : ''}</div></div>`;
    show(`<div id="v-spawn"><div class="map" style="${d.mapImage ? `background-image:url('${esc(d.mapImage)}')` : ''}"></div>
      <div class="sp-t"><h1>${ic('pin')}Point d'apparition</h1><p>Choisissez votre point d'apparition sur la carte de Los Santos.</p></div>
      ${spots.map((s, i) => { const [x, y] = xy(s); return `<div class="pin ${i === sel ? 'on' : ''}" data-i="${i}" style="left:${x}%;top:${y}%">${ic('pin')}</div>`; }).join('')}
      <div style="position:absolute;left:62px;bottom:128px;width:313px">${card(s0, sel, true)}</div><button class="go-here" id="go">${ic('check', 16)}Apparaître ici</button>
      <div class="cards" style="left:430px;gap:60px">${vis.map(([s, i]) => card(s, i, false)).join('')}</div>
      ${pages > 1 ? `<button style="position:absolute;right:62px;bottom:420px;font-size:12px;display:flex;gap:10px;align-items:center" id="pg">Page ${page + 1}/${pages}${ic('right', 18)}</button>` : ''}</div>`);
  };
  draw();
  root.onclick = e => { const t = e.target.closest('[data-i],#go,#pg'); if (!t) return; if (t.id === 'go') return post('spawnPick', { index: sel + 1 }); if (t.id === 'pg') { page++; return draw(); } sel = +t.dataset.i; draw(); };
}

/* ─────────── BIENVENUE ─────────── */
function welcome(d) {
  view = 'welcome';
  show(`<div id="v-welcome"><div class="wl">${d.logo ? `<img src="${esc(d.logo)}" alt="">` : ''}<div class="dia"></div><h1>${esc(d.title)} <em>${esc(d.highlight)}</em></h1><p>${esc(d.text)}</p>${d.duration ? '' : '<button class="ok" id="ok">Continuer</button>'}</div></div>`);
  const end = () => { post('welcomeDone'); close(); };
  if (d.duration) setTimeout(() => { if (view === 'welcome') end(); }, d.duration); else $('#ok').onclick = end;
}

/* ─────────── ANIMATIONS ─────────── */
function emotes(d) {
  view = 'emotes'; const favs = new Set(d.favs || []); let cat = 'all', q = '', sort = 'az', limit = 60, quick = d.fav || '';
  const CATS = [['all', 'Tout', 'grid'], ['emotes', 'Animations', 'run'], ['props', 'Objets', 'box'], ['shared', 'À deux', 'duo'], ['expr', 'Expressions', 'smile'], ['walks', 'Démarches', 'walk'], ['fav', 'Favoris', 'heart']];
  const list = () => { let a = d.items.filter(i => (cat === 'all' || (cat === 'fav' ? favs.has(i.id) : i.type === cat)) && (!q || (i.label + ' ' + i.cmd).toLowerCase().includes(q))); a = a.slice().sort((x, y) => sort === 'za' ? y.label.localeCompare(x.label, 'fr') : x.label.localeCompare(y.label, 'fr')); if (sort === 'rnd') a.sort(() => Math.random() - .5); return a; };
  const rows = () => { const a = list(); return a.slice(0, limit).map(i => `<div class="erow"><div class="ico">${ic({ emotes: 'run', props: 'box', shared: 'duo', expr: 'smile', walks: 'walk' }[i.type] || 'run', 24)}</div><div class="t"><b>${esc(i.label)}</b><small>/${i.type === 'walks' ? 'walk' : 'e'} ${esc(i.cmd)}</small></div><button class="pl" data-play="${esc(i.id)}">${ic('play')}</button><button class="fv ${favs.has(i.id) ? 'on' : ''}" data-fav="${esc(i.id)}">${ic('heart', 22)}</button></div>`).join('') + (a.length > limit ? '<div style="text-align:center;padding:10px;color:#888;font-size:11px">Défile pour en afficher plus…</div>' : '') || '<div style="color:#888;padding:20px;text-align:center">Aucune animation.</div>'; };
  show(`<div id="v-emotes"><div class="hd"><small>GESTIONNAIRE</small><h1>ANIMATIONS</h1></div>
    <div class="erail">${CATS.map(([id, l, i]) => `<button data-cat="${id}" class="${id === cat ? 'on' : ''}">${ic(i)}${l}</button>`).join('')}</div>
    <div class="eshort"><span>Attribuez des touches</span><b>RACCOURCIS</b></div>
    <div class="elist"><input class="esearch" id="es" placeholder="Recherchez une animation"><div class="esort">Trier :<button data-sort="az" class="on">De A à Z</button><button data-sort="za">De Z à A</button><button data-sort="rnd">Aléatoire</button></div><div class="erows" id="er">${rows()}</div></div></div>`);
  const redraw = () => { $('#er').innerHTML = rows(); root.querySelectorAll('[data-cat]').forEach(b => b.classList.toggle('on', b.dataset.cat === cat)); root.querySelectorAll('[data-sort]').forEach(b => b.classList.toggle('on', b.dataset.sort === sort)); };
  root.onclick = e => { const t = e.target.closest('[data-cat],[data-sort],[data-play],[data-fav]'); if (!t) return;
    if (t.dataset.cat) { cat = t.dataset.cat; limit = 60; } else if (t.dataset.sort) sort = t.dataset.sort;
    else if (t.dataset.play) { post('emotePlay', { id: t.dataset.play }); return; } else if (t.dataset.fav) { const id = t.dataset.fav; if (favs.has(id)) favs.delete(id); else favs.add(id); post('emoteFav', { id, on: favs.has(id), favs: [...favs] }); }
    redraw(); };
  $('#es').oninput = e => { q = e.target.value.toLowerCase(); limit = 60; redraw(); };
  $('#er').onscroll = e => { const n = e.target; if (n.scrollTop + n.clientHeight > n.scrollHeight - 80 && limit < list().length) { limit += 60; $('#er').insertAdjacentHTML('beforeend', ''); const top = n.scrollTop; redraw(); n.scrollTop = top; } };
}

window.addEventListener('message', e => {
  const d = e.data || {};
  if (d.cfg && typeof d.cfg === 'object') CFG = d.cfg;
  switch (d.a) {
    case 'identity': return identity(d);
    case 'skin': return skin(d);
    case 'spawn': return spawn(d);
    case 'welcome': return welcome(d);
    case 'emotes': return emotes(d);
    case 'close': return close();
  }
});
document.addEventListener('keydown', e => { if (e.key === 'Escape') post('escape', { view }); });
