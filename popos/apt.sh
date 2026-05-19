#!/bin/bash

set -e

echo "=== Installing packages for Pop!_OS ==="
echo ""

# Remove LibreOffice (if user wants)
read -p "Do you want to remove LibreOffice? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing LibreOffice packages..."
    sudo apt remove --purge libreoffice-* -y || true
    sudo apt autoremove -y
fi

# Update system first
echo ""
echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install essential build tools
echo ""
echo "Installing essential build tools..."
sudo apt install -y \
    build-essential \
    git \
    curl \
    wget \
    htop \
    gparted \
    timeshift \
    vim \
    gnupg2 \
    ca-certificates \
    software-properties-common \
    apt-transport-https

# Brave Browser
if ! command -v brave-browser &> /dev/null; then
    echo ""
    echo "Installing Brave Browser..."
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | \
        sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo apt update
    sudo apt install -y brave-browser
    echo "✓ Brave Browser installed"
else
    echo "Brave Browser already installed"
fi

# Sublime Text
if ! command -v subl &> /dev/null; then
    echo ""
    echo "Installing Sublime Text..."
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | \
        gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
    echo "deb https://download.sublimetext.com/ apt/stable/" | \
        sudo tee /etc/apt/sources.list.d/sublime-text.list
    sudo apt update
    sudo apt install -y sublime-text
    echo "✓ Sublime Text installed"
else
    echo "Sublime Text already installed"
fi

# Docker
if ! command -v docker &> /dev/null; then
    echo ""
    echo "Installing Docker..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
    echo "✓ Docker installed"
else
    echo "Docker already installed"
fi

# VS Code
if ! command -v code &> /dev/null; then
    echo ""
    echo "Installing Visual Studio Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
        gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg \
        /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f packages.microsoft.gpg
    sudo apt update
    sudo apt install -y code
    echo "✓ VS Code installed"
else
    echo "VS Code already installed"
fi

# Install common development tools
echo ""
echo "Installing development tools..."
sudo apt install -y \
    zsh \
    golang-go \
    gcc \
    make \
    net-tools \
    iputils-ping \
    ssh \
    openssh-server \
    obs-studio \
    gnome-tweaks \
    dconf-editor \
    btop \
    ncdu \
    tree

# Install Pop!_OS specific packages (if not already installed)
echo ""
echo "Checking Pop!_OS specific packages..."
if dpkg -l | grep -q pop-desktop; then
    echo "Pop!_OS desktop packages already installed"

    # Install Pop!_Shell if not present (tiling window manager)
    if ! dpkg -l | grep -q pop-shell; then
        echo "Installing Pop!_Shell (tiling window manager)..."
        sudo apt install -y pop-shell || echo "Pop!_Shell not available"
    fi

    # System76 Power Management
    if ! command -v system76-power &> /dev/null; then
        echo "Installing System76 Power Management..."
        sudo apt install -y system76-power || echo "System76 Power not available"
    fi
fi

# Modern CLI tools via apt (where available)
echo ""
echo "Installing modern CLI tools..."
sudo apt install -y \
    bat \
    fd-find \
    ripgrep \
    fzf \
    silversearcher-ag \
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
