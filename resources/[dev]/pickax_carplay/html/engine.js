'use strict';
/* Moteur audio CarPlay : un « canal » par véhicule audible (3 maximum, les plus proches).
 *  - YouTube : lecteur IFrame API masqué (le son seul est utilisé)
 *  - lien direct / flux radio : élément <audio>
 * Le serveur donne l'horloge : position = maintenant - startedAt (en secondes réelles) → tous les joueurs entendent la même chose au même moment. */
const Engine = (() => {
  const box = document.getElementById('engine');
  const chans = {};                // id → canal
  let off = 0;                     // décalage horloge serveur - horloge locale (s)
  let ytReady = false, ytLoading = false, ytWait = [];
  const cloud = () => Date.now() / 1000 + off;
  const post = (name, body) => fetch(`https://${typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_carplay'}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }).catch(() => { });

  const posOf = c => (c.playing ? cloud() - c.startedAt : c.pausedAt) || 0;

  function loadYT(cb) {
    if (ytReady) return cb();
    ytWait.push(cb);
    if (ytLoading) return;
    ytLoading = true;
    window.onYouTubeIframeAPIReady = () => { ytReady = true; const w = ytWait; ytWait = []; w.forEach(f => f()); };
    const s = document.createElement('script');
    s.src = 'https://www.youtube.com/iframe_api';
    s.onerror = () => { ytLoading = false; ytWait = []; };
    document.head.appendChild(s);
  }

  function destroy(c) {
    try { if (c.player && c.player.destroy) c.player.destroy(); } catch (e) { /* ignore */ }
    if (c.audio) { try { c.audio.pause(); c.audio.removeAttribute('src'); c.audio.load(); } catch (e) { /* ignore */ } }
    if (c.el && c.el.parentNode) c.el.parentNode.removeChild(c.el);
    c.player = c.audio = c.el = null; c.ready = false; c.metaSent = false;
  }

  function create(c) {
    c.el = document.createElement('div');
    box.appendChild(c.el);
    c.metaSent = false; c.liveSince = 0;
    if (c.kind === 'yt') {
      loadYT(() => {
        if (!c.el) return;
        const host = document.createElement('div');
        c.el.appendChild(host);
        c.player = new YT.Player(host, {
          width: '200', height: '113', videoId: c.ref,
          playerVars: { start: Math.max(0, Math.floor(posOf(c))), autoplay: 1, controls: 0, disablekb: 1, fs: 0, modestbranding: 1, rel: 0, playsinline: 1, enablejsapi: 1, origin: /^https?:/.test(location.origin) ? location.origin : undefined },
          events: {
            onReady: () => { c.ready = true; apply(c, true); },
            onStateChange: e => { if (e.data === 1) c.started = true; },
            onError: e => post('error', { id: c.id, rev: c.rev, code: e.data }),
          },
        });
      });
    } else {
      const a = new Audio();
      a.preload = 'auto';
      a.addEventListener('error', () => post('error', { id: c.id, rev: c.rev, code: 'audio' }));
      a.addEventListener('loadedmetadata', () => { c.ready = true; apply(c, true); });
      a.src = c.ref;
      c.audio = a;
      c.pendingStart = Math.max(0, posOf(c));
    }
  }

  function setVol(c) {
    const v = Math.max(0, Math.min(1, c.vol));
    try {
      if (c.kind === 'yt' && c.player && c.player.setVolume) c.player.setVolume(Math.round(v * 100));
      else if (c.audio) c.audio.volume = v;
    } catch (e) { /* ignore */ }
  }

  function duration(c) {
    try {
      if (c.kind === 'yt' && c.player && c.player.getDuration) return c.player.getDuration() || 0;
      if (c.audio) return isFinite(c.audio.duration) ? c.audio.duration : 0;
    } catch (e) { /* ignore */ }
    return 0;
  }

  function current(c) {
    try {
      if (c.kind === 'yt' && c.player && c.player.getCurrentTime) return c.player.getCurrentTime() || 0;
      if (c.audio) return c.audio.currentTime || 0;
    } catch (e) { /* ignore */ }
    return 0;
  }

  // aligne lecture / pause / position / volume sur l'état du serveur.
  // Recalage de position seulement si l'écart est grand ET que le lecteur joue vraiment (jamais pendant le chargement), avec un délai entre deux recalages :
  // sinon chaque recalage relance la mise en mémoire tampon et la musique redémarre en boucle.
  function seek(c, t) {
    c.lastSeek = Date.now();
    try { if (c.kind === 'yt') c.player.seekTo(Math.max(0, t), true); else c.audio.currentTime = Math.max(0, t); } catch (e) { /* ignore */ }
  }
  function apply(c, force) {
    if (!c.ready) return;
    setVol(c);
    const want = posOf(c);
    const live = c.live === true;
    const settled = !c.lastSeek || Date.now() - c.lastSeek > 8000;
    try {
      if (c.playing) {
        let state = 0;
        if (c.kind === 'yt') { state = c.player.getPlayerState ? c.player.getPlayerState() : -1; }
        else state = c.audio.paused ? 2 : 1;
        if (force && !live && want > 2) seek(c, want);                                    // premier calage (le lecteur démarre déjà à peu près au bon endroit)
        else if (!live && state === 1 && settled && want >= 0 && Math.abs(current(c) - want) > 6) seek(c, want);   // dérive importante : un seul recalage
        if (c.kind === 'yt') { if ((state === -1 || state === 5 || state === 2) && (!c.lastPlay || Date.now() - c.lastPlay > 3000)) { c.lastPlay = Date.now(); c.player.playVideo(); } }
        else if (c.audio.paused && (!c.lastPlay || Date.now() - c.lastPlay > 3000)) { c.lastPlay = Date.now(); const p = c.audio.play(); if (p && p.catch) p.catch(() => { }); }
      } else {
        if (c.kind === 'yt') { c.player.pauseVideo(); if (force) seek(c, want); }
        else { c.audio.pause(); if (force && !live) seek(c, want); }
      }
    } catch (e) { /* lecteur pas encore prêt */ }
  }

  function update(list, now) {
    off = (Number(now) || cloud()) - Date.now() / 1000;
    const seen = {};
    for (const n of list || []) {
      seen[n.id] = true;
      let c = chans[n.id];
      if (c && (c.rev !== n.rev || c.ref !== n.ref || c.kind !== n.kind)) { destroy(c); delete chans[n.id]; c = null; }
      if (!c) { c = chans[n.id] = { id: n.id, kind: n.kind, ref: n.ref, rev: n.rev, vol: 0, quietSince: 0 }; }
      c.playing = !!n.playing; c.startedAt = n.startedAt || 0; c.pausedAt = n.pausedAt || 0; c.vol = n.vol || 0; c.mine = !!n.mine;
      if (c.vol <= 0.004) { if (!c.quietSince) c.quietSince = Date.now(); } else c.quietSince = 0;
      if (!c.el && c.vol > 0.004) create(c); else apply(c, false);
    }
    for (const id of Object.keys(chans)) if (!seen[id]) { destroy(chans[id]); delete chans[id]; }
  }

  // surveillance : dérive, durée du titre, canaux muets trop longtemps (on libère le lecteur)
  setInterval(() => {
    for (const c of Object.values(chans)) {
      if (c.el && c.vol <= 0.004 && c.quietSince && Date.now() - c.quietSince > 8000) { destroy(c); continue; }
      if (!c.ready) continue;
      apply(c, false);
      if (!c.metaSent) {
        const d = duration(c);
        if (d > 0) { c.metaSent = true; post('meta', { id: c.id, rev: c.rev, dur: d }); }
        else if (c.playing && (c.started || c.kind === 'direct')) {
          c.liveSince = c.liveSince || Date.now();
          if (Date.now() - c.liveSince > 9000) { c.metaSent = true; c.live = true; post('meta', { id: c.id, rev: c.rev, dur: 0 }); }
        }
      }
    }
  }, 1000);

  const sync = now => { if (now) off = Number(now) - Date.now() / 1000; };
  return { update, sync, channels: () => chans, posOf, cloud };
})();
