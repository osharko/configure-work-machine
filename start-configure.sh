#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub repository information
GITHUB_USER="osharko"
REPO_NAME="configure-work-machine"
BRANCH="develop"
BASE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/${BRANCH}"

# Temporary directory for scripts
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

# Mode flags
INTERACTIVE_MODE=false
SILENT_MODE=false

# Parse command-line arguments
show_help() {
    echo "Linux Machine Configuration Script (Pop!_OS / Fedora)"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --interactive    Interactive mode - ask before each step"
    echo "  -y, --yes           Silent mode - auto-approve all steps"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Modes:"
    echo "  Default mode:      Ask once at the beginning, then run all scripts"
    echo "  Interactive mode:  Ask before each script execution"
    echo "  Silent mode:       Run everything without prompts (for automation)"
    echo ""
    echo "Supported distributions:"
    echo "  - Pop!_OS (System76)"
    echo "  - Fedora (including COSMIC desktop)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Default mode"
    echo "  $0 -i                 # Interactive mode (recommended)"
    echo "  $0 --yes              # Silent mode"
    echo ""
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interactive)
            INTERACTIVE_MODE=true
            shift
            ;;
        -y|--yes)
            SILENT_MODE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Export mode for subscripts
export INTERACTIVE_MODE
export SILENT_MODE

echo -e "${GREEN}=== Linux Machine Configuration Script ===${NC}"
echo ""

if [ "$INTERACTIVE_MODE" = true ]; then
    echo -e "${BLUE}Running in INTERACTIVE mode - you'll be asked before each step${NC}"
    echo ""
elif [ "$SILENT_MODE" = true ]; then
    echo -e "${BLUE}Running in SILENT mode - all steps will execute automatically${NC}"
    echo ""
fi

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

# Get script description
get_script_description() {
    local script_name=$1
    case $script_name in
        apt.sh)
            echo "Install Pop!_OS system packages, development tools, and modern CLI tools (Brave, Docker, VS Code, etc.)"
            ;;
        dnf.sh)
            echo "Install Fedora system packages, development tools, and modern CLI tools (Brave, Docker, VS Code, etc.)"
            ;;
        zsh.sh)
            echo "Set up Zsh shell with Powerlevel10k theme and install Homebrew + CLI tools (lazygit, lazydocker, eza, zoxide, bat, etc.)"
            ;;
        node.sh)
            echo "Install Node.js LTS (v20 & v22) via nvm with global packages (yarn, pnpm, nodemon, etc.)"
            ;;
        java.sh)
            echo "Install Java development environment: JDK 8 & 21 (via jenv), Maven 3.9.9, Gradle 8.11.1 in /opt/jdks"
            ;;
        flatpak_and_service.sh)
            echo "Configure system services (Docker, SSH, libvirt) and install Flatpak applications (Bottles, Telegram, Discord, etc.)"
            ;;
        dell-oem-drivers.sh)
            echo "Install Dell OEM hardware drivers (audio, fingerprint, firmware)"
            ;;
        finalize.sh)
            echo "Finalize configuration: verify installations, configure terminal font, set environment variables, and change default shell to Zsh"
            ;;
        *)
            echo "Execute $script_name"
            ;;
    esac
}

# Run script with interactive prompt if needed
run_script() {
    local script_file=$1
    local script_name=$(basename "$script_file")
    local description=$(get_script_description "$script_name")

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Script: ${script_name}${NC}"
    echo -e "${YELLOW}Description: ${description}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # In interactive mode, ask before running each script
    if [ "$INTERACTIVE_MODE" = true ]; then
        echo ""
        read -p "$(echo -e ${YELLOW}Do you want to run this script? \(Y/n\): ${NC})" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo -e "${YELLOW}⊘ Skipped ${script_name}${NC}"
            return 0
        fi
    fi

    echo ""
    echo -e "${GREEN}▶ Running ${script_name}...${NC}"
    echo ""

    if bash "$script_file"; then
        echo ""
        echo -e "${GREEN}✓ ${script_name} completed successfully${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}✗ ${script_name} failed${NC}"
        return 1
    fi
}

# Main execution
detect_os
echo -e "Detected OS: ${GREEN}${OS} ${VERSION}${NC}"
echo ""

# Check if supported OS
DISTRO_DIR=""
if [ "$OS" = "pop" ]; then
    DISTRO_DIR="popos"
    echo -e "${GREEN}✓ Pop!_OS detected - using Pop!_OS scripts${NC}"
elif [ "$OS" = "fedora" ]; then
    DISTRO_DIR="fedora"
    echo -e "${GREEN}✓ Fedora detected - using Fedora scripts${NC}"
