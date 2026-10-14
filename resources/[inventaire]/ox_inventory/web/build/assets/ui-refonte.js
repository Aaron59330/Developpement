/* Refonte : sons motion design (activables), état du poids, rien d'autre ne touche à la logique de l'inventaire. */
(() => {
  'use strict';
  const KEY = 'oxui.sound';
  let on = true;
  try { on = localStorage.getItem(KEY) !== '0'; } catch (e) {}
  let ctx = null, lastHover = 0;
  const audio = () => {
    if (!ctx) { try { ctx = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) { return null; } }
    if (ctx.state === 'suspended') ctx.resume();
    return ctx;
  };
  function tone(f, d, type, v, delay, slide) {
    const c = audio(); if (!c) return;
    const t0 = c.currentTime + (delay || 0), o = c.createOscillator(), g = c.createGain();
    o.type = type || 'sine'; o.frequency.setValueAtTime(f, t0);
    if (slide) o.frequency.exponentialRampToValueAtTime(slide, t0 + d);
    g.gain.setValueAtTime(0.0001, t0); g.gain.exponentialRampToValueAtTime(Math.max(0.0001, v || 0.08), t0 + 0.008); g.gain.exponentialRampToValueAtTime(0.0001, t0 + d);
    o.connect(g); g.connect(c.destination); o.start(t0); o.stop(t0 + d + 0.02);
  }
  const SND = {
    click: () => { tone(540, .06, 'sine', .09); tone(810, .08, 'sine', .06, .035); },
    pick: () => tone(660, .05, 'sine', .07, 0, 880),
    drop: () => { tone(520, .09, 'triangle', .1); tone(780, .12, 'triangle', .09, .07); },
    hover: () => tone(1250, .025, 'sine', .028),
    tab: () => tone(420, .07, 'sine', .07, 0, 640),
    open: () => { tone(330, .12, 'sine', .08, 0, 520); tone(660, .16, 'sine', .07, .09); },
    close: () => tone(620, .1, 'sine', .07, 0, 330),
    on: () => { tone(500, .07, 'sine', .08); tone(760, .1, 'sine', .08, .06); }
  };
  const play = n => { if (on && SND[n]) { try { SND[n](); } catch (e) {} } };

  const app = document.getElementById('app');
  if (app) {
    let was = app.classList.contains('open');
    new MutationObserver(() => { const v = app.classList.contains('open'); if (v !== was) { was = v; play(v ? 'open' : 'close'); } })
      .observe(app, { attributes: true, attributeFilter: ['class'] });

    // saisie d'un objet / dépôt / filtres / boutons
    document.addEventListener('mousedown', e => { const s = e.target.closest && e.target.closest('.slot.has'); if (s && e.button === 0) play('pick'); }, true);
    document.addEventListener('mouseup', e => { if (document.querySelector('.slot.over')) play('drop'); }, true);
    document.addEventListener('click', e => {
      const t = e.target.closest && e.target.closest('.rail button, .shop-pay button, .amount button, .ctx-item, #help-btn, .tenue-slot');
      if (!t) return;
      play(t.closest('.rail') ? 'tab' : 'click');
    }, true);
    document.addEventListener('mouseover', e => {
      const s = e.target.closest && e.target.closest('.slot.has, .rail button, .ctx-item');
      if (!s || s === e.relatedTarget) return;
      const now = Date.now(); if (now - lastHover < 60) return; lastHover = now; play('hover');
    }, true);

    // bouton son
    const help = document.getElementById('help-btn');
    const stage = document.getElementById('stage');
    const btn = document.createElement('button');
    btn.id = 'snd-btn'; btn.title = 'Sons de l\'inventaire';
    const ICON = '<svg viewBox="0 0 24 24"><path d="M11 5 6 9H3v6h3l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9 9 0 0 1 0 13"/></svg>';
    const paint = () => { btn.innerHTML = ICON; btn.classList.toggle('off', !on); btn.title = on ? 'Sons activés (cliquer pour couper)' : 'Sons coupés (cliquer pour activer)'; };
    btn.addEventListener('click', e => { e.stopPropagation(); on = !on; try { localStorage.setItem(KEY, on ? '1' : '0'); } catch (err) {} paint(); if (on) play('on'); });
    paint();
    (help && help.parentNode ? help.parentNode : stage || app).appendChild(btn);

    // poids : orange à 80 %, rouge à 100 %
    const watch = bar => {
      const row = bar.closest('.head-right'); if (!row) return;
      const upd = () => { const w = parseFloat(bar.style.width) || 0; row.classList.toggle('w-warn', w >= 80 && w < 100); row.classList.toggle('w-full', w >= 99.5); };
      new MutationObserver(upd).observe(bar, { attributes: true, attributeFilter: ['style'] }); upd();
    };
    document.querySelectorAll('.weight-bar i').forEach(watch);
  }
})();
