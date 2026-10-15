/* Sons des menus (synthétisés, aucun fichier) — même banque que les builders */
(function () {
  'use strict';
  var ctx = null;
  function audio() {
    if (!ctx) { try { ctx = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) { return null; } }
    if (ctx.state === 'suspended') ctx.resume();
    return ctx;
  }
  function tone(freq, dur, type, vol, delay, slideTo, master) {
    var c = audio(); if (!c) return;
    var t0 = c.currentTime + (delay || 0), o = c.createOscillator(), g = c.createGain();
    o.type = type || 'sine';
    o.frequency.setValueAtTime(freq, t0);
    if (slideTo) o.frequency.exponentialRampToValueAtTime(slideTo, t0 + dur);
    var v = Math.max(0.0001, (vol || 0.1) * (master / 100));
    g.gain.setValueAtTime(0.0001, t0);
    g.gain.exponentialRampToValueAtTime(v, t0 + 0.008);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    o.connect(g); g.connect(c.destination);
    o.start(t0); o.stop(t0 + dur + 0.02);
  }
  var SND = {
    click:   function (m) { tone(540, 0.06, 'sine', 0.10, 0, 0, m); tone(810, 0.08, 'sine', 0.07, 0.035, 0, m); },
    confirm: function (m) { tone(520, 0.09, 'triangle', 0.11, 0, 0, m); tone(780, 0.09, 'triangle', 0.10, 0.07, 0, m); tone(1040, 0.16, 'triangle', 0.09, 0.14, 0, m); },
    warn:    function (m) { tone(320, 0.14, 'sawtooth', 0.06, 0, 200, m); },
    hover:   function (m) { tone(1250, 0.025, 'sine', 0.035, 0, 0, m); },
    tab:     function (m) { tone(420, 0.07, 'sine', 0.07, 0, 640, m); },
    on:      function (m) { tone(500, 0.07, 'sine', 0.09, 0, 0, m); tone(760, 0.1, 'sine', 0.09, 0.06, 0, m); },
    off:     function (m) { tone(760, 0.07, 'sine', 0.08, 0, 0, m); tone(480, 0.1, 'sine', 0.08, 0.06, 0, m); },
    open:    function (m) { tone(330, 0.12, 'sine', 0.09, 0, 520, m); tone(660, 0.16, 'sine', 0.08, 0.09, 0, m); },
    close:   function (m) { tone(620, 0.1, 'sine', 0.08, 0, 330, m); },
    success: function (m) { tone(660, 0.1, 'triangle', 0.1, 0, 0, m); tone(990, 0.18, 'triangle', 0.09, 0.09, 0, m); },
    // annonce de serveur / d'entreprise : carillon doux en trois notes
    announce:     function (m) { tone(659, 0.16, 'sine', 0.1, 0, 0, m); tone(880, 0.16, 'sine', 0.1, 0.13, 0, m); tone(1318, 0.42, 'sine', 0.09, 0.26, 0, m); tone(1976, 0.3, 'sine', 0.025, 0.28, 0, m); },
    // ── Sons du staff (chacun reconnaissable) ──
    // nouveau report : alerte montante en 3 notes + petite pulsation grave
    report:       function (m) { tone(740, 0.09, 'triangle', 0.11, 0, 0, m); tone(988, 0.09, 'triangle', 0.11, 0.1, 0, m); tone(1318, 0.2, 'triangle', 0.1, 0.2, 0, m); tone(220, 0.28, 'sine', 0.08, 0.18, 165, m); },
    // report pris en charge : « ding » cristallin à deux notes
    reportTaken:  function (m) { tone(1175, 0.16, 'sine', 0.1, 0, 0, m); tone(1568, 0.3, 'sine', 0.09, 0.1, 0, m); tone(2349, 0.22, 'sine', 0.03, 0.1, 0, m); },
    // report fermé : glissando descendant doux
    reportClosed: function (m) { tone(880, 0.18, 'sine', 0.09, 0, 523, m); tone(523, 0.22, 'sine', 0.07, 0.14, 392, m); },
    // mode staff : balayage montant avec scintillement / descendant
    staffOn:      function (m) { tone(260, 0.22, 'sawtooth', 0.04, 0, 780, m); tone(520, 0.16, 'sine', 0.08, 0.12, 0, m); tone(1040, 0.22, 'sine', 0.07, 0.2, 0, m); tone(1560, 0.2, 'sine', 0.03, 0.26, 0, m); },
    staffOff:     function (m) { tone(780, 0.2, 'sawtooth', 0.035, 0, 260, m); tone(1040, 0.14, 'sine', 0.07, 0, 0, m); tone(520, 0.22, 'sine', 0.07, 0.12, 0, m); },
    error:   function (m) { tone(210, 0.18, 'square', 0.05, 0, 0, m); tone(170, 0.2, 'square', 0.05, 0.12, 0, m); }
  };
  window.addEventListener('message', function (e) {
    var m = e.data || {};
    if (m.a !== 'snd') return;
    var f = SND[m.n] || SND.click;
    try { f(Number(m.v) || 60); } catch (err) {}
  });
})();
