@echo off
setlocal EnableDelayedExpansion

REM Change directory to where the script is
cd /d "%~dp0"

set "ENV_FILE=.env"

REM First start: no auth token in .env yet -> ask for a password and save it.
REM Stored as JUPYTERLAB_SERVER_TOKEN, it becomes the password the JupyterLab
REM login page asks for (it is never placed in the URL).
findstr /b /c:"JUPYTERLAB_SERVER_TOKEN=" "%ENV_FILE%" >nul 2>&1
if errorlevel 1 call :set_password

REM Check for Nvidia GPU using wmic, only NVIDIA check is supported
wmic path win32_VideoController get name | findstr /i "NVIDIA" >nul

REM Capture the exit code
set gpu_available=%errorlevel%

REM Execute commands based on GPU availability
if %gpu_available% equ 0 (
    echo NVIDIA GPU is available
    docker.exe compose --env-file .env.default --env-file .env -f compose.yml -f compose-gpu.yml up --no-recreate --no-build -d
) else (
    echo NVIDIA GPU is not available
    docker.exe compose --env-file .env.default --env-file .env -f compose.yml up --no-recreate --no-build -d
)

REM Access information: hosts derive from COMPOSE_PROJECT_NAME (.env overrides .env.default)
set "PROJECT_NAME="
for /f "tokens=1,* delims==" %%a in ('findstr /b /c:"COMPOSE_PROJECT_NAME=" "%ENV_FILE%" 2^>nul') do set "PROJECT_NAME=%%b"
if not defined PROJECT_NAME for /f "tokens=1,* delims==" %%a in ('findstr /b /c:"COMPOSE_PROJECT_NAME=" ".env.default" 2^>nul') do set "PROJECT_NAME=%%b"
if not defined PROJECT_NAME set "PROJECT_NAME=stellars-jupyterlab-ds"
set "LAB_PORT="
for /f "tokens=1,* delims==" %%a in ('findstr /b /c:"LAB_PORT=" "%ENV_FILE%" 2^>nul') do set "LAB_PORT=%%b"
if not defined LAB_PORT for /f "tokens=1,* delims==" %%a in ('findstr /b /c:"LAB_PORT=" ".env.default" 2^>nul') do set "LAB_PORT=%%b"
if not defined LAB_PORT set "LAB_PORT=443"
set "ACCESS_URL=https://lab.!PROJECT_NAME!.localhost"
if not "!LAB_PORT!"=="443" set "ACCESS_URL=!ACCESS_URL!:!LAB_PORT!"
echo.
echo JupyterLab is starting.
echo Access URL: !ACCESS_URL!
echo Log in with the password you set ^(it is not in the URL^).
echo The password is stored in %~dp0%ENV_FILE% ^(key JUPYTERLAB_SERVER_TOKEN^).
echo.
pause
exit /b

:set_password
echo First start - set the initial password for JupyterLab access.
echo This is the initial password; you can change it after you log in.
set /p "JUPYTERLAB_PASSWORD=Enter a password: "
>>"%ENV_FILE%" echo JUPYTERLAB_SERVER_TOKEN=!JUPYTERLAB_PASSWORD!
echo Initial password saved to %ENV_FILE% ^(key JUPYTERLAB_SERVER_TOKEN^).
goto :eof

REM EOF
