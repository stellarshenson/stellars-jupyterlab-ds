#!/bin/bash
## Installs cloudflared (Cloudflare Tunnel client) to ~/.local/bin (user-local,
## no sudo, persists across container restarts like the Docker CLI install)

set -e

# Trap errors and interruptions
trap 'echo -e "\n\033[31mInstallation failed or was interrupted\033[0m"; exit 1' ERR INT TERM

INSTALL_BIN="$HOME/.local/bin/cloudflared"
RELEASE_BASE="https://github.com/cloudflare/cloudflared/releases/latest/download"

# Map uname arch to cloudflared release asset suffix
detect_architecture() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7l)  echo "arm" ;;
        i386|i686) echo "386" ;;
        *)
            echo "ERROR: Unsupported architecture: $arch" >&2
            return 1
            ;;
    esac
}

echo "Installing cloudflared..."

# Report existing install (binary gets overwritten with latest below)
if [[ -f "$INSTALL_BIN" ]]; then
    installed_version=$("$INSTALL_BIN" --version 2>/dev/null | grep -oP 'version \K[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    echo "cloudflared already installed: $installed_version"
    echo "Upgrading to latest version..."
fi

arch=$(detect_architecture)
[[ $? -ne 0 ]] && exit 1
echo "Architecture: $arch"

download_url="${RELEASE_BASE}/cloudflared-linux-${arch}"
temp_file=$(mktemp)

echo "Downloading cloudflared (latest)..."
if ! curl -fsSL -o "$temp_file" "$download_url"; then
    echo "ERROR: Failed to download cloudflared" >&2
    rm -f "$temp_file"
    exit 1
fi

# Install user-local (no sudo needed)
mkdir -p "$HOME/.local/bin"
install -m 0755 "$temp_file" "$INSTALL_BIN"
rm -f "$temp_file"

clear
echo -e "\033[32mcloudflared Installation Successful\033[0m"
echo ""
echo -e "Version: \033[1;34m$("$INSTALL_BIN" --version)\033[0m"
echo -e "Binary: \033[1;34m~/.local/bin/cloudflared\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Authenticate: '\033[36mcloudflared tunnel login\033[0m'"
echo -e "2. Create a tunnel: '\033[36mcloudflared tunnel create <name>\033[0m'"
echo -e "3. Run a quick tunnel: '\033[36mcloudflared tunnel --url http://localhost:8888\033[0m'"
echo -e "See: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/"
echo ""

# EOF
