# configure-work-machine — branch `cachy-niri`

Setup riproducibile per **CachyOS + Niri + Noctalia**, gestito con
[chezmoi](https://chezmoi.io).

> **Multi-distro repo**: questo branch è dedicato a CachyOS+Niri.
> Per altri setup (Fedora, Ubuntu, …) cambia branch:
> `git checkout fedora` / `ubuntu` / ecc. Vedi `develop` per l'indice.

- **Identità**: 1Password (default) **oppure** `~/.config/configure-work-machine/secrets.env` (no-1P)
- **Host-specific**: `~/.config/configure-work-machine/config.env` (flag e profili)
- **Pacchetti**: pacman + AUR + chaotic-aur via **paru**, filtrati per profili
- **Moduli opzionali** scelti al primo run: profili installazione (base/dev/work/gaming/mediacenter),
  Noctalia config, wallpapers

## Onboarding macchina nuova

### Una-tantum, da macchina vergine

```sh
bash -c "$(curl -sL https://raw.githubusercontent.com/osharko/configure-work-machine/cachy-niri/bootstrap.sh)"
```

Stesso pattern di Homebrew. `curl` esegue come **command substitution**
(`$(...)`) e bash riceve lo script come argomento, mantenendo stdin del
terminale → i prompt interattivi (gum, op signin) funzionano.

> **⚠ Non usare `curl ... | bash`**: in modalità pipe il bash perde il
> controlling tty e i prompt non funzionano. Lo script rileva la pipe e
> si rifiuta di partire con istruzioni esplicite.

Lo script installa `git` se manca, clona il repo (branch `cachy-niri`) in
`~/configure-work-machine`, e prosegue interattivamente come sotto.

### Cosa fa `bootstrap.sh`

Sequenza completamente automatica fino al primo prompt — nessun comando
pacman manuale richiesto:

1. **`bootstrap.sh`** — se chiamato via `curl|bash` da macchina vergine:
   installa `git` (unica dep non bootstrappabile in altro modo) → clona il
   repo → ri-attacca stdin a `/dev/tty` → lancia `basic-config.sh`.
2. **`basic-config.sh`** (5 step):
   1. **Prerequisiti** — install via `paru` di tutto: chezmoi, git,
      base-devel, jq, gum, 1password-cli. Su Arch vanilla, bootstrap `paru`
      stesso (clone+makepkg di `paru-bin` AUR).
   2. **Scelta vault provider** — TUI gum: `1password` o `env`.
   3. **Vault setup**:
      - `1password` → `op account add` + signin (QR mobile o Secret Key)
      - `env` → copia `.env.personal.example` in `~/.config/configure-work-machine/secrets.env`,
        ti chiede di editarlo + rilanciare lo script
   4. **Verifica identità** — controlla item `Identity` + `Default` (1P)
      oppure validità campi in `secrets.env`
   5. **Config host-specific (`.env`)** — TUI per hostname, fingerprint,
      autologin, passwordless sudo (defaults LUKS-aware), **moduli opzionali**
      (`INSTALL_PROFILES` multi-select, `USE_NOCTALIA_CONFIG`, `DOWNLOAD_WALLPAPERS`),
      e loop distrobox.
3. **`full-config.sh --apply`** — verifica precondizioni, risolve i profili
   (calcola `pacman_sections`/`aur_sections`/`enable_flatpak`), legge identità
   dal vault scelto, scrive `~/.config/chezmoi/chezmoi.toml`, fa `chezmoi diff`,
   esegue `chezmoi apply -v`.

### Controllo granulare

```fish
./basic-config.sh             # onboarding (idempotente)
./full-config.sh              # solo diff (dry-run)
./full-config.sh --apply      # diff + apply
```

### Skip prompt via env var

Ogni prompt TUI di `basic-config.sh` viene **skippato** se la corrispondente
variabile d'ambiente è già impostata. Utile per install non-presidiati o per
re-runs idempotenti.

| Env var | Valori | Cosa skippa |
|---|---|---|
| `VAULT_PROVIDER` | `1password` \| `env` | Scelta vault provider |
| `EMAIL` | email | Prompt email per `op signin` (modo 1P manuale) |
| `OP_ACCOUNT` | URL | Prompt account URL 1P |
| `VAULT` | nome vault | Default `PersonalConfiguration` |
| `IDENTITY_ITEM` | nome item 1P | Default `Identity` |
| `SSH_ITEM` | nome item 1P | Default `Default` |
| `GIT_NAME` | "Nome Cognome" | Letto da git config global se assente |
| `HOSTNAME_VAL` | hostname | Default `$(hostname)` |
| `HAS_FINGERPRINT` | `true` \| `false` | Default `false` |
| `AUTOLOGIN_TTY` | `true` \| `false` | Default = `true` se disco LUKS |
| `PASSWORDLESS_SUDO` | `true` \| `false` | Default = `true` se LUKS |
| `PASSWORDLESS_KEYRING` | `true` \| `false` | Default = `true` se LUKS |
| `SSHD_ENABLED` | `true` \| `false` | Default `true` |
| `DISABLE_AMDGPU_PSR` | `true` \| `false` | Default `false` |
| `INSTALL_PROFILES` | CSV `base,dev,work,gaming` | Multi-select TUI |
| `USE_NOCTALIA_CONFIG` | `true` \| `false` | Default `true` |
| `DOWNLOAD_WALLPAPERS` | `true` \| `false` | Default `true` |
| `NOCTALIA_FORCE_REFRESH` | `true` \| `false` | Default `false`: preserva live settings/plugins JSON. True: backup + rebuild dal template ad ogni apply (utile dopo update bar layout) |
| `AUTHORIZED_KEYS_FALLBACK` | `true` \| `false` | Default `true` |
| `DISTROBOXES` | CSV `name1\|img1,name2\|img2` | Skip loop distrobox |
| `NON_INTERACTIVE` | `1` | Forza no-TUI ovunque; errore se manca un required |

### Esempi

**Vault 1Password** (resta solo `op signin` da 1P desktop):

```sh
VAULT_PROVIDER=1password \
EMAIL=tua@email \
GIT_NAME="Nome Cognome" \
INSTALL_PROFILES=base,dev,work \
HAS_FINGERPRINT=true \
DISTROBOXES="dev|fedora:latest" \
bash -c "$(curl -sL https://raw.githubusercontent.com/osharko/configure-work-machine/cachy-niri/bootstrap.sh)"
```

**Vault env** (no 1Password, identità da `~/.config/configure-work-machine/secrets.env`):

```sh
VAULT_PROVIDER=env \
INSTALL_PROFILES=base,dev,gaming \
HAS_FINGERPRINT=false \
DISTROBOXES="" \
bash -c "$(curl -sL https://raw.githubusercontent.com/osharko/configure-work-machine/cachy-niri/bootstrap.sh)"
```

(Al primo run con `VAULT_PROVIDER=env`, lo script copia `.env.personal.example`
in `~/.config/configure-work-machine/secrets.env` e ti chiede di editarlo +
rilanciare lo script. Da lì in poi è zero-prompt.)

Args CLI equivalenti su `basic-config.sh` (vedi `-h`):
`--vault-provider`, `--email`, `--op-account`, `--vault`, `--identity-item`,
`--ssh-item`, `--git-name`, `--non-interactive`.

> **Per chi sviluppa questo repo**: vedi [CLAUDE.md](./CLAUDE.md) — architettura,
> convenzioni chezmoi, package management, gotchas raccolti durante lo sviluppo.

## Provider identità: 1Password o `.env`

### Opzione A — 1Password (default)

Servono **2 item** nel vault `PersonalConfiguration` (vault e nomi item sono
dinamici via `.env`, default consigliati):

| `.env` var | Default | Categoria 1P | Contenuto |
|---|---|---|---|
| `OP_VAULT` | `PersonalConfiguration` | — | Nome vault |
| `OP_IDENTITY_ITEM` | `Identity` | Login | Field `Email` + field `User` |
| `OP_SSH_ITEM` | `Default` | **SSH Key** | Field `public key` + `private key` (auto-popolati da 1P) |

### Perché 2 item separati

- **Identity** (Login): solo info testuali (email, nome). Riusabile per altri tool/script senza esporre chiavi.
- **SSH Key** (categoria nativa 1P): obbligatoria per il **1Password SSH Agent** (usato da git per commit signing). L'agent **non** legge SSH key da item Login/Document con file attachment — vuole proprio la categoria nativa.

### Setup veloce

```fish
# 1. Identity (CLI)
op item create --category=login --vault=PersonalConfiguration --title=Identity \
    'Email[email]=tua@email' 'User[text]=Nome Cognome'

# 2. Default (via UI 1Password — l'import private key non è esposto in CLI v2):
#    + New Item → SSH Key → titolo "Default", vault PersonalConfiguration
#    → "Add private key" → "Enter manually" → incolla `~/.ssh/id_ed25519`
#    1Password deriva auto la public key + il fingerprint.
```

### Verifica path

```fish
op read "op://$OP_VAULT/$OP_IDENTITY_ITEM/Email"
op read "op://$OP_VAULT/$OP_IDENTITY_ITEM/User"
op read "op://$OP_VAULT/$OP_SSH_ITEM/public key"
op read "op://$OP_VAULT/$OP_SSH_ITEM/private key"
```

`basic-config.sh` fa questi check automaticamente.

### Identità SSH multiple (personal, work, …)

Il repo gestisce **solo l'identità di default** (vault `PersonalConfiguration`,
deployata in `~/.ssh/id_ed25519` da `45-ssh-keys`). Per identità aggiuntive
(es. account work con email diversa, server azienda con chiave dedicata) usa
la convention **"un vault 1Password per identità"** — zero info personali o
aziendali nel repo o sul filesystem locale.

