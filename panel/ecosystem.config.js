// pm2 start ecosystem.config.js && pm2 save && pm2 startup
module.exports = { apps: [{ name: 'aero-panel', script: 'server.js', env: { NODE_ENV: 'production' }, max_memory_restart: '300M' }] };
