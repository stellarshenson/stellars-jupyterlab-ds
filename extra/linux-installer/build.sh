#!/bin/sh
# builds the linux all-in-one installer: version-stamped self-extracting sh with the deployment files as payload
# output goes to the repo-root dist/ folder (gitignored)
set -e
cd "$(dirname "$0")"
VERSION=$(python3 -c 'import tomllib;print(tomllib.load(open("../../pyproject.toml","rb"))["project"]["version"])')
mkdir -p ../../dist
rm -f ../../dist/stellars-jupyterlab-ds-setup-*.sh
OUT="../../dist/stellars-jupyterlab-ds-setup-$VERSION.sh"
sed "s/@VERSION@/$VERSION/" installer.sh.in > "$OUT"
tar czf - -C ../.. compose.yml compose-gpu.yml .env.default start.sh stop.sh LICENSE >> "$OUT"
chmod +x "$OUT"
GREEN=$(tput setaf 2 2>/dev/null || true); BOLD=$(tput bold 2>/dev/null || true); RESET=$(tput sgr0 2>/dev/null || true)
printf 'installer built: %s%sdist/stellars-jupyterlab-ds-setup-%s.sh%s\n' "$GREEN" "$BOLD" "$VERSION" "$RESET"
