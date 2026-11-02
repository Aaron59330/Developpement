'use strict';
// ───────── Alertes Discord, économie, candidatures, export/import des réglages ─────────
const gMoney = n => Math.round(n || 0).toLocaleString('fr-FR') + ' $';

PAGES.alerts = async function () {
  const s = curServer(); if (!s) return needServer();
  const [d, a] = await Promise.all([api('GET', `/api/servers/${s.id}/discord`), api('GET', `/api/servers/${s.id}/discord/alerts`)]);
  if (!d.ok) return el('div', { class: 'card' }, d.error);
  if (!(d.channels || []).length) return el('div', {}, head('Alertes Discord'), el('div', { class: 'card' }, 'Ajoute d’abord un salon dans « Message Discord » (webhook), puis reviens ici.'));
  const c = a.config, chk = v => el('input', { type: 'checkbox', checked: !!v }), num = v => el('input', { type: 'number', min: 0, value: v });
  const on = chk(c.enabled), off = chk(c.offline), er = chk(c.errors), rep = chk(c.reports !== false), rich = chk(c.rich), el1 = num(c.errorLimit), rl = num(c.richLimit);
  const ch = el('select', {}, d.channels.map(x => el('option', { value: x.id, selected: x.id === c.channelId }, '# ' + x.name)));
  return el('div', {}, head('Alertes Discord'),
    el('p', { class: 'muted', style: 'margin-bottom:14px' }, 'Le panel te prévient dans Discord quand quelque chose ne va pas, sans que tu aies à surveiller. Chaque alerte n’est envoyée qu’une fois.'),
    el('div', { class: 'card' }, el('label', { class: 'row' }, on, el('b', {}, 'Activer les alertes')), el('label', {}, 'Salon'), ch,
      el('label', { class: 'row', style: 'margin-top:12px' }, off, el('span', {}, 'Serveur hors ligne (plus de 5 minutes) et retour en ligne')),
      el('label', { class: 'row' }, er, el('span', {}, 'Pic d’erreurs')), el('label', {}, 'Nombre d’erreurs en 10 minutes à partir duquel prévenir'), el1,
      el('label', { class: 'row', style: 'margin-top:12px' }, rep, el('span', {}, 'Nouvelle plainte déposée en jeu')),
      el('label', { class: 'row', style: 'margin-top:12px' }, rich, el('span', {}, 'Joueur très riche (possible triche)')), el('label', {}, 'Fortune (cash + banque) à partir de laquelle prévenir ($)'), rl,
      el('div', { style: 'margin-top:12px' }, el('button', { class: 'btn p', onclick: async () => { const x = await api('PUT', `/api/servers/${s.id}/discord/alerts`, { enabled: on.checked, channelId: +ch.value, offline: off.checked, errors: er.checked, errorLimit: +el1.value, reports: rep.checked, rich: rich.checked, richLimit: +rl.value }); toast(x.ok ? 'Alertes enregistrées' : x.error, x.ok ? 'ok' : 'bad'); } }, el('span', {}, 'Enregistrer')))));
};

PAGES.economy = async function () {
  const s = curServer(); if (!s) return needServer();
  const r = await api('GET', `/api/servers/${s.id}/economy`); if (!r.ok) return el('div', { class: 'card' }, r.error);
  const stat = (l, v) => el('div', { class: 'card', style: 'flex:1;min-width:150px' }, el('div', { class: 'muted' }, l), el('div', { style: 'font-size:22px;font-weight:700;margin-top:4px' }, v));
  const inf = r.inflation, label = { inflation: 'Inflation : les joueurs s’enrichissent vite', deflation: 'Déflation : la richesse baisse', stable: 'Économie stable' };
  const hist = r.history.slice(-96), max = Math.max(1, ...hist.map(h => h.avg));
  return el('div', {}, head('Économie'),
    el('p', { class: 'muted', style: 'margin-bottom:14px' }, 'Richesse des joueurs connectés (cash + banque). Une photo est prise toutes les 30 minutes quand il y a du monde.'),
    el('div', { class: 'row', style: 'gap:12px;flex-wrap:wrap' }, stat('Joueurs en ligne', r.online), stat('Argent total', gMoney(r.total)), stat('Moyenne par joueur', gMoney(r.avg)), stat('Les 5 plus riches détiennent', r.topShare + ' %')),
    el('div', { class: 'card' }, el('h2', {}, 'Signal d’inflation'), inf.known ? el('div', {}, el('b', {}, label[inf.level]), el('p', { class: 'muted' }, `Richesse moyenne par joueur : ${gMoney(inf.now)} ces dernières 24 h contre ${gMoney(inf.before)} il y a une semaine (${inf.pct > 0 ? '+' : ''}${inf.pct} %).`)) : el('p', { class: 'muted' }, 'Pas encore assez d’historique (il faut environ une semaine de données).')),
    el('div', { class: 'card' }, el('h2', {}, 'Richesse moyenne par joueur'), hist.length ? el('div', { style: 'display:flex;align-items:flex-end;gap:2px;height:110px' }, hist.map(h => el('div', { title: `${fmtDate(h.at)} · ${gMoney(h.avg)}`, style: `flex:1;min-width:2px;background:var(--accent,#fdc27d);opacity:.85;height:${Math.max(2, h.avg / max * 100)}%` }))) : el('p', { class: 'muted' }, 'Aucune donnée pour le moment.')),
    el('div', { class: 'card' }, el('h2', {}, 'Les plus riches en ce moment'), r.top.length ? r.top.map((p, i) => el('div', { class: 'row', style: 'justify-content:space-between;padding:4px 0' }, el('span', {}, `${i + 1}. ${p.name}`), el('span', { class: 'muted' }, `${gMoney(p.money)} cash · ${gMoney(p.bank)} banque`))) : el('p', { class: 'muted' }, 'Personne en ligne.')));
};

