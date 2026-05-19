#!/usr/bin/env bash
# basic-config.sh — onboarding minimo macchina nuova.
#
# Cosa fa:
#   1) Installa prereq (via paru): chezmoi, git, base-devel, jq, gum, 1password-cli
#   2) Chiede TUI quale vault provider usare (1password | env)
#   3) Setup vault scelto:
#        - 1password: op account add + op signin (QR mobile o Secret Key)
#        - env:       copia .env.personal.example e chiede di editarlo prima di proseguire
#   4) Verifica identità (item 1P Identity+SSH oppure valori in secrets.env)
#   5) Genera ~/.config/configure-work-machine/config.env con flag host + moduli opzionali
#
# Args (tutti opzionali — se mancanti, vengono chiesti via gum):
#   --vault-provider PROV     1password | env  (default: 1password)
#   --email EMAIL             email primaria (anche per 1P)
#   --op-account URL          default: my.1password.com
#   --vault VAULT             default: PersonalConfiguration
#   --identity-item NAME      default: Identity      (Login: Email + User)
#   --ssh-item NAME           default: Default (SSH Key: public key + private key)
#   --git-name "Nome Cognome" se non in git config global
#   --non-interactive         non aprire TUI; errore se manca un required
#
# Env vars equivalenti: VAULT_PROVIDER, EMAIL, OP_ACCOUNT, VAULT,
#   IDENTITY_ITEM, SSH_ITEM, GIT_NAME, NON_INTERACTIVE=1
set -euo pipefail

# ─── parse args ─────────────────────────────────────────────────────────────
# VAULT_PROVIDER: NIENTE default qui — applicato solo se il prompt è skippato
# (NON_INTERACTIVE) o dopo il gum choose. Altrimenti il check "if [ -z ... ]"
# fallirebbe sempre e il prompt non apparirebbe (utente ne ha già beccato uno
# loop di Step 2 ignorato per via del default).
VAULT_PROVIDER="${VAULT_PROVIDER:-}"
EMAIL="${EMAIL:-}"
# OP_ACCOUNT: niente default qui — applicato come default nel prompt o post-skip
OP_ACCOUNT="${OP_ACCOUNT:-}"
VAULT="${VAULT:-PersonalConfiguration}"
IDENTITY_ITEM="${IDENTITY_ITEM:-Identity}"
SSH_ITEM="${SSH_ITEM:-Default}"
GIT_NAME="${GIT_NAME:-}"
NON_INTERACTIVE="${NON_INTERACTIVE:-0}"

while [ $# -gt 0 ]; do
    case "$1" in
        --vault-provider)    VAULT_PROVIDER="$2"; shift 2 ;;
        --email)             EMAIL="$2"; shift 2 ;;
        --op-account)        OP_ACCOUNT="$2"; shift 2 ;;
        --vault)             VAULT="$2"; shift 2 ;;
        --identity-item)     IDENTITY_ITEM="$2"; shift 2 ;;
        --ssh-item)          SSH_ITEM="$2"; shift 2 ;;
        --git-name)          GIT_NAME="$2"; shift 2 ;;
        --non-interactive)   NON_INTERACTIVE=1; shift ;;
        -h|--help)
            sed -n '2,/^set -euo/p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *) echo "Argomento sconosciuto: $1" >&2; exit 2 ;;
    esac
done

# ─── helpers ────────────────────────────────────────────────────────────────
say()   { printf "\n\033[1;34m──\033[0m \033[1m%s\033[0m\n" "$*"; }
ok()    { printf "\033[1;32m✓\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m⚠\033[0m %s\n" "$*" >&2; }
err()   { printf "\033[1;31m✗\033[0m %s\n" "$*" >&2; }
die()   { err "$*"; exit 1; }

