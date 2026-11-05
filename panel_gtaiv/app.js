'use strict';
// Registre des modules du panel. Vide pour l'instant : on les ajoute un par un.
// { id:'joueurs', label:'Joueurs', render(el){ … } }
const MODULES = [];

const $ = id => document.getElementById(id);
const menu = $('menu'), view = $('view');
function show(id) {
  const m = MODULES.find(x => x.id === id);
  [...menu.querySelectorAll('a')].forEach(b => b.classList.toggle('on', b.dataset.id === id));
  if (!m) {
    view.innerHTML = `<h1>Accueil</h1><section class="card empty"><h2>Aucun module</h2>
      <p class="muted">Le panel est vide pour l'instant.</p></section>`;
    return;
  }
  view.innerHTML = `<h1>${m.label}</h1><div id="mod"></div>`;
  m.render($('mod'));
}
function buildMenu() {
  menu.innerHTML = [{ id: 'home', label: 'Accueil' }, ...MODULES].map(m => `<a class="nav" href="#" data-id="${m.id}"><span>${m.label}</span></a>`).join('');
  menu.onclick = e => { e.preventDefault(); const b = e.target.closest('a'); if (b) show(b.dataset.id); };
}
$('go').onclick = () => { $('login').classList.add('hidden'); $('app').classList.remove('hidden'); buildMenu(); show('home'); };
$('out').onclick = e => { e.preventDefault(); $('app').classList.add('hidden'); $('login').classList.remove('hidden'); };
document.addEventListener('keydown', e => { if (e.key === 'Enter' && !$('login').classList.contains('hidden')) $('go').click(); });
if (location.hash === '#app') $('go').click();
