#!/bin/bash
## Installs Google Gemini CLI Assistant

set -e

# Trap errors and interruptions
trap 'echo -e "\n\033[31mInstallation failed or was interrupted\033[0m"; exit 1' ERR INT TERM

echo "Installing Node.js via conda..."
if ! conda install -y --update-all -n base nodejs; then
    echo -e "\033[31mError: Failed to install Node.js\033[0m"
    exit 1
fi

echo "Installing Google Gemini CLI..."
if ! conda run -n base npm install -g @google/gemini-cli; then
    echo -e "\033[31mError: Failed to install Gemini CLI\033[0m"
    exit 1
fi

echo "Updating npm packages..."
conda run -n base npm -g update || echo "Warning: npm update encountered issues"

clear
echo -e "\033[32mGoogle Gemini CLI Installation Successful\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Set your API key: \033[36mexport GOOGLE_API_KEY='your-api-key'\033[0m"
echo -e "2. Go to your project folder"
echo -e "3. Type '\033[36mgemini\033[0m' to start working with Gemini"
echo -e "Get API key: https://aistudio.google.com/app/apikey"
echo ""

# EOF
