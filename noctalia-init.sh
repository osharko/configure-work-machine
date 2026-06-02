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
# NB: niri-session re-execs come login shell (vedi /usr/bin/niri-session).
# Senza guard env var, l'hook scatena loop infinito (fish→exec niri-session→
# niri-session→exec -l fish→hook fa exec niri-session→loop).
# NIRI_AUTOSTART_GUARD viene esportato → presente al re-exec → blocca seconda fire.
MARKER="spawn niri-session on tty1"

case "$SHELL_NAME" in
    fish)
        SHELL_CONFIG=~/.config/fish/config.fish
        SHELL_SNIPPET='
# '"$MARKER"'
# Guard: niri-session re-execs login shell, evita loop con env var.
if not set -q WAYLAND_DISPLAY
    and not set -q NIRI_AUTOSTART_GUARD
    and test (tty) = /dev/tty1
    set -gx NIRI_AUTOSTART_GUARD 1
    exec niri-session
end'
        ;;
    bash)
        SHELL_CONFIG=~/.bash_profile
        SHELL_SNIPPET='
# '"$MARKER"'
# Guard: niri-session re-execs login shell, evita loop con env var.
if [ -z "$WAYLAND_DISPLAY" ] && [ -z "${NIRI_AUTOSTART_GUARD:-}" ] && [ "$(tty)" = "/dev/tty1" ]; then
    export NIRI_AUTOSTART_GUARD=1
    exec niri-session
fi'
        ;;
    zsh)
        SHELL_CONFIG=~/.zprofile
        SHELL_SNIPPET='
# '"$MARKER"'
# Guard: niri-session re-execs login shell, evita loop con env var.
if [[ -z $WAYLAND_DISPLAY && -z ${NIRI_AUTOSTART_GUARD:-} && $(tty) == /dev/tty1 ]]; then
    export NIRI_AUTOSTART_GUARD=1
    exec niri-session
fi'
        ;;
    *)
        echo "⚠ shell '$SHELL_NAME' non supportata (atteso fish/bash/zsh). Skip shell hook."
        SHELL_CONFIG=""
        ;;
esac

if [[ -n "$SHELL_CONFIG" ]]; then
    mkdir -p "$(dirname "$SHELL_CONFIG")"
    # Se esiste vecchia versione senza guard, rimuovila per ri-aggiungerla corretta
    if [[ -f "$SHELL_CONFIG" ]] && grep -q "$MARKER" "$SHELL_CONFIG" && ! grep -q "NIRI_AUTOSTART_GUARD" "$SHELL_CONFIG"; then
        echo "→ rilevato vecchio hook ($SHELL_NAME) senza guard → rimuovo"
        case "$SHELL_NAME" in
            fish)
                awk '/^# '"$MARKER"'$/ {skip=1; next} skip && /^end$/ {skip=0; next} skip {next} {print}' "$SHELL_CONFIG" > "$SHELL_CONFIG.new"
                ;;
            bash)
                awk '/^# '"$MARKER"'$/ {skip=1; next} skip && /^fi$/ {skip=0; next} skip {next} {print}' "$SHELL_CONFIG" > "$SHELL_CONFIG.new"
                ;;
            zsh)
                awk '/^# '"$MARKER"'$/ {skip=1; next} skip && /^\[\[/ {skip=0; print; next} skip {next} {print}' "$SHELL_CONFIG" > "$SHELL_CONFIG.new"
                ;;
        esac
        mv "$SHELL_CONFIG.new" "$SHELL_CONFIG"
    fi

    if grep -q "NIRI_AUTOSTART_GUARD" "$SHELL_CONFIG" 2>/dev/null; then
        echo "✓ shell hook ($SHELL_NAME) con guard già presente"
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
