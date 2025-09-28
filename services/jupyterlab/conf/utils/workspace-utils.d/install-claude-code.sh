#!/bin/bash
## Installs Claude Code Assistant

conda install -y --update-all -n base nodejs
conda run -n base npm install npm install -g @anthropic-ai/claude-code && npm -g update

clear
echo -e "\033[32mClaude Code Installation Successful\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Enter your project repository inside the workspace"
echo -e "2. Type '\033[36mclaude\033[0m' to start working with Claude Code"
echo ""

# EOF
