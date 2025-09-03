#!/bin/bash
## Conda default environment selector 

PROFILE_FILE="$HOME/.profile"
CONDA_CMD=/opt/conda/bin/conda

# Function to get conda environments
get_conda_envs() {
    ${CONDA_CMD} env list | grep -v "^#" | awk '{print $1}' | grep -v "^$" | sort
}

# Function to get current default environment from ~/.profile
get_current_default() {
    if [[ -f "$PROFILE_FILE" ]]; then
        grep "CONDA_DEFAULT_ENV=" "$PROFILE_FILE" | sed 's/.*CONDA_DEFAULT_ENV="\?\([^"]*\)"\?.*/\1/' | head -1
    else
        echo ""
    fi
}

# Function to update ~/.profile with selected environment
update_profile() {
    local selected_env="$1"
    
    # Backup original file
    if [[ -f "$PROFILE_FILE" ]]; then
        cp "$PROFILE_FILE" "${PROFILE_FILE}.backup"
    fi
    
    # Check if CONDA_DEFAULT_ENV line exists
    if grep -q "CONDA_DEFAULT_ENV=" "$PROFILE_FILE" 2>/dev/null; then
        # Replace existing line
        sed -i "s/CONDA_DEFAULT_ENV=.*/CONDA_DEFAULT_ENV=\"$selected_env\"/" "$PROFILE_FILE"
    else
        # Add new line after the comment or at the end
        if grep -q "# set default conda environment" "$PROFILE_FILE" 2>/dev/null; then
            sed -i "/# set default conda environment/a CONDA_DEFAULT_ENV=\"$selected_env\"" "$PROFILE_FILE"
        else
            echo "# set default conda environment" >> "$PROFILE_FILE"
            echo "CONDA_DEFAULT_ENV=\"$selected_env\"" >> "$PROFILE_FILE"
        fi
    fi
}

# Check if conda is available
if ! command -v ${CONDA_CMD} &> /dev/null; then
    dialog --title "Error" --msgbox "conda command not found. Ensure conda is installed and in PATH." 10 50
    exit 1
fi

# Check if dialog is available
if ! command -v dialog &> /dev/null; then
    echo "Error: dialog command not found. Install it with:"
    echo "  Ubuntu/Debian: sudo apt install dialog"
    echo "  CentOS/RHEL: sudo yum install dialog"
    exit 1
fi

# Get list of conda environments
mapfile -t ENVS < <(get_conda_envs)

if [[ ${#ENVS[@]} -eq 0 ]]; then
    dialog --title "Error" --msgbox "No conda environments found." 10 40
    exit 1
fi

# Get current default environment
CURRENT_DEFAULT=$(get_current_default)

# Prepare menu options for dialog
MENU_OPTIONS=()
for i in "${!ENVS[@]}"; do
    env="${ENVS[$i]}"
    if [[ "$env" == "$CURRENT_DEFAULT" ]]; then
        MENU_OPTIONS+=("$((i+1))" "$env [CURRENT DEFAULT]")
    else
        MENU_OPTIONS+=("$((i+1))" "$env")
    fi
done

# Display current default if set
if [[ -n "$CURRENT_DEFAULT" ]]; then
    CURRENT_MSG="Current default: $CURRENT_DEFAULT"
else
    CURRENT_MSG="No default environment currently set"
fi

# Show selection dialog
CHOICE=$(dialog --clear --title "Conda Environment Selector" \
                --menu "$CURRENT_MSG\n\nSelect new default environment:" \
                20 60 10 \
                "${MENU_OPTIONS[@]}" \
                2>&1 >/dev/tty)

# Check if user cancelled
if [[ $? -ne 0 ]]; then
    clear
    echo "Operation cancelled by user."
    exit 0
fi

# Get selected environment name
SELECTED_ENV="${ENVS[$((CHOICE-1))]}"

# Confirm selection
if dialog --title "Confirm Selection" \
          --yesno "Set '$SELECTED_ENV' as default conda environment?\n\nThis will update $PROFILE_FILE" 10 60; then
    
    # Update profile
    clear
    update_profile "$SELECTED_ENV"
    echo "Default conda environment set to: $SELECTED_ENV"
    echo "Backup saved as: ${PROFILE_FILE}.backup"
    
else
    clear
    echo "Operation cancelled."
fi

# EOF
