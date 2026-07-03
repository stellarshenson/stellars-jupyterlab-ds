#!/bin/sh
# builds the windows installer with makensis (NSIS 3), stamping the platform version from pyproject.toml
# output goes to the repo-root dist/ folder (gitignored)
set -e
cd "$(dirname "$0")"
if ! command -v makensis >/dev/null 2>&1; then
    echo "WARNING: makensis not found - skipping Windows installer build (install NSIS 3: sudo apt install nsis)" >&2
    exit 0
fi
VERSION=$(python3 -c 'import tomllib;print(tomllib.load(open("../../pyproject.toml","rb"))["project"]["version"])')
mkdir -p ../../dist
rm -f ../../dist/stellars-jupyterlab-ds-setup-*.exe
makensis -DVERSION="$VERSION" installer.nsi
GREEN=$(tput setaf 2 2>/dev/null || true); BOLD=$(tput bold 2>/dev/null || true); RESET=$(tput sgr0 2>/dev/null || true)
printf 'installer built: %s%sdist/stellars-jupyterlab-ds-setup-%s.exe%s\n' "$GREEN" "$BOLD" "$VERSION" "$RESET"
