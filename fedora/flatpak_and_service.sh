#!/bin/bash

set -e

echo "=== Configuring Services and Installing Flatpak Applications ==="
echo ""

# Enable Docker
if command -v docker &> /dev/null; then
    echo "Enabling Docker service..."
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$(whoami)"
    echo "✓ Docker enabled and user added to docker group"
fi

# Enable libvirt (if installed via brew in zsh.sh)
if command -v virsh &> /dev/null || [ -f /usr/sbin/libvirtd ]; then
    echo ""
    echo "Enabling libvirt service..."
    sudo systemctl enable --now libvirtd || true
    sudo usermod -aG libvirt "$(whoami)" || true
    echo "✓ Libvirt enabled and user added to libvirt group"
fi

# Enable SSH daemon
if command -v sshd &> /dev/null || [ -f /usr/sbin/sshd ]; then
    echo ""
    echo "Enabling SSH daemon..."
    sudo systemctl enable --now sshd
    echo "✓ SSH daemon enabled"
fi

# Ensure Flatpak is installed (should be by default on Pop!_OS)
echo ""
if ! command -v flatpak &> /dev/null; then
    echo "Installing Flatpak..."
    sudo apt install -y flatpak
else
    echo "Flatpak already installed"
fi

# Install Flatpak applications
echo ""
echo "Installing Flatpak applications via Pop!_Shop/Flathub..."

applications=(
    "org.telegram.desktop"              # Telegram Desktop
    "com.thincast.client"               # ThinCast client
    "com.system76.Popsicle"             # USB flasher (Pop!_OS tool)
    "io.dbeaver.DBeaverCommunity"       # Database management
    "com.usebottles.bottles"            # Bottles (Windows app compatibility - modern Wine wrapper)
    "com.spotify.Client"                # Spotify (optional but nice to have)
    "com.github.tchx84.Flatseal"        # Flatseal (manage Flatpak permissions)
    "io.podman_desktop.PodmanDesktop"   # Podman Desktop (Docker alternative)
    "com.sublimetext.three"             # Flatpak
)

echo ""
echo "The following applications will be installed:"
for app in "${applications[@]}"; do
    echo "  - $app"
done
echo ""
read -p "Install all applications? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    for app in "${applications[@]}"; do
        app_id=$(echo "$app" | cut -d'#' -f1 | xargs)
        app_name=$(echo "$app" | cut -d'#' -f2- 2>/dev/null || echo "$app_id")

        if flatpak list | grep -q "$app_id"; then
            echo "  $app_id already installed, skipping..."
        else
            echo "  Installing $app_id..."
            flatpak install -y flathub "$app_id" || {
                echo "  Warning: Failed to install $app_id, continuing..."
            }
        fi
    done
else
    echo "Skipping application installation"
fi

# Configure Pop!_Shell settings (if installed)
if command -v gnome-extensions &> /dev/null; then
    if gnome-extensions list | grep -q "pop-shell"; then
        echo ""
        echo "Enabling Pop!_Shell..."
        gnome-extensions enable pop-shell@system76.com || true
        echo "✓ Pop!_Shell enabled (Press Super+Y to toggle tiling)"
    fi
fi

echo ""
echo "=== Configuration complete! ==="
echo ""
echo "Important notes:"
echo "  - Log out and log back in for group changes (docker, libvirt) to take effect"
echo "  - Bottles is installed for running Windows applications"
echo "  - Flatseal is installed to manage Flatpak app permissions"
echo "  - Pop!_Shell tiling: Press Super+Y to toggle"
echo ""
echo "Useful Pop!_OS keyboard shortcuts:"
echo "  Super+Y          - Toggle tiling mode"
echo "  Super+O          - Change window orientation"
echo "  Super+G          - Float focused window"
echo "  Super+Arrow      - Move focus between windows"
echo "  Super+Enter      - Adjust window size"
echo "  Super+M          - Maximize window"
echo ""
echo "To manage graphics on hybrid systems:"
echo "  system76-power graphics [intel|nvidia|hybrid|compute]"
echo ""
echo "To verify services:"
echo "  sudo systemctl status docker"
echo "  sudo systemctl status libvirtd"
echo "  sudo systemctl status system76-power"
