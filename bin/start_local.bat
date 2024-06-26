@echo off
REM Check if GPU is available
powershell -Command "if ((Get-WmiObject Win32_VideoController | Where-Object { $_.Name -ne $null }).Count -gt 0) { exit 0 } else { exit 1 }"

REM Capture the exit code
set gpu_available=%errorlevel%

REM Execute commands based on GPU availability
if %gpu_available% equ 0 (
    echo GPU is available. Running local docker-compose.yml
    docker-compose.exe -f ..\local\docker-compose-nvidia.yml up --no-recreate --no-build 
) else (
    echo GPU is not available. Running local docker-compose-nvidia.yml
    docker-compose.exe -f ..\local\docker-compose.yml up --no-recreate --no-build 
)

REM EOF


