#!/usr/bin/env bash
# noctalia-init.sh — install niri + noctalia (v5) via paru su Arch/CachyOS.
# Idempotent (--needed). Zero prompts (--noconfirm --skipreview).
#
# Uso:
#   bash -c "$(curl -sL https://raw.githubusercontent.com/osharko/configure-work-machine/cachy-niri/noctalia-init.sh)"
#
# Per setup completo macchina (chezmoi, dotfiles, profili) usa invece bootstrap.sh.

set -euo pipefail

if ! command -v paru >/dev/null 2>&1; then
    cat <<EOF
✗ paru non installato.
Installa prima con:
  sudo pacman -S --needed git base-devel
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  cd /tmp/paru && makepkg -si
Poi rilancia questo script.
EOF
    exit 1
fi

echo "→ paru install: niri + noctalia-git (v5)"
paru -Sy --noconfirm --skipreview --needed niri noctalia-git

echo ""
echo "✓ niri + noctalia installati."
echo ""
echo "Prossimo step (autologin + auto-launch desktop su tty1):"
echo "  vedi run_once_after_85-autologin-niri.sh.tmpl in questo repo"
echo "  oppure:"
echo "    sudo mkdir -p /etc/systemd/system/getty@tty1.service.d"
echo "    sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF"
echo "    [Service]"
echo "    ExecStart="
echo "    ExecStart=-/usr/bin/agetty --autologin \$USER --noclear %I \\\$TERM"
echo "    EOF"
echo "    # poi in ~/.config/fish/config.fish:"
echo "    #   if not set -q WAYLAND_DISPLAY; and test (tty) = /dev/tty1"
echo "    #       exec niri-session"
echo "    #   end"
echo "    sudo systemctl daemon-reload && sudo systemctl reboot"
