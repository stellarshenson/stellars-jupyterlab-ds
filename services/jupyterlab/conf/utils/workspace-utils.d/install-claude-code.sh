#!/bin/bash
## Installs Claude Code Assistant

conda install -y --update-all -n base nodejs
conda run -n base npm install npm install -g @anthropic-ai/claude-code
conda run -n base npm update

clear
echo "Claude Code Installation Successful
echo "Type \033[32mclaude\033[0m to start"
echo ""
