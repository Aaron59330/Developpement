// Habillage uniquement : lit l'avancement affiché par index.js, ne le modifie pas.

// ===== Liens des boutons (mets tes URLs https:// complètes) =====
var LINKS = {
	reglement: '',
	discord: 'https://discord.gg/JGxkBuckU',
	boutique: 'https://bluebayrp.tebex.io/'
};

// ===== Équipe du serveur (créateurs, développeurs…) =====
var TEAM = [
	{ name: 'Pickax', role: 'Fondateur · Développeur' },
	{ name: 'Pseudo', role: 'Co-fondateur' },
	{ name: 'Pseudo', role: 'Développeur' },
	{ name: 'Pseudo', role: 'Responsable staff' }
];

// ===== Dernières mises à jour (la plus récente en premier) =====
var UPDATES = [
	{ date: '20/10/2026', title: 'Boutique & Tebex', items: ['Nouvelle boutique avec panier et codes promo', 'Achat de coins via Tebex', 'Give de coins à tous les joueurs'] },
	{ date: '19/10/2026', title: 'Interface', items: ['Couleur et logo du serveur configurables', 'Nouveau menu pause', 'Builder d\'événements'] }
];

// ===== Fond : '' = fond dégradé aux couleurs du serveur ; sinon nom d'une image du dossier loading (ex : 'background.jpg') =====
var BACKGROUND = 'background.jpg';