PAGES.recruit = async function () {
  const s = curServer(); if (!s) return needServer();
  const [r, d] = await Promise.all([api('GET', `/api/servers/${s.id}/recruit`), api('GET', `/api/servers/${s.id}/discord`)]); if (!r.ok) return el('div', { class: 'card' }, r.error);
  const c = r.config, open = el('input', { type: 'checkbox', checked: !!c.open }), title = el('input', { value: c.title, maxlength: 80 }), intro = el('textarea', { rows: 3, maxlength: 800 }), jobs = el('textarea', { rows: 3 }), qs = el('textarea', { rows: 4 });
  intro.value = c.intro; jobs.value = c.jobs.join('\n'); qs.value = c.questions.join('\n');
  const ch = el('select', {}, [el('option', { value: '' }, 'Aucune notification'), ...((d.channels || []).map(x => el('option', { value: x.id, selected: x.id === c.channelId }, '# ' + x.name)))]);
  const link = c.token ? `${location.origin}/apply.html?t=${c.token}` : null;
  const lines = t => t.value.split('\n').map(x => x.trim()).filter(Boolean);
  const STAT = { new: 'Nouvelle', interview: 'Entretien', accepted: 'Acceptée', refused: 'Refusée' };
  const setSt = async (a, st) => { const x = await api('PATCH', `/api/servers/${s.id}/recruit/${a.id}`, { status: st }); if (!x.ok) return toast('Échec', 'bad'); render(); };
  const view = a => modal(`${a.name} · ${a.job}`, el('div', {}, el('p', { class: 'muted' }, `Discord : ${a.discord || '—'} · ${fmtDate(a.at)}`), a.answers.map(x => el('div', { style: 'margin:10px 0' }, el('b', {}, x.q), el('p', { style: 'white-space:pre-wrap;margin:4px 0 0' }, x.a)))));
  return el('div', {}, head('Candidatures'),
    el('p', { class: 'muted', style: 'margin-bottom:14px' }, 'Ouvre un formulaire public de recrutement : partage le lien dans Discord, les candidatures arrivent ici.'),
    el('div', { class: 'card' }, el('label', { class: 'row' }, open, el('b', {}, 'Candidatures ouvertes')), el('label', {}, 'Titre'), title, el('label', {}, 'Texte d’introduction'), intro,
      el('label', {}, 'Postes proposés (un par ligne)'), jobs, el('label', {}, 'Questions (une par ligne)'), qs, el('label', {}, 'Prévenir dans Discord à chaque candidature'), ch,
      el('div', { class: 'row', style: 'margin-top:12px' }, el('button', { class: 'btn p', onclick: async () => { const x = await api('PUT', `/api/servers/${s.id}/recruit`, { open: open.checked, title: title.value, intro: intro.value, jobs: lines(jobs), questions: lines(qs), channelId: ch.value ? +ch.value : null }); toast(x.ok ? 'Enregistré' : x.error, x.ok ? 'ok' : 'bad'); if (x.ok) render(); } }, el('span', {}, 'Enregistrer')),
        link ? el('button', { class: 'btn s', onclick: () => navigator.clipboard && navigator.clipboard.writeText(link).then(() => toast('Lien copié', 'ok')) }, 'Copier le lien du formulaire') : null)),
    el('div', { class: 'card' }, el('h2', {}, `Candidatures reçues (${r.apps.length})`), r.apps.length ? r.apps.map(a => el('div', { class: 'row', style: 'padding:6px 0;border-top:1px solid var(--bd,#2a2a30)' }, el('b', {}, a.name), el('span', { class: 'pill' }, a.job), el('span', { class: 'muted' }, fmtDate(a.at)), el('span', { class: 'pill' }, STAT[a.status]), el('div', { class: 'grow' }),
      el('button', { class: 'btn s', onclick: () => view(a) }, 'Lire'), el('button', { class: 'btn s', onclick: () => setSt(a, 'interview') }, 'Entretien'), el('button', { class: 'btn s', onclick: () => setSt(a, 'accepted') }, 'Accepter'), el('button', { class: 'btn s d', onclick: () => setSt(a, 'refused') }, 'Refuser'),
      el('button', { class: 'btn s d', onclick: () => confirmBox('Supprimer cette candidature ?', a.name, async () => { await api('DELETE', `/api/servers/${s.id}/recruit/${a.id}`); render(); }, true) }, '×'))) : el('p', { class: 'muted' }, 'Aucune candidature pour le moment.')));
};

