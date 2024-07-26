@echo off

REM Check for Nvidia GPU using wmic
wmic path win32_VideoController get name | findstr /i "NVIDIA" >nul

REM Capture the exit code
set gpu_available=%errorlevel%

REM Execute commands based on GPU availability
if %gpu_available% equ 0 (
    echo Nvidia GPU is available. Running local docker-compose.yml
    docker-compose.exe -f ..\local\docker-compose-nvidia.yml up --no-recreate --no-build 
) else (
    echo Nvidia GPU is not available. Running local docker-compose-nvidia.yml
    docker-compose.exe -f ..\local\docker-compose.yml up --no-recreate --no-build 
)

REM EOF


