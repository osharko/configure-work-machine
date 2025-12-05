#!/bin/bash

set -e

echo "=== Installing packages for Fedora ==="
echo ""

# Remove LibreOffice
echo "Removing LibreOffice packages..."

# Update system first
echo ""
echo "Updating system packages..."
sudo dnf update -y

# Install essential build tools
echo ""
echo "Installing essential build tools..."
sudo dnf install -y \
    gcc \
    git \
    curl \
    wget \
    htop \
    gparted \
    timeshift

# Brave Browser
if ! command -v brave-browser &> /dev/null; then
    echo ""
    echo "Installing Brave Browser..."
    curl -fsS https://dl.brave.com/install.sh | sh
    echo "✓ Brave Browser installed"
else
    echo "Brave Browser already installed"
fi

# Docker
if ! command -v docker &> /dev/null; then
    echo ""
    echo "Installing Docker..."
    sudo dnf -y install dnf-plugins-core
    sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    echo "✓ Docker installed"
else
    echo "Docker already installed"
fi

# VS Code
if ! command -v code &> /dev/null; then
    echo ""
    echo "Installing Visual Studio Code..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
    dnf check-update -y
    sudo dnf install code -y
    echo "✓ VS Code installed"
else
    echo "VS Code already installed"
fi

# Install common development tools
echo ""
echo "Installing development tools..."
sudo dnf install -y \
    zsh \
    golang-go \
    gcc \
    make \
    net-tools \
    ssh \
    openssh-server \
    obs-studio \
    dconf-editor \
    btop \
    ncdu \
    tree


# Modern CLI tools via apt (where available)
echo ""
echo "Installing modern CLI tools..."
sudo dnf install -y \
    bat \
    fd-find \
    ripgrep \
    fzf \
    jq \
    tldr

# Create symlinks for bat and fd (they have different names on Ubuntu/Pop!OS)
if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
    mkdir -p ~/.local/bin
    ln -sf /usr/bin/batcat ~/.local/bin/bat
    echo "✓ Created bat symlink"
fi

if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
    mkdir -p ~/.local/bin
    ln -sf /usr/bin/fdfind ~/.local/bin/fd
    echo "✓ Created fd symlink"
fi

# Add ~/.local/bin to PATH if not already there
if ! grep -q '$HOME/.local/bin' ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi
if [ -f ~/.zshrc ] && ! grep -q '$HOME/.local/bin' ~/.zshrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
fi

echo ""
echo "=== Pop!_OS package installation complete! ==="
echo ""
echo "Installed tools:"
echo "  ✓ Brave Browser, Sublime Text, VS Code"
echo "  ✓ Docker & Docker Compose"
echo "  ✓ Development tools (git, gcc, make, go)"
echo "  ✓ Modern CLI tools (bat, fd, ripgrep, fzf, btop)"
echo "  ✓ Pop!_Shell (tiling window manager)"
echo "  ✓ System76 Power Management"
echo ""
echo "Next steps:"
echo "  - Run flatpak_and_service.sh to configure services and install apps"
echo "  - Run ../common/zsh.sh to set up your shell environment"
echo "  - Press Super+Y to toggle Pop!_Shell tiling mode"
