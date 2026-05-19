# System Toggles

Plugin Noctalia per togglare stato di sistema da pannello.

## Toggles attivi

- **Sudo no password** → crea/rimuove `/etc/sudoers.d/99-chezmoi-nopasswd` (richiede pkexec)
- **No-sudo abbreviations** → crea/rimuove `~/.config/fish/conf.d/sudoless.fish` con abbreviazioni `pacman/systemctl/mount/...` auto-prefixate con `sudo`. Combinato con "Sudo no password" → effetto "OVH-like" (digiti senza prefix)

## Read-only (gestiti da chezmoi)

- **Autologin tty1** → stato di `/etc/systemd/system/getty@tty1.service.d/autologin.conf`
- **Keyring no password** → stato di `~/.local/share/keyrings/login.keyring` (formato ASCII = no pwd)

## Requisiti

- Script wrapper: `~/.local/bin/system-toggle` (incluso in `configure-work-machine`)
- `pkexec` (pacchetto `polkit`)
- Polkit agent attivo (es. plugin `polkit-agent` di Noctalia)

## Uso

1. Click su icona shield nella bar → apre panel
2. Toggle switch per Sudo/abbreviations
3. pkexec chiede password (1 volta per sessione)
4. Refresh automatico ogni 5s
