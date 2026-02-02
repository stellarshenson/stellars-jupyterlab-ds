#!/bin/bash
## Installs Anthropic Claude Code Assistant

set -e

# Trap errors and interruptions
trap 'echo -e "\n\033[31mInstallation failed or was interrupted\033[0m"; exit 1' ERR INT TERM

echo "Installing Claude Code via native installer..."
if ! curl -fsSL https://claude.ai/install.sh | bash; then
    echo -e "\033[31mError: Failed to install Claude Code\033[0m"
    exit 1
fi

# Install default config files if user doesn't have them
CLAUDE_SRC="/opt/utils/lab-utils.lib/claude"
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

# Copy settings.json if not present
if [[ -f "$CLAUDE_SRC/settings.json" ]] && [[ ! -f "$CLAUDE_DIR/settings.json" ]]; then
    cp "$CLAUDE_SRC/settings.json" "$CLAUDE_DIR/settings.json"
    echo "Installed default settings.json"
fi

# Copy statusline-command.sh if not present
if [[ -f "$CLAUDE_SRC/statusline-command.sh" ]] && [[ ! -f "$CLAUDE_DIR/statusline-command.sh" ]]; then
    cp "$CLAUDE_SRC/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
    chmod +x "$CLAUDE_DIR/statusline-command.sh"
    echo "Installed statusline-command.sh"
fi

clear
echo -e "\033[32mClaude Code Installation Successful\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Go to your project folder"
echo -e "2. Type '\033[36mclaude\033[0m' to start working with Claude Code"
echo -e "See: https://www.anthropic.com/engineering/claude-code-best-practices"
echo ""

# EOF
