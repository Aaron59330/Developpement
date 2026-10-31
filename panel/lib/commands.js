// Liste blanche des actions que le panel peut demander au serveur FiveM (validées ici ET dans la ressource pickax_panel)
const int = (v, min, max) => { v = Math.floor(Number(v)); return Number.isFinite(v) && v >= min && v <= max ? v : null; };
const str = (v, max, re) => { if (typeof v !== 'string') return null; v = v.trim(); if (!v || v.length > max) return null; if (re && !re.test(v)) return null; return v; };
const ID = /^[A-Za-z0-9_:\-\.]+$/;
const defs = {
  announce:   (p) => { const m = str(p.message, 200); return m && { message: m }; },
  kick:       (p) => { const id = int(p.id, 1, 65535); return id && { id, reason: str(p.reason || 'Expulsé par le staff', 120) || 'Expulsé par le staff' }; },
  ban:        (p) => { const id = p.id != null && p.id !== '' ? int(p.id, 1, 65535) : null; const ident = str(p.identifier || '', 120, ID); if (!id && !ident) return null; return { id, identifier: ident, name: str(p.name || '', 60) || '', reason: str(p.reason || 'Banni', 120) || 'Banni', days: int(p.days || 0, 0, 3650) || 0 }; },
  unban:      (p) => { const ident = str(p.identifier, 120, ID); return ident && { identifier: ident }; },
  setjob:     (p) => { const id = int(p.id, 1, 65535), job = str(p.job, 40, ID), grade = int(p.grade, 0, 99); return id && job && grade !== null && { id, job, grade }; },
  setgroup:   (p) => { const id = int(p.id, 1, 65535), group = str(p.group, 30, ID); return id && group && { id, group }; },
  givemoney:  (p) => { const id = int(p.id, 1, 65535), amount = int(p.amount, -10000000, 10000000), account = ['money', 'bank', 'black_money'].includes(p.account) ? p.account : null; return id && amount !== null && account && { id, amount, account }; },
  giveitem:   (p) => { const id = int(p.id, 1, 65535), item = str(p.item, 60, ID), count = int(p.count, 1, 10000); return id && item && count && { id, item, count }; },
  revive:     (p) => { const id = int(p.id, 1, 65535); return id && { id }; },
  message:    (p) => { const id = int(p.id, 1, 65535), m = str(p.message, 200); return id && m && { id, message: m }; },
  restart_resource: (p) => { const r = str(p.resource, 60, ID); return r && { resource: r }; },
  whitelist_add:    (p) => { const i = str(p.identifier, 120, ID); return i && { identifier: i }; },
  whitelist_remove: (p) => { const i = str(p.identifier, 120, ID); return i && { identifier: i }; },
  economy_event: (p) => { const k = str(p.key, 40, ID), s = Number(p.swing), h = int(p.hours, 1, 720); return k && Number.isFinite(s) && s >= -0.9 && s <= 3 && h && { key: k, swing: s, hours: h }; },
  economy_reset: (p) => ({ key: str(p.key || '', 40, ID) || '' }),
  console:    (p) => { const c = str(p.cmd, 200); return c && !/[\r\n;]/.test(c) && { cmd: c }; },
  settings_profile: (p) => { const id = str(p.profile, 30, ID); return id && require('./profiles').PROFILES.some(x => x.id === id) && { profile: id }; },
  server_restart: () => ({}),
  server_stop:    () => ({}),
  resource_start: (p) => { const r = str(p.resource, 60, ID); return r && { resource: r }; },
  resource_stop:  (p) => { const r = str(p.resource, 60, ID); return r && { resource: r }; },
  apply_theme: (p) => ({ core: !!p.core }),
  apply_loading: (p) => ({ core: !!p.core }),
  refresh_docs: () => ({}),
  teleport:   (p) => { const id = int(p.id, 1, 65535), x = Number(p.x), y = Number(p.y); return id && Number.isFinite(x) && Number.isFinite(y) && x >= -6000 && x <= 8000 && y >= -8000 && y <= 11000 && { id, x: Math.round(x * 10) / 10, y: Math.round(y * 10) / 10 }; },
  jobs_refresh: () => ({}),
};
function validate(type, payload) { const f = defs[type]; if (!f) return { error: 'Action inconnue' }; const out = f(payload || {}); return out ? { payload: out } : { error: 'Paramètres invalides' }; }
const DOC_KEYS = { theme: 1, bans: 1, whitelist: 1, motd: 1, server: 1, economy: 1, loading: 1, creator: 1, boutique: 1 };
const ECONOMY_PRESETS = ['equilibre', 'realiste', 'abuse'];
function validateDoc(key, v) {
  if (!DOC_KEYS[key]) return { error: 'Document inconnu' };
  if (v == null || typeof v !== 'object') return { error: 'Données invalides' };
  if (key === 'theme') {
    const hex = /^#[0-9a-fA-F]{6}$/; const t = {};
    if (!hex.test(v.AccentColor || '')) return { error: 'Couleur principale invalide (#RRGGBB)' };
    t.AccentColor = v.AccentColor.toLowerCase(); t.InventoryColor = hex.test(v.InventoryColor || '') ? v.InventoryColor.toLowerCase() : '';
    const txt = (x, max, req) => { x = String(x == null ? '' : x).trim(); if (x.length > max || /['"\\\r\n]/.test(x)) return null; if (req && !x) return null; return x; };
    t.ServerName = txt(v.ServerName, 60, true); t.ServerShortName = txt(v.ServerShortName, 24, true); t.ServerTagline = txt(v.ServerTagline, 80); t.ServerDiscord = txt(v.ServerDiscord, 80); t.ServerLogo = txt(v.ServerLogo, 200, true);
    t.Design = ['ancien', 'pinata'].includes(v.Design) ? v.Design : 'arcade';
    const url = x => { x = String(x == null ? '' : x).trim(); if (!x) return ''; return x.length <= 300 && /^https:\/\/[\w\-._~:/?#@!$&()*+,;=%]+$/.test(x) ? x : null; };
    t.MenuBanner = url(v.MenuBanner); t.LoadingBanner = url(v.LoadingBanner);
    const num = (x, lo, hi, d) => { x = Number(x); return Number.isFinite(x) ? Math.min(hi, Math.max(lo, x)) : d; };
    t.MarkerType = Math.round(num(v.MarkerType, 0, 43, 23)); t.MarkerAlpha = Math.round(num(v.MarkerAlpha, 0, 255, 150)); t.MarkerSize = num(v.MarkerSize, 0.1, 5, 1);
    t.MarkerColor = /^#[0-9a-fA-F]{6}$/.test(v.MarkerColor || '') ? v.MarkerColor.toLowerCase() : '';
    t.BlipScale = num(v.BlipScale, 0.1, 3, 0.5); t.BlipColor = Math.round(num(v.BlipColor, -1, 85, -1));
    if (Object.values(t).includes(null)) return { error: 'Un champ du thème est invalide (pas de guillemets, longueur limitée)' };
    return { value: t };
  }
  if (key === 'loading') {
    const clean = (x, max) => String(x == null ? '' : x).replace(/[\u0000-\u001f]/g, ' ').trim().slice(0, max);
    const url = x => { x = String(x == null ? '' : x).trim(); if (!x) return ''; return x.length <= 300 && /^https:\/\/[\w\-._~:/?#@!$&()*+,;=%]+$/.test(x) ? x : null; };
    const o = { tips: [], links: {}, team: [], updates: [], stages: [], music: {} };
    for (const t of (Array.isArray(v.tips) ? v.tips : []).slice(0, 12)) { const x = clean(t, 140); if (x) o.tips.push(x); }
    const L = v.links && typeof v.links === 'object' ? v.links : {};
    for (const k of ['reglement', 'discord', 'boutique']) { const u = url(L[k]); if (u === null) return { error: `Lien « ${k} » invalide : il doit commencer par https://` }; o.links[k] = u; }
    for (const m of (Array.isArray(v.team) ? v.team : []).slice(0, 12)) { const n = clean(m && m.name, 40); if (n) o.team.push({ name: n, role: clean(m.role, 60) }); }
    for (const u of (Array.isArray(v.updates) ? v.updates : []).slice(0, 8)) { const t = clean(u && u.title, 60); if (t) o.updates.push({ date: clean(u.date, 20), title: t, items: (Array.isArray(u.items) ? u.items : []).map(i => clean(i, 120)).filter(Boolean).slice(0, 6) }); }
    for (let i = 0; i < 4; i++) o.stages.push(clean(Array.isArray(v.stages) ? v.stages[i] : '', 40));
    const M = v.music && typeof v.music === 'object' ? v.music : {}; const mu = url(M.url); if (mu === null) return { error: 'Adresse de la musique invalide : elle doit commencer par https://' };
    const vol = Number(M.volume); o.music = { enabled: M.enabled !== false, url: mu, volume: Number.isFinite(vol) ? Math.min(100, Math.max(0, Math.round(vol))) : 10, autoplay: M.autoplay !== false };
    o.showTeam = v.showTeam !== false; o.showUpdates = v.showUpdates !== false;
    // apparence : image de fond, logo, textes de l'interface, éléments masqués
    const B = v.bg && typeof v.bg === 'object' ? v.bg : {}; const bi = url(B.image); if (bi === null) return { error: 'Image de fond invalide : elle doit commencer par https://' };
    o.bg = { image: bi, dim: Math.min(100, Math.max(0, Math.round(Number(B.dim) || 0))), blur: Math.min(20, Math.max(0, Math.round(Number(B.blur) || 0))) };
    const lg = url(v.logo); if (lg === null) return { error: 'Logo invalide : il doit commencer par https://' }; o.logo = lg;
    o.texts = {}; for (const [k, t] of Object.entries(v.texts && typeof v.texts === 'object' ? v.texts : {}).slice(0, 80)) { const kk = clean(k, 80), tt = clean(t, 140); if (kk && tt) o.texts[kk] = tt; }
    const H = v.hide && typeof v.hide === 'object' ? v.hide : {}; o.hide = {}; for (const k of ['logo', 'ticker', 'links', 'progress', 'name']) o.hide[k] = !!H[k];
    return { value: o };
  }
  if (key === 'creator') {
    // Parcours d'arrivée : identité, apparence, point d'apparition, bienvenue, animations
    const clean = (x, max) => String(x == null ? '' : x).replace(/[\u0000-\u001f]/g, ' ').trim().slice(0, max);
    const url = x => { x = String(x == null ? '' : x).trim(); if (!x) return ''; return x.length <= 300 && /^https:\/\/[\w\-._~:/?#@!$&()*+,;=%]+$/.test(x) ? x : null; };
    const file = (x, re) => { x = String(x == null ? '' : x).trim(); if (!x) return ''; if (/^https:\/\//.test(x)) return url(x); return x.length <= 120 && re.test(x) && !x.includes('..') ? x : null; };
    const IMG = /^[\w\- .\/]+\.(jpg|jpeg|png)$/i, AUD = /^[\w\- .\/]+\.(mp3|ogg|wav)$/i;
    const num = (x, lo, hi, d) => { x = Number(x); return Number.isFinite(x) ? Math.min(hi, Math.max(lo, x)) : d; };
    const o = { texts: {}, bg: {}, music: { enabled: true, volume: 35, tracks: [] }, studio: {}, spots: [], map: {}, welcome: {} };
    for (const [k, t] of Object.entries(v.texts && typeof v.texts === 'object' ? v.texts : {}).slice(0, 150)) { const kk = clean(k, 100), tt = clean(t, 200); if (kk && tt) o.texts[kk] = tt; }
    const B = v.bg && typeof v.bg === 'object' ? v.bg : {};
    for (const k of ['identity', 'skin', 'spawn', 'welcome', 'emotes']) { const u = file(B[k], IMG); if (u === null) return { error: `Image de fond « ${k} » invalide : lien https:// ou nom de fichier .jpg ou .png` }; o.bg[k] = u; }
    o.bg.dim = Math.round(num(B.dim, 0, 100, 0));
    const M = v.music && typeof v.music === 'object' ? v.music : {}; o.music.enabled = M.enabled !== false; o.music.volume = Math.round(num(M.volume, 0, 100, 35));
    for (const t of (Array.isArray(M.tracks) ? M.tracks : []).slice(0, 12)) { const f = file(t && t.file, AUD); if (f === null) return { error: 'Fichier de musique invalide : lien https:// ou nom de fichier .mp3/.ogg' }; const cv = file(t && t.cover, IMG); if (cv === null) return { error: 'Pochette de musique invalide' }; if (f) o.music.tracks.push({ title: clean(t.title, 60), artist: clean(t.artist, 60), file: f.startsWith('http') ? f : (f.startsWith('music/') ? f : 'music/' + f), cover: cv }); }
    const S = v.studio && typeof v.studio === 'object' ? v.studio : {}; if (S.x !== undefined && S.x !== '' && S.x !== null) o.studio = { enabled: S.enabled !== false, x: num(S.x, -8000, 8000, 0), y: num(S.y, -8000, 11000, 0), z: num(S.z, -500, 2000, 30), h: num(S.h, 0, 360, 0), camDistance: num(S.camDistance, 0.9, 6, 2.4), camHeight: num(S.camHeight, -0.5, 1.5, 0.45) };
    for (const sp of (Array.isArray(v.spots) ? v.spots : []).slice(0, 12)) { const label = clean(sp && sp.label, 50); if (!label) continue; const im = file(sp.image, IMG); if (im === null) return { error: `Image du lieu « ${label} » invalide : lien https:// ou nom de fichier .jpg ou .png` }; o.spots.push({ label, description: clean(sp.description, 90), icon: clean(sp.icon, 12), image: im, x: num(sp.x, -8000, 8000, 0), y: num(sp.y, -8000, 11000, 0), z: num(sp.z, -500, 2000, 30), h: num(sp.h, 0, 360, 0) }); }
    const MP = v.map && typeof v.map === 'object' ? v.map : {}; const mi = file(MP.image, IMG); if (mi === null) return { error: 'Image de la carte invalide' };
    o.map = { image: mi, minX: num(MP.minX, -20000, 20000, -4100), maxX: num(MP.maxX, -20000, 20000, 4500), minY: num(MP.minY, -20000, 20000, -4200), maxY: num(MP.maxY, -20000, 20000, 8000) };
    const W = v.welcome && typeof v.welcome === 'object' ? v.welcome : {}; const wl = url(W.logo); if (wl === null) return { error: 'Logo de bienvenue invalide (https://)' };
    o.welcome = { enabled: W.enabled !== false, title: clean(W.title, 80), highlight: clean(W.highlight, 40), text: clean(W.text, 400), duration: Math.round(num(W.duration, 0, 60000, 9000)), logo: wl };
    return { value: o };
  }
  if (key === 'boutique') {
    // Boutique à coins : véhicules, motos, avions et bateaux, armes, caisses, packs, VIP, entreprises
    const txt = (x, max) => String(x == null ? '' : x).replace(/[\u0000-\u0008\u000b-\u001f]/g, ' ').trim().slice(0, max);
    const price = x => { x = Math.floor(Number(x)); return Number.isFinite(x) && x >= 0 && x <= 100000000 ? String(x) : null; };
    const ID = /^[A-Za-z0-9_]{1,50}$/;
    const list = (a, max) => Array.isArray(a) ? a.slice(0, max) : [];
    const num = (x, lo, hi, d) => { x = Number(x); return Number.isFinite(x) ? Math.min(hi, Math.max(lo, x)) : d; };
    const o = {}; const bad = m => ({ error: m });
    const veh = (arr, label, withType) => { const out = []; for (const r of list(arr, 120)) { if (r && r.Separator) { if (withType) out.push({ Separator: true, name: txt(r.name, 60) }); continue; } const name = txt(r && r.name, 60), model = String((r && r.model) || '').trim(), p = price(r && r.price); if (!name) continue; if (!ID.test(model)) return bad(`${label} « ${name} » : nom de modèle invalide (lettres, chiffres, _)`); if (p === null) return bad(`${label} « ${name} » : prix invalide`); const e = { name, model, price: p }; if (withType && ['aircraft', 'boat'].includes(r.type)) e.type = r.type; out.push(e); } return out; };
    for (const [k, l, wt] of [['vehicle', 'Véhicule', false], ['Motos', 'Moto', false], ['Autres', 'Avion / bateau', true]]) { if (v[k] === undefined) continue; const r = veh(v[k], l, wt); if (r.error) return r; o[k] = r; }
    if (v.weapon !== undefined) { o.weapon = []; for (const r of list(v.weapon, 60)) { const name = txt(r && r.name, 60), model = String((r && r.model) || '').trim().toLowerCase(), p = price(r && r.price), b = Math.floor(Number(r && r.balle)); if (!name) continue; if (!/^weapon_[a-z0-9_]{1,40}$/.test(model)) return bad(`Arme « ${name} » : le nom doit commencer par weapon_`); if (p === null) return bad(`Arme « ${name} » : prix invalide`); o.weapon.push({ name, model, price: p, balle: String(Number.isFinite(b) && b >= 0 && b <= 9999 ? b : 250) }); } }
    const rewards = (arr, where) => { const out = []; for (const w of list(arr, 30)) { if (!w || typeof w !== 'object') continue; if (w.item !== undefined) { const it = String(w.item).trim(); const am = Math.floor(Number(w.amount)); if (!ID.test(it) || !(am >= 1 && am <= 100000)) return bad(`${where} : objet ou quantité invalide`); out.push({ item: it, amount: am }); } else if (w.money !== undefined) { const m = Math.floor(Number(w.money)); if (!(m >= 1 && m <= 1000000000)) return bad(`${where} : montant invalide`); out.push({ money: m }); } else if (w.weapon !== undefined) { const wp = String(w.weapon).trim().toLowerCase(); if (!/^weapon_[a-z0-9_]{1,40}$/.test(wp)) return bad(`${where} : arme invalide`); out.push({ weapon: wp }); } else if (w.vip !== undefined) { const lv = Math.floor(Number(w.vip)), d = Math.floor(Number(w.days)); if (!(lv >= 1 && lv <= 3) || !(d >= 1 && d <= 3650)) return bad(`${where} : niveau VIP (1 à 3) ou durée invalide`); out.push({ vip: lv, days: d }); } } return out; };
    if (v.pack !== undefined) { o.pack = []; for (const r of list(v.pack, 40)) { const name = txt(r && r.name, 60), p = price(r && r.price); if (!name) continue; if (p === null) return bad(`Pack « ${name} » : prix invalide`); const w = rewards(r.Win, `Pack « ${name} »`); if (w.error) return w; o.pack.push({ name, desc: txt(r.desc, 400), price: p, Win: w }); } }
    if (v.vip !== undefined) { o.vip = []; for (const r of list(v.vip, 12)) { const name = txt(r && r.name, 60), p = price(r && r.price); if (!name) continue; if (p === null) return bad(`VIP « ${name} » : prix invalide`); const w = rewards(r.Win, `VIP « ${name} »`); if (w.error) return w; o.vip.push({ name, desc: txt(r.desc, 400), price: p, Win: w }); } }
    if (v.Entreprise !== undefined) { o.Entreprise = []; for (const r of list(v.Entreprise, 30)) { const name = txt(r && r.name, 60), p = price(r && r.price); if (!name) continue; if (p === null) return bad(`Entreprise « ${name} » : prix invalide`); o.Entreprise.push({ name, desc: txt(r.desc, 400), price: p }); } }
    if (v.boost !== undefined) { o.boost = []; for (const r of list(v.boost, 6)) { const p = price(r && r.price); if (p === null) return bad('Boost : prix invalide'); o.boost.push({ price: p }); } }
    if (v.ESXCustom !== undefined) {
      o.ESXCustom = {}; const src = v.ESXCustom && typeof v.ESXCustom === 'object' ? v.ESXCustom : {};
      for (const [id, c] of Object.entries(src).slice(0, 15)) { if (!ID.test(id)) return bad('Identifiant de caisse invalide : ' + id); const name = txt(c && c.name, 60) || id; const items = []; for (const it of list(c && c.list, 60)) { const nm = txt(it && it.name, 60); if (!nm) continue; const tier = Math.floor(Number(it.tier)); const e = { name: nm, tier: tier >= 1 && tier <= 5 ? tier : 5 }; if (it.vehicle !== undefined && String(it.vehicle).trim()) { if (!ID.test(String(it.vehicle).trim())) return bad(`Caisse « ${name} » : modèle de véhicule invalide`); e.vehicle = String(it.vehicle).trim(); } else if (it.weapon !== undefined && String(it.weapon).trim()) { const wp = String(it.weapon).trim().toLowerCase(); if (!/^weapon_[a-z0-9_]{1,40}$/.test(wp)) return bad(`Caisse « ${name} » : arme invalide`); e.weapon = wp; e.amount = Math.max(1, Math.floor(Number(it.amount)) || 1); } else if (it.Coins !== undefined) { const n = Math.floor(Number(it.Coins)); if (!(n >= 1 && n <= 10000000)) return bad(`Caisse « ${name} » : coins invalides`); e.Coins = n; } else if (it.money !== undefined) { const n = Math.floor(Number(it.money)); if (!(n >= 1 && n <= 1000000000)) return bad(`Caisse « ${name} » : montant invalide`); e.money = n; } else if (it.item !== undefined && String(it.item).trim()) { if (!ID.test(String(it.item).trim())) return bad(`Caisse « ${name} » : objet invalide`); e.item = String(it.item).trim(); e.amount = Math.max(1, Math.floor(Number(it.amount)) || 1); } else continue; if (it.modelTexture && ID.test(String(it.modelTexture))) e.modelTexture = String(it.modelTexture); items.push(e); } o.ESXCustom[id] = { name, list: items }; }
    }
    if (v.caisse !== undefined) { o.caisse = []; for (const r of list(v.caisse, 15)) { const name = txt(r && r.name, 60), p = price(r && r.price), model = String((r && r.model) || '').trim(); if (!name) continue; if (!ID.test(model)) return bad(`Caisse « ${name} » : identifiant invalide`); if (p === null) return bad(`Caisse « ${name} » : prix invalide`); o.caisse.push({ name, model, price: p, desc: txt(r.desc, 500) }); } }
    if (v.chance !== undefined) { o.chance = []; for (const r of list(v.chance, 5)) { const rate = Number(r && r.rate); if (!Number.isFinite(rate) || rate < 0 || rate > 100) return bad('Chances des caisses : pourcentage invalide (0 à 100)'); o.chance.push({ name: txt(r.name, 40), rate }); } }
    if (v.wheel !== undefined) {   // roulette du jour
      const w = v.wheel && typeof v.wheel === 'object' ? v.wheel : {}; const prizes = [];
      for (const r of list(w.prizes, 12)) { const label = txt(r && r.label, 40); if (!label) continue; const kind = ['coins', 'money', 'item', 'none'].includes(r.kind) ? r.kind : 'none'; const wgt = Number(r.weight); if (!(wgt > 0 && wgt <= 1000)) return bad(`Roulette « ${label} » : le poids doit être entre 0,1 et 1000`);
        const e = { label, kind, weight: Math.round(wgt * 100) / 100 }; if (kind === 'coins' || kind === 'money') { const n = Math.floor(Number(r.amount)); const max = kind === 'coins' ? 100000 : 5000000; if (!(n >= 1 && n <= max)) return bad(`Roulette « ${label} » : montant invalide (1 à ${max})`); e.amount = n; } else if (kind === 'item') { const it = String(r.item || '').trim(); const n = Math.floor(Number(r.amount)); if (!/^[A-Za-z0-9_\-]{1,50}$/.test(it) || !(n >= 1 && n <= 1000)) return bad(`Roulette « ${label} » : objet ou quantité invalide`); e.item = it; e.amount = n; }
        if (/^#[0-9a-fA-F]{6}$/.test(String(r.color || ''))) e.color = String(r.color).toLowerCase(); prizes.push(e); }
      if (prizes.length < 2) return bad('Roulette : il faut au moins 2 lots (maximum 12)');
      o.wheel = { enabled: w.enabled !== false, spins: Math.round(num(w.spins, 1, 10, 1)), resetHour: Math.round(num(w.resetHour, 0, 23, 0)), account: w.account === 'bank' ? 'bank' : 'money', prizes };
    }
    if (v.weaponCustom !== undefined) o.weaponCustom = !!v.weaponCustom;
    for (const k of ['weaponCustomPrice', 'WeaponAmmoInWeapon']) if (v[k] !== undefined && v[k] !== '') { const n = Math.floor(Number(v[k])); if (!(n >= 0 && n <= 1000000)) return bad('Valeur invalide : ' + k); o[k] = n; }
    if (v.LinkShop !== undefined) { const u = String(v.LinkShop || '').trim(); if (u && !/^https:\/\/[\w\-._~:/?#@!$&()*+,;=%]{1,280}$/.test(u)) return bad('Lien de la boutique Tebex invalide (https://)'); o.LinkShop = u; }
    return { value: o };
  }
  if (key === 'bans') { if (!Array.isArray(v)) return { error: 'Liste invalide' }; return { value: v.slice(0, 5000).map(b => ({ identifier: str(String(b.identifier || ''), 120, ID) || '', name: str(String(b.name || ''), 60) || '', reason: str(String(b.reason || ''), 120) || '', until: int(b.until || 0, 0, 4102444800) || 0, at: int(b.at || 0, 0, 4102444800) || 0 })).filter(b => b.identifier) }; }
  if (key === 'whitelist') { if (!Array.isArray(v)) return { error: 'Liste invalide' }; return { value: [...new Set(v.map(x => str(String(x), 120, ID)).filter(Boolean))].slice(0, 20000) }; }
  if (key === 'server') {
    const t = (x, max) => { x = String(x == null ? '' : x).trim(); if (x.length > max || /["\\\r\n;]/.test(x)) return null; return x; };
    const o = { projectName: t(v.projectName, 200), projectDesc: t(v.projectDesc, 200), hostname: t(v.hostname, 200) };
    // liste FiveM : étiquettes, Discord, bannières (liens https uniquement)
    o.tags = t(v.tags, 600); o.discord = t(String(v.discord == null ? '' : v.discord).replace(/^https?:\/\//, ''), 80);
    const bu = x => { x = String(x == null ? '' : x).trim(); if (!x) return ''; return x.length <= 300 && /^https:\/\/[\w\-._~:/?#@!$&()*+,;=%]+$/.test(x) ? x : null; };
    o.bannerDetail = bu(v.bannerDetail); o.bannerConnecting = bu(v.bannerConnecting);
    if (o.bannerDetail === null || o.bannerConnecting === null) return { error: 'Une bannière est invalide : le lien doit commencer par https://' };
    const mc = v.maxClients === '' || v.maxClients == null ? 0 : Math.floor(Number(v.maxClients)); if (!Number.isFinite(mc) || mc < 0 || mc > 2048) return { error: 'Nombre de places invalide (1 à 2048, ou vide pour ne pas y toucher)' }; o.maxClients = mc;
    if (Object.values(o).includes(null)) return { error: 'Texte invalide : pas de guillemets, de point-virgule ni de retour à la ligne (200 caractères max)' };
    return { value: o };
  }
  if (key === 'economy') { return ECONOMY_PRESETS.includes(v.preset) ? { value: { preset: v.preset } } : { error: 'Type d’économie inconnu' }; }
  if (key === 'motd') { const m = str(String(v.text || ''), 300); return { value: { text: m || '', enabled: !!v.enabled } }; }
}
// Appels « RPC » : le navigateur attend la réponse du serveur FiveM (fichiers)
const PATH = /^[A-Za-z0-9_\-\.\[\] \/]{0,200}$/;
function cleanPath(p) { if (typeof p !== 'string' || !PATH.test(p) || p.includes('..') || p.startsWith('/') || /\/\//.test(p)) return null; return p.replace(/\/+$/, ''); }
const GR = /^[A-Za-z0-9_]{1,40}$/;
function cleanJob(j) {
  if (!j || typeof j !== 'object') return null; const name = str(j.name, 40, /^[a-z0-9_]+$/); const label = str(String(j.label || ''), 50); if (!name || !label || /[\u0000-\u001f]/.test(label)) return null;
  if (!Array.isArray(j.grades) || j.grades.length < 1 || j.grades.length > 40) return null; const seen = new Set(); const grades = [];
  for (const g of j.grades) { const grade = int(g.grade, 0, 99), gname = str(String(g.name || ''), 40, GR), glabel = str(String(g.label || ''), 50), salary = int(g.salary, 0, 1000000); if (grade === null || !gname || !glabel || salary === null || seen.has(grade) || /[\u0000-\u001f]/.test(glabel)) return null; seen.add(grade); grades.push({ grade, name: gname, label: glabel, salary }); }
  return { name, label, whitelisted: !!j.whitelisted, grades: grades.sort((a, b) => a.grade - b.grade) };
}
const rpcDefs = {
  'db.jobs':  () => ({}),
  'db.job_save': (p) => { const job = cleanJob(p.job); return job && { job }; },
  'db.shop': (p) => {   // callbacks du builder de boutiques (pickax_shopbuilder) appelés depuis le panel
    const ok = ['catalog', 'list', 'get', 'create', 'save', 'delete', 'duplicate', 'toggle', 'restock', 'resetStats', 'logs'];
    if (!ok.includes(p.fn) || !Array.isArray(p.args) || p.args.length > 4) return null;
    if (JSON.stringify(p.args).length > 400000) return null;
    return { fn: p.fn, args: p.args };
  },
  'db.tables': () => ({}),
  'db.export': (p) => { const t = Array.isArray(p.tables) ? p.tables.filter(x => typeof x === 'string' && /^[A-Za-z0-9_]{1,64}$/.test(x)) : []; return t.length && t.length <= 8 && t.length === p.tables.length && { tables: t }; },
  'fs.list':  (p) => { const path = cleanPath(p.path || ''); return path !== null && { path }; },
  'fs.read':  (p) => { const path = cleanPath(p.path || ''); return path && { path }; },
  'fs.write': (p) => { const path = cleanPath(p.path || ''); if (!path || typeof p.content !== 'string' || p.content.length > 1000000) return null; return { path, content: p.content }; },
  'fs.create': (p) => { const path = cleanPath(p.path || ''); return path && { path, content: typeof p.content === 'string' ? p.content.slice(0, 1000000) : '' }; },
};
function validateRpc(type, payload) { const f = rpcDefs[type]; if (!f) return { error: 'Appel inconnu' }; const out = f(payload || {}); return out ? { payload: out } : { error: 'Chemin ou contenu invalide' }; }
module.exports = { validate, validateDoc, validateRpc, cleanPath, DOC_KEYS };
