// Vérification de signature Ed25519 (le Lua de FiveM n'a pas de cryptographie) + empreinte de la clé.
const crypto = require('crypto');
exports('Verify', (payload, sig, publicKeyB64) => {
  try {
    if (typeof payload !== 'string' || typeof sig !== 'string' || typeof publicKeyB64 !== 'string' || !publicKeyB64) return false;
    const key = crypto.createPublicKey({ key: Buffer.from(publicKeyB64, 'base64'), format: 'der', type: 'spki' });
    return crypto.verify(null, Buffer.from(payload, 'utf8'), key, Buffer.from(sig, 'base64'));
  } catch (e) { return false; }
});
exports('KeyHash', (key) => crypto.createHash('sha256').update(String(key)).digest('hex').slice(0, 16));
exports('Random', (n) => crypto.randomBytes(Math.ceil((n || 24) / 2)).toString('hex').slice(0, n || 24));
