#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}=== Finalizing Configuration ===${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verify installations
echo -e "${YELLOW}Verifying installations...${NC}"
echo ""

# Check Zsh
if command -v zsh &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Zsh: $(zsh --version | head -n1)"
else
    echo -e "  ${RED}✗${NC} Zsh: Not found"
fi

# Check Homebrew
if command -v brew &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Homebrew: $(brew --version | head -n1)"
else
    echo -e "  ${RED}✗${NC} Homebrew: Not found"
fi

# Check nvm
if [ -f "$HOME/.nvm/nvm.sh" ] || [ -d "/home/linuxbrew/.linuxbrew/opt/nvm" ]; then
    echo -e "  ${GREEN}✓${NC} NVM: Installed"
else
    echo -e "  ${YELLOW}⚠${NC} NVM: Not found (optional)"
fi

# Check jenv
if command -v jenv &> /dev/null || [ -d "$HOME/.jenv" ]; then
    echo -e "  ${GREEN}✓${NC} jenv: Installed"
else
    echo -e "  ${YELLOW}⚠${NC} jenv: Not found (optional)"
fi

# Check Docker
if command -v docker &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Docker: $(docker --version)"
else
    echo -e "  ${YELLOW}⚠${NC} Docker: Not found"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Ensure all environment configurations are in place
echo -e "${YELLOW}Ensuring all environment configurations are in place...${NC}"
echo ""

# Function to add to file if not present
add_to_file() {
    local file=$1
    local content=$2
    local marker=$3

    if [ -f "$file" ]; then
        if ! grep -q "$marker" "$file"; then
            echo "" >> "$file"
            echo "$content" >> "$file"
            echo -e "  ${GREEN}✓${NC} Added to $file"
        else
            echo -e "  ${BLUE}ℹ${NC} Already in $file"
        fi
    fi
}

# Homebrew configuration
BREW_CONFIG='# Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'

add_to_file "$HOME/.bashrc" "$BREW_CONFIG" "linuxbrew/bin/brew"
add_to_file "$HOME/.zshrc" "$BREW_CONFIG" "linuxbrew/bin/brew"

# NVM configuration
NVM_CONFIG='# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"'

if [ -d "/home/linuxbrew/.linuxbrew/opt/nvm" ]; then
    add_to_file "$HOME/.bashrc" "$NVM_CONFIG" "NVM_DIR"
    add_to_file "$HOME/.zshrc" "$NVM_CONFIG" "NVM_DIR"
fi

# jenv configuration
JENV_CONFIG='# jenv (Java Environment Manager)
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"'

if command -v jenv &> /dev/null || [ -d "$HOME/.jenv" ]; then
    add_to_file "$HOME/.bashrc" "$JENV_CONFIG" "jenv init"
    add_to_file "$HOME/.zshrc" "$JENV_CONFIG" "jenv init"
fi

# ~/.local/bin in PATH
LOCAL_BIN_CONFIG='export PATH="$HOME/.local/bin:$PATH"'

add_to_file "$HOME/.bashrc" "$LOCAL_BIN_CONFIG" ".local/bin"
add_to_file "$HOME/.zshrc" "$LOCAL_BIN_CONFIG" ".local/bin"

echo ""
echo -e "${GREEN}✓ All environment configurations are in place${NC}"
echo ""

# Change default shell to Zsh
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

current_shell=$(getent passwd "$USER" | cut -d: -f7)
zsh_path=$(command -v zsh)

if [ "$current_shell" != "$zsh_path" ]; then
    echo -e "${YELLOW}Your current shell is: $current_shell${NC}"
    echo -e "${GREEN}Zsh is installed at: $zsh_path${NC}"
    echo ""
    echo "Would you like to change your default shell to Zsh?"
    echo "(This requires sudo and will take effect after logout)"
    echo ""

    if [ "$SILENT_MODE" = true ]; then
        # In silent mode, always change
        REPLY="y"
    else
        read -p "$(echo -e ${YELLOW}Change default shell to Zsh? \(Y/n\): ${NC})" -n 1 -r
        echo
    fi

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        sudo usermod --shell "$zsh_path" "$USER"
        echo ""
        echo -e "${GREEN}✓ Default shell changed to Zsh${NC}"
        echo -e "${YELLOW}  Log out and log back in for this change to take effect${NC}"
    else
        echo ""
        echo -e "${YELLOW}⊘ Default shell not changed${NC}"
        echo "  You can change it later with: chsh -s $zsh_path"
    fi
else
    echo -e "${GREEN}✓ Zsh is already your default shell${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Configure terminal font for emoji/icons support
echo -e "${YELLOW}Configuring terminal font...${NC}"
echo ""

# Check if MesloLGS NF font is installed
FONT_NAME="MesloLGS NF Regular"
FONT_INSTALLED=false

