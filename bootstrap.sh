#!/usr/bin/env bash
# bootstrap.sh — download tarball + esegue da /tmp, niente repo locale persistente.
#
# Uso:
#   bash -c "$(curl -sL https://raw.githubusercontent.com/osharko/configure-work-machine/cachy-niri/bootstrap.sh)"
#
# Note:
# - Niente `git clone`: scarico tarball da GitHub, estraggo in /tmp, eseguo.
#   A fine run (anche su errore via trap) la dir tmp viene cancellata.
# - Niente `curl ... | bash`: il bash da pipe perde controlling tty, prompt
#   interattivi falliscono. Forzo errore esplicito in quel caso.
# - chezmoi state + config.env restano persistenti in ~/.config/ e
#   ~/.local/share/chezmoi/ (sopravvivono al cleanup tmp).
set -euo pipefail

REPO="${REPO:-osharko/configure-work-machine}"
BRANCH="${REPO_BRANCH:-cachy-niri}"

# ─── stdin tty obbligatorio ─────────────────────────────────────────────────
if [ ! -t 0 ]; then
    cat <<EOF >&2
✗ Questo script richiede un terminale interattivo (stdin tty).

  Stai usando \`curl ... | bash\` — il bash da pipe perde il controlling tty
  e i prompt (gum, op signin) non funzionano. Usa invece command substitution
  (mantiene stdin del terminale):

      bash -c "\$(curl -sL https://raw.githubusercontent.com/${REPO}/${BRANCH}/bootstrap.sh)"
EOF
    exit 1
fi

# ─── prereq minimi (curl + tar) ─────────────────────────────────────────────
for tool in curl tar; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "→ $tool mancante, installo via pacman..."
        sudo pacman -Sy --needed --noconfirm "$tool"
    fi
done

# ─── download tarball in dir tmp + cleanup automatico su exit ──────────────
WORKDIR=$(mktemp -d -t configure-work-machine-XXXXXX)
trap 'rm -rf "$WORKDIR"' EXIT

TARBALL_URL="https://github.com/${REPO}/archive/${BRANCH}.tar.gz"
echo "── Bootstrap: scarico ${REPO}@${BRANCH} → ${WORKDIR} ──"
curl -fsSL "$TARBALL_URL" | tar -xz -C "$WORKDIR" --strip-components=1

cd "$WORKDIR"
chmod +x basic-config.sh full-config.sh

export REPO_DIR="$WORKDIR"
"$WORKDIR/basic-config.sh" "$@"
"$WORKDIR/full-config.sh" --apply

echo
echo "✓ Bootstrap completato. La dir temporanea $WORKDIR verrà rimossa."
