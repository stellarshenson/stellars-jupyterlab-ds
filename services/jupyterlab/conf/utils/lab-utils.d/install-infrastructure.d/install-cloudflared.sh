#!/bin/bash
## Installs cloudflared (Cloudflare Tunnel client) from Cloudflare's apt repository

set -e

# Trap errors and interruptions
trap 'echo -e "\n\033[31mInstallation failed or was interrupted\033[0m"; exit 1' ERR INT TERM

keyring="/usr/share/keyrings/cloudflare-main.gpg"
sources_list="/etc/apt/sources.list.d/cloudflared.list"

echo "Adding Cloudflare GPG key..."
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee "$keyring" >/dev/null

echo "Adding Cloudflare apt repository..."
echo "deb [signed-by=${keyring}] https://pkg.cloudflare.com/cloudflared any main" | sudo tee "$sources_list" >/dev/null

echo "Installing cloudflared..."
sudo apt-get update
sudo apt-get install -y cloudflared

clear
echo -e "\033[32mcloudflared Installation Successful\033[0m"
echo ""
echo -e "Version: \033[1;34m$(cloudflared --version)\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Authenticate: '\033[36mcloudflared tunnel login\033[0m'"
echo -e "2. Create a tunnel: '\033[36mcloudflared tunnel create <name>\033[0m'"
echo -e "3. Run a quick tunnel: '\033[36mcloudflared tunnel --url http://localhost:8888\033[0m'"
echo -e "See: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/"
echo ""

# EOF
