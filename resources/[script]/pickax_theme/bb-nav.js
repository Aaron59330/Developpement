/* ═════════════ Menu de gauche des builders : recherche + groupes repliables ═════════════
   Commun à tous les builders (même gabarit .shell > .side > .nav). Aucune modification des builders : ce script réorganise le menu après chaque affichage.
   • une barre de recherche (dès que le menu compte plus de 8 entrées) ;
   • chaque section (Garages, Police, EMS…) se replie / se déplie d'un clic, avec son nombre d'entrées ;
   • l'état replié est mémorisé ; la section de l'entrée active reste toujours ouverte ;
   • taper dans la recherche déplie tout et masque ce qui ne correspond pas. */
(function () {
  'use strict';
  var RES = (typeof GetParentResourceName === 'function' ? GetParentResourceName() : location.host) || 'builder';
  var KEY = 'bbnav:' + RES;
  var collapsed = {}, query = '';
  try { collapsed = JSON.parse(localStorage.getItem(KEY) || '{}') || {}; } catch (e) { collapsed = {}; }
  var save = function () { try { localStorage.setItem(KEY, JSON.stringify(collapsed)); } catch (e) { } };
  var norm = function (s) { return String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase(); };
  var timer = null;

  function enhance() {
    var nav = document.querySelector('.shell .side .nav');
    if (!nav || nav.getAttribute('data-bb') === '1') return;
    var kids = Array.prototype.slice.call(nav.children);
    var groups = [], cur = null;
    kids.forEach(function (el) {
      if (el.classList.contains('nav-label')) { cur = { label: el, items: [] }; groups.push(cur); }
      else if (cur) cur.items.push(el);
      else { cur = { label: null, items: [el] }; groups.push(cur); }
    });
    var total = groups.reduce(function (n, g) { return n + g.items.length; }, 0);
    nav.setAttribute('data-bb', '1');
    nav.innerHTML = '';
    groups.forEach(function (g) {
      var wrap = document.createElement('div'); wrap.className = 'bbg';
      var title = g.label ? g.label.textContent.trim() : '';
      var hasActive = g.items.some(function (i) { return i.classList.contains('active') || i.classList.contains('on'); });
      if (title) {
        var h = document.createElement('div'); h.className = 'nav-label bbg-h';
        h.innerHTML = '<span class="bbg-c">▾</span><span class="bbg-t"></span><span class="bbg-n">' + g.items.length + '</span>';
        h.querySelector('.bbg-t').textContent = title;
        h.addEventListener('click', function () { collapsed[title] = !collapsed[title]; save(); apply(); });
        wrap.appendChild(h);
        wrap.setAttribute('data-k', title);
        if (hasActive) wrap.setAttribute('data-act', '1');
      }
      var body = document.createElement('div'); body.className = 'bbg-b';
      g.items.forEach(function (i) { body.appendChild(i); });
      wrap.appendChild(body);
      nav.appendChild(wrap);
    });
    // barre de recherche
    var side = nav.parentNode, old = side.querySelector('.bbs');
    if (old) old.remove();
    if (total > 8) {
      var bar = document.createElement('div'); bar.className = 'bbs';
      bar.innerHTML = '<input type="text" placeholder="Rechercher…" autocomplete="off" spellcheck="false"><button type="button" aria-label="Effacer">×</button>';
      var inp = bar.querySelector('input');
      inp.value = query;
      inp.addEventListener('input', function () { query = inp.value; apply(); });
      bar.querySelector('button').addEventListener('click', function () { query = ''; inp.value = ''; apply(); inp.focus(); });
      side.insertBefore(bar, nav);
    }
    apply();
  }

  function apply() {
    var nav = document.querySelector('.shell .side .nav');
    if (!nav) return;
    var q = norm(query.trim());
    Array.prototype.forEach.call(nav.querySelectorAll('.bbg'), function (wrap) {
      var k = wrap.getAttribute('data-k') || '';
      var items = wrap.querySelectorAll('.bbg-b > *');
      var shown = 0;
      Array.prototype.forEach.call(items, function (it) {
        var ok = !q || norm(it.textContent).indexOf(q) !== -1;
        it.style.display = ok ? '' : 'none';
        if (ok) shown++;
      });
      var isCol = !!(k && collapsed[k]) && !q && !wrap.getAttribute('data-act');
      wrap.classList.toggle('bbg-col', isCol);
      wrap.style.display = (q && !shown) ? 'none' : '';
    });
  }

  function schedule() { if (timer) return; timer = setTimeout(function () { timer = null; try { enhance(); } catch (e) { } }, 30); }
  new MutationObserver(schedule).observe(document.documentElement, { childList: true, subtree: true });
  schedule();
})();
