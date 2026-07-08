@echo off
setlocal EnableDelayedExpansion

REM Change directory to where the script is
cd /d "%~dp0"

set "ENV_FILE=.env"

REM fail early with a clear message when docker is not up - compose errors are cryptic
docker.exe info >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not running - start Docker Desktop or Rancher Desktop and run this script again.
    pause
    exit /b 1
)

REM First start: no auth token in .env yet -> ask for a password and save it.
REM Stored as JUPYTERLAB_SERVER_TOKEN, it becomes the password the JupyterLab
REM login page asks for (it is never placed in the URL). An EMPTY value counts
REM as unset: jupyter would autogenerate a random token and lock the user out.
REM The quoted-empty forms '' and "" also parse to an empty token (Windows
REM writers only ever produce single-quoted values, but .env is hand-editable).
set "TOKEN_MISSING=0"
findstr /r /c:"^JUPYTERLAB_SERVER_TOKEN=." "%ENV_FILE%" >nul 2>&1
if errorlevel 1 set "TOKEN_MISSING=1"
findstr /r /c:"^JUPYTERLAB_SERVER_TOKEN=''$" "%ENV_FILE%" >nul 2>&1
if not errorlevel 1 set "TOKEN_MISSING=1"
findstr /r /c:"^JUPYTERLAB_SERVER_TOKEN=\"\"$" "%ENV_FILE%" >nul 2>&1
if not errorlevel 1 set "TOKEN_MISSING=1"
if "%TOKEN_MISSING%"=="1" (
    call :set_password
    if errorlevel 1 exit /b 1
)

REM GPU needs BOTH a working driver (nvidia-smi; wmic is removed on Windows 11
REM 24H2+) and docker's nvidia runtime - with only the driver, the GPU overlay fails.
set "GPU_AVAILABLE=1"
nvidia-smi >nul 2>&1
if errorlevel 1 set "GPU_AVAILABLE=0"
if "%GPU_AVAILABLE%"=="1" (
    docker.exe info --format "{{json .Runtimes}}" 2>nul | findstr /i nvidia >nul 2>&1
    if errorlevel 1 (
        echo WARNING: NVIDIA GPU detected but docker has no nvidia runtime - starting without GPU.
        set "GPU_AVAILABLE=0"
    )
)

REM Execute commands based on GPU availability
if "%GPU_AVAILABLE%"=="1" (
    echo NVIDIA GPU is available
    docker.exe compose --env-file .env.default --env-file .env -f compose.yml -f compose-gpu.yml up --no-recreate --no-build -d
) else (
    echo NVIDIA GPU is not available
    docker.exe compose --env-file .env.default --env-file .env -f compose.yml up --no-recreate --no-build -d
)
if errorlevel 1 (
    echo.
    echo ERROR: docker compose up failed - see the messages above ^(port conflict, missing image, invalid .env^).
    pause
    exit /b 1
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
echo Note: changes to %ENV_FILE% apply after stop.bat + start.bat ^(running containers are not recreated^).
echo.
pause
exit /b

:set_password
echo First start - set the initial password for JupyterLab access.
echo This is the initial password; change it later in %ENV_FILE% ^(restart to apply^).
REM PowerShell is required: it ships with every supported Windows, and the plain
REM cmd fallback could not reject bad input or write the file safely.
where powershell >nul 2>&1
if errorlevel 1 (
    echo ERROR: PowerShell is required to save the password - add JUPYTERLAB_SERVER_TOKEN=^<password^> to %ENV_FILE% manually and re-run.
    exit /b 1
)
set /a PW_TRIES=0

:pw_ps
REM PowerShell reads the password hidden AND writes the .env line itself: the value
REM never round-trips through cmd expansion, so !, %%, ^& survive verbatim. The value
REM is written single-quoted so compose dotenv keeps $ and # literal. Exit codes:
REM 2 = empty input, 3 = contains a single quote, 4 = non-ASCII (the ANSI/ASCII
REM encoding .env is written with would silently corrupt such characters).
powershell -NoProfile -Command "$p=Read-Host -AsSecureString 'Enter a password'; $b=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($p); $s=[Runtime.InteropServices.Marshal]::PtrToStringAuto($b); if([string]::IsNullOrEmpty($s)){exit 2}; if($s.Contains([char]39)){exit 3}; if($s -match '[^\x20-\x7E]'){exit 4}; $lines=@(); if(Test-Path '%ENV_FILE%'){$lines=@(@(Get-Content '%ENV_FILE%') | Where-Object {$_ -notmatch ('^JUPYTERLAB_SERVER_TOKEN=(' + [char]39 + [char]39 + '|' + [char]34 + [char]34 + ')?$')})}; $lines += (\"JUPYTERLAB_SERVER_TOKEN='\" + $s + \"'\"); Set-Content -Path '%ENV_FILE%' -Value $lines -Encoding ASCII"
if %errorlevel% equ 0 (
    echo Initial password saved to %ENV_FILE% ^(key JUPYTERLAB_SERVER_TOKEN^).
    exit /b 0
)
if %errorlevel% equ 4 echo Use printable ASCII characters only - the Windows .env encoding would corrupt others.
if %errorlevel% equ 3 echo Single quotes ^(^'^) are not supported in the password - please choose another.
if %errorlevel% equ 2 echo Password cannot be empty.
set /a PW_TRIES+=1
if %PW_TRIES% geq 3 (
    echo ERROR: no password provided - add JUPYTERLAB_SERVER_TOKEN=^<password^> to %ENV_FILE% and re-run.
    exit /b 1
)
goto pw_ps

REM EOF
