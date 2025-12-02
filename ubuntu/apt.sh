#!/bin/bash

set -e

echo "=== Installing packages for Ubuntu/Pop!OS ==="

# Remove LibreOffice
sudo apt remove --purge libreoffice-math libreoffice-calc libreoffice-draw libreoffice-writer libreoffice-core -y || true
sudo apt autoremove -y

# Update system first
sudo apt update
sudo apt upgrade -y

# Install essential build tools
sudo apt install build-essential git curl wget htop gparted timeshift -y

# Brave Browser
if ! command -v brave-browser &> /dev/null; then
    sudo apt install curl -y
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo apt update
    sudo apt install brave-browser -y
fi

# Sublime Text
if ! command -v subl &> /dev/null; then
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
    echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
    sudo apt update
    sudo apt install sublime-text -y
fi

# Docker
if ! command -v docker &> /dev/null; then
    sudo apt install ca-certificates curl gnupg -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
fi

# VS Code
if ! command -v code &> /dev/null; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f packages.microsoft.gpg
    sudo apt update
    sudo apt install code -y
fi

# Install common tools
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
    corectrl \
    vim \
    gnupg2

# GNOME Extensions (if running GNOME)
if [ "$DESKTOP_SESSION" == "gnome" ] || [ "$XDG_CURRENT_DESKTOP" == "ubuntu:GNOME" ] || [ "$XDG_CURRENT_DESKTOP" == "pop:GNOME" ]; then
    echo "Installing GNOME Extensions..."

    # Install gnome-shell-extension-manager if not present
    sudo apt install gnome-shell-extension-manager -y || {
        # If not available in repos, try flatpak
        flatpak install flathub com.mattjakeman.ExtensionManager -y || true
    }

    # Install chrome-gnome-shell for browser extension support
    sudo apt install chrome-gnome-shell -y || true

    # Install extensions via gnome-extensions command
    array=(
        # Clipboard History
        https://extensions.gnome.org/extension-data/clipboard-historyalexsaveau.dev.v46.shell-extension.zip
        # Dash to Panel
        https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v68.shell-extension.zip
        # Tiling Shell
        https://extensions.gnome.org/extension-data/tilingshellferrarodomenico.com.v54.shell-extension.zip
        # System Monitor
        https://extensions.gnome.org/extension-data/system-monitorgnome-shell-extensions.gcampax.github.com.v9.shell-extension.zip
        # Removable Drive Menu
        https://extensions.gnome.org/extension-data/drive-menugnome-shell-extensions.gcampax.github.com.v67.shell-extension.zip
    )

    for extension_url in "${array[@]}"; do
        wget "$extension_url" -O temp.zip
        gnome-extensions install --force temp.zip || true
        rm temp.zip
    done
fi

echo "=== Package installation complete ==="
