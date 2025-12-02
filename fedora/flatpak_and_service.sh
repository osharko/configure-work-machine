#!/bin/bash

set -e

echo "=== Configuring System Services and Flatpak Applications ==="
echo ""

# Enable Docker service
if systemctl list-unit-files | grep -q docker.service; then
    echo "Enabling Docker service..."
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$(whoami)"
    echo "✓ Docker enabled and user added to docker group"
else
    echo "Warning: Docker service not found, skipping..."
fi

# Enable libvirtd service
if systemctl list-unit-files | grep -q libvirtd.service; then
    echo ""
    echo "Enabling libvirtd service..."
    sudo systemctl enable --now libvirtd
    sudo usermod -aG libvirt "$(whoami)"
    echo "✓ libvirtd enabled and user added to libvirt group"
else
    echo "Warning: libvirtd service not found, skipping..."
fi

# Enable SSH daemon
if systemctl list-unit-files | grep -q sshd.service; then
    echo ""
    echo "Enabling SSH daemon..."
    sudo systemctl enable --now sshd
    echo "✓ SSH daemon enabled"
else
    echo "Warning: sshd service not found, skipping..."
fi

# Enable XRDP (Remote Desktop)
if systemctl list-unit-files | grep -q xrdp.service; then
    echo ""
    echo "Enabling XRDP (Remote Desktop)..."
    sudo systemctl enable --now xrdp

    # Configure firewall for XRDP
    if command -v firewall-cmd &> /dev/null; then
        echo "Configuring firewall for XRDP..."
        sudo firewall-cmd --permanent --new-zone=xrdp 2>/dev/null || echo "  Zone already exists"
        sudo firewall-cmd --permanent --zone=xrdp --add-port=3389/tcp
        sudo firewall-cmd --reload
        echo "✓ Firewall configured for XRDP"
    fi
    echo "✓ XRDP enabled"
else
    echo "Warning: XRDP service not found, skipping..."
fi

# Install Flatpak applications
echo ""
echo "Installing Flatpak applications..."

# Ensure Flatpak is installed and Flathub is configured
if ! command -v flatpak &> /dev/null; then
    echo "Error: Flatpak not found. Please install it first."
    exit 1
fi

# Add Flathub repository if not already added
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install applications
applications=(
    "org.telegram.desktop"
    "com.thincast.client"
    "com.system76.Popsicle"
    "io.dbeaver.DBeaverCommunity"
    "io.beekeeperstudio.Studio"
)

for app in "${applications[@]}"; do
    echo "  Installing $app..."
    flatpak install -y flathub "$app" || {
        echo "  Warning: Failed to install $app, continuing..."
    }
done

echo ""
echo "=== Configuration complete! ==="
echo ""
echo "Important notes:"
echo "  - Group changes (docker, libvirt) require logout/login to take effect"
echo "  - XRDP is accessible on port 3389"
echo "  - Reboot recommended to ensure all services start properly"
echo ""
echo "To verify services status:"
echo "  sudo systemctl status docker"
echo "  sudo systemctl status libvirtd"
echo "  sudo systemctl status sshd"
echo "  sudo systemctl status xrdp"
