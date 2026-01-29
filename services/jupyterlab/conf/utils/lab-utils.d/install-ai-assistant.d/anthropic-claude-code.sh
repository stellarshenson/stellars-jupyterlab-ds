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

# Install statusline config if user doesn't have one
STATUSLINE_SRC="/opt/utils/lab-utils.lib/claude-statusline-command.sh"
CLAUDE_DIR="$HOME/.claude"
STATUSLINE_DEST="$CLAUDE_DIR/statusline-command.sh"

if [[ -f "$STATUSLINE_SRC" ]] && [[ ! -f "$STATUSLINE_DEST" ]]; then
    echo "Installing Claude statusline config..."
    mkdir -p "$CLAUDE_DIR"
    cp "$STATUSLINE_SRC" "$STATUSLINE_DEST"
    chmod +x "$STATUSLINE_DEST"
    echo -e "\033[32mStatusline config installed to $STATUSLINE_DEST\033[0m"
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
