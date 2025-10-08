#!/bin/bash
## Installs Anthropic Claude Code Assistant

conda install -y --update-all -n base nodejs
conda run -n base npm install -g @anthropic-ai/claude-code && npm -g update

clear
echo -e "\033[32mClaude Code Installation Successful\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Go to your project folder"
echo -e "2. Type '\033[36mclaude\033[0m' to start working with Claude Code"
echo -e "See: https://www.anthropic.com/engineering/claude-code-best-practices"
echo ""

# EOF
