#!/bin/bash
## Installs additional conda environments

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/install-conda-env.d"
CONDA_ENV_DIR="/opt/utils/conda-env.d"
USER_CONDA_ENV_DIR="/home/lab/.local/conda-env.d"

# Function to extract description from file (works for both .sh and .yml)
get_file_description() {
    local file="$1"
    local description=""

    # Look for line starting with ## and extract description
    description=$(grep "^##" "$file" 2>/dev/null | head -1 | sed 's/^##[[:space:]]*//' || echo "")

    if [[ -z "$description" ]]; then
        description="No description available"
    fi

    echo "$description"
}

# Function to get all installable items (scripts and yml files)
get_items() {
    local items=()

    # 1. Find all .sh files in the scripts directory
    if [[ -d "$SCRIPTS_DIR" ]]; then
        for script in "$SCRIPTS_DIR"/*.sh; do
            # Check if file exists and is executable
            if [[ -f "$script" && -x "$script" ]]; then
                local basename_item=$(basename "$script")
                local description=$(get_file_description "$script")
                # Output format: fullpath|basename|description|type
                echo "$script|$basename_item|$description|script"
            fi
        done
    fi

    # 2. Find all .yml and .sh files in conda-env.d
    if [[ -d "$CONDA_ENV_DIR" ]]; then
        # 2a. YAML files
        for yml in "$CONDA_ENV_DIR"/*.yml; do
            if [[ -f "$yml" ]]; then
                local basename_item=$(basename "$yml")
                local description=$(get_file_description "$yml")
                echo "$yml|$basename_item|$description|env"
            fi
        done

        # 2b. Shell scripts
        for script in "$CONDA_ENV_DIR"/*.sh; do
            if [[ -f "$script" && -x "$script" ]]; then
                local basename_item=$(basename "$script")
                local description=$(get_file_description "$script")
                echo "$script|$basename_item|$description|script"
            fi
        done
    fi

    # 3. Find all .yml and .sh files in user's local conda-env.d
    if [[ -d "$USER_CONDA_ENV_DIR" ]]; then
        # 3a. YAML files
        for yml in "$USER_CONDA_ENV_DIR"/*.yml; do
            if [[ -f "$yml" ]]; then
                local basename_item=$(basename "$yml")
                local description=$(get_file_description "$yml")
                echo "$yml|$basename_item (user)|$description|env"
            fi
        done

        # 3b. Shell scripts
        for script in "$USER_CONDA_ENV_DIR"/*.sh; do
            if [[ -f "$script" && -x "$script" ]]; then
                local basename_item=$(basename "$script")
                local description=$(get_file_description "$script")
                echo "$script|$basename_item (user)|$description|script"
            fi
        done
    fi
}

# Check if dialog is available
if ! command -v dialog &> /dev/null; then
    echo "Error: dialog command not found. Install it with:"
    echo "  Ubuntu/Debian: sudo apt install dialog"
    echo "  CentOS/RHEL: sudo yum install dialog"
    exit 1
fi

# Get available items
mapfile -t ITEM_DATA < <(get_items)

if [[ ${#ITEM_DATA[@]} -eq 0 ]]; then
    dialog --title "Error" --msgbox "No installation scripts or environment files found" 10 50
    clear
    echo "No items available for installation."
    exit 1
fi

# Build menu options for dialog
MENU_OPTIONS=()
declare -A ITEM_MAP

for i in "${!ITEM_DATA[@]}"; do
    # Split: fullpath|basename|description|type
    IFS='|' read -r fullpath basename description type <<< "${ITEM_DATA[$i]}"

    # Store mapping of basename to full data
    ITEM_MAP["$basename"]="$fullpath|$type"

    # Use basename as key and description as value
    MENU_OPTIONS+=("$basename" "$description")
done

# Show selection dialog
TEMPFILE=$(mktemp)
dialog --clear --title "Install Conda Environment" \
	--menu "Select conda environment to install:" \
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

# Get the full path and type for the selected item
IFS='|' read -r fullpath type <<< "${ITEM_MAP[$CHOICE]}"

# Execute based on type
if [[ "$type" == "script" ]]; then
    echo "Executing: $fullpath"
    "$fullpath"
    # Script handles its own announcement with proper environment name

elif [[ "$type" == "env" ]]; then
    # Extract environment name from yml file
    ENV_NAME=$(grep "^name:" "$fullpath" | head -1 | sed 's/^name:[[:space:]]*//' || echo "")

    if [[ -z "$ENV_NAME" ]]; then
        echo "Error: Could not extract environment name from $fullpath"
        exit 1
    fi

    echo "Installing conda environment: $ENV_NAME"
    echo "Using environment file: $fullpath"

    # Check if environment already exists
    if conda env list | grep -q "^${ENV_NAME} "; then
        echo "Environment $ENV_NAME already exists. Updating..."
        conda env update -n "$ENV_NAME" -f "$fullpath"
    else
        echo "Creating new environment $ENV_NAME..."
        conda env create -f "$fullpath"
    fi

    # Announce completion for yml-based installation
    clear
    echo -e "\033[32mConda Environment Installation Successful\033[0m"
    echo ""
    echo -e "Environment: \033[1;34m$ENV_NAME\033[0m"
    echo ""
    echo -e "Typical Usage:"
    echo -e "1. Activate the environment: '\033[1;34mconda activate $ENV_NAME\033[0m'"
    echo -e "2. The environment will be available as a Jupyter kernel (if ipykernel is installed)"
    echo ""

else
    echo "Error: Unknown item type: $type"
    exit 1
fi

# EOF
