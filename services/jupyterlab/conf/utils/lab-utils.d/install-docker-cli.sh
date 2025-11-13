#!/bin/bash
## Installs Docker CLI to /opt/docker

set -e

DOCKER_INSTALL_DIR="/opt/docker"
DOCKER_BASE_URL="https://download.docker.com/linux/static/stable"

# Detect system architecture
detect_architecture() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64) echo "x86_64" ;;
        aarch64) echo "aarch64" ;;
        armv7l) echo "armhf" ;;
        armv6l) echo "armel" ;;
        ppc64le) echo "ppc64le" ;;
        s390x) echo "s390x" ;;
        *)
            echo "ERROR: Unsupported architecture: $arch" >&2
            return 1
            ;;
    esac
}

# Get latest Docker version
get_latest_version() {
    local arch=$1
    local url="${DOCKER_BASE_URL}/${arch}/"

    echo "Fetching latest Docker CLI version for ${arch}..." >&2

    local version=$(curl -fsSL "$url" | \
        grep -oP 'docker-\K[0-9]+\.[0-9]+\.[0-9]+(?=\.tgz)' | \
        sort -V | \
        tail -1)

    if [[ -z "$version" ]]; then
        echo "ERROR: Could not determine latest Docker version" >&2
        return 1
    fi

    echo "$version"
}

# Main installation
echo "Installing Docker CLI..."

# Check if already installed
if [[ -f "${DOCKER_INSTALL_DIR}/docker" ]]; then
    installed_version=$(${DOCKER_INSTALL_DIR}/docker --version 2>/dev/null | grep -oP 'version \K[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    echo "Docker CLI already installed: $installed_version"
    read -p "Reinstall/upgrade? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
fi

# Detect architecture and get latest version
arch=$(detect_architecture)
[[ $? -ne 0 ]] && exit 1

version=$(get_latest_version "$arch")
[[ $? -ne 0 ]] && exit 1

echo "Latest version: $version"
echo "Architecture: $arch"

# Download and extract
download_url="${DOCKER_BASE_URL}/${arch}/docker-${version}.tgz"
temp_dir=$(mktemp -d)
temp_file="${temp_dir}/docker.tgz"

echo "Downloading Docker CLI..."
if ! curl -fsSL -o "$temp_file" "$download_url"; then
    echo "ERROR: Failed to download Docker CLI" >&2
    rm -rf "$temp_dir"
    exit 1
fi

echo "Extracting Docker CLI..."
temp_extract=$(mktemp -d)
if ! tar -xzf "$temp_file" -C "$temp_extract"; then
    echo "ERROR: Failed to extract archive" >&2
    rm -rf "$temp_dir" "$temp_extract"
    exit 1
fi

# Install Docker CLI
echo "Installing to ${DOCKER_INSTALL_DIR}..."
sudo mkdir -p "$DOCKER_INSTALL_DIR"
if ! sudo cp -r "$temp_extract/docker/"* "$DOCKER_INSTALL_DIR/"; then
    echo "ERROR: Failed to install binaries" >&2
    rm -rf "$temp_dir" "$temp_extract"
    exit 1
fi

# Install plugins from /opt/extra/docker-cli-plugins if available
plugins_source="/opt/extra/docker-cli-plugins"
if [[ -d "$plugins_source" ]] && [[ -n "$(ls -A $plugins_source 2>/dev/null)" ]]; then
    echo "Installing Docker CLI plugins..."
    plugins_dir="${DOCKER_INSTALL_DIR}/cli-plugins"
    sudo mkdir -p "$plugins_dir"
    if sudo cp -r "$plugins_source/"* "$plugins_dir/"; then
        sudo chmod +x "$plugins_dir/"*
        echo "Plugins installed to ${plugins_dir}"
    else
        echo "WARNING: Failed to copy plugins" >&2
    fi
fi

# Copy plugins to user directory for Docker plugin discovery
# Docker looks for plugins in ~/.docker/cli-plugins/ by default
user_plugin_dir="$HOME/.docker/cli-plugins"
if [[ -d "${DOCKER_INSTALL_DIR}/cli-plugins" ]] && [[ -n "$(ls -A ${DOCKER_INSTALL_DIR}/cli-plugins 2>/dev/null)" ]]; then
    echo "Setting up user plugin directory..."
    mkdir -p "$user_plugin_dir"
    cp -f "${DOCKER_INSTALL_DIR}/cli-plugins/"* "$user_plugin_dir/"
    chmod +x "$user_plugin_dir/"*
    echo "Plugins copied to ${user_plugin_dir}"
fi

# Cleanup
rm -rf "$temp_dir" "$temp_extract"

# Success announcement
if [[ -f "${DOCKER_INSTALL_DIR}/docker" ]]; then
    final_version=$(${DOCKER_INSTALL_DIR}/docker --version)

    clear
    echo -e "\033[32mDocker CLI Installation Successful\033[0m"
    echo ""
    echo -e "Version: \033[1;34m$final_version\033[0m"

    # List installed plugins using docker's plugin discovery
    if [[ -d "${DOCKER_INSTALL_DIR}/cli-plugins" ]] && [[ -n "$(ls -A ${DOCKER_INSTALL_DIR}/cli-plugins 2>/dev/null)" ]]; then
        plugins=$(ls ${DOCKER_INSTALL_DIR}/cli-plugins | sed 's/docker-//' | tr '\n' ', ' | sed 's/,$//')
        echo -e "Plugins: \033[1;34m${plugins}\033[0m"
    fi

    echo ""
    echo -e "Typical Usage:"
    echo -e "1. Use Docker socket: '\033[1;34mexport DOCKER_HOST=unix:///var/run/docker.sock\033[0m'"
    echo -e "2. Connect to remote Docker: '\033[1;34mexport DOCKER_HOST=tcp://hostname:2375\033[0m'"

    # Show plugin usage if installed
    if [[ -f "${DOCKER_INSTALL_DIR}/cli-plugins/docker-buildx" ]]; then
        echo -e "3. Build multi-platform images: '\033[1;34mdocker buildx build\033[0m'"
    fi
    if [[ -f "${DOCKER_INSTALL_DIR}/cli-plugins/docker-mcp" ]]; then
        echo -e "4. Use MCP plugin: '\033[1;34mdocker mcp <command>\033[0m'"
    fi

    echo ""
    echo -e "Note: Docker daemon not installed (CLI only)"
    echo -e "Socket access requires proper permissions"
    echo ""
else
    echo "ERROR: Installation failed" >&2
    exit 1
fi

# EOF
