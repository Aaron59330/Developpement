// Assistant IA qui AGIT : il propose des actions précises (annonce, événement d'économie, redémarrage, réglage, événement programmé…),
// le panel les revalide, et rien n'est exécuté tant que le client ne clique pas sur « Appliquer ».
const router = require('express').Router();
const { db, now, audit } = require('../lib/db'); const A = require('../lib/auth'); const C = require('../lib/commands'); const cfg = require('../lib/config');
const SET = require('../lib/settings'); const { own, active } = require('../lib/access'); const { enqueue } = require('../lib/enqueue'); const { SCHEDULABLE } = require('../lib/scheduler'); const planner = require('./planner');
router.use(A.needUser);
const docOf = (lid, key) => { const d = db.prepare('SELECT value FROM docs WHERE license_id=? AND key=?').get(lid, key); return d ? JSON.parse(d.value) : null; };
const DIRECT = ['announce', 'restart_resource', 'server_restart', 'economy_event', 'economy_reset'];

const SYSTEM = `Tu es l'assistant d'administration d'un serveur FiveM (base ESX « AERO »). Tu aides le propriétaire en FRANÇAIS, de façon brève et concrète.
Tu peux PROPOSER des actions que le propriétaire validera d'un clic ; tu ne les exécutes jamais toi-même. N'invente aucune action hors de cette liste :
- announce {"message": "texte (200 max)"} : annonce à tous les joueurs
- restart_resource {"resource": "nom"} : redémarre une ressource
- server_restart {} : redémarre le serveur (préavis automatique pour les joueurs)
- economy_event {"key": "all" ou clé, "swing": nombre de -0.9 à 3, "hours": 1 à 720} : événement d'économie temporaire (swing 0.5 = +50 % ; ex. « double paie » ≈ swing 1.0, « jour de crise » ≈ -0.3)
- economy_reset {"key": ""} : annule les événements d'économie
- set_setting {"key": "clé de réglage de la liste fournie", "value": valeur du bon type} : modifie un réglage du serveur
- schedule {"name": "titre", "type": "announce|restart_resource|server_restart|economy_event|economy_reset", "payload": {...comme ci-dessus}, "when": "AAAA-MM-JJ HH:MM" (heure locale du propriétaire), "every": "none|daily|weekly", "warn_min": 0|5|10|15|30|60} : programme l'action plus tard
Règles : demande une précision (sans action) si la demande est ambiguë ; si elle est impossible avec ces actions, dis-le et suggère l'onglet du panel adapté (Éditeur de base, Fichiers, Joueurs, Personnalisation). Ne propose jamais plus de 6 actions. Les dates relatives (« samedi », « demain ») se calculent avec l'heure locale fournie.
Réponds UNIQUEMENT par un objet JSON : {"reply": "ta réponse courte", "actions": [{"label": "résumé court de l'action", "type": "...", "payload": {...}}]}  (actions peut être vide).`;

