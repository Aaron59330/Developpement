// Événements Discord avec inscriptions + rappels de licence
PAGES.events = async function () {
  const s = curServer(); if (!s) return needServer();
  const [d, ev, rm] = await Promise.all([api('GET', `/api/servers/${s.id}/discord`), api('GET', `/api/servers/${s.id}/discord/events`), api('GET', `/api/servers/${s.id}/discord/reminders`)]);
  if (!d.ok) return el('div', { class: 'card' }, d.error);
  const chans = d.channels || [];
  if (!chans.length) return el('div', {}, head('Événements & rappels'), el('div', { class: 'card' }, 'Ajoute d’abord un salon dans « Message Discord » (webhook), puis reviens ici.'));
  const sel = (id, v) => el('select', { id }, chans.map(c => el('option', { value: c.id, selected: c.id === v }, '# ' + c.name)));
  const f = { title: el('input', { maxlength: 120, placeholder: 'Ex : Braquage de la banque centrale' }), desc: el('textarea', { rows: 4, maxlength: 1500, placeholder: 'Détails de l’événement' }), date: el('input', { type: 'datetime-local' }), slots: el('input', { type: 'number', min: 0, max: 1000, value: 0 }), ch: sel('evch', chans[0].id) };
  const create = async () => {
    const x = await api('POST', `/api/servers/${s.id}/discord/events`, { title: f.title.value, description: f.desc.value, starts_at: f.date.value || null, slots: +f.slots.value || 0, channelId: +f.ch.value });
    if (!x.ok) return toast(x.error, 'bad'); toast('Événement publié dans Discord', 'ok'); render();
  };
  const show = async e => {
    const x = await api('GET', `/api/servers/${s.id}/discord/events/${e.id}`); if (!x.ok) return toast(x.error, 'bad');
    modal(`Inscrits : ${e.title}`, el('div', {}, x.signups.length ? x.signups.map((u, i) => el('div', { class: 'row', style: 'justify-content:space-between;padding:4px 0' }, el('span', {}, `${i + 1}. ${u.name}`), el('span', { class: 'muted' }, u.discord || '—'))) : el('p', { class: 'muted' }, 'Personne ne s’est encore inscrit.'),
      x.signups.length ? el('button', { class: 'btn s', style: 'margin-top:10px', onclick: () => navigator.clipboard && navigator.clipboard.writeText(x.signups.map(u => u.name + (u.discord ? ' (' + u.discord + ')' : '')).join('\n')).then(() => toast('Liste copiée', 'ok')) }, 'Copier la liste') : null));
  };
  const rc = rm.config || { enabled: false, channelId: null }; const rch = sel('rmch', rc.channelId || chans[0].id); const ron = el('input', { type: 'checkbox', checked: !!rc.enabled });
  const dleft = rm.expires_at ? Math.ceil((rm.expires_at * 1000 - Date.now()) / 864e5) : null;
  return el('div', {}, head('Événements & rappels'),
    el('p', { class: 'muted', style: 'margin-bottom:14px' }, 'Publie un événement dans Discord avec un lien d’inscription public : tes joueurs s’inscrivent sans compte et tu vois la liste ici.'),
    el('div', { class: 'card' }, el('h2', {}, 'Nouvel événement'), el('label', {}, 'Titre'), f.title, el('label', {}, 'Description'), f.desc,
      el('div', { class: 'row' }, el('div', { class: 'grow' }, el('label', {}, 'Date et heure'), f.date), el('div', {}, el('label', {}, 'Places (0 = illimité)'), f.slots)),
      el('label', {}, 'Salon'), f.ch, el('div', { style: 'margin-top:10px' }, el('button', { class: 'btn p', onclick: create }, el('span', {}, 'Publier sur Discord')))),
    el('div', { class: 'card' }, el('h2', {}, 'Événements publiés'),
      ev.events && ev.events.length ? ev.events.map(e => el('div', { class: 'row', style: 'padding:6px 0;border-top:1px solid var(--bd,#2a2a30)' }, el('b', {}, e.title), el('span', { class: 'muted' }, e.starts_at ? fmtDate(e.starts_at) : ''), el('span', { class: 'pill' }, `${e.signed}${e.slots ? ' / ' + e.slots : ''} inscrits`), el('div', { class: 'grow' }),
        el('button', { class: 'btn s', onclick: () => show(e) }, 'Inscrits'), el('button', { class: 'btn s', onclick: () => navigator.clipboard && navigator.clipboard.writeText(`${location.origin}/event.html?t=${e.token}`).then(() => toast('Lien copié', 'ok')) }, 'Copier le lien'),
        el('button', { class: 'btn s d', onclick: () => confirmBox('Supprimer cet événement ?', 'Le lien d’inscription ne fonctionnera plus.', async () => { await api('DELETE', `/api/servers/${s.id}/discord/events/${e.id}`); render(); }, true) }, 'Supprimer'))) : el('p', { class: 'muted' }, 'Aucun événement pour le moment.')),
    el('div', { class: 'card' }, el('h2', {}, 'Rappels de licence'),
      el('p', { class: 'muted' }, dleft != null ? `Ta licence expire dans ${dleft} jour${dleft > 1 ? 's' : ''}. ` : '', 'Reçois un message Discord 7, 3 puis 1 jour avant l’expiration.'),
      el('label', { class: 'row' }, ron, el('span', {}, 'Activer les rappels')), el('label', {}, 'Salon'), rch,
      el('div', { style: 'margin-top:10px' }, el('button', { class: 'btn p', onclick: async () => { const x = await api('PUT', `/api/servers/${s.id}/discord/reminders`, { enabled: ron.checked, channelId: +rch.value }); toast(x.ok ? 'Rappels enregistrés' : x.error, x.ok ? 'ok' : 'bad'); } }, el('span', {}, 'Enregistrer')))));
};
