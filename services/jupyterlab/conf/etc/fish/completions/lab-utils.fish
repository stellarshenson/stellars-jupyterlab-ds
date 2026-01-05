# Fish completions for lab-utils

# Disable file completions
complete -c lab-utils -f

# Options
complete -c lab-utils -s h -l help -d "Show help message"
complete -c lab-utils -s l -l list -d "List available scripts"
complete -c lab-utils -l json -d "List scripts as JSON"
complete -c lab-utils -l create-local -d "Create local scripts directory"

# Dynamic script completions (top-level and nested)
# Uses select(.path) instead of select(.path != null) to avoid shell escaping issues
complete -c lab-utils -n "not __fish_seen_subcommand_from --help -h --list -l --json --create-local" \
    -a "(lab-utils --json 2>/dev/null | jq -r '(.global.scripts[] | select(.path) | .name), (.local.scripts[] | select(.path) | .name)' 2>/dev/null)"