function localToEpoch(str, tz) {
  const m = String(str || '').match(/^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})/); if (!m) return null;
  const t = Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5]) + (Number.isFinite(+tz) ? +tz : 0) * 60000; return Math.floor(t / 1000);
}
// valide une action venant de l'IA (ou du navigateur) ; renvoie { type, payload, label? } prêt à exécuter, ou { error }
function normalize(l, a, tz) {
  if (!a || typeof a !== 'object') return { error: 'action vide' }; const type = String(a.type || ''), p = a.payload && typeof a.payload === 'object' ? a.payload : {};
  if (DIRECT.includes(type)) { const v = C.validate(type, p); return v.error ? { error: v.error } : { type, payload: v.payload }; }
  if (type === 'set_setting') {
    const sch = docOf(l.id, 'settings_schema'); if (!sch) return { error: 'réglages indisponibles (pickax_settings non synchronisé)' };
    const cur = docOf(l.id, 'settings') || {}; const defs = Object.fromEntries(sch.map(d => [d.key, d])); const def = defs[p.key]; if (!def) return { error: 'réglage inconnu : ' + p.key };
    const vals = {}; for (const d of sch) vals[d.key] = d.key in cur ? cur[d.key] : d.default; vals[p.key] = p.value;
    const r = SET.validate(sch, vals); if (r.errors.length) return { error: 'valeur invalide pour ' + (def.label || p.key) }; if (def.type === 'number') { const eff = p.key in r.overrides ? r.overrides[p.key] : def.default; if (Number(p.value) !== eff) return { error: `valeur hors limites pour ${def.label || p.key} (${def.min} à ${def.max})` }; }
    return { type, payload: { key: p.key, value: def.type === 'number' ? Number(p.value) : p.value }, overrides: r.overrides };
  }
  if (type === 'schedule') {
    if (!SCHEDULABLE.includes(p.type)) return { error: 'type non programmable' };
    const run = p.run_at != null ? Math.floor(+p.run_at) : localToEpoch(p.when, tz); if (!run) return { error: 'date illisible' };
    const c = planner.clean({ name: p.name, type: p.type, payload: p.payload, run_at: run, every: p.every, warn_min: p.warn_min }); if (c.error) return { error: c.error };
    return { type, payload: { name: c.v.name, type: c.v.type, payload: c.v.payload, run_at: c.v.run, every: c.v.every, warn_min: c.v.warn } };
  }
  return { error: 'action non autorisée : ' + type };
}
function execute(req, l, n) {
  if (DIRECT.includes(n.type)) { const r = enqueue(l.id, n.type, n.payload, req.user.id); if (r.ok) audit(req.user.id, l.id, 'ai:' + n.type, JSON.stringify(n.payload).slice(0, 200), A.ip(req)); return r; }
  if (n.type === 'set_setting') {
    db.prepare('INSERT INTO docs(license_id,key,value,version,updated_at) VALUES(?,?,?,?,?) ON CONFLICT(license_id,key) DO UPDATE SET value=excluded.value, version=docs.version+1, updated_at=excluded.updated_at').run(l.id, 'settings', JSON.stringify(n.overrides), 1, now());
    require('../lib/bus').wake(l.id); audit(req.user.id, l.id, 'ai:set_setting', n.payload.key, A.ip(req)); return { ok: true };
  }
  if (n.type === 'schedule') {
    if (db.prepare('SELECT COUNT(*) n FROM schedules WHERE license_id=?').get(l.id).n >= 100) return { ok: false, error: '100 événements maximum' };
    const v = n.payload; db.prepare('INSERT INTO schedules(license_id,name,type,payload,run_at,every,warn_min,by_user,created_at) VALUES(?,?,?,?,?,?,?,?,?)').run(l.id, v.name, v.type, JSON.stringify(v.payload), v.run_at, v.every, v.warn_min, req.user.id, now());
    audit(req.user.id, l.id, 'ai:schedule', v.name, A.ip(req)); return { ok: true };
  }
  return { ok: false, error: 'action non autorisée' };
}
const describe = n => n.type === 'set_setting' ? `Réglage « ${n.payload.key} » → ${JSON.stringify(n.payload.value)}` : n.type === 'schedule' ? `Programmer « ${n.payload.name} » le ${new Date(n.payload.run_at * 1000).toLocaleString('fr-FR')}` : n.type;

router.get('/:id/assistant/status', (req, res) => { const l = own(req, res); if (!l) return; const day = new Date().toISOString().slice(0, 10); const u = db.prepare('SELECT n FROM ai_usage WHERE license_id=? AND day=?').get(l.id, day); res.json({ ok: true, enabled: !!cfg.aiKey, limit: cfg.aiDaily, used: u ? u.n : 0 }); });

