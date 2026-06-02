# CLAUDE.md

Documentazione di sviluppo del repo `configure-work-machine`, **branch
`cachy-niri`**. Target: futuro Claude (o sviluppatore) che apre questo branch
per la prima volta. Non duplica il README (quello è user-facing); qui c'è
**come funziona dentro** e **come modificarlo senza romperlo**.

## Handoff context (2026-06-02 — sessione Claude su 192.168.188.179)

Lavoro recente sul branch `cachy-niri`, agente prossimo (opencode dal portatile o
Claude nuova chat) deve sapere:

**Macchina test:** `osharko@192.168.188.179` (Dell, CachyOS, AMD Krackan, schermo
HiDPI 2560x1600). NOPASSWD sudo abilitato → puoi `ssh` + comandi privilegiati liberi.
Niri+Noctalia v5 girano in produzione tramite `noctalia-init.sh` (NON via chezmoi
completo). Setup:
- agetty autologin su tty1 → fish (no shell hook) → user@1000.service via PAM
- `~/.config/systemd/user/niri-session.service` (`WantedBy=default.target`)
- linger DISABILITATO (causava race condition: user@ partiva a boot prima che tty1 avesse seat0)
- niri-session script fast-path: detecta MANAGERPID systemd-user → exec niri --session diretto

**Noctalia v5 (non v4):** rewrite completo C++/OpenGL ES via `lionheartp/Hyprland`
COPR (`noctalia-git`). NO plugin .qml (sono v4-only). v5 ha "Scripted Widgets" in Luau.
I 3 script del repo `02b-noctalia-plugin-prefetch`, `03-noctalia-refresh`,
`05-prereq-cleanup` hanno guard `if noctalia-version >= 5 → exit 0` — NON tentare di
forzarli su v5, vanno solo aggiornati come Luau widgets se servono custom.

**`noctalia-init.sh` (root del repo):** standalone quick-install niri+noctalia+
greetd+ghostty + setup completo autologin/dark-mode/portal/rounded/no-titlebar.
Idempotente. Lanciato via `bash -c "$(curl ... noctalia-init.sh)"`. Sostituisce
`chez.sh` quando vuoi solo DE base senza dotfiles/profili/chezmoi.

**`chez.sh` (in ~ utente, NON nel repo):** bootstrap MASSIVO completo (1Password +
chezmoi + tutti i run_once/run_onchange). Usalo SOLO per setup work-machine totale
da zero, con 1Password vault già pronto.

**Cose non ancora portate in script (decidere se aggiungere o lasciare manuale):**
- chafa/viu (image-in-terminal) — non aggiunti, decidere chez.sh vs noctalia-init.sh
- Display scale 1.5 (HiDPI default) — utente preferisce 1.5, lasciato così
- Custom keybinds personalizzati (Mod+B brave, Mod+E nautilus) → niri default
  config sovrascrive il nostro al primo run. Da risolvere con write più aggressivo
  o config dichiarativa via chezmoi

## Deploy model

**ZIP-throwaway** (bootstrap.sh): macchina utente NON ha repo locale
persistente. Bootstrap scarica tarball da GitHub in `/tmp/configure-work-machine-XXXXXX`,
esegue tutto da lì, `trap rm -rf` su exit. Solo persistente è la config
utente in `~/.config/configure-work-machine/` (config.env + secrets.env) e lo state
chezmoi (`~/.local/share/chezmoi/chezmoistate.boltdb` +
`~/.config/chezmoi/chezmoi.toml`).

Per **sviluppo del repo**: clone normale via SSH (`git clone -b cachy-niri
git@github.com:osharko/configure-work-machine.git`), poi commit/push. Quando
modifichi e vuoi testare, NON serve aggiornare nessuna macchina — ogni
bootstrap.sh prende fresh dal branch su GitHub.

## Scopo del progetto

