# -*- coding: utf-8 -*-
# Génère panel/public/explications-data.js à partir des textes (entries.py), des commandes extraites (commands_raw.json) et de commands_text.py.
# Utilisation : cd panel && python3 tools/explications/extract_commands.py && python3 tools/explications/build.py
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from entries import ENTRIES
from commands_text import CD
raw = json.load(open(os.path.join(HERE, 'commands_raw.json'), encoding='utf8'))
ids = {e['id'] for e in ENTRIES}
def owner(res, file):
    if res == '[script]/pickax_core':
        parts = file.split('/')
        for n in (3, 2, 1):
            cand = 'pickax_core/' + '/'.join(parts[:n])
            if cand in ids: return cand
        return '[script]/pickax_core'
    return res
cmds = []
for res, lst in raw.items():
    for c in lst:
        if not __import__('re').match(r'^[A-Za-z0-9_]+$', c['name']): continue
        who, desc = CD.get(c['name'], ('', c.get('desc', '')))
        cmds.append(dict(name=c['name'], res=res.split('/')[1], owner=owner(res, c['file']), who=who, desc=desc or c.get('desc', ''), key=c.get('key', ''), file=c['file']))
missing = sorted({c['name'] for c in cmds if not c['who']})
for e in ENTRIES:
    e['cmds'] = [c['name'] for c in cmds if c['owner'] == e['id']]
data = dict(entries=ENTRIES, commands=sorted(cmds, key=lambda c: c['name'].lower()))
out = os.path.join(HERE, '..', '..', 'public', 'explications-data.js')
open(out, 'w', encoding='utf8').write('// Généré par tools/explications/build.py : ne pas modifier à la main\nwindow.EXPL = ' + json.dumps(data, ensure_ascii=False) + ';\n')
print(len(ENTRIES), 'entrées', len(cmds), 'commandes', 'sans explication :', missing)