**Setup per ogni vault aggiuntivo** (es. `Work`, `Client1`, …):

1. Nel vault, **tutti gli item SSH Key vengono processati** per le pubbliche
   (puoi averne più di uno: `Default`, `git-rsa`, `legacy`, …). Schema rigido
   1P (public/private key, fingerprint, type) — niente custom field richiesti.

2. **Opzionale: Secure Note `_ssh`** nello stesso vault, con 2 field custom:
   - `config` (multiline text): snippet `ssh_config` per quel vault →
     scritto in `~/.ssh/config.d/<vault_slug>.conf`
   - `vaults` (CSV): ricorsione cross-vault → tutti i vault elencati vengono
     processati a cascata (cicli evitati via SEEN tracking).

   Esempio nel vault `Work`:
   ```
   Item: _ssh (Secure Note)
   Field: config  →
     Host gitlab.company.example *.company.example
         User myuser
         IdentityFile ~/.ssh/work/default
         IdentitiesOnly yes
   Field: vaults  → "Client1"   (opzionale, lascia vuoto se no ricorsione)
   ```

3. In `~/.config/configure-work-machine/config.env` setta:
   ```bash
   SSH_EXTRA_IDENTITIES="Work"
   ```
   (CSV dei nomi vault da processare. Default vuoto = nessuna identità extra.)

