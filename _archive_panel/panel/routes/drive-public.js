const router = require('express').Router(); const path = require('path'), fs = require('fs'); const { db } = require('../lib/db'); const cfg = require('../lib/config');
router.get('/:token', (req, res) => {
  const f = db.prepare('SELECT * FROM drive WHERE token=?').get(String(req.params.token).replace(/[^a-f0-9]/g, '')); if (!f) return res.status(404).end();
  const file = path.join(cfg.dataDir, 'drive', f.token); if (!fs.existsSync(file)) return res.status(404).end();
  res.set({ 'Content-Type': f.mime, 'Content-Disposition': 'inline', 'X-Content-Type-Options': 'nosniff', 'Cache-Control': 'public, max-age=3600', 'Content-Security-Policy': "default-src 'none'; style-src 'unsafe-inline'; sandbox" }); res.sendFile(file);
});
module.exports = router;
