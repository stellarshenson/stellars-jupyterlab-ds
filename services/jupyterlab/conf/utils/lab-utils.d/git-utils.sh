#!/bin/bash
## Git Utils (pull, push, commit repos and submodules)

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/git-utils.d"

# Function to extract description from script
get_script_description() {
    local script_file="$1"
    local description=""

    # Look for line starting with ## and extract description
    description=$(grep "^##" "$script_file" 2>/dev/null | head -1 | sed 's/^##[[:space:]]*//' || echo "")

    if [[ -z "$description" ]]; then
        description="No description available"
    fi

    echo "$description"
}

# Function to get executable scripts with descriptions
get_scripts() {
    local scripts=()
    local descriptions=()

    # Find all .sh files in the scripts directory
    if [[ ! -d "$SCRIPTS_DIR" ]]; then
        echo "Error: Scripts directory $SCRIPTS_DIR not found."
        exit 1
    fi

    for script in "$SCRIPTS_DIR"/*.sh; do
        # Check if file exists and is executable
        if [[ -f "$script" && -x "$script" ]]; then
            local basename_script=$(basename "$script")
            local description=$(get_script_description "$script")

            scripts+=("$basename_script")
            descriptions+=("$description")
        fi
    done

    # Output in format: filename|description
    for i in "${!scripts[@]}"; do
        echo "${scripts[$i]}|${descriptions[$i]}"
    done
}

# Check if dialog is available
if ! command -v dialog &> /dev/null; then
    echo "Error: dialog command not found. Install it with:"
    echo "  Ubuntu/Debian: sudo apt install dialog"
    echo "  CentOS/RHEL: sudo yum install dialog"
    exit 1
fi

# Get available scripts
mapfile -t SCRIPT_DATA < <(get_scripts)

if [[ ${#SCRIPT_DATA[@]} -eq 0 ]]; then
    dialog --title "Error" --msgbox "No executable .sh scripts found in $SCRIPTS_DIR" 10 50
    clear
    echo "No scripts available for execution."
    exit 1
fi

# Build menu options for dialog
MENU_OPTIONS=()

for i in "${!SCRIPT_DATA[@]}"; do
    # Split script name and description
    IFS='|' read -r script_name description <<< "${SCRIPT_DATA[$i]}"

    # Use script name as key and description as value
    MENU_OPTIONS+=("$script_name" "$description")
done

# Show selection dialog
TEMPFILE=$(mktemp)
dialog --clear --title "Git Utils" \
	--menu "Select git utility to execute:" \
	20 120 10 \
	"${MENU_OPTIONS[@]}" \
	2>$TEMPFILE >/dev/tty || {

    clear
    exit 0
}

# save up response and clean up the screen
CHOICE=$(cat $TEMPFILE)
rm $TEMPFILE
clear

# Execute the selected script
echo "Executing: ${SCRIPTS_DIR}/$CHOICE"
"${SCRIPTS_DIR}/$CHOICE"

# EOF
