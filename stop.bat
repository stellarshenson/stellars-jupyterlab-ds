@echo off

REM Change directory to where the script is
cd /d "%~dp0"

REM fail early with a clear message when docker is not up - compose errors are cryptic
docker.exe info >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not running - start Docker Desktop or Rancher Desktop and run this script again.
    pause
    exit /b 1
)

REM compose errors on a missing env-file
if not exist ".env" type nul > ".env"

docker.exe compose --env-file .env.default --env-file .env -f compose.yml down

pause

REM EOF
