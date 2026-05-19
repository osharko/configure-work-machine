# Quick Reference - Comandi Utili

Riferimento rapido per i comandi più comuni relativi all'hardware Dell.

## Prima del Riavvio

### Installa i Driver Dell OEM
```bash
cd ~/Code/Personal/configure-work-machine
./popos/dell-oem-drivers.sh
```

### Oppure Installazione Rapida (senza clonare repo)
```bash
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/develop/install-dell-drivers.sh | bash -
```

## Dopo il Riavvio

### Verifica Installazione
```bash
cd ~/Code/Personal/configure-work-machine
./popos/verify-dell-hardware.sh
```

## Audio

### Stato Audio
```bash
# PipeWire status
wpctl status

# Lista dispositivi
aplay -l

# Moduli caricati
lsmod | grep -E "(soundwire|rt722|rt1320)"
```

### Configurazione Audio
```bash
# Imposta sink predefinito (sostituisci 56 con l'ID corretto)
wpctl set-default 56

# Regola volume
wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%

# Test audio
speaker-test -t wav -c 2 -l 1
```

### Debug Audio
```bash
# Log audio
journalctl -b | grep -iE "(audio|soundwire)"

# Ricarica moduli
sudo modprobe -r snd_soc_rt722_sdca && sudo modprobe snd_soc_rt722_sdca
```

## Sensore Impronte

### Verifica Sensore
```bash
# Lista dispositivi
fprintd-list $USER

# Info dispositivo USB
lsusb | grep -i broadcom
```

### Registrazione Impronta
```bash
# Registra impronta
fprintd-enroll

# Testa sensore
fprintd-verify
```

### Debug Sensore
```bash
# Pacchetti installati
dpkg -l | grep libfprint

# Stato servizio
systemctl status fprintd

# Riavvia servizio
sudo systemctl restart fprintd
```

## Sistema

### Info Hardware
```bash
# Modello
cat /sys/class/dmi/id/product_name

# SKU
cat /sys/class/dmi/id/product_sku

# Vendor
cat /sys/class/dmi/id/sys_vendor
```

### Pacchetti OEM
```bash
# Cerca pacchetti OEM
apt search oem-somerville

# Verifica installazione
dpkg -l | grep oem-somerville
```

### Aggiornamenti
```bash
# Aggiorna sistema
sudo apt update && sudo apt upgrade -y

# Aggiorna firmware
fwupdmgr get-devices
fwupdmgr update
```

## Log e Diagnostica

### Log Generali
```bash
# Log boot corrente
journalctl -b

# Filtra per audio
journalctl -b | grep -iE "(soundwire|rt722|rt1320)"

# Filtra per broadcom
journalctl -b | grep -i broadcom

# Filtra per firmware
journalctl -b | grep -i firmware
```

### Kernel e Moduli
```bash
# Versione kernel
uname -r

# Info modulo
modinfo snd_soc_rt722_sdca

# Lista moduli caricati
lsmod | grep snd
```

## Setup Completo Sistema

### Configurazione Completa
```bash
cd ~/Code/Personal/configure-work-machine

# Modo normale
./start-configure.sh

# Modo interattivo
./start-configure.sh -i

# Modo silenzioso
./start-configure.sh -y
```

### Solo Componenti Specifici
```bash
# Solo pacchetti
./popos/apt.sh

# Solo driver Dell
./popos/dell-oem-drivers.sh

# Solo Zsh
./common/zsh.sh

# Solo Node/Java
./common/node_java.sh

# Solo Flatpak/Services
./popos/flatpak_and_service.sh
```

## File nel Repository

```
configure-work-machine/
├── start-configure.sh              # Script principale
├── install-dell-drivers.sh         # Quick install Dell drivers
├── DELL_SETUP_GUIDE.md            # Guida completa (questo file)
├── QUICK_REFERENCE.md             # Riferimento rapido comandi
├── popos/
│   ├── apt.sh                     # Installazione pacchetti
│   ├── dell-oem-drivers.sh        # Driver Dell OEM
│   ├── verify-dell-hardware.sh    # Verifica hardware
│   └── flatpak_and_service.sh     # Flatpak e servizi
├── common/
│   ├── zsh.sh                     # Setup Zsh
│   ├── node_java.sh              # Node.js e Java
│   └── like_manjaro_zsh.sh       # Config Zsh Manjaro-style
└── ...
```

## Shortcuts Utili

### Audio
```bash
alias audio-status='wpctl status'
alias audio-test='speaker-test -t wav -c 2 -l 1'
alias audio-sinks='wpctl status | grep -A10 "Sinks:"'
```

### Impronte
```bash
alias fp-list='fprintd-list $USER'
alias fp-enroll='fprintd-enroll'
alias fp-verify='fprintd-verify'
```

### Sistema
```bash
alias dell-info='cat /sys/class/dmi/id/product_name && cat /sys/class/dmi/id/product_sku'
alias dell-verify='~/Code/Personal/configure-work-machine/popos/verify-dell-hardware.sh'
```

Aggiungi questi alias al tuo `~/.zshrc` o `~/.bashrc`!

## Link Rapidi

- [Repository GitHub](https://github.com/osharko/configure-work-machine)
- [Guida Completa Dell](./DELL_SETUP_GUIDE.md)
- [README Principale](./README.md)

## Prossimi Passi

1. ✓ Hai eseguito `./popos/dell-oem-drivers.sh`
2. ⏳ **RIAVVIA ORA**: `sudo reboot`
3. ⏳ Dopo riavvio: `./popos/verify-dell-hardware.sh`
4. ⏳ Configura audio con wpctl
5. ⏳ Registra impronta con fprintd-enroll

---
*Ultimo aggiornamento: Dicembre 2024*
