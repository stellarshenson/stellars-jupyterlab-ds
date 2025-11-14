#!/bin/bash
## Installs Anthropic Claude Code Assistant

set -e

# Trap errors and interruptions
trap 'echo -e "\n\033[31mInstallation failed or was interrupted\033[0m"; exit 1' ERR INT TERM

echo "Installing Node.js via conda..."
if ! conda install -y --update-all -n base nodejs; then
    echo -e "\033[31mError: Failed to install Node.js\033[0m"
    exit 1
fi

echo "Installing Claude Code..."
if ! conda run -n base npm install -g @anthropic-ai/claude-code; then
    echo -e "\033[31mError: Failed to install Claude Code\033[0m"
    exit 1
fi

echo "Updating npm packages..."
conda run -n base npm -g update || echo "Warning: npm update encountered issues"

clear
echo -e "\033[32mClaude Code Installation Successful\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Go to your project folder"
echo -e "2. Type '\033[36mclaude\033[0m' to start working with Claude Code"
echo -e "See: https://www.anthropic.com/engineering/claude-code-best-practices"
echo ""

# EOF
