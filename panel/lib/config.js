const fs = require('fs'), path = require('path');
// charge .env sans dépendance
try {
  for (const l of fs.readFileSync(path.join(__dirname, '..', '.env'), 'utf8').split(/\r?\n/)) {
    const m = l.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/); if (m && !l.trim().startsWith('#') && process.env[m[1]] === undefined) process.env[m[1]] = m[2];
  }
} catch (e) {}
const env = process.env;
module.exports = {
  port: +env.PORT || 3000,
  publicUrl: (env.PUBLIC_URL || '').replace(/\/$/, ''),
  secret: env.SESSION_SECRET || 'dev-secret-change-me',
  adminEmail: env.ADMIN_EMAIL || 'admin@example.com',
  adminPassword: env.ADMIN_PASSWORD || 'ChangeMoi!2024',
  allowRegister: (env.ALLOW_REGISTER || 'true') === 'true',
  trialDays: +env.TRIAL_DAYS || 0,
  trustProxy: (env.TRUST_PROXY || 'false') === 'true',
  dataDir: path.resolve(__dirname, '..', env.DATA_DIR || './data'),
  sessionDays: 14,
  agentIntervalSec: 10,
};
