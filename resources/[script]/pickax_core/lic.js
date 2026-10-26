// [AERO] vérification autonome du jeton de licence signé par le panel (Ed25519). La clé publique est celle embarquée dans la ressource.
const crypto = require('crypto');
exports('LicVerify', (payload, sig, publicKeyB64, key) => {
  try {
    if (typeof payload !== 'string' || typeof sig !== 'string' || !publicKeyB64 || !key) return false;
    const pub = crypto.createPublicKey({ key: Buffer.from(publicKeyB64, 'base64'), format: 'der', type: 'spki' });
    if (!crypto.verify(null, Buffer.from(payload, 'utf8'), pub, Buffer.from(sig, 'base64'))) return false;
    const p = JSON.parse(payload), now = Math.floor(Date.now() / 1000);
    if (p.valid !== true || p.kh !== crypto.createHash('sha256').update(String(key)).digest('hex').slice(0, 16)) return false;
    if (typeof p.iat !== 'number' || p.iat > now + 900 || now > p.iat + (Number(p.grace) || 0)) return false;
    return true;
  } catch (e) { return false; }
});
