// Diagnostic du serveur (mode test) : vérifie ce que le panel sait de la base et renvoie une liste lisible.
// input = { now, license, lastSeen, resources:[{name,state}], players, maxPlayers, stats, settingsSchema, overrides, logs:[{level,source,message,at}], docs:{theme,loading} }
const ESSENTIAL = ['oxmysql', 'ox_lib', 'es_extended', 'ox_inventory', 'pickax_core', 'pickax_settings', 'pickax_panel'];
const BUILDERS = ['pickax_jobbuilder', 'pickax_gangbuilder', 'pickax_illegalbuilder', 'pickax_shopbuilder'];

function run(i) {
  const out = []; const add = (level, label, detail, fix) => out.push({ level, label, detail, fix });
  const now = i.now || Math.floor(Date.now() / 1000);
  // licence
  const l = i.license || {};
  if (l.status !== 'active') add('bad', 'Licence', `Statut « ${l.status || 'inconnu'} »`, 'Renouvelle ou réactive la licence.');
  else if (l.expires_at && l.expires_at < now) add('bad', 'Licence', 'Expirée', 'Renouvelle la licence : le serveur sera coupé.');
  else if (l.expires_at && l.expires_at - now < 7 * 86400) add('warn', 'Licence', `Expire dans ${Math.max(0, Math.ceil((l.expires_at - now) / 86400))} jour(s)`, 'Pense à renouveler.');
  else add('ok', 'Licence', l.expires_at ? `Valide jusqu’au ${new Date(l.expires_at * 1000).toLocaleDateString('fr-FR')}` : 'Valide, sans date de fin');
  // connexion
  const age = i.lastSeen ? now - i.lastSeen : null;
  if (age === null) add('bad', 'Connexion du serveur', 'Le serveur ne s’est jamais connecté au panel', 'Mets la clé de licence dans pickax_panel puis démarre la ressource.');
  else if (age > 120) add('bad', 'Connexion du serveur', `Dernier signe de vie il y a ${Math.round(age / 60)} min`, 'Le serveur est éteint ou pickax_panel est arrêté.');
  else add('ok', 'Connexion du serveur', 'Le serveur répond au panel');
  // ressources
  const res = Object.fromEntries((i.resources || []).map(r => [r.name, r.state]));
  if (!(i.resources || []).length) add('warn', 'Ressources', 'Liste non reçue pour le moment', 'Attends la prochaine synchronisation (1 à 2 minutes).');
  else {
    const missing = ESSENTIAL.filter(n => res[n] !== 'started');
    add(missing.length ? 'bad' : 'ok', 'Ressources essentielles', missing.length ? `Non démarrées : ${missing.join(', ')}` : `${ESSENTIAL.length} ressources essentielles démarrées`, missing.length ? 'Vérifie resources.cfg et la console du serveur.' : undefined);
    const stoppedB = BUILDERS.filter(n => res[n] && res[n] !== 'started'), absentB = BUILDERS.filter(n => !res[n]);
    if (stoppedB.length) add('warn', 'Builders', `Arrêtés : ${stoppedB.join(', ')}`, 'Relance-les depuis la page Ressources.');
    else if (absentB.length) add('warn', 'Builders', `Absents : ${absentB.join(', ')}`, 'Ils ne sont pas installés sur ce serveur.');
    else add('ok', 'Builders', 'Job, gang, illégal et boutique démarrés');
    const failed = (i.resources || []).filter(r => /^(missing|uninitialized|stopped)$/.test(r.state) && /^pickax_/.test(r.name) && !stoppedB.includes(r.name));
    if (failed.length) add('warn', 'Ressources Pickax', `${failed.length} arrêtée(s) : ${failed.slice(0, 6).map(r => r.name).join(', ')}`, 'Relance-les ou vérifie leurs erreurs.');
  }
  // réglages
  if (!(i.settingsSchema || []).length) add('warn', 'Réglages du serveur', 'Non disponibles : pickax_settings n’a pas envoyé sa liste', 'Redémarre pickax_settings.');
  else {
    const ov = i.overrides || {};
    add('ok', 'Réglages du serveur', `${i.settingsSchema.length} réglages disponibles, ${Object.keys(ov).length} modifié(s), mode ${ov.game_mode === 'facile' ? 'facile' : 'difficile'}`);
    if (ov.maintenance_enabled) add('warn', 'Maintenance', 'Le mode maintenance est ACTIVÉ : les nouveaux joueurs sont refusés', 'Désactive-le dans Réglages → Serveur.');
    if (ov.discord_alerts && !ov.discord_webhook) add('warn', 'Alertes Discord', 'Activées mais aucun webhook renseigné', 'Colle l’URL du webhook dans Réglages → Discord.');
  }
  // erreurs récentes
  const errs = (i.logs || []).filter(x => x.level === 'error' && x.at > now - 3600);
  if (errs.length) { const top = {}; for (const e of errs) top[e.message.slice(0, 90)] = (top[e.message.slice(0, 90)] || 0) + 1; add(errs.length > 20 ? 'bad' : 'warn', 'Erreurs de la dernière heure', `${errs.length} erreur(s). Principales : ${Object.entries(top).sort((a, b) => b[1] - a[1]).slice(0, 3).map(([m, n]) => `« ${m} » ×${n}`).join(' · ')}`, 'Ouvre la console / le journal pour le détail.'); }
  else add('ok', 'Erreurs de la dernière heure', 'Aucune erreur remontée');
  // capacité
  if (i.maxPlayers && i.players / i.maxPlayers >= 0.9) add('warn', 'Capacité', `${i.players} / ${i.maxPlayers} joueurs : presque plein`, 'Augmente le nombre de places si besoin.');
  else add('ok', 'Capacité', `${i.players || 0} / ${i.maxPlayers || '—'} joueurs`);
  // démarrage récent / mémoire
  const up = i.stats && i.stats.uptime;
  if (up != null && up < 300) add('warn', 'Démarrage', 'Le serveur vient de redémarrer', 'Certains systèmes finissent de se charger : relance le test dans 2 minutes.');
  // personnalisation
  const th = i.docs && i.docs.theme;
  if (!th) add('warn', 'Identité du serveur', 'Aucun thème enregistré', 'Passe par l’assistant d’installation.');
  else if (/^(AERO|BLUEBAY)$/i.test(th.ServerName || '') && /^(AERO|BLUEBAY)$/i.test(th.ServerShortName || '')) add('warn', 'Identité du serveur', `Le nom est encore « ${th.ServerName} »`, 'Mets le nom de TON serveur (assistant d’installation).');
  else add('ok', 'Identité du serveur', `Nom : ${th.ServerName}`);
  const score = Math.round(out.reduce((s, c) => s + (c.level === 'ok' ? 1 : c.level === 'warn' ? 0.5 : 0), 0) / out.length * 100);
  return { checks: out, score, bad: out.filter(c => c.level === 'bad').length, warn: out.filter(c => c.level === 'warn').length };
}
module.exports = { run, ESSENTIAL, BUILDERS };
