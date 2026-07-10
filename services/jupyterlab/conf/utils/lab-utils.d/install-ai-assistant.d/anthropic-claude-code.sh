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

# Install the mdstamp timestamp-cadence hook scripts if the user doesn't have them
mkdir -p "$CLAUDE_DIR/bin" "$CLAUDE_DIR/.mdstamp"
for f in mdstamp mdstamp-hook; do
    if [[ -f "$CLAUDE_SRC/bin/$f" ]] && [[ ! -f "$CLAUDE_DIR/bin/$f" ]]; then
        cp "$CLAUDE_SRC/bin/$f" "$CLAUDE_DIR/bin/$f"
        chmod +x "$CLAUDE_DIR/bin/$f"
        echo "Installed bin/$f"
    fi
done

# Wire the mdstamp UserPromptSubmit hook into settings.json. jq-merge (not copy)
# so it reaches users who already have a settings.json; the presence check keeps
# it idempotent - never a duplicate on re-run. New users are covered too: their
# settings.json was seeded above, or is created empty here.
HOOK_CMD="/home/lab/.claude/bin/mdstamp-hook"
[[ -f "$CLAUDE_DIR/settings.json" ]] || echo '{}' > "$CLAUDE_DIR/settings.json"
if command -v jq >/dev/null 2>&1 \
   && ! jq -e --arg c "$HOOK_CMD" 'any(.hooks.UserPromptSubmit[]?.hooks[]?; .command == $c)' "$CLAUDE_DIR/settings.json" >/dev/null 2>&1; then
    tmp="$(mktemp)"
    if jq --arg c "$HOOK_CMD" '.hooks.UserPromptSubmit = ((.hooks.UserPromptSubmit // []) + [{hooks: [{type: "command", command: $c, timeout: 5}]}])' "$CLAUDE_DIR/settings.json" > "$tmp"; then
        mv "$tmp" "$CLAUDE_DIR/settings.json"
        echo "Wired mdstamp UserPromptSubmit hook into settings.json"
    else
        rm -f "$tmp"
        echo "Warning: could not merge mdstamp hook into settings.json"
    fi
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