Setup riproducibile per un laptop **CachyOS + Niri + Noctalia** (compositore
Wayland tiling + shell Quickshell), gestito via [chezmoi](https://chezmoi.io).
Macchina target: `my-laptop` (AMD Krackan iGPU, LUKS-encrypted).

Obiettivo: dopo una reinstallazione fresca, `curl … | bash` ricostruisce il
sistema completo (config + pacchetti + servizi + plugin) in pochi minuti, senza
configurazione manuale post-install.

## Architettura

```
~/configure-work-machine/
├── bootstrap.sh             # entrypoint: orchestratore basic+full+apply
├── basic-config.sh          # onboarding interattivo (paru bootstrap, 1P signin, .env gen)
├── full-config.sh           # render chezmoi.toml da .env+1P, lancia chezmoi apply
├── .chezmoi.toml.tmpl       # template del config chezmoi (data variables)
├── .chezmoidata/            # variabili dichiarative consumate dagli script
│   ├── packages.yaml        # tutti i pacchetti (pacman+AUR+flatpak) per categoria
│   └── wallpapers.yaml      # lista wallpaper riproducibili per cartella
├── dot_config/              # → ~/.config/      (chezmoi prefix)
├── dot_local/               # → ~/.local/
├── dot_gitconfig.tmpl       # → ~/.gitconfig    (con template vars)
├── private_dot_ssh/         # → ~/.ssh/         (perms 0700 enforced)
└── run_*_*.sh.tmpl          # script eseguiti durante chezmoi apply
```

### Convenzioni chezmoi usate qui

| Prefisso | Significato |
|---|---|
| `dot_<name>` | → `~/.<name>` (es. `dot_config` → `~/.config`) |
| `private_dot_<name>` | → `~/.<name>` con perms `0700` (per `~/.ssh`) |
| `executable_<name>` | → file con bit `+x` (per binari in `dot_local/bin/`) |
| `<file>.tmpl` | template Go: rendered con `chezmoi.toml.data` |
| `create_<name>` | crea solo se mancante (no overwrite — per file mutabili tipo `settings.json`) |
| `run_once_before_NN-<name>.sh.tmpl` | script eseguito UNA volta PRIMA di copiare i file |
| `run_once_after_NN-<name>.sh.tmpl` | UNA volta DOPO i file |
| `run_onchange_*` | rieseguito quando l'hash del file (o di un suo trigger esplicito) cambia |

NN è un numero a 2 cifre per ordinare alfabeticamente l'esecuzione (vedi sotto).

### Ordine esecuzione script (~20 totali)

Numerazione progressiva = ordine cronologico. Convenzioni:
- `00–09` bootstrap + repo setup (chaotic-aur, prereq cleanup)
- `10` install pacchetti (paru -Syu)
- `15` hardware (sensori, fan)
- `30–49` config utente (mise, lazyvim, ssh keys, keyring)
- `50–69` workspace/distrobox/fingerprint
- `70–89` post-install app (flatpak, default-apps, niri-tweaks, wallpapers)
- `85–99` services + sudoers + autologin

L'ordine si determina alfabeticamente tra prefissi `run_once_before_` <
`run_onchange_before_` < `run_once_after_` < `run_onchange_after_`, e dentro
ognuno per nome file.

## Flusso bootstrap

```
bootstrap.sh
   ├─→ basic-config.sh
   │    ├─ pacman bootstrap (paru, gum, base-devel)
   │    ├─ 1Password signin (op CLI)
   │    ├─ verifica/crea item op://$VAULT/$ITEM con email/name/ssh-keys
   │    └─ genera ~/.config/configure-work-machine/config.env (host-specific)
   └─→ full-config.sh
        ├─ legge .env + identità da 1P
        ├─ scrive ~/.config/chezmoi/chezmoi.toml ([data] populated)
        └─ chezmoi apply  → esegue tutti gli script run_*
```

`config.env` (host-specific, NON in git) contiene flag tipo `IS_WORK_MACHINE`,
`HAS_FINGERPRINT`, `PASSWORDLESS_SUDO`, `DISABLE_AMDGPU_PSR`. Questi diventano
data variables nel template chezmoi.toml e gateano sezioni package o script.

### Identity provider — swap 1P/env

`VAULT_PROVIDER` in `.env` controlla la sorgente:
- `1password` (default): `basic-config.sh` fa `op signin`, verifica item `Identity` + `Default`. `full-config.sh` legge via `op read` → scrive in `chezmoi.toml`.
- `env`: `basic-config.sh` copia `.env.personal.example` in `~/.config/configure-work-machine/secrets.env` (richiede edit utente). `full-config.sh` sorgenta quel file → scrive in `chezmoi.toml`.

**I template chezmoi sono vault-agnostic**: usano solo `.email`, `.git_name`, `.signing_key` (variabili pre-risolte da full-config.sh). Niente `onepasswordRead` nei template. Per aggiungere un nuovo provider in futuro (gh CLI, age, sops…), basta aggiungere un branch in `basic-config.sh` (step 2/3) e `full-config.sh` (step 2). I template non si toccano.

#### Schema 1Password attuale

Due item nel vault `PersonalConfiguration`:

| Item | Categoria 1P | Field/Content | Usato da |
|---|---|---|---|
| `Identity` | Login | `Email`, `User` | git config (`.gitconfig`) |
| `Default` | **SSH Key** | `public key`, `private key` (auto-popolati) | git signing (1P SSH agent), `~/.ssh/` deploy |

**Importante**: l'item SSH Key DEVE essere categoria nativa "SSH Key" di 1P
(non Login/Document con file attachment) — il 1Password SSH Agent legge solo
da quella categoria. La public key è esposta come field text (leggibile via
`op read`), la private resta protetta dall'agent.

Path 1P consumati dal codice:
- `op://{op_vault}/{op_identity_item}/Email`
- `op://{op_vault}/{op_identity_item}/User`
- `op://{op_vault}/{op_ssh_item}/public key`
- `op://{op_vault}/{op_ssh_item}/private key`

Variabili `.env`: `OP_VAULT`, `OP_IDENTITY_ITEM`, `OP_SSH_ITEM`,
`OP_ACCOUNT_URL`. Per cambiare i nomi degli item: edita il `.env` e rilancia
`full-config.sh`.

#### 1P SSH agent config

In `~/.config/1Password/ssh/agent.toml` serve dichiarare il vault dove cercare
le chiavi SSH:

```toml
[[ssh-keys]]
vault = "PersonalConfiguration"
```

Senza questo (o con vault sbagliato), l'agent risponde a `op-ssh-sign` con
"No SSH private key found for the specified public key" → commit signing
fallisce. Restart 1Password dopo modifiche al file:
`systemctl --user restart app-1password@autostart.service`.

## Moduli opzionali (opt-in dal .env)

Tre flag di "vorrei/non vorrei" controllano il comportamento al `chezmoi apply`:

| Flag `.env` | Cosa controlla | Quando applicato |
|---|---|---|
| `INSTALL_PROFILES` | CSV di profili (`base,dev,work,gaming`) → quali sezioni di `packages.yaml` installare | Resolved da `full-config.sh` → `pacman_sections`/`aur_sections`/`enable_flatpak` in chezmoi.toml |
| `USE_NOCTALIA_CONFIG` | Applica la mia config Noctalia (settings, plugins, bar, dock) | Se `false`, `.chezmoiignore.tmpl` esclude `dot_config/noctalia/**` |
| `DOWNLOAD_WALLPAPERS` | Scarica i 20 wallpaper definiti in `.chezmoidata/wallpapers.yaml` | Se `false`, lo script `82-wallpapers` esce subito senza scaricare |

I prompt per queste scelte stanno in `basic-config.sh` Step 4 (TUI gum
multi-select per `INSTALL_PROFILES`, bool per gli altri due). Default consigliati:
`base,dev,work` + `USE_NOCTALIA_CONFIG=true` + `DOWNLOAD_WALLPAPERS=true`.

### Profili (`.chezmoidata/profiles.yaml`)

4 profili definiti, niente `extends` (ogni profilo elenca esplicitamente tutte
le sue sezioni — più verboso, ma niente magia ricorsiva):

- `base`: cli + fonts + apps + remote + hardware + hypr_compat
- `dev`: base + toolchain + containers + editors + utils + flatpak
- `work`: dev + work_only (gated anche da `is_work_machine = true`, derivato auto)
- `gaming`: solo gaming (laterale, additivo)

`full-config.sh` risolve `INSTALL_PROFILES` → unisce + dedupe le sezioni → scrive
`pacman_sections = [...]` come array TOML in chezmoi.toml. Lo script
`10-packages.sh.tmpl` itera solo quelle sezioni:

```go-tmpl
{{- range $cat := .pacman_sections }}
  # --- pacman/{{ $cat }} ---
  {{- range $pkg := index $.pacman $cat }}
  {{ $pkg | quote }}
  {{- end }}
{{- end }}
```

## Package management

`/.chezmoidata/packages.yaml` è la **single source of truth** per i pacchetti.
Struttura:

```yaml
pacman:
  cli: [...]           # tool CLI base
  toolchain: [...]     # mise, direnv
  containers: [...]    # docker, distrobox, podman
  work_only: [...]     # gated da .is_work_machine (kubectl, helm, k9s)
  apps: [...]          # GUI app
  hardware: [...]
  fonts: [...]
  editors: [...]
  gaming: [...]
aur:
  apps: [...]          # 1password, typora, beekeeper
  utils: [...]         # quickemu-git, boxbuddy, ventoy
  fonts: [...]
  gaming: [...]
  hardware_dell: [...] # gated da .has_fingerprint (libfprint-tod)
  work_only: [...]     # gated da .is_work_machine (forticlient-vpn, harlequin)
flatpak: [...]
noctalia_plugins: [...]
services: { system: [...] }
groups: [...]
```

Lo script `run_onchange_before_10-packages.sh.tmpl` itera tutte le categorie,
applica i gating (`work_only` only if `.is_work_machine`), e lancia un unico
`paru -Syu --needed --noconfirm --sudoloop --skipreview --batchinstall
--noupgrademenu --useask` con la lista risultante.

### Conventions critiche (vedi anche memorie Claude)

- **Mai `sudo pacman -S` o `paru` nudo** → sempre `paru-mise` (wrapper in
  `dot_local/bin/`) che strippa `~/.local/share/mise/{installs,shims}` dal PATH
  per evitare conflitti con il prefix di mise quando build pkg Python AUR.
- **chaotic-aur è abilitato come repo** (script `02-chaotic-aur`) → AUR popolari
  arrivano precompilati. Per ogni nuovo pkg AUR: `paru-mise -Si <pkg>` e
  controlla `Repository:` — se chaotic-aur, niente compile.
- **Patch transient** (sed in-place su file di sistema) ammesse SOLO se
  accompagnate da `run_onchange` idempotente + condizionale grep-su-pattern
  (auto-no-op quando upstream fixa). Esempio: `57-harlequin-patch.sh.tmpl`.

## Plugin Noctalia custom: `permissions-toggles`

In `dot_config/noctalia/plugins/permissions-toggles/` — **decisione: resta
mono-repo**. Motivo: troppo specifico a questo setup per giustificare un repo
separato + estrazione e PR upstream a `noctalia-dev/noctalia-plugins` ha costo
non commisurato all'uso effettivo.

Cosa fa: 7 toggle nella bar Noctalia per stato di permessi/auth (sudoers
NOPASSWD, keyring no-password, autologin niri, abbreviations enabled, faillock,
polkit rules, ssh keys present). Click sul toggle invoca
`~/.local/bin/permissions-toggle <key> on|off` (wrapper bash) che modifica i
file di sistema via `pkexec`.

File del plugin:
- `manifest.json` — id, entrypoints
- `Main.qml` — QtObject con stato + apply logic
- `BarWidget.qml` — NIconButton shield-check
- `Panel.qml` — NBox con NToggle per ognuno
- `README.md` — doc plugin

Per modificarne uno: edita QML in `dot_config/noctalia/plugins/...`, niri ha
auto-reload via Noctalia. Per testare lo script: `permissions-toggle <key>
status` (bash).

## Gotchas (lessons learned, evita di re-imbatterti)

### mise vs paru AUR Python

I PKGBUILD AUR per pkg Python fanno `python -m build` e si installano nel prefix
del primo `python` in PATH. Se mise's python è in PATH (`~/.local/share/mise/...`),
i pkg ci si installano e **collidono con i file gestiti da mise** (`python-tree-sitter` etc.).

Fix in `paru-mise` (wrapper): strippa mise dal PATH per il subprocess paru +
mantiene `--assume-installed` per evitare che paru tenti di installare runtime
duplicati da pacman. Lo script `10-packages` fa lo stesso strip inline (perché
viene eseguito prima che paru-mise sia stato copiato come file).

### sudo NOPASSWD + `sudo -v`

`NOPASSWD: ALL` matcha solo i COMANDI sudo. `sudo -v` (validate, senza comando)
chiede comunque password. `paru --sudoloop` fa `sudo -v` periodico → si blocca
in attesa di TTY. Soluzione: SEMPRE entrambe le righe nel sudoers:
```
Defaults:<user> !authenticate
<user> ALL=(ALL) NOPASSWD: ALL
```

Pattern in `run_once_after_92-sudo-nopasswd.sh.tmpl`.

### chezmoi `create_` prefix

`create_<name>` significa: copia il file SOLO se non esiste già. Critico per
`dot_config/noctalia/create_settings.json.tmpl` perché Noctalia aggiorna quel
file via UI nel tempo. Senza `create_`, ogni `chezmoi apply` schiaccerebbe le
modifiche utente.

Quando vuoi aggiornare il template dal file live (snapshot): `cp ~/.config/...
~/configure-work-machine/dot_config/...` + sostituisci `/home/$USER` con
`{{ .chezmoi.homeDir }}` (sed) + verifica `chezmoi execute-template < … | jq empty`.

### Aggiungere un plugin Noctalia con system deps

I plugin Noctalia (sia upstream da `noctalia-plugins` che custom locali) spesso
hanno **system dependencies** non gestite dal plugin loader stesso: tools CLI
chiamati da QML via `Process` (`grim`, `slurp`, `tesseract`, `udisksctl` ecc.).
Il plugin si installa ma non funziona finché i tool non sono presenti.

Convenzione per aggiungere un plugin con deps:

1. Aggiungi l'id plugin a `.chezmoidata/packages.yaml` → `noctalia_plugins:`
2. Leggi il README del plugin (in `~/.config/noctalia/plugins/<id>/README.md`)
   per la sezione **Requirements / Dependencies**
3. Aggiungi i pacchetti pacman a `pacman.apps` con commento `# Deps plugin Noctalia <id>`
4. Se ci sono dep AUR-only, aggiungile a `aur.utils` (preferendo varianti
   in `chaotic-aur` o `cachyos-extra-znver4` se disponibili — vedi
   [[feedback-paru-chaotic-default]] in memoria)
5. `chezmoi apply` (hash trigger 10-packages → install)

Esempi noti nel repo:
- `screen-toolkit` → deps: grim, slurp, tesseract, tesseract-data-eng,
  translate-shell, wl-screenrec, gifski, hyprpicker (già presente)
- `usb-drive-manager` → deps: udisks2, ntfs-3g (più yazi se vuoi file
  browser TUI; può funzionare anche con xdg-open)
- `slowbongo` → deps: evtest, gruppo `input` (vedi 90-services)
- `screen-recorder` → deps: gpu-screen-recorder

### Noctalia settings.json schema NON è versionato

Il template `create_settings.json.tmpl` riflette lo schema della versione di
Noctalia al momento dello snapshot. Quando Noctalia rilascia una versione con
nuovi campi (es. v5 aggiunge una sezione), il template non li ha → Noctalia
fallback ai default per quei campi. NON si rompe ma puoi perdere fixture nuove.

Workflow di update post-upgrade Noctalia:
```fish
# 1. Sblocca Noctalia desktop, configura ciò che vuoi tramite UI
# 2. Ri-snapshotta il template dal file live
cp ~/.config/noctalia/settings.json ~/configure-work-machine/dot_config/noctalia/create_settings.json.tmpl
# 3. Templatizza i path utente
sed -i "s|$HOME|{{ .chezmoi.homeDir }}|g" ~/configure-work-machine/dot_config/noctalia/create_settings.json.tmpl
# 4. Verifica render JSON valido
chezmoi execute-template < ~/configure-work-machine/dot_config/noctalia/create_settings.json.tmpl | jq empty
```

Niente automation possibile: lo schema è "snapshot stato app", non versionato.

### Niri workspace named

I workspace named **persistent** (dichiarati top-level `workspace "foo" { }`)
sono SEMPRE in cima alla lista e shiftano i `focus-workspace 1..9` di una
posizione. I workspace named **dinamici** (creati on-demand da rules
`open-on-workspace`) non funzionano in niri 26.04 — il nome resta `null`. Per
scratchpad-like funzionalità non c'è soluzione clean: niri NON ha lo "special
workspace" di Hyprland.

### Spotify Linux non ha SNI tray

L'icona Spotify che si vede in tray Noctalia è MPRIS (controllo media via D-Bus),
NON un system-tray-icon classica. Spotify Linux ha rimosso SNI nel 2018 e non
l'ha ripristinato. Niente "close to tray" pulito.

### Layout tastiera IT

Su layout IT i tasti `` ` `` / `\` / `[` / `]` richiedono AltGr e sono inadatti
come keybind compositore. Preferire digit/letter/`,`/`.`. Documentato in
memoria utente.

## Operazioni dev comuni

### Aggiungere un pacchetto

1. Identifica la sezione giusta in `.chezmoidata/packages.yaml`:
   - In repo (pacman, cachyos-extra, chaotic-aur) → `pacman.<categoria>`
   - In AUR only (build locale) → `aur.<categoria>`
   - Flatpak → `flatpak:`
2. Aggiungi voce + commento se non-ovvio
3. `paru-mise -Si <pkg>` per smoke test (e per verificare se in chaotic-aur)
4. `chezmoi apply` (lo script 10-packages ha hash trigger su packages.yaml)

### Aggiungere uno script chezmoi

1. Scegli il prefisso (`run_once_after_NN-` per setup una tantum,
   `run_onchange_*` per ri-applicare quando un trigger cambia)
2. Pick NN libero in ordine cronologico
3. Crea `run_*_<name>.sh.tmpl` con `{{- if .flag }}` per gating opzionale
4. `chezmoi execute-template < <file>` per smoke test rendering
5. `chezmoi apply -v` per applicare

### Sync di una config live in chezmoi

Es. dopo aver modificato keybinds da Niri UI o settings da Noctalia:
```fish
cp ~/.config/niri/cfg/keybinds.kdl ~/configure-work-machine/dot_config/niri/cfg/
# se è un create_<file> con template vars: sostituisci /home/$USER con {{ .chezmoi.homeDir }}
```

### Add wallpaper riproducibile

1. Aggiungi voce a `.chezmoidata/wallpapers.yaml` (ID wallhaven o URL diretto)
2. `chezmoi state delete-bucket --bucket=scriptState` per re-trigger
   `run_once_after_82-wallpapers`
3. `chezmoi apply`

## Stato del fish wrapper chezmoi

In `dot_config/fish/config.fish` c'è una funzione `chezmoi` che intercetta
`chezmoi apply` e aggiunge `--force` (skip prompt all-overwrite/diff/quit).
Altri sub-command (`diff`, `edit`, `cd`) restano normali interattivi. Per
disabilitarla temporaneamente: `command chezmoi apply`.

## Riferimenti utili

- Repo: `https://github.com/osharko/configure-work-machine`
- chezmoi docs: `https://www.chezmoi.io/`
- niri wiki: `https://github.com/YaLTeR/niri/wiki/`
- noctalia docs: `https://docs.noctalia.dev/`
- paru: `https://github.com/Morganamilo/paru`
- chaotic-aur: `https://aur.chaotic.cx/`