PAGES.reports = async function () {
  const s = curServer(); if (!s) return needServer();
  const st = { f: 'new' }; const r = await api('GET', `/api/servers/${s.id}/reports`); if (!r.ok) return el('div', { class: 'card' }, r.error);
  const rows = r.rows.filter(x => st.f === 'all' || x.status === st.f);
  const note = el('input', { placeholder: 'Note du staff (facultatif)', maxlength: 300 });
  const act = async (x, body) => { const y = await api('PATCH', `/api/servers/${s.id}/reports/${x.id}`, body); if (!y.ok) return toast('Échec', 'bad'); render(); };
  const card = x => el('div', { class: 'card' }, el('div', { class: 'row' }, el('b', {}, x.reporter), x.target ? el('span', {}, '→ ' + x.target) : el('span', { class: 'muted' }, 'sans joueur visé'), el('span', { class: 'muted' }, fmtDate(x.at)), el('span', { class: 'pill ' + (x.status === 'new' ? 'acc' : 'ok') }, x.status === 'new' ? 'À traiter' : 'Traitée'), el('div', { class: 'grow' }),
      x.status === 'new' ? el('button', { class: 'btn s p', onclick: () => act(x, { status: 'handled' }) }, 'Marquer traitée') : el('button', { class: 'btn s', onclick: () => act(x, { status: 'new' }) }, 'Rouvrir'),
      el('button', { class: 'btn s d', onclick: () => confirmBox('Supprimer cette plainte ?', x.reporter, async () => { await api('DELETE', `/api/servers/${s.id}/reports/${x.id}`); render(); }, true) }, '×')),
    el('p', { style: 'white-space:pre-wrap;margin:10px 0' }, x.message),
    el('div', { class: 'muted', style: 'font-size:12px' }, x.reporter_ident ? 'Plaignant : ' + x.reporter_ident : '', x.target_ident ? ' · Visé : ' + x.target_ident : '', x.x != null ? ` · Position : ${Math.round(x.x)}, ${Math.round(x.y)}` : ''),
    x.note ? el('div', { style: 'margin-top:6px' }, el('b', {}, 'Note : '), x.note) : el('div', { class: 'row', style: 'margin-top:8px' }, el('button', { class: 'btn s', onclick: () => ask('Note du staff', [{ name: 'n', label: 'Note', value: '' }], async v => { await api('PATCH', `/api/servers/${s.id}/reports/${x.id}`, { note: v.n }); render(); }, 'Enregistrer') }, 'Ajouter une note')));
  return el('div', {}, head('Plaintes'), el('p', { class: 'muted', style: 'margin-bottom:14px' }, `Les joueurs déposent une plainte en jeu avec la commande /plainte <id du joueur visé ou 0> <message>. ${r.newCount} à traiter.`),
    el('div', { class: 'row', style: 'margin-bottom:12px' }, [['new', 'À traiter'], ['handled', 'Traitées'], ['all', 'Toutes']].map(([k, l]) => el('button', { class: 'btn s' + (st.f === k ? ' p' : ''), onclick: async () => { st.f = k; const y = await api('GET', `/api/servers/${s.id}/reports${k === 'all' ? '' : '?status=' + k}`); r.rows = y.rows; const c = document.getElementById('rp-list'); if (c) c.replaceChildren(...(y.rows.length ? y.rows.map(card) : [el('p', { class: 'muted' }, 'Rien ici.')])); } }, l))),
    el('div', { id: 'rp-list' }, rows.length ? rows.map(card) : el('p', { class: 'muted' }, 'Aucune plainte à traiter.')));
};