else
    echo -e "${YELLOW}Warning: This script is optimized for Pop!_OS and Fedora${NC}"
    echo -e "Detected: $OS"
    echo ""
    echo -e "Choose installation profile:"
    echo "  1) Pop!_OS/Ubuntu-based"
    echo "  2) Fedora-based"
    echo "  3) Cancel"
    read -p "Select (1-3): " -n 1 -r
    echo
    case $REPLY in
        1)
            DISTRO_DIR="popos"
            echo -e "${YELLOW}Using Pop!_OS scripts${NC}"
            ;;
        2)
            DISTRO_DIR="fedora"
            echo -e "${YELLOW}Using Fedora scripts${NC}"
            ;;
        *)
            echo -e "${YELLOW}Installation cancelled.${NC}"
            exit 0
            ;;
    esac
fi

echo ""

# Scripts to run (distro-specific first script determined by detection)
if [ "$DISTRO_DIR" = "popos" ]; then
    PACKAGE_MANAGER_SCRIPT="${DISTRO_DIR}/apt.sh"
elif [ "$DISTRO_DIR" = "fedora" ]; then
    PACKAGE_MANAGER_SCRIPT="${DISTRO_DIR}/dnf.sh"
fi

SCRIPTS=(
    "$PACKAGE_MANAGER_SCRIPT"
    "common/zsh.sh"
    "common/node.sh"
    "common/java.sh"
    "${DISTRO_DIR}/flatpak_and_service.sh"
    "common/finalize.sh"
)

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

# Download dell-oem-drivers.sh if exists (optional, only for Pop!_OS)
if [ "$DISTRO_DIR" = "popos" ]; then
    if download_script "popos/dell-oem-drivers.sh" "${TEMP_DIR}/dell-oem-drivers.sh" 2>/dev/null; then
        DOWNLOADED_SCRIPTS+=("${TEMP_DIR}/dell-oem-drivers.sh")
    fi
fi

echo ""
echo -e "${GREEN}All scripts downloaded successfully!${NC}"
echo ""

# Show execution plan
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Installation Plan:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
for i in "${!DOWNLOADED_SCRIPTS[@]}"; do
    script_name=$(basename "${DOWNLOADED_SCRIPTS[$i]}")
    description=$(get_script_description "$script_name")
    echo -e "${GREEN}$((i+1)). ${script_name}${NC}"
    echo -e "   ${description}"
    echo ""
done
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Ask for confirmation (skip in silent mode or if interactive mode will ask per-script)
if [ "$SILENT_MODE" = false ] && [ "$INTERACTIVE_MODE" = false ]; then
    read -p "$(echo -e ${YELLOW}Do you want to continue? \(y/N\): ${NC})" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi
fi

# Change to temp directory so relative paths work
cd "${TEMP_DIR}"

# Run all scripts in order
SKIPPED_SCRIPTS=()
FAILED_SCRIPTS=()
COMPLETED_SCRIPTS=()

for script in "${DOWNLOADED_SCRIPTS[@]}"; do
    script_name=$(basename "$script")

    if run_script "$script"; then
        COMPLETED_SCRIPTS+=("$script_name")
    else
        FAILED_SCRIPTS+=("$script_name")

        if [ "$SILENT_MODE" = false ]; then
            echo ""
            echo -e "${RED}Script $script_name failed.${NC}"
            read -p "$(echo -e ${YELLOW}Do you want to continue with remaining scripts? \(y/N\): ${NC})" -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Installation stopped.${NC}"
                break
            fi
        fi
    fi
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}=== Configuration Complete! ===${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Show summary
if [ ${#COMPLETED_SCRIPTS[@]} -gt 0 ]; then
    echo -e "${GREEN}✓ Completed scripts (${#COMPLETED_SCRIPTS[@]}):${NC}"
    for script in "${COMPLETED_SCRIPTS[@]}"; do
        echo -e "  ${GREEN}✓${NC} $script"
    done
    echo ""
fi

if [ ${#FAILED_SCRIPTS[@]} -gt 0 ]; then
    echo -e "${RED}✗ Failed scripts (${#FAILED_SCRIPTS[@]}):${NC}"
    for script in "${FAILED_SCRIPTS[@]}"; do
        echo -e "  ${RED}✗${NC} $script"
    done
    echo ""
fi

echo -e "${YELLOW}Important next steps:${NC}"
echo "  1. Reboot your system to apply all changes"
echo "  2. Run 'p10k configure' to customize your zsh prompt"
echo "  3. Change your terminal font to 'MesloLGS NF' for proper icons"
echo "  4. Log out and back in for group changes (docker, libvirt) to take effect"
echo ""

if [ "$INTERACTIVE_MODE" = true ]; then
    echo -e "${BLUE}Tip: You ran in interactive mode. Next time use -y for silent mode.${NC}"
elif [ "$SILENT_MODE" = false ]; then
    echo -e "${BLUE}Tip: Use -i for interactive mode or -y for silent mode next time.${NC}"
fi
echo ""
