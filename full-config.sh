#!/usr/bin/env bash
# full-config.sh — config completa: scrive chezmoi.toml + diff + (opzionale) apply.
#
# Precondizioni:
#   - op signin attivo  (lanciato basic-config.sh almeno una volta)
#   - ~/.config/configure-work-machine/config.env presente con tutti i campi
#   - item 1P op://$OP_VAULT/$OP_ITEM con email/gitName/opAccountUrl
#
# Workflow:
#   1) Carica .env e verifica precondizioni — exit 1 se manca qualcosa
#   2) Legge identità da 1Password
#   3) Scrive ~/.config/chezmoi/chezmoi.toml (sourceDir + data combinati)
#   4) chezmoi diff
#   5) Se --apply (o YES=1): chezmoi apply -v
#
# Args:
#   --config PATH    .env da usare (default: ~/.config/configure-work-machine/config.env)
#   --apply          esegue chezmoi apply -v dopo il diff
#   --quiet          no diff verbose, solo summary
#
# Env: REPO_DIR, CONFIG_ENV, APPLY=1, QUIET=1
set -euo pipefail

# REPO_DIR è settato da bootstrap.sh (dir tmp dove è stato estratto il tarball).
# Se lo script viene lanciato standalone, derivalo dal percorso dello script stesso.
REPO_DIR="${REPO_DIR:-$(dirname "$(readlink -f "$0")")}"
CONFIG_ENV="${CONFIG_ENV:-$HOME/.config/configure-work-machine/config.env}"
APPLY="${APPLY:-0}"
QUIET="${QUIET:-0}"

while [ $# -gt 0 ]; do
    case "$1" in
        --config) CONFIG_ENV="$2"; shift 2 ;;
        --apply)  APPLY=1; shift ;;
        --quiet)  QUIET=1; shift ;;
        -h|--help) sed -n '2,/^set -euo/p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *) echo "Argomento sconosciuto: $1" >&2; exit 2 ;;
    esac
done

# ─── helpers ────────────────────────────────────────────────────────────────
say()  { printf "\n\033[1;34m──\033[0m \033[1m%s\033[0m\n" "$*"; }
ok()   { printf "\033[1;32m✓\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m⚠\033[0m %s\n" "$*" >&2; }
err()  { printf "\033[1;31m✗\033[0m %s\n" "$*" >&2; }
die()  { err "$*"; exit 1; }

# ─── 1. precondizioni ───────────────────────────────────────────────────────
say "Step 1/4 — Verifica precondizioni"

MISSING=()

command -v chezmoi >/dev/null 2>&1 || MISSING+=("comando 'chezmoi' (lancia basic-config.sh prima)")
command -v jq >/dev/null 2>&1      || MISSING+=("comando 'jq'")
[ -f "$REPO_DIR/.chezmoidata/packages.yaml" ] || MISSING+=("source repo invalido: $REPO_DIR (manca .chezmoidata/)")
[ -f "$CONFIG_ENV" ]               || MISSING+=("config env: $CONFIG_ENV (lancia basic-config.sh)")

# Carica .env se esiste
if [ -f "$CONFIG_ENV" ]; then
    # shellcheck disable=SC1090
    set -a; source "$CONFIG_ENV"; set +a

    REQUIRED_VARS=(HOSTNAME_VAL HAS_FINGERPRINT AUTOLOGIN_TTY PASSWORDLESS_SUDO PASSWORDLESS_KEYRING SSHD_ENABLED
        DISABLE_AMDGPU_PSR INSTALL_PROFILES USE_NOCTALIA_CONFIG DOWNLOAD_WALLPAPERS NOCTALIA_FORCE_REFRESH
        VAULT_PROVIDER OP_VAULT OP_IDENTITY_ITEM OP_SSH_ITEM OP_ACCOUNT_URL AUTHORIZED_KEYS_FALLBACK)
    # SSH_EXTRA_IDENTITIES è opzionale (default vuoto) — non required
    SSH_EXTRA_IDENTITIES="${SSH_EXTRA_IDENTITIES:-}"
    for var in "${REQUIRED_VARS[@]}"; do
        if [ -z "${!var:-}" ]; then
            MISSING+=("variabile $var nel .env")
        fi
    done
    grep -q '^DISTROBOXES=' "$CONFIG_ENV" || MISSING+=("variabile DISTROBOXES nel .env (può essere vuota)")

    # Vault provider gating: op CLI obbligatorio solo se 1password
    if [ "${VAULT_PROVIDER:-}" = "1password" ]; then
        command -v op >/dev/null 2>&1 || MISSING+=("comando 'op' (vault=1password)")
        if ! op account list 2>/dev/null | tail -n +2 | grep -q .; then
            MISSING+=("op account configurato (lancia basic-config.sh)")
        fi
    fi
