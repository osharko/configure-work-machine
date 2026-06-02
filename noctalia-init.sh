#!/usr/bin/env bash
# noctalia-init.sh — install + autosetup niri + noctalia (v5) su Arch/CachyOS.
# Idempotente: skip install se i binari già presenti; setup tutto via systemd.
#
# Cosa fa:
#   1. paru -S niri noctalia-git (solo se mancanti)
#   2. /etc/systemd/system/getty@tty1.service.d/autologin.conf (autologin tty1
#      → PAM session → seat0 → user@1000.service)
#   3. ~/.config/systemd/user/niri-session.service (WantedBy=default.target)
#   4. systemctl --user enable niri-session.service
#   5. loginctl enable-linger osharko (user@ parte a boot)
#
# Boot flow: agetty autologin → login PAM → fish (no hack) + user@1000.service
# → niri-session.service triggers → niri-session script in systemd-user context
# → fast-path detects MANAGERPID systemd-user → exec niri --session diretto.
#
# Uso:
#   bash -c "$(curl -sL https://raw.githubusercontent.com/osharko/configure-work-machine/cachy-niri/noctalia-init.sh)"

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
if [[ -f "$AUTOLOGIN_CONF" ]] && sudo grep -q "autologin $USER" "$AUTOLOGIN_CONF" 2>/dev/null; then
    echo "✓ autologin getty@tty1 già configurato per $USER"
else
    echo "→ configuro autologin getty@tty1 per $USER (sudo)"
    sudo mkdir -p "$(dirname "$AUTOLOGIN_CONF")"
    sudo tee "$AUTOLOGIN_CONF" > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
EOF
    sudo systemctl daemon-reload
fi

# ─── 3. niri-session.service (systemd-user) ─────────────────────────────────
SERVICE_FILE=~/.config/systemd/user/niri-session.service
mkdir -p "$(dirname "$SERVICE_FILE")"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Avvia la sessione Niri

[Service]
ExecStart=/usr/bin/niri-session
Restart=on-failure

[Install]
WantedBy=default.target
EOF
echo "✓ scritto $SERVICE_FILE"

# ─── 4. Enable + linger ─────────────────────────────────────────────────────
systemctl --user daemon-reload
systemctl --user enable niri-session.service >/dev/null 2>&1
echo "✓ systemctl --user enable niri-session.service"

if loginctl show-user "$USER" 2>/dev/null | grep -q "Linger=yes"; then
    echo "✓ linger già attivo per $USER"
else
    sudo loginctl enable-linger "$USER"
    echo "✓ loginctl enable-linger $USER"
fi

# ─── 5. niri config + spawn-at-startup noctalia ─────────────────────────────
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
echo "  Al boot: agetty autologin → user@1000 → niri-session.service → niri + noctalia"
