#!/bin/bash
## Installs OpenAI Codex Code Assistant

set -e

# Trap errors and interruptions
trap 'echo -e "\n\033[31mInstallation failed or was interrupted\033[0m"; exit 1' ERR INT TERM

echo "Installing Node.js via conda..."
if ! conda install -y --update-all -n base nodejs; then
    echo -e "\033[31mError: Failed to install Node.js\033[0m"
    exit 1
fi

echo "Installing OpenAI Codex..."
if ! conda run -n base npm install -g @openai/codex; then
    echo -e "\033[31mError: Failed to install OpenAI Codex\033[0m"
    exit 1
fi

echo "Updating npm packages..."
conda run -n base npm -g update || echo "Warning: npm update encountered issues"

clear
echo -e "\033[32mOpenAI Codex Installation Successful\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Go to your project folder"
echo -e "2. Type '\033[36mcodex\033[0m' to start working with OpenAI Codex"
echo -e "See: https://developers.openai.com/codex/quickstart"
echo ""

# EOF