(function () {
	var bars = ['INIT_BEFORE_MAP_LOADED', 'MAP', 'INIT_AFTER_MAP_LOADED', 'INIT_SESSION'];
	var texts = ['Initialisation…', 'Chargement de la carte…', 'Démarrage…', 'Connexion à la session…'];
	var percentEl = document.getElementById('percent');
	var stageEl = document.getElementById('stageText');
	var shown = 0;

	function target() {
		var total = 0, stage = 0;
		bars.forEach(function (name, i) {
			var b = document.getElementById(name + '-bar');
			if (!b) return;
			var w = parseFloat(b.style.width) || 0;
			total += w;
			if (w > 0) stage = i;
		});
		return { p: Math.min(100, Math.round(total / 99.1 * 100)), stage: stage };
	}

	(function tick() {
		var t = target();
		if (shown < t.p) shown += Math.max(1, Math.round((t.p - shown) / 8));
		else if (shown > t.p) shown = t.p;
		percentEl.textContent = shown;
		stageEl.textContent = texts[t.stage];
		requestAnimationFrame(tick);
	})();

	var SV = window.PICKAX_SERVER || {};
	if (!LINKS.discord && SV.discord) LINKS.discord = 'https://' + String(SV.discord).replace(/^https?:\/\//, '');   // Discord du config du core

	// Fond
	if (BACKGROUND) document.getElementById('background').style.background = 'linear-gradient(rgba(8,10,16,.35), rgba(8,10,16,.5)), url(' + BACKGROUND + ') center / cover no-repeat';

	// Menu équipe / mises à jour
	var esc = function (s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); };
	var infoBody = document.getElementById('infoBody');
	var views = {
		team: function () { return TEAM.map(function (m) { return '<div class="mb"><span class="av">' + esc((m.name || '?').charAt(0).toUpperCase()) + '</span><div><b>' + esc(m.name) + '</b><small>' + esc(m.role) + '</small></div></div>'; }).join(''); },
		updates: function () { return UPDATES.map(function (u) { return '<div class="up"><div class="uh"><b>' + esc(u.title) + '</b><span>' + esc(u.date) + '</span></div><ul>' + (u.items || []).map(function (i) { return '<li>' + esc(i) + '</li>'; }).join('') + '</ul></div>'; }).join(''); }
	};
	function showInfo(t) {
		infoBody.innerHTML = views[t]();
		Array.prototype.forEach.call(document.querySelectorAll('.itab'), function (b) { b.classList.toggle('on', b.getAttribute('data-t') === t); });
	}
	Array.prototype.forEach.call(document.querySelectorAll('.itab'), function (b) { b.addEventListener('click', function () { b.blur(); showInfo(b.getAttribute('data-t')); }); });
	showInfo('team');

	// Boutons de liens
	Array.prototype.forEach.call(document.querySelectorAll('.tab'), function (el) {
		el.addEventListener('click', function () {
			el.blur();
			var url = LINKS[el.getAttribute('data-link')];
			if (!url) return;
			if (window.invokeNative) window.invokeNative('openUrl', url); else window.open(url, '_blank');
		});
	});

	// Volume + bouton musique (même logique que la touche ESPACE)
	var slider = document.getElementById('volume');
	var vv = document.getElementById('volumeValue');
	var icOn = document.getElementById('icOn'), icOff = document.getElementById('icOff');
	function paintSlider() {
		var v = slider.value;
		slider.style.background = 'linear-gradient(90deg, var(--accent) ' + v + '%, rgba(255,255,255,.12) ' + v + '%)';
		vv.textContent = v + '%';
	}
	slider.addEventListener('input', function () { myAudio.volume = slider.value / 100; paintSlider(); });
	document.getElementById('musicBtn').addEventListener('click', function () { this.blur(); toggleMusic(); });
	window.onMusicToggle = function (on) { icOn.style.display = on ? '' : 'none'; icOff.style.display = on ? 'none' : ''; };
	paintSlider();

	// ===== Configuration réglée depuis le panel web (Écran de chargement) : loading/loading.json =====
	// Chaque champ est facultatif : s'il est absent, la valeur d'origine de ce fichier est conservée.
	var KEYC = 'pickax_loading_cfg_v1';
	function applyCfg(c) {
		if (!c || typeof c !== 'object') return;
		if (c.links) ['reglement', 'discord', 'boutique'].forEach(function (k) { if (typeof c.links[k] === 'string') LINKS[k] = c.links[k]; });
		if (Array.isArray(c.team)) { TEAM.length = 0; c.team.forEach(function (m) { TEAM.push(m); }); }
		if (Array.isArray(c.updates)) { UPDATES.length = 0; c.updates.forEach(function (u) { UPDATES.push(u); }); }
		if (Array.isArray(c.stages)) c.stages.forEach(function (t, i) { if (typeof t === 'string' && t) texts[i] = t; });
		// messages du bandeau défilant
		if (Array.isArray(c.tips) && c.tips.length) {
			var tk = document.querySelector('.ticker');
			if (tk) tk.innerHTML = c.tips.map(function (t) { return '<div class="ticker__item">' + esc(t) + '</div>'; }).join('');
		}
		// panneau équipe / mises à jour
		var info = document.getElementById('info'), itabs = document.querySelectorAll('.itab');
		var sT = c.showTeam !== false, sU = c.showUpdates !== false;
		if (info) info.style.display = (sT || sU) ? '' : 'none';
		Array.prototype.forEach.call(itabs, function (b) { var t = b.getAttribute('data-t'); b.style.display = (t === 'team' ? sT : sU) ? '' : 'none'; });
		showInfo(sT ? 'team' : 'updates');
		// boutons de liens : un bouton sans lien est masqué
		Array.prototype.forEach.call(document.querySelectorAll('.tab'), function (el) { if (c.links) el.style.display = LINKS[el.getAttribute('data-link')] ? '' : 'none'; });
		// apparence : fond, logo, textes, éléments masqués
		if (c.bg && typeof c.bg === 'object') {
			var bgEl = document.getElementById('background'), d = Math.max(0, Math.min(100, +c.bg.dim || 0)) / 100;
			if (typeof c.bg.image === 'string' && /^https:\/\//i.test(c.bg.image)) bgEl.style.background = 'linear-gradient(rgba(8,10,16,' + d + '), rgba(8,10,16,' + d + ')), url(' + c.bg.image + ') center / cover no-repeat';
			else if (c.bg.dim) bgEl.style.background = 'linear-gradient(rgba(8,10,16,' + Math.max(.35, d) + '), rgba(8,10,16,' + Math.max(.5, d) + ')), url(' + BACKGROUND + ') center / cover no-repeat';
			bgEl.style.filter = c.bg.blur ? 'blur(' + Math.min(20, +c.bg.blur) + 'px)' : '';
		}
		if (typeof c.logo === 'string' && /^https:\/\//i.test(c.logo)) { window.PICKAX_LOGO = c.logo; Array.prototype.forEach.call(document.querySelectorAll('[data-pk-logo]'), function (el) { el.setAttribute('src', c.logo); }); }
		if (c.texts && typeof c.texts === 'object') {
			var w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT), nd, all = [];
			while ((nd = w.nextNode())) all.push(nd);
			all.forEach(function (t) { var k = t.nodeValue.trim(); if (k && Object.prototype.hasOwnProperty.call(c.texts, k)) t.nodeValue = t.nodeValue.replace(k, c.texts[k]); });
			Object.keys(c.texts).forEach(function (k) { var i = texts.indexOf(k); if (i >= 0) texts[i] = c.texts[k]; });
		}
		if (c.hide && typeof c.hide === 'object') {
			var map = { logo: '#logo img, .logo, [data-pk-logo]', ticker: '.ticker-wrap', links: '.tabs', progress: '.loading-container', name: '.ldname, [data-pk=name], [data-pk=short]' };
			Object.keys(map).forEach(function (k) { Array.prototype.forEach.call(document.querySelectorAll(map[k]), function (el) { el.style.display = c.hide[k] ? 'none' : ''; }); });
		}
		// musique
		var m = c.music;
		if (m && typeof m === 'object') {
			var vol = document.querySelector('.volume-control');
			if (m.enabled === false) { try { myAudio.pause(); } catch (e) {} play = false; if (vol) vol.style.display = 'none'; }
			else {
				if (typeof m.url === 'string' && /^https:\/\//i.test(m.url)) { myAudio.src = m.url; }
				if (typeof m.volume === 'number') { slider.value = Math.max(0, Math.min(100, Math.round(m.volume))); myAudio.volume = slider.value / 100; paintSlider(); }
				if (m.autoplay === false) { try { myAudio.pause(); } catch (e) {} play = false; window.onMusicToggle(false); }
				else { play = true; window.onMusicToggle(true); var pr = myAudio.play(); if (pr && pr.catch) pr.catch(function () {}); }
			}
		}
	}
	var cachedCfg = null;
	try { cachedCfg = JSON.parse(localStorage.getItem(KEYC) || 'null'); } catch (e) {}
	if (cachedCfg) applyCfg(cachedCfg);
	fetch('loading.json?t=' + Date.now()).then(function (r) { return r.ok ? r.json() : null; }).catch(function () { return null; }).then(function (c) {
		if (!c || typeof c !== 'object') return;
		try { localStorage.setItem(KEYC, JSON.stringify(c)); } catch (e) {}
		if (JSON.stringify(c) !== JSON.stringify(cachedCfg)) applyCfg(c);
	});
})();
