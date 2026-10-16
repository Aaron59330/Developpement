'use strict';
/* Hub NUI de pickax_core : une seule page d'interface par ressource FiveM → chaque module (builders, HUD, menu pause…) vit dans son
 * propre cadre. Le hub reçoit les messages du jeu et les redirige vers le bon cadre ; le focus clavier / souris suit le module actif.
 *   {__ui:'nom', __d:{…}}  → message pour le module « nom » (livré tel quel, comme avant la fusion)
 *   {__hub:'focus', …}     → un module prend / rend le focus NUI
 *   autre                  → carte d'identité (page d'origine du core)
 * Liste à tenir synchronisée avec modules/registry.lua (clé ui).                                                              */
(() => {
  const UIS = {
    idcard: '../../players/jsfour-idcard/html/index.html',
    builderhub: '../builderhub/html/index.html',
    jobbuilder: '../jobbuilder/html/index.html',
    gangbuilder: '../gangbuilder/html/index.html',
    shopbuilder: '../shopbuilder/html/index.html',
    worldbuilder: '../worldbuilder/html/index.html',
    hud1: '../hud1/index.html',
    hud2: '../hud2/html/index.html',
    speedometer: '../speedometer/web/build/index.html',
    pause: '../pause/html/index.html',
    carplay: '../carplay/html/index.html',
  };
  const DEFAULT = 'idcard';
  const frames = {}, ready = {}, queue = {};

  function makeFrame(name, src) {
    const f = document.createElement('iframe');
    f.dataset.ui = name;
    f.setAttribute('allow', 'autoplay');
    f.addEventListener('load', () => {
      ready[name] = true;
      for (const m of queue[name] || []) f.contentWindow.postMessage(m, '*');
      queue[name] = [];
    });
    f.src = src;
    document.body.appendChild(f);
    frames[name] = f;
    return f;
  }
  for (const [name, src] of Object.entries(UIS)) makeFrame(name, src);

  function post(name, data) {
    let f = frames[name];
    // module absent de la liste ci-dessus : on suppose la convention modules/<nom>/html/index.html
    if (!f && typeof name === 'string' && /^[a-z0-9_]+$/.test(name)) f = makeFrame(name, '../' + name + '/html/index.html');
    if (!f) return;
    if (ready[name]) f.contentWindow.postMessage(data, '*');
    else (queue[name] = queue[name] || []).push(data);
  }

  function setFocus(name, on) {
    for (const f of Object.values(frames)) f.classList.remove('on');
    if (on && !frames[name] && typeof name === 'string' && /^[a-z0-9_]+$/.test(name)) makeFrame(name, '../' + name + '/html/index.html');
    const f = on && frames[name];
    if (!f) { try { document.activeElement && document.activeElement.blur(); } catch (e) { /* ignore */ } return; }
    f.classList.add('on');
    try { f.focus(); f.contentWindow.focus(); } catch (e) { /* ignore */ }
  }

  window.addEventListener('message', e => {
    const m = e.data;
    if (!m || typeof m !== 'object') return;
    if (m.__hub === 'focus') return setFocus(m.ui, m.on);
    if (m.__ui) return post(m.__ui, m.__d);
    post(DEFAULT, m);
  });
})();
