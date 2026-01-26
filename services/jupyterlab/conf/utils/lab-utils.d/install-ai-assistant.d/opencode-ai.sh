#!/bin/bash
## Installs OpenCode AI Assistant

set -e

# Trap errors and interruptions
trap 'echo -e "\n\033[31mInstallation failed or was interrupted\033[0m"; exit 1' ERR INT TERM

echo "Installing OpenCode via native installer..."
if ! curl -fsSL https://opencode.ai/install | bash; then
    echo -e "\033[31mError: Failed to install OpenCode\033[0m"
    exit 1
fi

clear
echo -e "\033[32mOpenCode Installation Successful\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Go to your project folder"
echo -e "2. Type '\033[36mopencode\033[0m' to start working with OpenCode"
echo -e "See: https://opencode.ai/"
echo ""

# EOF
