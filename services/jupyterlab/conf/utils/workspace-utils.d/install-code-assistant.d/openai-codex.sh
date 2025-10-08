#!/bin/bash
## Installs OpenAI Codex Code Assistant

conda install -y --update-all -n base nodejs
conda run -n base npm install -g @openai/codex && npm -g update

clear
echo -e "\033[32mOpenAI Codex Installation Successful\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Go to your project folder"
echo -e "2. Type '\033[36mcodex\033[0m' to start working with OpenAI Codex"
echo -e "See: https://developers.openai.com/codex/quickstart"
echo ""

# EOF