PAGES.retention = async function () {
  const s = curServer(); if (!s) return needServer();
  const r = await api('GET', `/api/servers/${s.id}/retention`); if (!r.ok) return el('div', { class: 'card' }, r.error);
  const off = -new Date().getTimezoneOffset() / 60, hours = Array.from({ length: 24 }, (_, h) => r.hours[((h - off) % 24 + 24) % 24]), maxH = Math.max(1, ...hours), maxN = Math.max(1, ...r.newPerDay.map(d => d.n));
  const stat = (l, v, sub) => el('div', { class: 'card', style: 'flex:1;min-width:150px' }, el('div', { class: 'muted' }, l), el('div', { style: 'font-size:22px;font-weight:700;margin-top:4px' }, v), sub ? el('div', { class: 'muted', style: 'font-size:12px' }, sub) : null);
  const ret = (l, x) => stat(l, x.known ? x.pct + ' %' : '—', x.known ? `${x.back} sur ${x.cohort} joueurs` : 'pas encore assez de recul');
  const bars = (arr, max, label) => el('div', { style: 'display:flex;align-items:flex-end;gap:3px;height:110px' }, arr.map((v, i) => el('div', { title: label(i, v), style: `flex:1;min-width:3px;background:var(--accent,#fdc27d);opacity:.85;border-radius:2px;height:${Math.max(2, v / max * 100)}%` })));
  return el('div', {}, head('Rétention des joueurs'), el('p', { class: 'muted', style: 'margin-bottom:14px' }, 'Basée sur les joueurs vus par le panel : combien reviennent, à quelle heure ils jouent et qui est le plus assidu.'),
    el('div', { class: 'row', style: 'gap:12px;flex-wrap:wrap' }, stat('Joueurs connus', r.total), stat('Actifs sur 7 jours', r.active7), stat('Actifs sur 30 jours', r.active30), ret('Reviennent après 1 jour', r.d1), ret('Reviennent après 7 jours', r.d7), ret('Reviennent après 30 jours', r.d30)),
    el('div', { class: 'card' }, el('h2', {}, 'Affluence par heure (moyenne des 14 derniers jours)'), bars(hours, maxH, (i, v) => `${String(i).padStart(2, '0')} h · ${v} joueurs`), el('div', { class: 'row muted', style: 'justify-content:space-between;font-size:11px;margin-top:4px' }, el('span', {}, '0 h'), el('span', {}, '6 h'), el('span', {}, '12 h'), el('span', {}, '18 h'), el('span', {}, '23 h'))),
    el('div', { class: 'card' }, el('h2', {}, 'Nouveaux joueurs par jour (14 jours)'), bars(r.newPerDay.map(d => d.n), maxN, (i, v) => `${new Date(r.newPerDay[i].day * 1000).toLocaleDateString('fr-FR')} · ${v} nouveaux`)),
    el('div', { class: 'card' }, el('h2', {}, 'Les plus assidus'), r.top.length ? r.top.map((p, i) => el('div', { class: 'row', style: 'justify-content:space-between;padding:4px 0' }, el('span', {}, `${i + 1}. ${p.name}`), el('span', { class: 'muted' }, `${hm(p.minutes)} · ${p.sessions} sessions`))) : el('p', { class: 'muted' }, 'Pas encore de données.')),
    el('p', { class: 'muted' }, `Temps de jeu moyen : ${hm(r.avgMinutes)} · ${r.avgSessions} sessions par joueur.`));
};

