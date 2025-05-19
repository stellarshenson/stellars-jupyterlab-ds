@echo off

REM Change directory to where the script is
cd /d "%~dp0"

REM Check for Nvidia GPU using wmic, only NVIDIA check is supported
wmic path win32_VideoController get name | findstr /i "NVIDIA" >nul

REM Capture the exit code
set gpu_available=%errorlevel%

REM Execute commands based on GPU availability
if %gpu_available% equ 0 (
    echo NVIDIA GPU is available
    docker.exe compose --env-file ..\project.env -f ..\compose.yml -f ..\compose-gpu.yml up --no-recreate --no-build -d
) else (
    echo NVIDIA GPU is not available
    docker.exe compose --env-file ..\project.env -f ..\compose.yml up --no-recreate --no-build -d
)

REM EOF