ui_input() {
    # $1=prompt $2=default $3=required(0|1) $4=password(0|1)
    local prompt="$1" default="${2:-}" required="${3:-0}" password="${4:-0}" val
    if [ "$NON_INTERACTIVE" = "1" ]; then
        if [ -z "$default" ] && [ "$required" = "1" ]; then
            die "Required mancante (--non-interactive): $prompt"
        fi
        printf '%s' "$default"; return
    fi
    while true; do
        if command -v gum >/dev/null 2>&1; then
            local gum_args=(--prompt="$prompt: " --value="$default")
            [ "$password" = "1" ] && gum_args=(--prompt="$prompt: " --password)
            val=$(gum input "${gum_args[@]}" </dev/tty)
        else
            printf "\033[1;36m?\033[0m %s [%s]: " "$prompt" "$default" >&2
            if [ "$password" = "1" ]; then read -rs val; echo >&2
            else read -r val; fi
            val="${val:-$default}"
        fi
        if [ "$required" = "1" ] && [ -z "$val" ]; then
            warn "Obbligatorio, riprova"; continue
        fi
        break
    done
    printf '%s' "$val"
}

ui_bool() {
    # $1=prompt $2=default(true|false) → stampa 'true' o 'false' su stdout
    local prompt="$1" default="${2:-false}"
    if [ "$NON_INTERACTIVE" = "1" ]; then
        printf '%s' "$default"; return
    fi
    if command -v gum >/dev/null 2>&1; then
        local args=(--default=true "$prompt")
        [ "$default" = "false" ] && args=(--default=false "$prompt")
        if gum confirm "${args[@]}" </dev/tty; then echo true; else echo false; fi
    else
        local pmt
        if [ "$default" = "false" ]; then pmt="$prompt [y/N] "
        else pmt="$prompt [Y/n] "; fi
        printf "\033[1;36m?\033[0m %s" "$pmt" >&2
        read -r ans
        case "$ans" in
            [Yy]|[Yy][Ee][Ss]|true)  echo true ;;
            [Nn]|[Nn][Oo]|false)     echo false ;;
            *)                       echo "$default" ;;
        esac
    fi
}

# ─── 0. Carica .env esistente per fornire default agli step seguenti ───────
# Ordine di priorità per ogni var:
#   1. env CLI (passata via `VAR=val ./bootstrap.sh` o export)
#   2. valore corrente in .env (se file presente)
#   3. prompt TUI / default hardcoded
#
# Source SOLO se var non già valorizzata via CLI (check :- = set+nonempty).
ENV_FILE="$HOME/.config/configure-work-machine/config.env"

# Migrazione one-shot: ~/.config/chez-osharko-niri/ → ~/.config/configure-work-machine/
# (legacy nome dir prima del rename repo). Idempotente.
OLD_DIR="$HOME/.config/chez-osharko-niri"
NEW_DIR="$HOME/.config/configure-work-machine"
if [ -d "$OLD_DIR" ] && [ ! -d "$NEW_DIR" ]; then
    mv "$OLD_DIR" "$NEW_DIR"
    ok "Migrato $OLD_DIR → $NEW_DIR"
elif [ -d "$OLD_DIR" ] && [ -d "$NEW_DIR" ]; then
    warn "Entrambe $OLD_DIR e $NEW_DIR esistono — controlla manualmente, non sovrascrivo"
fi