4. Aggiungi i vault al **1Password SSH Agent** in `~/.config/1Password/ssh/agent.toml`:
   ```toml
   [[ssh-keys]]
   vault = "PersonalConfiguration"
   [[ssh-keys]]
   vault = "Work"
   [[ssh-keys]]
   vault = "Client1"
   ```
   Riavvia 1Password (`systemctl --user restart app-1password@autostart.service`).

5. `chezmoi apply` — lo script `46-ssh-identities` produce un layout **nested**
   mirroring del recursion tree:

   ```
   ~/.ssh/<vault>/
       ├── <item>.pub        (0644)   public key
       ├── <item>            (0600)   private key
       ├── config            (0644)   da _ssh.config
       └── <sub-vault>/      (ricorsione)
           └── ...
   ~/.gitconfig.d/<vault>.gitconfig    [user] da Identity item
   ```

   Lo slug è kebab-case lowercase (`Client1` → `client1`). `~/.ssh/config`
   include via glob `~/.ssh/*/config ~/.ssh/*/*/config` (ssh non supporta
   `**`, quindi nesting massimo: 1 livello via _ssh.vaults).

Private keys: deployate da 1P (`op read .../private key`). Utile per CLI/git
quando l'agent non gira; l'agent può comunque servirle se vault è in
`agent.toml`. ssh client seleziona quale via `IdentityFile` nello snippet.

**Per-vault git identity**: ogni `Identity` item (Email+User) genera
`~/.gitconfig.d/<vault>.gitconfig`. Attivalo nel tuo `~/.gitconfig`:
```ini
[includeIf "gitdir:~/lavoro/work/"]
    path = ~/.gitconfig.d/work.gitconfig
[includeIf "gitdir:~/lavoro/client1/"]
    path = ~/.gitconfig.d/client1.gitconfig
```

