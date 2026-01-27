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

# Symlink to ~/.local/bin for PATH access
if [[ -f "$HOME/.opencode/bin/opencode" ]]; then
    mkdir -p "$HOME/.local/bin"
    rm -f "$HOME/.local/bin/opencode"
    ln -s "$HOME/.opencode/bin/opencode" "$HOME/.local/bin/opencode"
    echo "Symlinked to ~/.local/bin/opencode"
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
