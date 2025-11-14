#!/bin/bash
## Installs Anysphere Cursor AI Assistant

set -e

# Trap errors and interruptions
trap 'echo -e "\n\033[31mInstallation failed or was interrupted\033[0m"; exit 1' ERR INT TERM

echo "Installing Node.js via conda..."
if ! conda install -y --update-all -n base nodejs; then
    echo -e "\033[31mError: Failed to install Node.js\033[0m"
    exit 1
fi

echo "Installing Cursor..."
if ! conda run -n base bash -c "curl https://cursor.com/install -fsS | bash"; then
    echo -e "\033[31mError: Failed to install Cursor\033[0m"
    exit 1
fi

clear
echo -e "\033[32mAnysphere Cursor Installation Successful\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Go to your project folder"
echo -e "2. Type '\033[36mcursor-agent\033[0m' to start working with Cursor"
echo -e "See: https://cursor.com/cli"
echo ""

# EOF
