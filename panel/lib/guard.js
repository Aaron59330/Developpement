// Protection de la base : le panel signe (Ed25519) chaque réponse de vérification de licence.
// La clé PRIVÉE reste sur le VPS (data/guard-ed25519.json, jamais dans le dépôt) ; la clé PUBLIQUE est copiée dans pickax_guard/config.lua
// (livré avec la base) : un faux panel ne peut pas fabriquer une réponse valide.
const crypto = require('crypto'), fs = require('fs'), path = require('path'); const cfg = require('./config');
const FILE = path.join(cfg.dataDir, 'guard-ed25519.json');
function load() {
  try { const j = JSON.parse(fs.readFileSync(FILE, 'utf8')); if (j.privatePem && j.publicB64) return j; } catch (e) {}
  fs.mkdirSync(cfg.dataDir, { recursive: true });
  const { publicKey, privateKey } = crypto.generateKeyPairSync('ed25519');
  const j = { privatePem: privateKey.export({ type: 'pkcs8', format: 'pem' }), publicB64: publicKey.export({ type: 'spki', format: 'der' }).toString('base64'), created_at: Math.floor(Date.now() / 1000) };
  fs.writeFileSync(FILE, JSON.stringify(j), { mode: 0o600 }); return j;
}
const keys = load(); const priv = crypto.createPrivateKey(keys.privatePem);
const sign = payload => crypto.sign(null, Buffer.from(payload, 'utf8'), priv).toString('base64');
const keyHash = key => crypto.createHash('sha256').update(String(key)).digest('hex').slice(0, 16);
module.exports = { publicKey: keys.publicB64, sign, keyHash };
