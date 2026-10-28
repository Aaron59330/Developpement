'use strict';
// ───────── Alertes Discord, économie, candidatures, export/import des réglages ─────────
const gMoney = n => Math.round(n || 0).toLocaleString('fr-FR') + ' $';

PAGES.alerts = async function () {
  const s = curServer(); if (!s) return needServer();
  const [d, a] = await Promise.all([api('GET', `/api/servers/${s.id}/discord`), api('GET', `/api/servers/${s.id}/discord/alerts`)]);
  if (!d.ok) return el('div', { class: 'card' }, d.error);
  if (!(d.channels || []).length) return el('div', {}, head('Alertes Discord'), el('div', { class: 'card' }, 'Ajoute d’abord un salon dans « Message Discord » (webhook), puis reviens ici.'));
  const c = a.config, chk = v => el('input', { type: 'checkbox', checked: !!v }), num = v => el('input', { type: 'number', min: 0, value: v });
  const on = chk(c.enabled), off = chk(c.offline), er = chk(c.errors), rich = chk(c.rich), el1 = num(c.errorLimit), rl = num(c.richLimit);
  const ch = el('select', {}, d.channels.map(x => el('option', { value: x.id, selected: x.id === c.channelId }, '# ' + x.name)));
  return el('div', {}, head('Alertes Discord'),
    el('p', { class: 'muted', style: 'margin-bottom:14px' }, 'Le panel te prévient dans Discord quand quelque chose ne va pas, sans que tu aies à surveiller. Chaque alerte n’est envoyée qu’une fois.'),
    el('div', { class: 'card' }, el('label', { class: 'row' }, on, el('b', {}, 'Activer les alertes')), el('label', {}, 'Salon'), ch,
      el('label', { class: 'row', style: 'margin-top:12px' }, off, el('span', {}, 'Serveur hors ligne (plus de 5 minutes) et retour en ligne')),
      el('label', { class: 'row' }, er, el('span', {}, 'Pic d’erreurs')), el('label', {}, 'Nombre d’erreurs en 10 minutes à partir duquel prévenir'), el1,
      el('label', { class: 'row', style: 'margin-top:12px' }, rich, el('span', {}, 'Joueur très riche (possible triche)')), el('label', {}, 'Fortune (cash + banque) à partir de laquelle prévenir ($)'), rl,
      el('div', { style: 'margin-top:12px' }, el('button', { class: 'btn p', onclick: async () => { const x = await api('PUT', `/api/servers/${s.id}/discord/alerts`, { enabled: on.checked, channelId: +ch.value, offline: off.checked, errors: er.checked, errorLimit: +el1.value, rich: rich.checked, richLimit: +rl.value }); toast(x.ok ? 'Alertes enregistrées' : x.error, x.ok ? 'ok' : 'bad'); } }, el('span', {}, 'Enregistrer')))));
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
