#!/bin/bash

# Local Modular Testing Script
# Test individual scripts without running the full installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo "Local Modular Testing Script"
    echo ""
    echo "Usage: $0 [SCRIPT_NAME]"
    echo ""
    echo "Available scripts:"
    echo "  1. apt             - Test Pop!_OS package installation"
    echo "  2. zsh             - Test Zsh and Homebrew setup"
    echo "  3. node-java       - Test Node.js and Java installation"
    echo "  4. flatpak         - Test Flatpak apps and services"
    echo "  5. dell            - Test Dell OEM drivers (if present)"
    echo "  6. finalize        - Test finalization (environment setup, shell change)"
    echo "  all                - Run all scripts in order"
    echo ""
    echo "Examples:"
    echo "  $0 apt             # Test only apt.sh"
    echo "  $0 zsh             # Test only zsh.sh"
    echo "  $0 all             # Test all scripts"
    echo ""
    echo "Note: Some scripts require sudo and will modify your system!"
    echo "      Use this on a test VM or system you don't mind modifying."
    echo ""
}

run_script() {
    local script_name=$1
    local script_path=$2
    local description=$3

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Testing: ${script_name}${NC}"
    echo -e "${YELLOW}Description: ${description}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    read -p "$(echo -e ${YELLOW}Run this script? \(Y/n\): ${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}⊘ Skipped${NC}"
        return 0
    fi

    echo -e "${GREEN}▶ Running $script_name...${NC}"
    echo ""

    if bash "$script_path"; then
        echo ""
        echo -e "${GREEN}✓ $script_name completed successfully${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}✗ $script_name failed${NC}"
        return 1
    fi
}

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "pop" ]; then
        echo -e "${YELLOW}Warning: This script is designed for Pop!_OS${NC}"
        echo -e "Detected OS: $ID"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
fi

# Parse arguments
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

SCRIPT_TO_RUN=$1

case $SCRIPT_TO_RUN in
    apt|1)
        run_script "apt.sh" "$SCRIPT_DIR/popos/apt.sh" \
            "Install system packages and development tools"
        ;;
    zsh|2)
        cd "$SCRIPT_DIR/common"
        run_script "zsh.sh" "$SCRIPT_DIR/common/zsh.sh" \
            "Set up Zsh with Powerlevel10k and install Homebrew + CLI tools"
        ;;
    node-java|node|java|3)
        cd "$SCRIPT_DIR/common"
        run_script "node_java.sh" "$SCRIPT_DIR/common/node_java.sh" \
            "Install Node.js (via nvm) and Java (via jenv)"
        ;;
    flatpak|services|4)
        run_script "flatpak_and_service.sh" "$SCRIPT_DIR/popos/flatpak_and_service.sh" \
            "Configure system services and install Flatpak applications"
        ;;
    dell|dell-oem|5)
        if [ -f "$SCRIPT_DIR/popos/dell-oem-drivers.sh" ]; then
            run_script "dell-oem-drivers.sh" "$SCRIPT_DIR/popos/dell-oem-drivers.sh" \
                "Install Dell OEM hardware drivers"
        else
            echo -e "${YELLOW}Dell OEM drivers script not found${NC}"
        fi
        ;;
    finalize|final|6)
        cd "$SCRIPT_DIR/common"
        run_script "finalize.sh" "$SCRIPT_DIR/common/finalize.sh" \
            "Finalize configuration and set Zsh as default shell"
        ;;
    all)
        echo -e "${GREEN}Running all scripts in order...${NC}"
        echo ""

        FAILED=0

        run_script "apt.sh" "$SCRIPT_DIR/popos/apt.sh" \
            "Install system packages and development tools" || FAILED=$((FAILED+1))

        cd "$SCRIPT_DIR/common"
        run_script "zsh.sh" "$SCRIPT_DIR/common/zsh.sh" \
            "Set up Zsh with Powerlevel10k and install Homebrew + CLI tools" || FAILED=$((FAILED+1))

        run_script "node_java.sh" "$SCRIPT_DIR/common/node_java.sh" \
            "Install Node.js (via nvm) and Java (via jenv)" || FAILED=$((FAILED+1))

        cd "$SCRIPT_DIR"
        run_script "flatpak_and_service.sh" "$SCRIPT_DIR/popos/flatpak_and_service.sh" \
            "Configure system services and install Flatpak applications" || FAILED=$((FAILED+1))

        if [ -f "$SCRIPT_DIR/popos/dell-oem-drivers.sh" ]; then
            run_script "dell-oem-drivers.sh" "$SCRIPT_DIR/popos/dell-oem-drivers.sh" \
                "Install Dell OEM hardware drivers" || FAILED=$((FAILED+1))
        fi

        cd "$SCRIPT_DIR/common"
        run_script "finalize.sh" "$SCRIPT_DIR/common/finalize.sh" \
            "Finalize configuration and set Zsh as default shell" || FAILED=$((FAILED+1))

        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        if [ $FAILED -eq 0 ]; then
            echo -e "${GREEN}All tests passed!${NC}"
        else
            echo -e "${RED}$FAILED script(s) failed${NC}"
        fi
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        ;;
    -h|--help|help)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown script: $SCRIPT_TO_RUN${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