if fc-list | grep -qi "MesloLGS NF"; then
    FONT_INSTALLED=true
    echo -e "${GREEN}✓ MesloLGS NF font is installed${NC}"
else
    echo -e "${YELLOW}⚠ MesloLGS NF font not found${NC}"
    echo "  The font should have been installed during Zsh setup"
fi

# Configure GNOME Terminal if available
if [ "$FONT_INSTALLED" = true ] && command -v gsettings &> /dev/null; then
    # Check if we're in a GNOME session
    if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ "$XDG_CURRENT_DESKTOP" = "pop:GNOME" ] || [ "$DESKTOP_SESSION" = "gnome" ]; then
        echo ""
        echo "MesloLGS NF font is required to see emoji and icons properly in Powerlevel10k."
        echo "Would you like to set it as your terminal font?"
        echo ""

        if [ "$SILENT_MODE" = true ]; then
            REPLY="y"
        else
            read -p "$(echo -e ${YELLOW}Configure terminal to use MesloLGS NF? \(Y/n\): ${NC})" -n 1 -r
            echo
        fi

        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            # Get the default GNOME Terminal profile UUID
            PROFILE_UUID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")

            if [ -n "$PROFILE_UUID" ]; then
                PROFILE_PATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_UUID/"

                # Set custom font
                gsettings set "$PROFILE_PATH" use-system-font false
                gsettings set "$PROFILE_PATH" font "$FONT_NAME 11"

                echo ""
                echo -e "${GREEN}✓ Terminal font set to MesloLGS NF${NC}"
                echo -e "${YELLOW}  Close and reopen your terminal to see the changes${NC}"
            else
                echo -e "${YELLOW}⚠ Could not find default terminal profile${NC}"
                echo "  You can set the font manually in Terminal Preferences"
            fi
        else
            echo ""
            echo -e "${YELLOW}⊘ Terminal font not changed${NC}"
            echo "  To set it manually:"
            echo "  1. Open Terminal → Preferences"
            echo "  2. Select your profile"
            echo "  3. Go to 'Text' tab"
            echo "  4. Uncheck 'Use system font'"
            echo "  5. Select 'MesloLGS NF Regular' font"
        fi
    else
        echo -e "${BLUE}ℹ Not running GNOME Terminal${NC}"
        echo "  Set the font manually in your terminal settings to: MesloLGS NF Regular"
    fi
elif [ "$FONT_INSTALLED" = false ]; then
    echo ""
    echo -e "${RED}Font installation may have failed${NC}"
    echo "You can install it manually from:"
    echo "  https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Final instructions
echo -e "${GREEN}=== Configuration Finalized! ===${NC}"
echo ""
echo -e "${YELLOW}Important next steps:${NC}"
echo ""
echo "  1. ${GREEN}Reboot your system${NC} to apply all changes"
echo "     (Required for: kernel modules, services, group changes)"
echo ""
echo "  2. ${GREEN}Close and reopen your terminal${NC} to see the new font"
echo ""
echo "  3. ${GREEN}Configure your Zsh prompt:${NC}"
echo "     ${BLUE}p10k configure${NC}"
echo ""
echo "  4. ${GREEN}Verify installations:${NC}"
echo "     ${BLUE}docker --version${NC}"
echo "     ${BLUE}node --version${NC}"
echo "     ${BLUE}java -version${NC}"
echo "     ${BLUE}lazygit --version${NC}"
echo "     ${BLUE}eza --version${NC}"
echo ""
echo "  5. ${GREEN}Check that emoji are visible:${NC}"
echo "     The terminal should now show emoji and icons correctly: 🚀 ✓ 📁 🔧"
echo ""
echo "  6. ${GREEN}Test modern CLI tools:${NC}"
echo "     ${BLUE}eza -la${NC}           # Better ls"
echo "     ${BLUE}bat README.md${NC}     # Better cat"
echo "     ${BLUE}lazygit${NC}           # Git TUI"
echo "     ${BLUE}lazydocker${NC}        # Docker TUI"
echo "     ${BLUE}btop${NC}              # System monitor"
echo ""

# Group membership reminders
groups_to_check=("docker" "libvirt")
need_relogin=false

for group in "${groups_to_check[@]}"; do
    if groups | grep -q "\b$group\b"; then
        continue
    elif getent group "$group" &> /dev/null && getent group "$group" | grep -q "$USER"; then
        need_relogin=true
    fi
done

if [ "$need_relogin" = true ]; then
    echo -e "${YELLOW}Note: You've been added to new groups (docker, libvirt).${NC}"
    echo -e "${YELLOW}      Log out and back in for this to take effect.${NC}"
    echo ""
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Enjoy your new development environment! 🚀${NC}"
echo ""
