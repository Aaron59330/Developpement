@echo off
cd /d "%~dp0"
if exist public-url.txt set /p PUBLIC_URL=<public-url.txt
start http://localhost:3000
node server.js
pause
