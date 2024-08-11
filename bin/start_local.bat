@echo off

REM Check for Nvidia GPU using wmic, only NVIDIA check is supported
wmic path win32_VideoController get name | findstr /i "NVIDIA" >nul

REM Capture the exit code
set gpu_available=%errorlevel%

REM Execute commands based on GPU availability
if %gpu_available% equ 0 (
    echo GPU is available. Running local docker-compose-gpu.yml
    docker-compose.exe -f ..\local\docker-compose-gpu.yml up --no-recreate --no-build 
) else (
    echo GPU is not available. Running local docker-compose.yml
    docker-compose.exe -f ..\local\docker-compose.yml up --no-recreate --no-build 
)

REM EOF


