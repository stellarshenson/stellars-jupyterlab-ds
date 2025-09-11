#!/bin/bash
## AWS profile default environment selector 

PROFILE_FILE="$HOME/.profile"
AWS_CONFIG_FILE="$HOME/.aws/config"
AWS_CREDENTIALS_FILE="$HOME/.aws/credentials"

# Function to get AWS profiles
get_aws_profiles() {
    local profiles=()
    
    # Get profiles from config file
    if [[ -f "$AWS_CONFIG_FILE" ]]; then
        profiles+=($(grep "^\[profile " "$AWS_CONFIG_FILE" | sed 's/\[profile \(.*\)\]/\1/'))
    fi
    
    # Get profiles from credentials file
    if [[ -f "$AWS_CREDENTIALS_FILE" ]]; then
        profiles+=($(grep "^\[" "$AWS_CREDENTIALS_FILE" | sed 's/\[\(.*\)\]/\1/'))
    fi
    
    # Remove duplicates and sort
    printf '%s\n' "${profiles[@]}" | sort -u | grep -v "^$"
}

# Function to get current default AWS profile from ~/.profile
get_current_default() {
    if [[ -f "$PROFILE_FILE" ]]; then
        grep "AWS_PROFILE=" "$PROFILE_FILE" | sed 's/.*AWS_PROFILE="\?\([^"]*\)"\?.*/\1/' | head -1
    else
        echo ""
    fi
}

# Function to update ~/.profile with selected AWS profile
update_profile() {
    local selected_profile="$1"
    
    # Backup original file
    if [[ -f "$PROFILE_FILE" ]]; then
        cp "$PROFILE_FILE" "${PROFILE_FILE}.backup"
    fi
    
    # Check if AWS_PROFILE line exists
    if grep -q "AWS_PROFILE=" "$PROFILE_FILE" 2>/dev/null; then
        # Replace existing line
	sed -i "s/^\s*\(export\s\+\)\?AWS_PROFILE\s*=.*/export AWS_PROFILE=\"$selected_profile\"/" "$PROFILE_FILE"
    else
        # Add new line after the comment or at the end
        if grep -q "# set default AWS profile" "$PROFILE_FILE" 2>/dev/null; then
            sed -i "/# set default AWS profile/a export AWS_PROFILE=\"$selected_profile\"" "$PROFILE_FILE"
        else
            echo "# set default AWS profile" >> "$PROFILE_FILE"
            echo "export AWS_PROFILE=\"$selected_profile\"" >> "$PROFILE_FILE"
        fi
    fi
}

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI not found. Ensure AWS CLI is installed and configured."
    exit 1
fi

# Check if AWS configuration exists
if [[ ! -f "$AWS_CONFIG_FILE" && ! -f "$AWS_CREDENTIALS_FILE" ]]; then
    echo "No AWS profiles have been configured."
    echo "Run 'aws configure' to set up your first profile."
    exit 1
fi

# Get list of AWS profiles
mapfile -t PROFILES < <(get_aws_profiles)

if [[ ${#PROFILES[@]} -eq 0 ]]; then
    echo "No AWS profiles have been configured."
    echo "Run 'aws configure' to set up your first profile."
    exit 1
fi

# Check if dialog is available
if ! command -v dialog &> /dev/null; then
    echo "Error: dialog command not found. Install it with:"
    echo "  Ubuntu/Debian: sudo apt install dialog"
    echo "  CentOS/RHEL: sudo yum install dialog"
    exit 1
fi

# Get current default profile
CURRENT_DEFAULT=$(get_current_default)

# Prepare menu options for dialog
MENU_OPTIONS=()
for i in "${!PROFILES[@]}"; do
    profile="${PROFILES[$i]}"
    if [[ "$profile" == "$CURRENT_DEFAULT" ]]; then
        MENU_OPTIONS+=("$((i+1))" "$profile [CURRENT DEFAULT]")
    else
        MENU_OPTIONS+=("$((i+1))" "$profile")
    fi
done

# Display current default if set
if [[ -n "$CURRENT_DEFAULT" ]]; then
    CURRENT_MSG="Current default: $CURRENT_DEFAULT"
else
    CURRENT_MSG="No default AWS profile currently set"
fi

# Show selection dialog
CHOICE=$(dialog --clear --title "AWS Profile Selector" \
                --menu "$CURRENT_MSG\n\nSelect new default AWS profile:" \
                20 60 10 \
                "${MENU_OPTIONS[@]}" \
                2>&1 >/dev/tty)

# Check if user cancelled
if [[ $? -ne 0 ]]; then
    clear
    echo "Operation cancelled by user."
    exit 0
fi

# Get selected profile name
SELECTED_PROFILE="${PROFILES[$((CHOICE-1))]}"

# Confirm selection
if dialog --title "Confirm Selection" \
          --yesno "Set '$SELECTED_PROFILE' as default AWS profile?\n\nThis will update $PROFILE_FILE" 10 60; then
    
    # Update profile
    clear
    update_profile "$SELECTED_PROFILE"
    echo "Default AWS profile set to: $SELECTED_PROFILE"
    echo "Backup saved as: ${PROFILE_FILE}.backup"
    echo ""
    
else
    clear
    echo "Operation cancelled."
fi

# EOF
