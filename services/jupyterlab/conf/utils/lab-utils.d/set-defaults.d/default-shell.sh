#!/bin/bash
## Default shell selector for JupyterLab terminals

PROFILE_FILE="$HOME/.profile"

# Available shells (only include those installed)
AVAILABLE_SHELLS=()
[[ -x /bin/bash ]] && AVAILABLE_SHELLS+=("bash" "/bin/bash")
[[ -x /usr/bin/fish ]] && AVAILABLE_SHELLS+=("fish" "/usr/bin/fish")

# Function to get current default shell from /etc/passwd
get_current_system_shell() {
    getent passwd "$USER" | cut -d: -f7
}

# Function to get current JupyterLab terminal shell from ~/.profile
get_current_jupyterlab_shell() {
    if [[ -f "$PROFILE_FILE" ]]; then
        grep "JUPYTERLAB_TERMINAL_SHELL=" "$PROFILE_FILE" | sed 's/.*JUPYTERLAB_TERMINAL_SHELL="\?\([^"]*\)"\?.*/\1/' | head -1
    else
        echo ""
    fi
}

# Function to update ~/.profile with selected shell
update_profile() {
    local selected_shell="$1"

    # Backup original file
    if [[ -f "$PROFILE_FILE" ]]; then
        cp "$PROFILE_FILE" "${PROFILE_FILE}.backup"
    else
        touch "$PROFILE_FILE"
    fi

    # Check if JUPYTERLAB_TERMINAL_SHELL line exists
    if grep -q "JUPYTERLAB_TERMINAL_SHELL=" "$PROFILE_FILE" 2>/dev/null; then
        # Replace existing line
        sed -i "s|^\s*\(export\s\+\)\?JUPYTERLAB_TERMINAL_SHELL=.*|export JUPYTERLAB_TERMINAL_SHELL=\"$selected_shell\"|" "$PROFILE_FILE"
    else
        # Add new line after the comment or at the end
        if grep -q "# set default jupyterlab terminal shell" "$PROFILE_FILE" 2>/dev/null; then
            sed -i "/# set default jupyterlab terminal shell/a export JUPYTERLAB_TERMINAL_SHELL=\"$selected_shell\"" "$PROFILE_FILE"
        else
            echo "# set default jupyterlab terminal shell" >> "$PROFILE_FILE"
            echo "export JUPYTERLAB_TERMINAL_SHELL=\"$selected_shell\"" >> "$PROFILE_FILE"
        fi
    fi
}

# Check if dialog is available
if ! command -v dialog &> /dev/null; then
    echo "Error: dialog command not found. Install it with:"
    echo "  Ubuntu/Debian: sudo apt install dialog"
    echo "  CentOS/RHEL: sudo yum install dialog"
    exit 1
fi

# Check if any shells are available
if [[ ${#AVAILABLE_SHELLS[@]} -eq 0 ]]; then
    dialog --title "Error" --msgbox "No supported shells found." 10 40
    exit 1
fi

# Get current settings
CURRENT_SYSTEM_SHELL=$(get_current_system_shell)
CURRENT_JUPYTERLAB_SHELL=$(get_current_jupyterlab_shell)

# Prepare menu options for dialog
MENU_OPTIONS=()
for ((i=0; i<${#AVAILABLE_SHELLS[@]}; i+=2)); do
    shell_name="${AVAILABLE_SHELLS[$i]}"
    shell_path="${AVAILABLE_SHELLS[$i+1]}"

    menu_num=$((i/2 + 1))

    label="$shell_name ($shell_path)"
    if [[ "$shell_path" == "$CURRENT_JUPYTERLAB_SHELL" ]]; then
        label="$label [CURRENT JUPYTERLAB]"
    fi
    if [[ "$shell_path" == "$CURRENT_SYSTEM_SHELL" ]]; then
        label="$label [SYSTEM DEFAULT]"
    fi

    MENU_OPTIONS+=("$menu_num" "$label")
done

# Display current defaults
if [[ -n "$CURRENT_JUPYTERLAB_SHELL" ]]; then
    CURRENT_MSG="Current JupyterLab shell: $CURRENT_JUPYTERLAB_SHELL\nSystem default: $CURRENT_SYSTEM_SHELL"
else
    CURRENT_MSG="Current JupyterLab shell: Not set (using system default)\nSystem default: $CURRENT_SYSTEM_SHELL"
fi

# Show selection dialog
CHOICE=$(dialog --clear --title "Default Shell Selector" \
                --menu "$CURRENT_MSG\n\nSelect default shell for JupyterLab terminals:" \
                20 70 10 \
                "${MENU_OPTIONS[@]}" \
                2>&1 >/dev/tty)

# Check if user cancelled
if [[ $? -ne 0 ]]; then
    clear
    echo "Operation cancelled by user."
    exit 0
fi

# Get selected shell path
SELECTED_SHELL="${AVAILABLE_SHELLS[$((CHOICE*2-1))]}"

# Confirm selection
if dialog --title "Confirm Selection" \
          --yesno "Set '$SELECTED_SHELL' as default JupyterLab terminal shell?\n\nThis will update $PROFILE_FILE\n\nNote: You need to restart JupyterLab for changes to take effect." 12 70; then

    # Update profile
    clear
    update_profile "$SELECTED_SHELL"
    echo "Default JupyterLab terminal shell set to: $SELECTED_SHELL"
    echo "Backup saved as: ${PROFILE_FILE}.backup"
    echo ""
    echo "IMPORTANT: Restart JupyterLab for changes to take effect."

else
    clear
    echo "Operation cancelled."
fi

# EOF
