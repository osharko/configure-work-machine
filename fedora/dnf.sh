#!/bin/bash

set -e

echo "=== Fedora Package Installation Script ==="
echo ""

# Remove LibreOffice
echo "Removing LibreOffice packages..."
sudo dnf remove -y \
    libreoffice-math \
    libreoffice-calc \
    libreoffice-draw \
    libreoffice-writer \
    libreoffice-core || echo "LibreOffice not found, skipping..."

# Install DNF plugins
echo ""
echo "Installing DNF plugins..."
sudo dnf install -y dnf-plugins-core

# Add third-party repositories
echo ""
echo "Adding third-party repositories..."

# Brave Browser
echo "Adding Brave Browser repository..."
sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

# Sublime Text
echo "Adding Sublime Text repository..."
sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
sudo dnf config-manager addrepo --from-repofile=https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo

# Docker
echo "Adding Docker repository..."
sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo

# VS Code
echo "Adding VS Code repository..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | \
    sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

# Update system
echo ""
echo "Updating system packages..."
sudo dnf update -y

# Install development tools
echo ""
echo "Installing development tools..."
sudo dnf group install -y development-tools

# Install essential packages
echo ""
echo "Installing essential packages..."
sudo dnf install -y \
    git-core \
    xrdp \
    obs-studio \
    gparted \
    timeshift \
    corectrl \
    gcc \
    htop \
    make \
    zsh \
    go \
    coreutils \
    iputils \
    net-tools \
    binutils \
    vim \
    wget \
    curl

# Install packages from added repositories
echo ""
echo "Installing software from third-party repositories..."
sudo dnf install -y \
    sublime-text \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    brave-browser \
    code

# GNOME Extensions (if running GNOME)
if [ "$DESKTOP_SESSION" == "gnome" ] || [ "$XDG_CURRENT_DESKTOP" == "GNOME" ]; then
    echo ""
    echo "GNOME detected - Installing Extension Manager and extensions..."

    flatpak install -y flathub com.mattjakeman.ExtensionManager || true

    # GNOME Extensions
    # Source: https://unix.stackexchange.com/a/707840
    extensions=(
        # Clipboard History - https://extensions.gnome.org/extension/4839/clipboard-history/
        "https://extensions.gnome.org/extension-data/clipboard-historyalexsaveau.dev.v46.shell-extension.zip"
        # Dash to Panel - https://extensions.gnome.org/extension/1160/dash-to-panel/
        "https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v68.shell-extension.zip"
        # Tiling Shell - https://extensions.gnome.org/extension/7065/tiling-shell/
        "https://extensions.gnome.org/extension-data/tilingshellferrarodomenico.com.v54.shell-extension.zip"
        # System Monitor - https://extensions.gnome.org/extension/6807/system-monitor/
        "https://extensions.gnome.org/extension-data/system-monitorgnome-shell-extensions.gcampax.github.com.v9.shell-extension.zip"
        # Removable Drive Menu - https://extensions.gnome.org/extension/7/removable-drive-menu/
        "https://extensions.gnome.org/extension-data/drive-menugnome-shell-extensions.gcampax.github.com.v67.shell-extension.zip"
    )

    for extension_url in "${extensions[@]}"; do
        echo "Installing extension: $(basename "$extension_url")"
        if wget -q "$extension_url" -O temp.zip; then
            gnome-extensions install --force temp.zip || echo "Failed to install extension, continuing..."
            rm -f temp.zip
        else
            echo "Failed to download extension, skipping..."
        fi
    done

    echo ""
    echo "GNOME extensions installed. You may need to enable them manually with:"
    echo "  gnome-extensions list"
    echo "  gnome-extensions enable <extension-id>"
fi

echo ""
echo "=== Fedora package installation complete! ==="
echo ""
echo "Next steps:"
echo "  - Run flatpak_and_service.sh to configure services"
echo "  - Run zsh.sh to set up your shell environment"
echo "  - Reboot your system to apply all changes"