Vantaggi: tutto sta nei vault 1P (compresi gli `Host *.azienda.it`), il repo
resta agnostic.

### Config 1P SSH Agent (per commit signing)

Per abilitare l'agent a leggere dall'item nel vault `PersonalConfiguration`:

```fish
mkdir -p ~/.config/1Password/ssh
cat > ~/.config/1Password/ssh/agent.toml <<'EOF'
[[ssh-keys]]
vault = "PersonalConfiguration"
EOF
# Restart 1Password (systemctl --user restart app-1password@autostart.service) + sblocca.
```

### SSH keys deploy

Lo script `run_once_after_45-ssh-keys.sh` legge `public key` / `private key`
dall'SSH item e li scrive in `~/.ssh/id_ed25519.pub` (0644) e `~/.ssh/id_ed25519` (0600).

**Fallback authorized_keys**: se `AUTHORIZED_KEYS_FALLBACK=true` nel `.env`,
la public key viene copiata in `~/.ssh/authorized_keys` per garantire accesso
ssh in entrata (utile su macchine senza condivisione di authorized_keys
dedicate).

**Re-deploy forzato** (dopo update chiavi in 1P):
```fish
chezmoi state forget-bucket --bucket=scriptState
chezmoi apply
```

### Opzione B — `.env` standalone (no 1Password)

Per macchine dove non vuoi 1P (CI, work-laptop bloccati, server): seleziona
`VAULT_PROVIDER=env` in `basic-config.sh`. Copia `.env.personal.example` →
`~/.config/configure-work-machine/secrets.env` (perms `0600`) e popola:

```bash
EMAIL="me@example.com"
GIT_NAME="My Full Name"
SIGNING_KEY="ssh-ed25519 AAAA... me@example.com"
OP_ACCOUNT_URL=""  # lasciare vuoto
```

Limitazioni in modalità `env`:
- **Private SSH key**: lo script NON la deploya. Copia a mano `~/.ssh/id_ed25519`
  (chmod 0600) prima del `chezmoi apply`.
- **1P SSH Agent / git signing**: serve comunque 1P desktop installato con la
  chiave caricata, altrimenti il signing è disabilitato (`commit.gpgsign=false`).

Il file `secrets.env` è in `.gitignore` (mai committato). Mai mettere chiavi
private lì — solo email/name/public key.

## Layout

| Path | Cosa fa |
|---|---|
| `basic-config.sh` | Onboarding macchina nuova (prereq + 1P + .env) |
| `full-config.sh` | Validate + write chezmoi.toml + diff + apply |
| `bootstrap.sh` | Wrapper `basic + full --apply` |
| `.chezmoidata/packages.yaml` | Pacchetti (pacman + AUR), servizi systemd, gruppi, plugin Noctalia |
| `.chezmoi.toml.tmpl` | Fallback per `chezmoi init` standalone (raro: bootstrap scrive direttamente il toml) |
| `run_once_before_00-bootstrap.sh.tmpl` | Keyring + verifica AUR helper + 1P signin |
| `run_onchange_before_10-packages.sh.tmpl` | Install pacman + AUR via paru (unico script) |
| `run_onchange_before_15-hardware.sh.tmpl` | Autodetect HW: CPU/GPU/fingerprint/Bluetooth/I²C/UEFI + driver |
| `run_once_after_45-ssh-keys.sh.tmpl` | Deploy chiavi SSH da 1P → `~/.ssh/` (auto-detect + fallback authorized_keys) |
| `run_once_after_50-distrobox.sh.tmpl` | Crea i distrobox dichiarati in `DISTROBOXES` (.env CSV `name1\|img1,…`) |
| `run_onchange_after_55-mise-install.sh.tmpl` | `mise install` LTS globali |
| `run_once_after_60-fingerprint.sh.tmpl` | PAM fingerprint (gated `has_fingerprint`) |
| `run_once_after_85-autologin-niri.sh.tmpl` | Disable SDDM + autologin tty1 (gated `autologin_tty`) |
| `run_once_after_90-services.sh.tmpl` | Servizi, gruppi, ufw, ddcutil |
| `run_once_after_92-sudo-nopasswd.sh.tmpl` | Sudoers passwordless (gated `passwordless_sudo`) |
| `dot_config/fish/config.fish` | Shell config (alias, mise/zoxide/direnv hook, starship) |
| `dot_config/fish/conf.d/niri-autostart.fish` | `exec niri-session` su tty1 login |
| `dot_config/alacritty/alacritty.toml` | Terminale (JetBrainsMono Nerd 10, Nord palette) |
| `dot_config/noctalia/plugins.json.tmpl` | Plugin Noctalia attivi (lista in packages.yaml → JSON) |
| `dot_config/noctalia/plugins/*/settings.json` | Settings persistiti per plugin (model-usage, slowbongo…) |
| `dot_config/starship.toml` | Prompt con mise toolchain |
| `dot_config/mise/config.toml` | Tool versions globali (Java, Node, Go, Python, Rust) |
| `dot_gitconfig.tmpl` | git user/email/signingKey letti da `op://Personal/git` |
| `private_dot_ssh/config` | SSH config che usa 1Password agent (zero chiavi su disco) |

