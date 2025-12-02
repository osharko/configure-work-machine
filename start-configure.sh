#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# GitHub repository information
GITHUB_USER="osharko"
REPO_NAME="configure-work-machine"
BRANCH="master"
BASE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/${BRANCH}"

# Temporary directory for scripts
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

echo -e "${GREEN}=== Work Machine Configuration Script ===${NC}"
echo ""

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        echo -e "${RED}Cannot detect OS. /etc/os-release not found.${NC}"
        exit 1
    fi
}

# Download script from GitHub
download_script() {
    local script_path=$1
    local output_file=$2
    local url="${BASE_URL}/${script_path}"

    echo -e "${YELLOW}Downloading ${script_path}...${NC}"
    if curl -fsSL "$url" -o "$output_file"; then
        chmod +x "$output_file"
        echo -e "${GREEN}✓ Downloaded ${script_path}${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to download ${script_path}${NC}"
        return 1
    fi
}

# Run script
run_script() {
    local script_file=$1
    local script_name=$(basename "$script_file")

    echo ""
    echo -e "${GREEN}=== Running ${script_name} ===${NC}"
    if bash "$script_file"; then
        echo -e "${GREEN}✓ ${script_name} completed successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ ${script_name} failed${NC}"
        return 1
    fi
}

# Main execution
detect_os
echo -e "Detected OS: ${GREEN}${OS}${NC}"
echo ""

case $OS in
    fedora)
        echo -e "${GREEN}Configuring for Fedora...${NC}"
        SCRIPTS=(
            "fedora/dnf.sh"
            "common/zsh.sh"
            "common/node_java.sh"
            "fedora/flatpak_and_service.sh"
        )
        ;;
    pop)
        echo -e "${GREEN}Configuring for Pop!_OS...${NC}"
        SCRIPTS=(
            "popos/apt.sh"
            "common/zsh.sh"
            "common/node_java.sh"
            "popos/flatpak_and_service.sh"
        )
        ;;
    ubuntu)
        echo -e "${GREEN}Configuring for Ubuntu...${NC}"
        SCRIPTS=(
            "ubuntu/apt.sh"
            "common/zsh.sh"
            "common/node_java.sh"
            "ubuntu/flatpak_and_service.sh"
        )
        ;;
    *)
        echo -e "${RED}Unsupported OS: ${OS}${NC}"
        echo "This script supports Fedora, Ubuntu, and Pop!_OS"
        exit 1
        ;;
esac

# Download all scripts first
echo -e "${YELLOW}Downloading scripts...${NC}"
DOWNLOADED_SCRIPTS=()
for script in "${SCRIPTS[@]}"; do
    output_file="${TEMP_DIR}/$(basename $script)"
    if download_script "$script" "$output_file"; then
        DOWNLOADED_SCRIPTS+=("$output_file")
    else
        echo -e "${RED}Failed to download required scripts. Exiting.${NC}"
        exit 1
    fi
done

# Download like_manjaro_zsh.sh (needed by zsh.sh)
download_script "common/like_manjaro_zsh.sh" "${TEMP_DIR}/like_manjaro_zsh.sh" || {
    echo -e "${RED}Failed to download like_manjaro_zsh.sh${NC}"
    exit 1
}

echo ""
echo -e "${GREEN}All scripts downloaded successfully!${NC}"
echo ""
echo -e "${YELLOW}The following scripts will be executed:${NC}"
for script in "${DOWNLOADED_SCRIPTS[@]}"; do
    echo "  - $(basename $script)"
done
echo ""

# Ask for confirmation
read -p "Do you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled.${NC}"
    exit 0
fi

# Change to temp directory so relative paths work
cd "${TEMP_DIR}"

# Run all scripts in order
for script in "${DOWNLOADED_SCRIPTS[@]}"; do
    if ! run_script "$script"; then
        echo ""
        echo -e "${RED}Script $(basename $script) failed. Do you want to continue with remaining scripts? (y/N)${NC}"
        read -p "" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Installation stopped.${NC}"
            exit 1
        fi
    fi
done

echo ""
echo -e "${GREEN}=== Configuration Complete! ===${NC}"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  - Please reboot your system to apply all changes"
echo "  - Run 'p10k configure' to customize your zsh prompt"
echo "  - Change your terminal font to 'MesloLGS NF' for proper icons"
echo ""
