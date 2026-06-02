#!/usr/bin/env bash
# noctalia-init.sh — install + autosetup niri + noctalia (v5) su Arch/CachyOS.
# Idempotente: skip install se i binari già presenti; idempotente sui config (no doppi append).
#
# Cosa fa:
#   1. paru -S niri noctalia-git (solo se mancanti)
#   2. /etc/systemd/system/getty@tty1.service.d/autologin.conf (autologin tty1)
#   3. ~/.config/<shell>/... → exec niri-session su tty1
#   4. ~/.config/niri/config.kdl → spawn-at-startup noctalia
#   5. systemctl daemon-reload
#
# Uso:
#   bash -c "$(curl -sL https://raw.githubusercontent.com/osharko/configure-work-machine/cachy-niri/noctalia-init.sh)"
#
# Setup completo macchina (chezmoi, dotfiles, profili) → bootstrap.sh.

set -euo pipefail

# ─── 1. INSTALL (skip se già presente) ─────────────────────────────────────
if command -v niri >/dev/null 2>&1 && command -v noctalia >/dev/null 2>&1; then
    echo "✓ niri + noctalia già presenti — skip install."
else
    if ! command -v paru >/dev/null 2>&1; then
        cat <<EOF
✗ paru non installato. Installa con:
  sudo pacman -S --needed git base-devel
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  cd /tmp/paru && makepkg -si
Poi rilancia.
EOF
        exit 1
    fi
    echo "→ paru install: niri + noctalia-git"
    paru -Sy --noconfirm --skipreview --needed niri noctalia-git
fi

# ─── 2. Autologin getty@tty1 ────────────────────────────────────────────────
AUTOLOGIN_CONF=/etc/systemd/system/getty@tty1.service.d/autologin.conf
EXPECTED_AUTOLOGIN="[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM"

if [[ -f "$AUTOLOGIN_CONF" ]] && sudo cat "$AUTOLOGIN_CONF" 2>/dev/null | grep -q "autologin $USER"; then
    echo "✓ autologin getty@tty1 già configurato per $USER"
else
    echo "→ configuro autologin getty@tty1 per $USER (sudo)"
    sudo mkdir -p "$(dirname "$AUTOLOGIN_CONF")"
    echo "$EXPECTED_AUTOLOGIN" | sudo tee "$AUTOLOGIN_CONF" > /dev/null
    sudo systemctl daemon-reload
fi

# ─── 3. Shell hook → exec niri-session su tty1 ──────────────────────────────
SHELL_NAME=$(basename "$SHELL")
MARKER="spawn niri-session on tty1"

case "$SHELL_NAME" in
    fish)
        SHELL_CONFIG=~/.config/fish/config.fish
        SHELL_SNIPPET='
# '"$MARKER"'
if not set -q WAYLAND_DISPLAY
    and test (tty) = /dev/tty1
    exec niri-session
end'
        ;;
    bash)
        SHELL_CONFIG=~/.bash_profile
        SHELL_SNIPPET='
# '"$MARKER"'
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec niri-session
fi'
        ;;
    zsh)
        SHELL_CONFIG=~/.zprofile
        SHELL_SNIPPET='
# '"$MARKER"'
[[ -z $WAYLAND_DISPLAY && $(tty) == /dev/tty1 ]] && exec niri-session'
        ;;
    *)
        echo "⚠ shell '$SHELL_NAME' non supportata (atteso fish/bash/zsh). Skip shell hook."
        SHELL_CONFIG=""
        ;;
esac

if [[ -n "$SHELL_CONFIG" ]]; then
    mkdir -p "$(dirname "$SHELL_CONFIG")"
    if grep -q "$MARKER" "$SHELL_CONFIG" 2>/dev/null; then
        echo "✓ shell hook ($SHELL_NAME) già presente in $SHELL_CONFIG"
    else
        echo "→ aggiungo shell hook ($SHELL_NAME) a $SHELL_CONFIG"
        echo "$SHELL_SNIPPET" >> "$SHELL_CONFIG"
    fi
fi

# ─── 4. niri config + spawn-at-startup noctalia ─────────────────────────────
NIRI_CONFIG=~/.config/niri/config.kdl
mkdir -p ~/.config/niri

if [[ ! -f "$NIRI_CONFIG" ]]; then
    echo "→ creo niri config minimale + autostart noctalia"
    cat > "$NIRI_CONFIG" <<'EOF'
// Autostart
spawn-at-startup "noctalia"

// Keybinds (Mod = Super)
binds {
    Mod+Return { spawn "ghostty"; }
    Mod+Q { close-window; }
    CTRL+ALT+Delete { quit; }
}
EOF
elif ! grep -q 'spawn-at-startup.*noctalia' "$NIRI_CONFIG"; then
    echo "→ aggiungo spawn-at-startup noctalia a niri config esistente"
    echo '' >> "$NIRI_CONFIG"
    echo 'spawn-at-startup "noctalia"' >> "$NIRI_CONFIG"
else
    echo "✓ niri config con spawn-at-startup noctalia già configurato"
fi

# ─── Done ───────────────────────────────────────────────────────────────────
echo ""
echo "✓ Setup completato."
echo "  Riavvia con: sudo systemctl reboot"
echo "  Al boot: tty1 autologin $USER → $SHELL_NAME → exec niri-session → niri + noctalia"
