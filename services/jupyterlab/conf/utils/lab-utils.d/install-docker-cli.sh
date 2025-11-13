#!/bin/bash
## Installs Docker CLI to /opt/docker

set -e

DOCKER_INSTALL_DIR="/opt/docker"
DOCKER_BASE_URL="https://download.docker.com/linux/static/stable"

# Detect system architecture
detect_architecture() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64)
            echo "x86_64"
            ;;
        aarch64)
            echo "aarch64"
            ;;
        armv7l)
            echo "armhf"
            ;;
        armv6l)
            echo "armel"
            ;;
        ppc64le)
            echo "ppc64le"
            ;;
        s390x)
            echo "s390x"
            ;;
        *)
            echo "ERROR: Unsupported architecture: $arch" >&2
            return 1
            ;;
    esac
}

# Get latest Docker version from download server
get_latest_version() {
    local arch=$1
    local url="${DOCKER_BASE_URL}/${arch}/"

    echo "Fetching latest Docker CLI version for ${arch}..." >&2

    # Download index page and extract version numbers
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

# Main installation logic
main() {
    echo "=================================="
    echo "Docker CLI Installation"
    echo "=================================="
    echo ""

    # Detect architecture
    local arch=$(detect_architecture)
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    echo "Detected architecture: $arch"

    # Get latest version
    local version=$(get_latest_version "$arch")
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    echo "Latest Docker CLI version: $version"
    echo ""

    # Construct download URL
    local download_url="${DOCKER_BASE_URL}/${arch}/docker-${version}.tgz"
    local temp_file=$(mktemp -d)/docker.tgz

    # Check if already installed
    if [[ -f "${DOCKER_INSTALL_DIR}/docker" ]]; then
        local installed_version=$(${DOCKER_INSTALL_DIR}/docker --version 2>/dev/null | grep -oP 'version \K[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        echo "Docker CLI is already installed: $installed_version"
        echo "Installation directory: ${DOCKER_INSTALL_DIR}"
        echo ""
        read -p "Do you want to reinstall/upgrade? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    fi

    # Download Docker CLI
    echo "Downloading Docker CLI from:"
    echo "  $download_url"
    echo ""

    if ! curl -fsSL -o "$temp_file" --progress-bar "$download_url"; then
        echo "ERROR: Failed to download Docker CLI" >&2
        rm -f "$temp_file"
        exit 1
    fi

    # Create installation directory
    sudo mkdir -p "$DOCKER_INSTALL_DIR"

    # Extract archive
    echo ""
    echo "Extracting Docker CLI..."
    local temp_extract=$(mktemp -d)
    if ! tar -xzf "$temp_file" -C "$temp_extract"; then
        echo "ERROR: Failed to extract archive" >&2
        rm -rf "$temp_file" "$temp_extract"
        exit 1
    fi

    # Move binaries to installation directory
    echo "Installing Docker CLI to ${DOCKER_INSTALL_DIR}..."
    if ! sudo cp -r "$temp_extract/docker/"* "$DOCKER_INSTALL_DIR/"; then
        echo "ERROR: Failed to copy binaries" >&2
        rm -rf "$temp_file" "$temp_extract"
        exit 1
    fi

    # Cleanup
    rm -rf "$temp_file" "$temp_extract"

    # Verify installation and announce success
    if [[ -f "${DOCKER_INSTALL_DIR}/docker" ]]; then
        local final_version=$(${DOCKER_INSTALL_DIR}/docker --version)

        clear
        echo -e "\033[32mDocker CLI Installation Successful\033[0m"
        echo ""
        echo -e "Version: \033[1;34m$final_version\033[0m"
        echo -e "Source: \033[1;34m${download_url}\033[0m"
        echo -e "Installed to: \033[1;34m${DOCKER_INSTALL_DIR}\033[0m"
        echo ""
        echo -e "Typical Usage:"
        echo -e "1. The '\033[36mdocker\033[0m' command is now available in your PATH"
        echo -e "2. Connect to remote Docker: '\033[36mexport DOCKER_HOST=tcp://hostname:2375\033[0m'"
        echo -e "3. Use Docker socket: '\033[36mexport DOCKER_HOST=unix:///var/run/docker.sock\033[0m'"
        echo ""
        echo -e "Note: Docker daemon is not installed - this is CLI only"
        echo -e ""
        echo -e "Access Requirements:"
        echo -e "- To use /var/run/docker.sock, you need socket access permissions"
        echo -e "- If using stellars-jupyterhub-ds, admin must add you to '\033[1;34mdocker-privileged\033[0m' group"
        echo ""
        echo -e "See: https://docs.docker.com/engine/reference/commandline/cli/"
        echo ""
    else
        echo "ERROR: Installation failed - docker binary not found" >&2
        exit 1
    fi
}

# Run main function
main

# EOF
