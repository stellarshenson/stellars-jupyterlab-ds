@echo off

REM Change directory to where the script is
cd /d "%~dp0"

REM compose errors on a missing env-file
if not exist ".env" type nul > ".env"

docker.exe compose --env-file .env.default --env-file .env -f compose.yml down

pause

REM EOF
