@echo off
REM stamp the duoptimum-lab-utils wheel with the platform version from pyproject.toml
for /f %%v in ('python -c "import tomllib;print(tomllib.load(open('../pyproject.toml','rb'))['project']['version'])"') do set PKG_VERSION=%%v
if not exist "..\.env" type nul > "..\.env"
docker.exe compose --env-file ..\.env.default --env-file ..\.env -f ..\compose.yml build
