(function () {
  const box = document.getElementById('box'), token = new URLSearchParams(location.search).get('t') || '';
  const T = (tag, props, ...kids) => { const e = document.createElement(tag); Object.assign(e, props || {}); kids.flat(Infinity).forEach(k => k && e.append(k)); return e; };
  const show = (...nodes) => box.replaceChildren(...nodes.flat(Infinity).filter(Boolean));
  const call = async (m, b) => { try { const r = await fetch('/api/public/apply/' + encodeURIComponent(token), { method: m, headers: { 'content-type': 'application/json' }, body: b ? JSON.stringify(b) : undefined }); return await r.json(); } catch (e) { return { ok: false, error: 'Connexion impossible.' }; } };
  const draw = f => {
    const name = T('input', { maxLength: 40, placeholder: 'Nom et prénom du personnage' }), dc = T('input', { maxLength: 40, placeholder: 'Facultatif' }), job = T('select', {}, f.jobs.map(j => T('option', { value: j, textContent: j })));
    const qs = f.questions.map(q => ({ q, i: T('textarea', { rows: 4, maxLength: 1200 }) })), err = T('div', { className: 'bad' });
    const btn = T('button', { textContent: 'Envoyer ma candidature', onclick: async () => { btn.disabled = true; const x = await call('POST', { name: name.value, discord: dc.value, job: job.value, answers: qs.map(o => o.i.value) }); btn.disabled = false; if (!x.ok) { err.textContent = x.error; return; } show(T('h1', { textContent: 'Candidature envoyée ✅' }), T('p', { className: 'ok', textContent: 'Le staff reviendra vers toi sur Discord.' })); } });
    show(T('div', { className: 'tag', textContent: f.server }), T('h1', { textContent: f.title }), f.intro ? T('pre', { textContent: f.intro }) : '', T('label', { textContent: 'Poste' }), job, T('label', { textContent: 'Personnage' }), name, T('label', { textContent: 'Discord' }), dc, qs.map(o => [T('label', { textContent: o.q }), o.i]), btn, err);
  };
  call('GET').then(x => x.ok ? draw(x.form) : show(T('p', { className: 'bad', textContent: x.error })));
})();
