// Plaintes déposées en jeu (/plainte) : validation, enregistrement et notification Discord facultative
const { db, now } = require('./db');
const clean = (v, n) => String(v == null ? '' : v).replace(/[\u0000-\u001f]/g, ' ').trim().slice(0, n);
const num = v => Number.isFinite(+v) ? Math.round(+v * 10) / 10 : null;
function ingest(l, list) {
  if (!Array.isArray(list) || !list.length) return 0;
  const ins = db.prepare('INSERT INTO reports(license_id,at,reporter,reporter_ident,target,target_ident,message,x,y) VALUES(?,?,?,?,?,?,?,?,?)');
  let n = 0;
  for (const r of list.slice(0, 30)) {
    if (!r || typeof r !== 'object') continue;
    const message = clean(r.message, 400); if (message.length < 5) continue;
    if (db.prepare('SELECT COUNT(*) n FROM reports WHERE license_id=?').get(l.id).n >= 500) db.prepare('DELETE FROM reports WHERE id IN (SELECT id FROM reports WHERE license_id=? AND status<>? ORDER BY id LIMIT 50)').run(l.id, 'new');
    const at = Math.min(now(), Math.max(now() - 86400, +r.at || now()));
    const row = { reporter: clean(r.reporter, 40) || '?', reporter_ident: clean(r.reporter_ident, 120), target: r.target ? clean(r.target, 40) : null, target_ident: r.target_ident ? clean(r.target_ident, 120) : null, message };
    ins.run(l.id, at, row.reporter, row.reporter_ident, row.target, row.target_ident, message, num(r.x), num(r.y)); n++;
    require('./alerts').reportAlert(l, row, at);
  }
  return n;
}
module.exports = { ingest };