## Profili installazione

`.chezmoidata/profiles.yaml` definisce 5 profili (`base`, `dev`, `work`,
`gaming`, `mediacenter`) che mappano a sezioni di `.chezmoidata/packages.yaml`. In `.env`:

```bash
INSTALL_PROFILES="base,dev"          # solo CLI + toolchain dev
INSTALL_PROFILES="work"              # work include automaticamente dev+base
INSTALL_PROFILES="dev,gaming"        # dev + gaming laterali
INSTALL_PROFILES="base,dev,work,gaming"  # tutto
```

`full-config.sh` risolve i profili attivi → calcola `pacman_sections` e
`aur_sections` (deduplicate) → li scrive in `chezmoi.toml` → il template
`10-packages` itera solo quelle sezioni.

Gating ulteriore: `work_only` (k8s/SQL TUI/VPN) richiede `INSTALL_PROFILES`
contenga `work` (auto-derivato `is_work_machine=true`).

### Aggiungere un pacchetto

1. Identifica la sezione in `.chezmoidata/packages.yaml` (es. `pacman.cli`)
2. Verifica che la sezione sia inclusa in almeno uno dei profili in
   `.chezmoidata/profiles.yaml` — altrimenti il pkg non viene installato
3. Aggiungi voce con commento se non ovvio
4. `chezmoi apply` (hash trigger)

## Aggiungere un plugin Noctalia

Aggiungi il nome (cartella del repo `noctalia-dev/noctalia-plugins`) a
`packages.yaml > noctalia_plugins`. Il template `plugins.json.tmpl`
rigenera il JSON; Noctalia fetcha il plugin in autonomia. Se il plugin ha
config personalizzata, persistila in `dot_config/noctalia/plugins/<name>/settings.json`.

## Strategia file Noctalia (`create_` vs tracked)

Noctalia ha 2 tipi di file:

- **File con stato runtime** (cambiati spesso dall'UI: `settings.json`, `colors.json`)
  → prefix `create_` → chezmoi li scrive **solo la prima volta** (macchina nuova)
  → poi puoi modificare via UI senza che `chezmoi apply` sovrascriva
- **File config-like** (cambiati raramente: plugin settings)
  → tracked normalmente → chezmoi sincronizza sempre con il source

Per **reset di un file `create_` su una macchina esistente**:
```fish
rm ~/.config/noctalia/settings.json && chezmoi apply
```

## Aggiungere un secret

In 1Password, poi nel template `.tmpl`:
```
{{ onepasswordRead "op://Personal/MyService/credential" }}
```

## Filosofia

- **Riproducibile**: `chezmoi apply` → stato target identico su qualunque macchina
- **Single source of truth**:
  - Identità (email, name, public ssh key) → item 1P (vault + nome dinamici via `.env`)
  - Host-specific (hostname, fingerprint, autologin, …) → `~/.config/configure-work-machine/config.env`
- **LUKS-aware**: autologin tty1 + sudoers passwordless attivi solo se disco cifrato (default smart)
- **Shell**: `fish` (default spin Niri-Noctalia), no chsh forzato
- **Toolchain**: `mise` (no nvm/jenv/sdkman)
- **Sandbox**: `distrobox` per ambienti di lavoro; host CachyOS resta vergine
- **Gaming**: `steam` + `mangohud`/`gamemode`, controller Xbox/Stadia via dkms+udev
- **Niente segreti committati**: solo 1P references nei `.tmpl`
