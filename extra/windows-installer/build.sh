#!/bin/sh
# builds the windows installer with makensis (NSIS 3), stamping the platform version from pyproject.toml
set -e
cd "$(dirname "$0")"
if ! command -v makensis >/dev/null 2>&1; then
    echo "ERROR: makensis not found - install NSIS 3 (Debian/Ubuntu: sudo apt install nsis)" >&2
    exit 1
fi
VERSION=$(python3 -c 'import tomllib;print(tomllib.load(open("../../pyproject.toml","rb"))["project"]["version"])')
mkdir -p dist
rm -f dist/stellars-jupyterlab-ds-setup-*.exe
makensis -DVERSION="$VERSION" installer.nsi
echo "installer built: dist/stellars-jupyterlab-ds-setup-$VERSION.exe"