router.post('/:id/assistant', async (req, res) => {
  const l = own(req, res); if (!l) return; if (!active(l)) return res.json({ ok: false, error: 'Licence inactive ou expirée' }); if (!cfg.aiKey) return res.json({ ok: false, error: 'Assistant IA non configuré sur ce panel (clé ANTHROPIC_API_KEY manquante)' });
  const b = req.body || {}, msg = String(b.message || '').trim().slice(0, 1500); if (!msg) return res.json({ ok: false, error: 'Écris une demande' });
  const tz = Number.isFinite(+b.tz) ? +b.tz : 0, localNow = String(b.local_now || '').slice(0, 40);
  const day = new Date().toISOString().slice(0, 10), u = db.prepare('SELECT n FROM ai_usage WHERE license_id=? AND day=?').get(l.id, day); if ((u ? u.n : 0) >= cfg.aiDaily) return res.json({ ok: false, error: `Limite de ${cfg.aiDaily} demandes par jour atteinte` });
  db.prepare('INSERT INTO ai_usage(license_id,day,n) VALUES(?,?,1) ON CONFLICT(license_id,day) DO UPDATE SET n=n+1').run(l.id, day);
  const st = db.prepare('SELECT players,max_players FROM server_state WHERE license_id=?').get(l.id); const sch = docOf(l.id, 'settings_schema') || [], cur = docOf(l.id, 'settings') || {}, eco = docOf(l.id, 'economy');
  const settingsList = sch.slice(0, 80).map(d => `- ${d.key} (${d.type}${d.type === 'select' ? ': ' + (d.options || []).map(o => o[0]).join('|') : ''}${d.min != null ? `, ${d.min}-${d.max}` : ''}) « ${d.label} » = ${JSON.stringify(d.key in cur ? cur[d.key] : d.default)}`).join('\n');
  const ctx = `Heure locale du propriétaire : ${localNow || 'inconnue'}\nServeur : ${l.server_name} · ${st ? JSON.parse(st.players).length : 0}/${st ? st.max_players : '?'} joueurs · économie : ${(eco && eco.preset) || 'équilibré'}\nRéglages disponibles :\n${settingsList || '(aucun)'}`;
  const hist = (Array.isArray(b.history) ? b.history.slice(-6) : []).filter(h => h && (h.role === 'user' || h.role === 'assistant') && typeof h.text === 'string').map(h => ({ role: h.role, content: h.text.slice(0, 1500) }));
  try {
    const r = await fetch(cfg.aiBase + '/v1/messages', { method: 'POST', headers: { 'content-type': 'application/json', 'x-api-key': cfg.aiKey, 'anthropic-version': '2023-06-01' }, signal: AbortSignal.timeout(60000),
      body: JSON.stringify({ model: cfg.aiModel, max_tokens: 2000, system: SYSTEM + '\n\n' + ctx, messages: [...hist, { role: 'user', content: msg }] }) });
    const j = await r.json(); if (!r.ok) return res.json({ ok: false, error: 'Erreur du service IA : ' + ((j.error && j.error.message) || r.status) });
    const text = (j.content || []).map(x => x.text || '').join(''); let out = null; const m = text.match(/\{[\s\S]*\}/); try { out = m && JSON.parse(m[0]); } catch (e) {}
    if (!out) return res.json({ ok: true, reply: text.trim().slice(0, 2000) || 'Je n’ai pas compris la demande.', actions: [] });
    const actions = [], dropped = []; for (const a of (Array.isArray(out.actions) ? out.actions : []).slice(0, 6)) { const n = normalize(l, a, tz); if (n.error) { dropped.push(n.error); continue; } actions.push({ label: String(a.label || describe(n)).slice(0, 140), type: n.type, payload: n.payload }); }
    audit(req.user.id, l.id, 'ai:ask', msg.slice(0, 100), A.ip(req)); res.json({ ok: true, reply: String(out.reply || '').slice(0, 2000), actions, dropped });
  } catch (e) { res.json({ ok: false, error: 'Service IA injoignable' }); }
});
// exécute UNE action proposée : elle est revalidée ici (on ne fait pas confiance à ce que renvoie le navigateur)
router.post('/:id/assistant/apply', (req, res) => {
  const l = own(req, res); if (!l) return; if (!active(l)) return res.json({ ok: false, error: 'Licence inactive ou expirée' });
  const n = normalize(l, req.body || {}, 0); if (n.error) return res.json({ ok: false, error: 'Action refusée : ' + n.error }); res.json(execute(req, l, n));
});
module.exports = router;
