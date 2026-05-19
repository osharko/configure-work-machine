# Roadmap

Lavori futuri sul repo `configure-work-machine`, in ordine di priorità.

## 🔵 In corso / prossimi

### 1. Plugin Noctalia: system-toggles
Switchabili dal pannello Noctalia senza editing manuale.

**Toggles iniziali** (tutti già rappresentati come flag `.env`):
- `SSHD_ENABLED`         → systemctl enable/disable sshd + ufw allow/delete ssh
- `AUTOLOGIN_TTY`        → drop-in `/etc/systemd/system/getty@tty1.service.d/`
- `PASSWORDLESS_SUDO`    → `/etc/sudoers.d/10-chezmoi-nopasswd`
- `HAS_FINGERPRINT`      → PAM stack + AUR driver (richiede HW)
- `AUTHORIZED_KEYS_FALLBACK` → utility per re-sync chiavi da 1P

**Toggles futuri** candidati:
- nightlight (wlsunset/hyprsunset)
- ufw firewall on/off
- bluetooth on/off
- power profile (performance/balanced/power-saver)
- microphone mute (mic globale)

**Architettura proposta:**
- `dot_config/noctalia/plugins/system-toggles/{manifest.json, BarWidget.qml, Settings.qml, Main.qml}`
- Plugin legge `~/.config/configure-work-machine/config.env` allo start + parsa stato runtime (`systemctl is-active sshd`)
- Switch state → chiama `~/.local/bin/system-toggle <KEY> <true|false>` via Quickshell `Process`
- `system-toggle`: script wrapper che:
  1. `sed -i` sulla riga `KEY=...` in config.env
  2. `pkexec full-config.sh --apply --quiet` per riallineare via chezmoi
- PolicyKit rule `/etc/polkit-1/rules.d/50-chezmoi-toggles.rules`: consente
  pkexec dello specifico script senza prompt password (gated da gruppo wheel
  + LUKS richiesto a runtime)
- Idempotente: chezmoi gli script `run_once_after_*` sono già idempotenti

**File preparatori già nel repo:**
- `.env` ha tutte le flag (basic-config.sh le scrive interattivamente)
- `full-config.sh` regenera chezmoi.toml da .env
- Script chezmoi `85-autologin`, `90-services`, `92-sudo-nopasswd` gated da rispettive flag → toggle = re-apply

### 2. PSR fix per AMD iGPU (Krackan/RDNA 3.5) — residui
Glitch grafici al centro schermo → workaround kernel param.
Base implementata (vedi ✅ Fatte). Restano:
- [ ] Detection automatica: se GPU è Krackan + flag non settato → suggerisci default `true`
- [ ] Verificare anche `linux-cachyos-bore` come kernel alternativo (oggi solo `linux-cachyos`)

### 3. Multi-host support
Stesso repo, machine differenti.
- [ ] `config.env` per-host nominato per hostname: `config.my-laptop.env`
- [ ] `full-config.sh` rileva hostname → carica file giusto
- [ ] Documentare workflow "nuova macchina": copy template `config.example.env`

## 🟡 Migliorie

### 4. Test su Arch vanilla
Il codice oggi assume CachyOS-Niri-Noctalia spin (cachyos-fish-config,
niri-session script, paru pre-installato).
- [ ] Audit di tutti i source path: cosa rompe su Arch base?
- [ ] Sezione README "Arch vanilla: pacchetti extra da installare a mano"

### 5. CI / lint
- [ ] `shellcheck` su tutti gli `.sh` / `.sh.tmpl` (con flag chezmoi-aware)
- [ ] `chezmoi diff` dry-run in CI con `.env` fake + 1P mock
- [ ] GitHub Action: validate template rendering

### 6. Plugin Noctalia: dashboard "system status"
Widget che mostra in tempo reale:
- LUKS attivo (sì/no)
- Fingerprint enrolled (sì/no)
- Distrobox container attivi
- Stato gruppi utente (input/i2c/libvirt/docker)

### 6.5 Migrazione bindings Omarchy → Niri completa
Il dump completo (~150 bindings) è in `omarchy-reference/`. Già tradotto un
sottoinsieme essenziale in `niri-binds-translated.kdl`. Manca:
- [ ] Wrapper per `omarchy-launch-walker` → usare `walker` (AUR) o `fuzzel`
- [ ] Bindings `omarchy-menu` (system/capture/theme/background/share/reminder)
      → o porting come plugin Noctalia (panel custom) o re-design Niri-native
- [ ] `omarchy-launch-webapp` → wrapper script `chromium --app=URL`
- [ ] `omarchy-toggle-nightlight` → `wlsunset` o `hyprsunset` toggle
- [ ] `omarchy-cmd-terminal-cwd` → script che legge cwd shell focused
- [ ] Plugin Noctalia `keybind-cheatsheet` già aggiunto in packages.yaml,
      mostrerà al volo le bindings parsate

## 🟢 Idee / nice-to-have

### 7. Backup snapper / btrfs hook pre-apply
Snapshot automatico prima di `chezmoi apply` per rollback rapido.

### 8. Self-update del repo
Cron user che fa `git pull` + `full-config.sh --apply --quiet` settimanale.

### 9. Validation `.env` schema
JSON Schema o checkov sul `.env` per evitare typo silenziosi.

### 10. Documentation
- [ ] Diagramma architetturale (basic ↔ full ↔ chezmoi ↔ 1P ↔ .env)
- [ ] Asciinema cast onboarding zero-touch

## ✅ Fatte (recenti)

- Niri config persistenti in chezmoi: `dot_config/niri/cfg/{keybinds,input,rules,misc}.kdl`
  (misc come `.tmpl` per `screenshot-path` via `{{ .chezmoi.homeDir }}`)
- Script utility in repo: `dock-launch` e `wallhaven-download` come
  `dot_local/bin/executable_*` (persistono a reinstallazione)
- Limine GPU fix gated da flag: `run_once_after_35-amdgpu-fix.sh.tmpl` aggiunge
  `amdgpu.dcdebugmask=0x10` alla entry `linux-cachyos` in `/boot/limine.conf`
  (idempotente, con backup) — gated da `.disable_amdgpu_psr`
- Sudoers prefix `99-`: drop-in spostato a `/etc/sudoers.d/99-chezmoi-nopasswd`
  perché `10-installer` di CachyOS sovrascriveva il nostro `10-` (ordine
  alfabetico → vince l'ultimo). Cleanup del file legacy `10-` incluso.
- Theme sync Noctalia → GTK/portal (path unit + script `noctalia-theme-sync`)
- Env vars Wayland propagate via `~/.config/environment.d/10-wayland.conf`
- Dump completo bindings Omarchy in `omarchy-reference/`
- Plugin Noctalia `keybind-cheatsheet` aggiunto al packages.yaml
- Flag `SSHD_ENABLED` in `.env` + gating dinamico in `90-services` (enable/disable sshd + ufw)
- 5 flag `.env` pronte per il plugin system-toggles (sshd/autologin/sudo/fp/auth-keys)
- Niri tweaks: Print key → screenshot, `~/Pictures/Screenshots/...` path (script idempotente)
- Wallpapers dir tree: `~/Pictures/Wallpapers/{minimal,nature,urban,abstract,dark,light,seasonal,niri-default}/`

## 🐛 Bug noti

- **Slow Bongo**: richiede gruppo `input` attivo nella sessione; serve reboot
  completo (non basta logout/login perché systemd --user persiste).
  Documentato in README; nessuna fix nel repo perché è una sequenza umana.
- **Mesa 26.1 + Krackan**: glitch occasionale al centro schermo (vedi roadmap #2).
