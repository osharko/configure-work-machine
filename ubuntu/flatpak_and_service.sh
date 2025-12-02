#!/bin/bash

set -e

echo "=== Configuring services and installing Flatpak applications ==="

# Enable Docker
if command -v docker &> /dev/null; then
    sudo systemctl --now enable docker
    sudo usermod -aG docker $(whoami)
    echo "✓ Docker enabled and user added to docker group"
fi

# Enable libvirt (if installed via brew in zsh.sh)
if command -v virsh &> /dev/null; then
    sudo systemctl enable --now libvirtd || true
    sudo usermod -aG libvirt $(whoami) || true
    echo "✓ Libvirt enabled and user added to libvirt group"
fi

# Enable SSH daemon
if command -v sshd &> /dev/null || [ -f /usr/sbin/sshd ]; then
    sudo systemctl enable --now ssh || sudo systemctl enable --now sshd
    echo "✓ SSH daemon enabled"
fi

# XRDP (Remote Desktop) - Optional for Ubuntu
read -p "Do you want to install and enable XRDP (Remote Desktop)? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo apt install xrdp -y
    sudo systemctl enable --now xrdp
    # Allow XRDP through firewall if UFW is active
    if command -v ufw &> /dev/null && sudo ufw status | grep -q "Status: active"; then
        sudo ufw allow 3389/tcp
        echo "✓ XRDP port allowed through UFW firewall"
    fi
    echo "✓ XRDP enabled"
fi

# Install Flatpak applications
echo "Installing Flatpak applications..."

# Ensure flatpak is installed
if ! command -v flatpak &> /dev/null; then
    sudo apt install flatpak -y
    # Add Flathub repository
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Install applications
flatpak install -y flathub \
    org.telegram.desktop \
    com.thincast.client \
    com.system76.Popsicle \
    io.dbeaver.DBeaverCommunity \
    io.beekeeperstudio.Studio || {
        echo "Some flatpak installations failed, continuing..."
    }

echo "=== Services configured and Flatpak applications installed ==="
echo ""
echo "Note: You may need to log out and log back in for group changes (docker, libvirt) to take effect"
