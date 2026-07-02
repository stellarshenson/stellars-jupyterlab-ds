#!/bin/sh
# builds the linux all-in-one installer: version-stamped self-extracting sh with the deployment files as payload
set -e
cd "$(dirname "$0")"
VERSION=$(python3 -c 'import tomllib;print(tomllib.load(open("../../pyproject.toml","rb"))["project"]["version"])')
mkdir -p dist
rm -f dist/stellars-jupyterlab-ds-setup-*.sh
OUT="dist/stellars-jupyterlab-ds-setup-$VERSION.sh"
sed "s/@VERSION@/$VERSION/" installer.sh.in > "$OUT"
tar czf - -C ../.. compose.yml compose-gpu.yml .env.default start.sh stop.sh LICENSE >> "$OUT"
chmod +x "$OUT"
echo "installer built: $OUT"
