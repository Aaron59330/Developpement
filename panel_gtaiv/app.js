'use strict';
// Registre des modules du panel. Vide pour l'instant : on les ajoute un par un.
// { id:'joueurs', label:'Joueurs', render(el){ … } }
const MODULES = [];

const $ = id => document.getElementById(id);
const menu = $('menu'), view = $('view');
function show(id) {
  const m = MODULES.find(x => x.id === id);
  [...menu.querySelectorAll('button')].forEach(b => b.classList.toggle('on', b.dataset.id === id));
  if (!m) {
    view.innerHTML = `<h1 class="title">Accueil</h1><p class="sub">Panel AERO</p>
      <section class="card empty"><div class="ico">+</div><h3>Aucun module</h3>
      <p>Le panel est vide pour l'instant. Les modules s'ajoutent un par un.</p></section>`;
    return;
  }
  view.innerHTML = `<h1 class="title">${m.label}</h1><p class="sub">${m.sub || ''}</p><div id="mod"></div>`;
  m.render($('mod'));
}
function buildMenu() {
  menu.innerHTML = '<h6>MENU</h6>' + [{ id: 'home', label: 'Accueil' }, ...MODULES].map(m => `<button data-id="${m.id}">${m.label}</button>`).join('');
  menu.onclick = e => { const b = e.target.closest('button'); if (b) show(b.dataset.id); };
}
$('go').onclick = () => { $('login').classList.add('hidden'); $('app').classList.remove('hidden'); buildMenu(); show('home'); };
$('out').onclick = () => { $('app').classList.add('hidden'); $('login').classList.remove('hidden'); };
document.addEventListener('keydown', e => { if (e.key === 'Enter' && !$('login').classList.contains('hidden')) $('go').click(); });
if (location.hash === '#app') $('go').click();
