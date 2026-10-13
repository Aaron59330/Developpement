(function () {
  var $ = function (id) { return document.getElementById(id); };
  var holder = $('holder'), card = $('id-card'), hideTimer = null;

  // Petit son d'ouverture / fermeture (WebAudio, aucun fichier)
  var ctx = null;
  function tone(freq, dur, slideTo, vol, delay) {
    try {
      ctx = ctx || new (window.AudioContext || window.webkitAudioContext)();
      var t = ctx.currentTime + (delay || 0), o = ctx.createOscillator(), g = ctx.createGain();
      o.type = 'triangle'; o.frequency.setValueAtTime(freq, t);
      if (slideTo) o.frequency.exponentialRampToValueAtTime(slideTo, t + dur);
      g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(vol || 0.05, t + 0.01);
      g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
      o.connect(g); g.connect(ctx.destination); o.start(t); o.stop(t + dur + 0.02);
    } catch (e) {}
  }

  function set(id, v) { $(id).textContent = v == null ? '' : v; }
  function capitalize(s) { return (s || '').replace(/(^|[\s-])(\S)/g, function (m, a, b) { return a + b.toUpperCase(); }); }
  function mrz(s) { return (s || '').toUpperCase().replace(/[^A-Z]/g, ''); }

  window.addEventListener('message', function (event) {
    var d = event.data;
    if (d.action == 'open') {
      clearTimeout(hideTimer);
      var type = d.type;
      var user = d.array['user'][0];
      var licenses = d.array['licenses'];
      var first = capitalize(user.firstname), last = (user.lastname || '').toUpperCase();
      var isMale = (user.sex || 'm').toLowerCase() == 'm';

      card.className = 'idcard ' + (type == 'driver' ? 'type-driver' : type == 'weapon' ? 'type-weapon' : 'type-id');

      set('cFirst', first); set('cLast', last);
      set('cDob', user.dateofbirth);
      set('cSex', isMale ? 'M' : 'F');
      set('cHeight', user.height ? user.height + ' cm' : '');
      set('cNat', user.nationality || '');
      set('signature', first + ' ' + capitalize(user.lastname));

      // Numéro de carte stable à partir du nom + naissance
      var seed = 0, str = (user.firstname || '') + (user.lastname || '') + (user.dateofbirth || '');
      for (var i = 0; i < str.length; i++) seed = (seed * 31 + str.charCodeAt(i)) % 900000;
      var no = String(100000 + seed);
      set('cNo', no);
      var l1 = ('ID' + no + '<<' + mrz(user.lastname) + '<<' + mrz(user.firstname) + '<<<<<<<<<<<<<<<<<<<<<<<<<<<<').slice(0, 30);
      var l2 = (no + '<<<' + mrz(user.firstname + user.lastname) + '<<<<<<<<<<<<<<<<<<<<<<<<<<<<').slice(0, 30);
      $('mrz').innerHTML = l1 + '<br>' + l2;

      // Variantes de carte
      $('cNat').style.display = 'block'; $('licenses').className = 'badges';
      document.querySelector('[data-f="sex"]').classList.remove('hidden');
      document.querySelector('[data-f="height"]').classList.remove('hidden');
      set('cExtraLabel', 'Nationalité');
      if (type == 'driver') {
        set('cTitle', 'Permis de conduire');
        set('cExtraLabel', 'Catégories');
        $('cNat').style.display = 'none';
        var out = $('licenses'); out.innerHTML = ''; out.className = 'badges on';
        if (licenses != null) {
          Object.keys(licenses).forEach(function (key) {
            var t = licenses[key].type;
            if (t == 'drive_bike') t = 'moto'; else if (t == 'drive_truck') t = 'poids lourd'; else if (t == 'drive') t = 'voiture';
            if (t == 'moto' || t == 'poids lourd' || t == 'voiture') {
              var s = document.createElement('span'); s.textContent = t; out.appendChild(s);
            }
          });
        }
      } else if (type == 'weapon') {
        set('cTitle', "Permis de port d'arme");
        document.querySelector('[data-f="height"]').classList.add('hidden');
        document.querySelector('[data-f="sex"]').classList.add('hidden');
      } else {
        set('cTitle', "Carte nationale d'identité");
      }

      // Vraie tête du personnage, sinon silhouette
      var img = $('headImg'), photo = $('photo');
      photo.classList.remove('has-head');
      if (d.head) {
        img.onload = function () { photo.classList.add('has-head'); };
        img.onerror = function () { photo.classList.remove('has-head'); };
        img.src = d.head;
      }

      holder.className = ''; void holder.offsetWidth; holder.className = 'show';
      tone(220, 0.18, 520, 0.05); tone(640, 0.12, null, 0.04, 0.12);
    } else if (d.action == 'close') {
      holder.className = 'hide'; tone(520, 0.14, 200, 0.04);
      hideTimer = setTimeout(function () {
        holder.className = '';
        $('licenses').innerHTML = '';
        $('headImg').removeAttribute('src');
        $('photo').classList.remove('has-head');
      }, 320);
    }
  });
})();
