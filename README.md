# configure-work-machine

Setup riproducibile per macchine personali. **Repo multi-branch**: ogni branch
contiene un setup completo per una specifica combinazione distro + ambiente.

`develop` è il **hub di indice** — niente codice, solo questo README. Per
applicare un setup, cambia branch (locale) o usa l'URL raw del branch giusto.

## Branch disponibili

| Branch | Distro / DE | Tooling | Stato |
|---|---|---|---|
| [`cachy-niri`](../../tree/cachy-niri) | **CachyOS + Niri + Noctalia** | chezmoi-based, paru/chaotic-aur, 1Password, profili | ✅ attivo |
| [`fedora`](../../tree/fedora) | Fedora (GNOME) | dnf + flatpak, script Manjaro-style zsh | legacy |
| [`pop-os`](../../tree/pop-os) | Pop!_OS (System76) | apt + Pop!_Shop, Dell OEM drivers | legacy |

## Quick install per branch attivo

### CachyOS + Niri (`cachy-niri`)

```sh
bash -c "$(curl -sL https://raw.githubusercontent.com/osharko/configure-work-machine/cachy-niri/bootstrap.sh)"
```

Setup completo via chezmoi: 1Password (o `.env`) per identità, profili
installazione (`base/dev/work/gaming/mediacenter`), Noctalia config,
wallpapers riproducibili. Documentazione completa nel branch.

### Fedora (`fedora`)

```sh
git clone -b fedora https://github.com/osharko/configure-work-machine ~/configure-work-machine
cd ~/configure-work-machine
./start-configure.sh   # vedi README del branch per opzioni
```

### Pop!_OS (`pop-os`)

```sh
git clone -b pop-os https://github.com/osharko/configure-work-machine ~/configure-work-machine
cd ~/configure-work-machine
./start-configure.sh   # include Dell OEM drivers auto-detection
```

## Aggiungere un nuovo setup

1. Crea un nuovo branch orfano: `git checkout --orphan <name>`
2. Aggiungi qui sopra una riga nella tabella branches
3. Push: `git push -u origin <name>`

## Branch policy

- `develop` = hub README + niente altro
- Ogni branch setup è **autonomo** (può evolvere indipendentemente)
- Niente merge tra branches: cherry-pick selettivi se serve condividere fix
