#!/usr/bin/env python3
"""Lance le panel EN LOCAL (http://localhost:8080) pour piloter un serveur distant (VPS).

Aucune installation : Python 3 suffit.  Usage :  python serve.py [port]
Sur la page, saisis l'adresse du serveur (http://IP_DU_VPS:30120) et la clé définie dans le server.cfg du VPS :
    set pickax_panel_key "..."
Les modifications sont envoyées au VPS (fichiers + base de données du VPS) : rien n'est écrit sur ton PC.
"""
import os, sys
from http.server import BaseHTTPRequestHandler, HTTPServer

WEB = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'resources', '[dev]', 'pickax_panel', 'web')
TYPES = {'.html': 'text/html; charset=utf-8', '.js': 'application/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8'}

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        name = {'/': 'index.html'}.get(self.path.split('?')[0], self.path.split('?')[0].lstrip('/'))
        if name not in ('index.html', 'app.js', 'app.css'):
            self.send_error(404); return
        with open(os.path.join(WEB, name), 'rb') as f:
            data = f.read()
        if name == 'index.html':
            data = data.replace(b'{{BASE}}', b'/').replace(b'{{REMOTE}}', b'yes')
        self.send_response(200)
        self.send_header('Content-Type', TYPES[os.path.splitext(name)[1]])
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *a):
        pass

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    print('Panel local : http://localhost:%d   (Ctrl+C pour arrêter)' % port)
    HTTPServer(('127.0.0.1', port), Handler).serve_forever()
