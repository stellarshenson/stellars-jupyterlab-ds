#!/bin/bash
## Installs Claude Code Assistant

conda install -y --update-all -n base nodejs
conda run -n base npm install npm install -g @anthropic-ai/claude-code
conda run -n base npm update

echo "Claude Code Installation Success, type `claude` to start"
