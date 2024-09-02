@echo off
echo Waking up WSL
wsl.exe --exec "true"

timeout /t 5 /nobreak

echo Running Docker Desktop
start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe" -Autostart