PAGES.dbbackups = async function () {
  const s = curServer(); if (!s) return needServer();
  const r = await api('GET', `/api/servers/${s.id}/dbbackups`); if (!r.ok) return el('div', { class: 'card' }, r.error);
  const make = () => ask('Nouvelle sauvegarde de la base', [{ name: 'name', label: 'Nom (facultatif)', placeholder: 'Avant la grosse mise à jour' }], async v => { toast('Sauvegarde en cours… (jusqu’à une minute)', 'ok'); const x = await api('POST', `/api/servers/${s.id}/dbbackups`, v); if (!x.ok) { toast(x.error, 'bad'); return false; } toast(`Sauvegarde créée (${x.tables} tables)${x.truncated && x.truncated.length ? ' — tables tronquées : ' + x.truncated.join(', ') : ''}`, 'ok'); render(); }, 'Sauvegarder');
  return el('div', {}, head('Sauvegardes de la base', el('button', { class: 'btn p', onclick: make }, el('span', {}, 'Nouvelle sauvegarde'))),
    el('p', { class: 'muted', style: 'margin-bottom:14px' }, 'Copie en lecture seule des tables de tes builders (métiers, gangs, boutiques, monde, drogues…). Le serveur de jeu doit être en ligne. Tu télécharges un fichier compressé (.json.gz) ; le panel garde les 10 dernières. La restauration se fait par ton hébergeur ou en me demandant un import — jamais automatiquement, pour ne rien écraser par erreur.'),
    el('div', { class: 'card tw' }, r.backups.length ? el('table', {}, el('thead', {}, el('tr', {}, ['Nom', 'Date', 'Tables', 'Taille', 'Par', ''].map(h => el('th', {}, h)))), el('tbody', {}, r.backups.map(b => el('tr', {}, el('td', {}, b.name), el('td', {}, fmtDate(b.at)), el('td', {}, b.tables), el('td', {}, Math.round(b.size / 1024) + ' Ko'), el('td', {}, b.by_name || '—'),
      el('td', {}, el('a', { class: 'btn s', href: `/api/servers/${s.id}/dbbackups/${b.id}/download` }, 'Télécharger'), ' ', el('button', { class: 'btn s d', onclick: () => confirmBox('Supprimer cette sauvegarde ?', b.name, async () => { await api('DELETE', `/api/servers/${s.id}/dbbackups/${b.id}`); render(); }, true) }, '×')))))) : el('p', { class: 'muted', style: 'padding:14px' }, 'Aucune sauvegarde pour le moment.')));
};

// Export / import des réglages (affiché en tête de la page Historique)
function settingsPortCard(s) {
  const file = el('input', { type: 'file', accept: '.json,application/json', style: 'display:none' });
  const dl = async () => { const x = await api('GET', `/api/servers/${s.id}/settings/export`); if (!x.ok) return toast(x.error, 'bad'); const a = el('a', { href: URL.createObjectURL(new Blob([JSON.stringify(x.file, null, 2)], { type: 'application/json' })), download: `aero-reglages-${(s.server_name || 'serveur').replace(/[^\w-]+/g, '_')}.json` }); document.body.append(a); a.click(); a.remove(); toast('Réglages exportés', 'ok'); };
  file.addEventListener('change', async () => {
    let f; try { f = JSON.parse(await file.files[0].text()); } catch (e) { return toast('Fichier illisible.', 'bad'); }
    const p = await api('POST', `/api/servers/${s.id}/settings/import`, { file: f }); if (!p.ok) return toast(p.error, 'bad');
    if (!p.diff.length) return toast('Rien à changer : ces réglages sont déjà en place.', 'ok');
    modal(`Importer ${p.diff.length} changement(s) ?`, el('div', {}, p.diff.slice(0, 60).map(c => el('div', { class: 'row', style: 'justify-content:space-between;gap:12px;font-size:13px;padding:2px 0' }, el('span', {}, c.label), el('span', { class: 'muted' }, `${fmtSetVal(c.from, c.type)} → ${fmtSetVal(c.to, c.type)}`))), p.unknown.length ? el('p', { class: 'muted' }, `${p.unknown.length} réglage(s) inconnus sur ce serveur seront ignorés.`) : null),
      close => [el('button', { class: 'btn', onclick: close }, el('span', {}, 'Annuler')), el('button', { class: 'btn p', onclick: async () => { const x = await api('POST', `/api/servers/${s.id}/settings/import`, { file: f, apply: true }); close(); toast(x.ok ? `${x.changed} réglage(s) importés` : x.error, x.ok ? 'ok' : 'bad'); if (x.ok) render(); } }, el('span', {}, 'Appliquer'))]);
    file.value = '';
  });
  return el('div', { class: 'card' }, el('h2', {}, 'Export / import'), el('p', { class: 'muted' }, 'Sauvegarde tes réglages dans un fichier, ou charge ceux d’un autre serveur. Tu vois les différences avant d’appliquer. Les secrets (webhook Discord) ne sont jamais exportés.'),
    el('div', { class: 'row' }, el('button', { class: 'btn s', onclick: dl }, 'Exporter mes réglages'), el('button', { class: 'btn s', onclick: () => file.click() }, 'Importer un fichier…'), file));
}