if [ -f "$ENV_FILE" ]; then
    while IFS= read -r line; do
        case "$line" in
            ''|\#*) continue ;;
        esac
        if [[ "$line" =~ ^([A-Z_][A-Z_0-9]*)=\"?(.*[^\"])\"?$ ]] || [[ "$line" =~ ^([A-Z_][A-Z_0-9]*)=(.*)$ ]]; then
            k="${BASH_REMATCH[1]}"
            v="${BASH_REMATCH[2]}"
            v="${v#\"}"; v="${v%\"}"
            # `HOSTNAME` collide con bash builtin (auto-set dal sistema):
            # rinominalo a HOSTNAME_VAL in lettura. Backward compat per .env vecchi.
            [ "$k" = "HOSTNAME" ] && k="HOSTNAME_VAL"
            if [ -z "${!k:-}" ]; then
                export "$k=$v"
            fi
        fi
    done < "$ENV_FILE"

    # Mapping nomi .env → script vars (alcuni differiscono per legacy)
    [ -z "${OP_ACCOUNT:-}" ]        && OP_ACCOUNT="${OP_ACCOUNT_URL:-}"
    [ -z "${VAULT:-}" ]             && VAULT="${OP_VAULT:-}"
    [ -z "${IDENTITY_ITEM:-}" ]     && IDENTITY_ITEM="${OP_IDENTITY_ITEM:-}"
    [ -z "${SSH_ITEM:-}" ]          && SSH_ITEM="${OP_SSH_ITEM:-}"
    [ -z "${DISTROBOXES_LIST:-}" ]  && DISTROBOXES_LIST="${DISTROBOXES:-}"
fi

# ─── 1. prereq via paru (uniforme repo+AUR) ─────────────────────────────────
# L'install prereq viene SEMPRE prima della scelta vault provider:
# - paru e gum servono per la TUI interattiva successiva
# - chezmoi/jq/base-devel servono ovunque
# - 1password-cli viene installato sempre (anche se poi sceglie vault=env):
#   meglio avere op disponibile per usi futuri che gestire 2 install flow
say "Step 1/5 — Prerequisiti (install via paru)"

# A. paru: preinstallato su CachyOS; bootstrap solo su Arch vanilla
if ! command -v paru >/dev/null 2>&1; then
    echo "  paru mancante (probabile Arch vanilla) → bootstrap via paru-bin AUR"
    sudo pacman -Sy --needed --noconfirm git base-devel
    tmpdir=$(mktemp -d)
    git clone --quiet https://aur.archlinux.org/paru-bin.git "$tmpdir"
    ( cd "$tmpdir" && makepkg -si --noconfirm )
    rm -rf "$tmpdir"
    ok "paru installato"
else
    ok "paru presente: $(command -v paru)"
fi

# B. Keyring refresh (best practice Arch)
sudo pacman -Sy --needed --noconfirm archlinux-keyring

# C. Tutti i prereq sempre (anche 1password-cli se vault=env: ~10MB, niente di che)
# `yq` serve a full-config.sh per resolvere i profili da .chezmoidata/profiles.yaml.
PREREQ=(chezmoi git base-devel jq yq gum 1password-cli)
MISSING=()
for p in "${PREREQ[@]}"; do
    pacman -Q "$p" >/dev/null 2>&1 || MISSING+=("$p")
done
if [ ${#MISSING[@]} -gt 0 ]; then
    echo "  paru install: ${MISSING[*]}"
    echo "  ⏳ paru in esecuzione — può richiedere 1-5 min (download + build AUR)."
    echo "     Se sembra fermo: paru lavora in silenzio durante download/build, non killare."
    paru -S --needed --noconfirm --sudoloop "${MISSING[@]}"
else
    ok "tutti i prereq presenti"
fi

# ─── 2. Vault provider choice (1password | env) ─────────────────────────────
# Skip prompt se env var già passata.
say "Step 2/5 — Scelta vault provider"

if [ -z "$VAULT_PROVIDER" ] && [ "$NON_INTERACTIVE" = "0" ]; then
    VAULT_PROVIDER=$(gum choose \
        --header="Quale signin vuoi configurare per email/name/ssh-key?" \
        --selected="1password" \
        1password env)
fi
# Fallback default se ancora vuoto (NON_INTERACTIVE senza env var)
VAULT_PROVIDER="${VAULT_PROVIDER:-1password}"

case "$VAULT_PROVIDER" in
    1password|env) ;;
    *) die "VAULT_PROVIDER non valido: '$VAULT_PROVIDER' (deve essere '1password' o 'env')" ;;
esac
ok "Vault provider: $VAULT_PROVIDER"

# ─── 2. Vault signin / secrets.env ──────────────────────────────────────────
say "Step 3/5 — Vault setup ($VAULT_PROVIDER)"

if [ "$VAULT_PROVIDER" = "1password" ]; then
    # 1Password desktop: serve per il QR pairing + 1P SSH agent (signing).
    # Usiamo 1password-beta (variante in packages.yaml). Se è già installato
    # il pkg stable o beta, skip.
    if ! pacman -Q 1password-beta >/dev/null 2>&1 && ! pacman -Q 1password >/dev/null 2>&1; then
        echo "  → install 1Password desktop beta (app GUI: QR pairing + SSH agent)"
        echo "  ⏳ AUR build, può richiedere 1-3 min — paru sembra fermo ma sta lavorando."
        paru -S --needed --noconfirm --sudoloop 1password-beta
    fi

    if op account list 2>/dev/null | tail -n +2 | grep -q .; then
        ok "account 1Password già configurato"
        op account list 2>/dev/null | sed 's/^/    /'
    else
        [ -z "$EMAIL" ] && EMAIL="$(git config --global --get user.email 2>/dev/null || true)"
        # Skip prompt se env var già passata (ui_input chiede sempre in modalità
        # interattiva anche con default — necessario wrap esplicito).
        [ -z "$EMAIL" ]      && EMAIL=$(ui_input "Email 1Password" "$EMAIL" 1)
        [ -z "$OP_ACCOUNT" ] && OP_ACCOUNT=$(ui_input "1Password account URL" "my.1password.com" 1)

        cat <<EOF

  🔐 op signin — due modalità di sign-in:

  A) Con 1Password desktop sbloccato (consigliato):
     - apri 1Password desktop (\`1password\` da CLI o launcher)
     - Settings → Developer → "Integrate with 1Password CLI" → ON
     - una volta sbloccato, \`op\` legge la session dall'agent → niente prompt

  B) Manuale (senza desktop):
     - tieni a portata Secret Key + Master Password
     - la Secret Key è nel pannello web 1password.com → My Profile → Setup
       Code → "Show Setup Code" (formato: A3-XXXXXX-XXXXXX-XXXXX-XXXXX...)
     - rispondi ai prompt che seguono

EOF
        op account add --address "$OP_ACCOUNT" --email "$EMAIL"
        eval "$(op signin)"
        ok "1Password loggato come $EMAIL"
    fi

    # Recupera email/account effettivi dall'account loggato
    ACCOUNT_INFO=$(op account list --format=json | jq -r '.[0]')
    EMAIL=$(echo "$ACCOUNT_INFO" | jq -r '.email')
    OP_ACCOUNT=$(echo "$ACCOUNT_INFO" | jq -r '.url' | sed 's|^https://||')
else
    # vault=env → controlla che ~/.config/configure-work-machine/secrets.env esista
    SECRETS_FILE="$HOME/.config/configure-work-machine/secrets.env"
    if [ ! -f "$SECRETS_FILE" ]; then
        mkdir -p "$(dirname "$SECRETS_FILE")"
        cp "$(dirname "$0")/.env.personal.example" "$SECRETS_FILE" 2>/dev/null \
            || die ".env.personal.example non trovato nel repo"
        chmod 0600 "$SECRETS_FILE"
        err "secrets.env appena creato in $SECRETS_FILE"
        echo "    Editalo con i tuoi valori (EMAIL, GIT_NAME, SIGNING_KEY) poi rilancia."
        exit 1
    fi
    # shellcheck disable=SC1090
    set -a; source "$SECRETS_FILE"; set +a
    [ -z "${EMAIL:-}" ]       && die "EMAIL vuota in $SECRETS_FILE"
    [ -z "${GIT_NAME:-}" ]    && die "GIT_NAME vuoto in $SECRETS_FILE"
    [ -z "${SIGNING_KEY:-}" ] && warn "SIGNING_KEY vuota — git signing disabilitato"
    ok "secrets.env caricato: $EMAIL, $GIT_NAME"
fi

# ─── 3. Verifica identità (Identity + SSH Key da 1P oppure secrets.env) ─────
say "Step 4/5 — Verifica identità"

if [ "$VAULT_PROVIDER" = "1password" ]; then
    # --- 3a. Identity (Login: Email + User) ---------------------------------
    if ! op item get "$IDENTITY_ITEM" --vault "$VAULT" --format=json >/dev/null 2>&1; then
        err "Item '$IDENTITY_ITEM' non trovato in '$VAULT'."
        echo "    Lista item:  op item list --vault '$VAULT'"
        echo "    Crea con:    op item create --category=login --vault='$VAULT' --title='$IDENTITY_ITEM' \\"
        echo "                   'Email[email]=tua@email' 'User[text]=Nome Cognome'"
        die "Item Identity obbligatorio"
    fi

    EMAIL_VAL=$(op read "op://$VAULT/$IDENTITY_ITEM/Email" 2>/dev/null \
             || op read "op://$VAULT/$IDENTITY_ITEM/email" 2>/dev/null || true)
    USER_VAL=$(op read "op://$VAULT/$IDENTITY_ITEM/User" 2>/dev/null \
             || op read "op://$VAULT/$IDENTITY_ITEM/name" 2>/dev/null || true)

    if [ -z "$EMAIL_VAL" ] || [ -z "$USER_VAL" ]; then
        [ -z "$EMAIL_VAL" ] && warn "campo 'Email' assente in '$IDENTITY_ITEM'"
        [ -z "$USER_VAL" ]  && warn "campo 'User' assente in '$IDENTITY_ITEM'"
        die "Item Identity incompleto"
    fi
    ok "Identity '$IDENTITY_ITEM' OK — Email: $EMAIL_VAL, User: $USER_VAL"

    # --- 3b. SSH Key (public key + private key) -----------------------------
    if ! op item get "$SSH_ITEM" --vault "$VAULT" --format=json >/dev/null 2>&1; then
        err "Item '$SSH_ITEM' non trovato in '$VAULT'."
        echo "    Crea via UI 1Password: + New → SSH Key → titolo '$SSH_ITEM', vault '$VAULT'"
        echo "    Importa la private key esistente (~/.ssh/id_ed25519) o lascia che 1P ne generi una nuova."
        die "Item SSH Key obbligatorio"
    fi

    PUB_VAL=$(op read "op://$VAULT/$SSH_ITEM/public key" 2>/dev/null || true)
    [ -z "$PUB_VAL" ] && warn "campo 'public key' assente in '$SSH_ITEM' (signing SSH disabilitato)"
    [ -n "$PUB_VAL" ] && ok "SSH '$SSH_ITEM' OK"
else
    # vault=env → SIGNING_KEY già caricato da secrets.env in Step 2
    EMAIL_VAL="$EMAIL"
    USER_VAL="$GIT_NAME"
    PUB_VAL="${SIGNING_KEY:-}"
    ok "Identity da secrets.env — Email: $EMAIL_VAL, User: $USER_VAL"
    if [ "$VAULT_PROVIDER" = "env" ]; then
        echo "    NB: in modalità env la private key NON viene deployata dallo script."
        echo "        Copiala a mano in ~/.ssh/id_ed25519 + chmod 0600 prima di chezmoi apply."
    fi
fi

# Fallback authorized_keys (entrambi i provider): la public key può fare da access key
[ -z "${AUTHORIZED_KEYS_FALLBACK:-}" ] && AUTHORIZED_KEYS_FALLBACK=$(ui_bool \
    "Copiare la public key in ~/.ssh/authorized_keys (per accesso ssh in entrata)?" \
    "true")

# ─── 5. .env host-specific (sempre rigenerato — vedi Step 0 per il merge) ──
say "Step 5/5 — Config host-specific (.env)"

ENV_DIR="$HOME/.config/configure-work-machine"
mkdir -p "$ENV_DIR"

# Da qui in poi i prompt TUI scattano solo se ancora vuoti dopo CLI+existing-env
{
    # Detection automatica
    IS_LUKS=false
    if lsblk -no FSTYPE 2>/dev/null | grep -qx 'crypto_LUKS'; then
        IS_LUKS=true
        ok "Disco LUKS rilevato → defaults adatti: autologin + sudoers passwordless"
    else
        warn "Nessun disco LUKS rilevato → defaults safe: niente autologin tty1, sudo con password"
    fi
    DEF_AUTOLOGIN=$IS_LUKS
    DEF_NOPASSWD=$IS_LUKS

    # Ogni var può essere pre-impostata via env var prima dello script
    # (es. `HOSTNAME_VAL=mybox INSTALL_PROFILES=base,dev bash -c "$(curl ...)"`)
    # In quel caso il prompt è skippato. Altrimenti chiede via TUI.
    [ -z "${HOSTNAME_VAL:-}" ]         && HOSTNAME_VAL=$(ui_input "Hostname della macchina" "$(hostname)" 1)
    [ -z "${HAS_FINGERPRINT:-}" ]      && HAS_FINGERPRINT=$(ui_bool "Fingerprint reader Dell?" "false")
    # NB: AUTOLOGIN_TTY, PASSWORDLESS_SUDO, PASSWORDLESS_KEYRING — niente prompt:
    # gestibili runtime dal plugin Noctalia `permissions-toggles`. Default
    # silenzioso = $IS_LUKS (passwordless se disco crittato).
    [ -z "${AUTOLOGIN_TTY:-}" ]        && AUTOLOGIN_TTY="$DEF_AUTOLOGIN"
    [ -z "${PASSWORDLESS_SUDO:-}" ]    && PASSWORDLESS_SUDO="$DEF_NOPASSWD"
    [ -z "${PASSWORDLESS_KEYRING:-}" ] && PASSWORDLESS_KEYRING="$DEF_NOPASSWD"
    [ -z "${SSHD_ENABLED:-}" ]         && SSHD_ENABLED=$(ui_bool "sshd: abilitare server SSH in entrata?" "true")
    [ -z "${DISABLE_AMDGPU_PSR:-}" ]   && DISABLE_AMDGPU_PSR=$(ui_bool "Disable AMDGPU PSR (workaround flicker iGPU Radeon)?" "false")

    # ─── Moduli opzionali (env-var-overridable) ─────────────────────────────
    if [ -z "${INSTALL_PROFILES:-}" ]; then
        echo
        echo "── Moduli opzionali (richiede input interattivo) ──"
        if command -v gum >/dev/null 2>&1; then
            echo "  → Sto per chiederti quali profili installazione abilitare."
            echo "    Premi Space per toggle, Enter per confermare."
            INSTALL_PROFILES_SEL=$(gum choose --no-limit \
                --header="Profili installazione (Space=toggle, Enter=conferma):" \
                --selected="base,dev,work" \
                base dev work gaming mediacenter 2>/dev/null | tr '\n' ',' | sed 's/,$//')
            INSTALL_PROFILES="${INSTALL_PROFILES_SEL:-base,dev}"
        else
            INSTALL_PROFILES=$(ui_input "Profili installazione CSV (base/dev/work/gaming/mediacenter)" "base,dev,work" 1)
        fi
    fi
    [ -z "${USE_NOCTALIA_CONFIG:-}" ]   && USE_NOCTALIA_CONFIG=$(ui_bool "Applicare config Noctalia (settings.json, plugins, bar/dock)?" "true")
    [ -z "${DOWNLOAD_WALLPAPERS:-}" ]   && DOWNLOAD_WALLPAPERS=$(ui_bool "Scaricare i 20 wallpaper preset?" "true")
    # NOCTALIA_FORCE_REFRESH: forzare refresh di settings.json/plugins.json dal template?
    # Default false: preserva tweak UI. True: backup + rebuild ogni volta che live ≠ template.
    [ -z "${NOCTALIA_FORCE_REFRESH:-}" ] && NOCTALIA_FORCE_REFRESH="false"
    # SSH_EXTRA_IDENTITIES: CSV vault 1Password aggiuntivi per identità SSH
    # (es. "Work,Client1"). Lo script 46-ssh-identities itera TUTTI gli SSH
    # Key items di ognuno + supporta ricorsione cross-vault via item Secure
    # Note `_ssh-refs` (field `vaults` CSV). Default vuoto = niente extra.
    # Skip prompt SOLO se la var è stata esplicitamente settata (anche "");
    # usiamo `${SSH_EXTRA_IDENTITIES+set}` per distinguere unset vs empty.
    if [ "${SSH_EXTRA_IDENTITIES+set}" != "set" ]; then
        if [ "$VAULT_PROVIDER" = "1password" ]; then
            SSH_EXTRA_IDENTITIES=$(ui_input "Vault 1P extra per SSH (CSV, vuoto=niente)" "" 0)
        else
            SSH_EXTRA_IDENTITIES=""
        fi
    fi

    # ─── Distrobox (env DISTROBOXES skippa il loop, anche se stringa vuota) ─
    # NB: usiamo `${DISTROBOXES+set}` per distinguere "non settata" da "vuota":
    # passare DISTROBOXES="" è una scelta esplicita (nessun distrobox),
    # passare niente attiva il loop interattivo.
    if [ "${DISTROBOXES+set}" = "set" ]; then
        DISTROBOXES_LIST="$DISTROBOXES"
        if [ -z "$DISTROBOXES_LIST" ]; then
            ok "Distrobox da env: nessuno (DISTROBOXES vuota)"
        else
            ok "Distrobox da env: $DISTROBOXES_LIST"
        fi
    else
        echo
        echo "── Distrobox (loop interattivo) ──"
        DISTROBOXES_LIST=""
        while true; do
            if [ -z "$DISTROBOXES_LIST" ]; then
                ADD=$(ui_bool "Vuoi creare un distrobox?" "true")
            else
                echo "  attuali: $DISTROBOXES_LIST"
                ADD=$(ui_bool "Aggiungere un altro distrobox?" "false")
            fi
            [ "$ADD" != "true" ] && break

            BOX_NAME=$(ui_input "Nome distrobox" "" 1)
            BOX_IMAGE=$(ui_input "Immagine (es. fedora:latest, debian:trixie, ubuntu:24.04)" "fedora:latest" 1)
            if [ -z "$DISTROBOXES_LIST" ]; then
                DISTROBOXES_LIST="${BOX_NAME}|${BOX_IMAGE}"
            else
                DISTROBOXES_LIST="${DISTROBOXES_LIST},${BOX_NAME}|${BOX_IMAGE}"
            fi
            ok "aggiunto: $BOX_NAME ($BOX_IMAGE)"
        done
        [ -z "$DISTROBOXES_LIST" ] && warn "nessun distrobox configurato (puoi aggiungerne dopo editando il .env)"
    fi

    # Tutti i valori sono quotati: i CSV con | e , vengono fraintesi dal source
    # se lasciati nudi (bash interpreta | come pipe, , come separator).
    cat > "$ENV_FILE" <<EOF
# Host-specific config per configure-work-machine.
# Generato da basic-config.sh — modificabile a mano poi rilancia full-config.sh

# Host (NB: usiamo HOSTNAME_VAL invece di HOSTNAME per non collidere con la
# variabile built-in di bash che il sistema auto-popola)
HOSTNAME_VAL="$HOSTNAME_VAL"
HAS_FINGERPRINT="$HAS_FINGERPRINT"
AUTOLOGIN_TTY="$AUTOLOGIN_TTY"
PASSWORDLESS_SUDO="$PASSWORDLESS_SUDO"
PASSWORDLESS_KEYRING="$PASSWORDLESS_KEYRING"
SSHD_ENABLED="$SSHD_ENABLED"
DISABLE_AMDGPU_PSR="$DISABLE_AMDGPU_PSR"

# Moduli opzionali (cosa applicare oltre alla base)
# - INSTALL_PROFILES: CSV di profili pacchetti (base,dev,work,gaming) — vedi profiles.yaml.example
# - USE_NOCTALIA_CONFIG: applica settings.json + plugins.json + permissions-toggles
# - DOWNLOAD_WALLPAPERS: scarica i wallpaper definiti in .chezmoidata/wallpapers.yaml
INSTALL_PROFILES="$INSTALL_PROFILES"
USE_NOCTALIA_CONFIG="$USE_NOCTALIA_CONFIG"
DOWNLOAD_WALLPAPERS="$DOWNLOAD_WALLPAPERS"
NOCTALIA_FORCE_REFRESH="$NOCTALIA_FORCE_REFRESH"

# SSH identità extra: CSV vault 1Password (es. "Work,Client1")
# Vuoto = solo l'identità default. Vedi run_once_after_46-ssh-identities.sh.tmpl
SSH_EXTRA_IDENTITIES="$SSH_EXTRA_IDENTITIES"

# Distrobox: lista di container da creare.
# Formato: name1|image1,name2|image2  (vuoto = nessuno)
# Esempi:  "work|fedora:latest,personal|debian:trixie"
#          "dev|ubuntu:24.04"
DISTROBOXES="$DISTROBOXES_LIST"

# Vault provider per identity (email/user/ssh public key)
#   1password → leggi da op://\$VAULT/\$IDENTITY_ITEM e op://\$VAULT/\$SSH_ITEM
#   env       → leggi da ~/.config/configure-work-machine/secrets.env
VAULT_PROVIDER="$VAULT_PROVIDER"
OP_ACCOUNT_URL="$OP_ACCOUNT"
OP_VAULT="$VAULT"
OP_IDENTITY_ITEM="$IDENTITY_ITEM"
OP_SSH_ITEM="$SSH_ITEM"

# SSH: se true, copia la public key dell'SSH item in ~/.ssh/authorized_keys
AUTHORIZED_KEYS_FALLBACK="$AUTHORIZED_KEYS_FALLBACK"
EOF
    ok ".env scritto: $ENV_FILE"
}

# ─── done ───────────────────────────────────────────────────────────────────
cat <<EOF

✓ basic-config completo.

  Prossimo passo:
    ./full-config.sh           # diff + opzionale apply
    ./full-config.sh --apply   # apply diretto

EOF
