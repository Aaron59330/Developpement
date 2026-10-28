(function () {
  const box = document.getElementById('box'), token = new URLSearchParams(location.search).get('t') || '';
  const T = (tag, props, ...kids) => { const e = document.createElement(tag); Object.assign(e, props || {}); kids.flat(Infinity).forEach(k => e.append(k)); return e; };
  const show = (...nodes) => box.replaceChildren(...nodes.flat(Infinity).filter(Boolean));
  const call = async (m, p, b) => { try { const r = await fetch('/api/public/event/' + encodeURIComponent(token) + p, { method: m, headers: { 'content-type': 'application/json' }, body: b ? JSON.stringify(b) : undefined }); return await r.json(); } catch (e) { return { ok: false, error: 'Connexion impossible.' }; } };
  const draw = ev => {
    const when = ev.starts_at ? new Date(ev.starts_at * 1000).toLocaleString('fr-FR', { dateStyle: 'full', timeStyle: 'short' }) : '';
    const name = T('input', { maxLength: 40, placeholder: 'Ton pseudo en jeu' }), dc = T('input', { maxLength: 40, placeholder: 'Facultatif' }), err = T('div', { className: 'bad' });
    const btn = T('button', { textContent: 'Je m’inscris', onclick: async () => { btn.disabled = true; const x = await call('POST', '/signup', { name: name.value, discord: dc.value }); btn.disabled = false; if (!x.ok) { err.textContent = x.error; return; } show(T('h1', { textContent: 'C’est noté ✅' }), T('p', { className: 'ok', textContent: `Tu es inscrit à « ${x.event.title} ».` })); } });
    show(T('div', { className: 'tag', textContent: ev.server }), T('h1', { textContent: ev.title }), when ? T('div', { className: 'm', textContent: '📅 ' + when }) : '', T('pre', { textContent: ev.description }),
      T('div', { className: 'm', textContent: `👥 ${ev.signed}${ev.slots ? ' / ' + ev.slots : ''} inscrits` }),
      ev.full ? T('p', { className: 'bad', textContent: 'Il n’y a plus de place.' }) : [T('label', { textContent: 'Pseudo' }), name, T('label', { textContent: 'Discord' }), dc, btn, err]);
  };
  call('GET', '').then(x => x.ok ? draw(x.event) : show(T('p', { className: 'bad', textContent: x.error })));
})();