fi

if [ ${#MISSING[@]} -gt 0 ]; then
    err "Precondizioni non soddisfatte:"
    for m in "${MISSING[@]}"; do printf "    - %s\n" "$m" >&2; done
    exit 1
fi
ok "tutte le precondizioni soddisfatte"

# ─── 2. identità (1Password o secrets.env) ──────────────────────────────────
say "Step 2/4 — Lettura identità (vault=$VAULT_PROVIDER)"

if [ "$VAULT_PROVIDER" = "1password" ]; then
    IDENTITY_REF="op://$OP_VAULT/$OP_IDENTITY_ITEM"
    SSH_REF="op://$OP_VAULT/$OP_SSH_ITEM"

    EMAIL=$(op read "$IDENTITY_REF/Email" 2>/dev/null || op read "$IDENTITY_REF/email" 2>/dev/null) \
        || die "op read $IDENTITY_REF/Email fallito"
    GIT_NAME=$(op read "$IDENTITY_REF/User" 2>/dev/null \
            || op read "$IDENTITY_REF/name" 2>/dev/null) \
        || die "op read $IDENTITY_REF/User fallito"
    SIGN_KEY=$(op read "$SSH_REF/public key" 2>/dev/null || true)
else
    SECRETS_FILE="$HOME/.config/configure-work-machine/secrets.env"
    [ -f "$SECRETS_FILE" ] || die "secrets.env mancante: $SECRETS_FILE (vault=env)"
    # shellcheck disable=SC1090
    set -a; source "$SECRETS_FILE"; set +a
    [ -z "${EMAIL:-}" ]    && die "EMAIL vuota in secrets.env"
    [ -z "${GIT_NAME:-}" ] && die "GIT_NAME vuoto in secrets.env"
    SIGN_KEY="${SIGNING_KEY:-}"
fi

ok "email:       $EMAIL"
ok "git name:    $GIT_NAME"
ok "op URL:      $OP_ACCOUNT_URL"
if [ -n "$SIGN_KEY" ]; then
    ok "ssh signing: public key disponibile"
else
    warn "ssh signing: public key non disponibile (signing sarà disabilitato)"
fi

# ─── 3. scrivi chezmoi.toml ─────────────────────────────────────────────────
say "Step 3/4 — Scrittura ~/.config/chezmoi/chezmoi.toml"

# Cleanup eventuali source dir stale
if [ -d "$HOME/.local/share/chezmoi" ]; then
    warn "Rimuovo source stale ~/.local/share/chezmoi/ (sourceDir andrà a $REPO_DIR)"
    rm -rf "$HOME/.local/share/chezmoi"
fi

# Render array of tables [[data.distroboxes]] dal CSV — SEMPRE presente nel
# .toml (anche se vuoto): i template fanno `range .distroboxes`, manca la
# chiave → errore "map has no entry for key distroboxes".
DISTROBOX_TOML=""
if [ -n "${DISTROBOXES:-}" ]; then
    IFS=',' read -ra _BOXES <<< "$DISTROBOXES"
    for _box in "${_BOXES[@]}"; do
        _name="${_box%%|*}"
        _image="${_box#*|}"
        [ -z "$_name" ] || [ -z "$_image" ] && continue
        DISTROBOX_TOML+="
[[data.distroboxes]]
  name = \"$_name\"
  image = \"$_image\""
    done
fi
# Se nessun distrobox configurato, scriviamo comunque un array vuoto inline
if [ -z "$DISTROBOX_TOML" ]; then
    DISTROBOX_TOML="
  distroboxes = []"
fi

# Render install_profiles come array TOML (es. ["base","dev"])
PROFILES_TOML=$(echo "$INSTALL_PROFILES" | awk -F',' '{
    out="[";
    for (i=1; i<=NF; i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", $i);
        if ($i != "") out = out "\"" $i "\",";
    }
    sub(/,$/, "", out); out = out "]";
    print out;
}')

# Resolve profili → calcola pacman_sections, aur_sections, enable_flatpak
# Unisce le sezioni di TUTTI i profili attivi, dedupe, scrive come array TOML.
PROFILES_YAML="$REPO_DIR/.chezmoidata/profiles.yaml"
[ -f "$PROFILES_YAML" ] || die "$PROFILES_YAML mancante"

ACTIVE_LIST=$(echo "$INSTALL_PROFILES" | tr ',' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//;/^$/d')

PAC_SET=$(while IFS= read -r p; do
    yq -r ".profiles.\"$p\".pacman[]? // empty" "$PROFILES_YAML"
done <<< "$ACTIVE_LIST" | awk '!seen[$0]++' | paste -sd, -)
AUR_SET=$(while IFS= read -r p; do
    yq -r ".profiles.\"$p\".aur[]? // empty" "$PROFILES_YAML"
done <<< "$ACTIVE_LIST" | awk '!seen[$0]++' | paste -sd, -)
FLATPAK_LIST=$(while IFS= read -r p; do
    yq -r ".profiles.\"$p\".flatpak // false" "$PROFILES_YAML"
done <<< "$ACTIVE_LIST")
if echo "$FLATPAK_LIST" | grep -qx true; then
    FLATPAK_ANY=true
else
    FLATPAK_ANY=false
fi

# CSV → array TOML
csv_to_toml() {
    echo "$1" | awk -F',' '{
        out="["; for (i=1;i<=NF;i++) if ($i!="") out=out"\""$i"\",";
        sub(/,$/,"",out); out=out"]"; print out
    }'
}
PAC_SECTIONS_TOML=$(csv_to_toml "$PAC_SET")
AUR_SECTIONS_TOML=$(csv_to_toml "$AUR_SET")

# is_work_machine = true se "work" tra i profili attivi (semantica derivata)
if echo ",$INSTALL_PROFILES," | grep -q ',work,'; then
    IS_WORK_MACHINE=true
else
    IS_WORK_MACHINE=false
fi

ok "Profili attivi: $INSTALL_PROFILES"
ok "  pacman sections: $PAC_SET"
ok "  aur sections:    $AUR_SET"
ok "  flatpak:         $FLATPAK_ANY"
ok "  is_work_machine: $IS_WORK_MACHINE (derivato)"

mkdir -p "$HOME/.config/chezmoi"
cat > "$HOME/.config/chezmoi/chezmoi.toml" <<EOF
sourceDir = "$REPO_DIR"

[data]
  email = "$EMAIL"
  git_name = "$GIT_NAME"
  signing_key = "${SIGN_KEY//\"/\\\"}"
  has_fingerprint = $HAS_FINGERPRINT
  is_work_machine = $IS_WORK_MACHINE
  autologin_tty = $AUTOLOGIN_TTY
  passwordless_sudo = $PASSWORDLESS_SUDO
  passwordless_keyring = $PASSWORDLESS_KEYRING
  sshd_enabled = $SSHD_ENABLED
  disable_amdgpu_psr = $DISABLE_AMDGPU_PSR
  use_noctalia_config = $USE_NOCTALIA_CONFIG
  download_wallpapers = $DOWNLOAD_WALLPAPERS
  noctalia_force_refresh = $NOCTALIA_FORCE_REFRESH
  ssh_extra_identities = "$SSH_EXTRA_IDENTITIES"
  install_profiles = $PROFILES_TOML
  pacman_sections = $PAC_SECTIONS_TOML
  aur_sections = $AUR_SECTIONS_TOML
  enable_flatpak = $FLATPAK_ANY
  vault_provider = "$VAULT_PROVIDER"
  op_account_url = "$OP_ACCOUNT_URL"
  op_vault = "$OP_VAULT"
  op_identity_item = "$OP_IDENTITY_ITEM"
  op_ssh_item = "$OP_SSH_ITEM"
  authorized_keys_fallback = $AUTHORIZED_KEYS_FALLBACK
$DISTROBOX_TOML
EOF
ok "chezmoi.toml scritto"

# NB: 'chezmoi init' NON serve qui — il toml è già scritto a mano sopra
# (con sourceDir + tutti i .data). chezmoi apply/diff lo leggerà direttamente.

# ─── 4. diff + apply ────────────────────────────────────────────────────────
say "Step 4/4 — chezmoi diff"
if [ "$QUIET" = "1" ]; then
    DIFF_COUNT=$(chezmoi diff 2>/dev/null | wc -l)
    echo "  $DIFF_COUNT righe di diff pendenti"
else
    if chezmoi diff --color=always 2>&1 | head -c 1 | grep -q .; then
        if command -v less >/dev/null; then chezmoi diff --color=always | less -R
        else chezmoi diff; fi
    else
        ok "filesystem già allineato — nessun apply necessario"
    fi
fi

if [ "$APPLY" = "1" ]; then
    say "chezmoi apply -v"
    chezmoi apply -v
    ok "Apply completo"
    cat <<EOF

  Prossimi passi:
  - Reboot consigliato (gruppi: i2c, libvirt, docker, input)
  - Fingerprint: fprintd-enroll (dopo reboot)
  - Verifica: distrobox list / fprintd-list / systemctl status

EOF
else
    cat <<EOF

  Per applicare:
    ./full-config.sh --apply
  Oppure direttamente:
    chezmoi apply -v

EOF
fi
