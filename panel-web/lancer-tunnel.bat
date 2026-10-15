@echo off
cd /d "%~dp0"
if not exist cloudflared.exe (
  echo Telecharge cloudflared.exe ici : https://github.com/cloudflare/cloudflared/releases/latest  ^(cloudflared-windows-amd64.exe^)
  echo Renomme-le en cloudflared.exe et place-le dans ce dossier, puis relance ce fichier.
  pause
  exit /b
)
echo Cherche la ligne "https://xxxx.trycloudflare.com" ci-dessous : c est l adresse publique de ton panel.
cloudflared.exe tunnel --url http://localhost:3000
pause
