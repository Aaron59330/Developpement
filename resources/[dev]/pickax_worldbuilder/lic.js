// [AERO] vérification autonome du jeton de licence signé par le panel (Ed25519). La clé publique est celle embarquée dans la ressource.
const crypto = require('crypto');
const fail = (why) => { console.log('^1[AERO] ' + GetCurrentResourceName() + ' : jeton de licence refusé (' + why + ')^0'); return false; };
exports('LicVerify', (payload, sig, publicKeyB64, key) => {
  try {
    if (typeof payload !== 'string' || typeof sig !== 'string') return fail('jeton absent');
    if (!publicKeyB64) return fail('clé publique non embarquée dans cette ressource');
    if (!key) return fail('aero_panel_key vide');
    const pub = crypto.createPublicKey({ key: Buffer.from(publicKeyB64, 'base64'), format: 'der', type: 'spki' });
    if (!crypto.verify(null, Buffer.from(payload, 'utf8'), pub, Buffer.from(sig, 'base64'))) return fail('signature invalide : mauvaise clé publique embarquée');
    const p = JSON.parse(payload), now = Math.floor(Date.now() / 1000);
    if (p.valid !== true) return fail('licence non valide');
    if (p.kh !== crypto.createHash('sha256').update(String(key)).digest('hex').slice(0, 16)) return fail('empreinte de clé différente');
    if (typeof p.iat !== 'number' || p.iat > now + 900) return fail('horloge du serveur en retard sur le panel');
    if (now > p.iat + (Number(p.grace) || 0)) return fail('jeton expiré');
    return true;
  } catch (e) { return fail('erreur : ' + (e && e.message)); }
});
