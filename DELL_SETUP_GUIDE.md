# Dell Hardware Setup Guide for Pop!_OS

Guida completa per configurare audio e sensore impronte su sistemi Dell con Pop!_OS.

## Problema Risolto

Questo setup risolve i seguenti problemi comuni sui Dell Pro Max e altri modelli Dell recenti:
- ✓ Audio non funzionante (codec SoundWire RT722/RT1320)
- ✓ Sensore impronte Broadcom non riconosciuto
- ✓ Driver hardware mancanti

## Quick Start - Installazione Rapida

### Opzione 1: Installazione Completa Sistema

Se stai configurando una nuova macchina da zero:

```bash
# Scarica e esegui l'intero setup (include pacchetti, zsh, docker, ecc.)
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/develop/start-configure.sh | bash -

# Modalità interattiva (chiede conferma per ogni step)
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/develop/start-configure.sh | bash -s -- -i
```

### Opzione 2: Solo Driver Dell

Se vuoi installare solo i driver Dell senza toccare il resto del sistema:

```bash
# Installazione rapida dei driver Dell
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/develop/install-dell-drivers.sh | bash -
```

### Opzione 3: Da Repository Locale

Se hai già clonato il repository:

```bash
cd ~/Code/Personal/configure-work-machine

# Solo driver Dell
./popos/dell-oem-drivers.sh

# Oppure setup completo
./start-configure.sh
```

## Dopo l'Installazione

### 1. Riavvia il Sistema

**IMPORTANTE:** Il riavvio è necessario per caricare i nuovi driver e firmware!

```bash
sudo reboot
```

### 2. Verifica Hardware (Dopo il Riavvio)

Esegui lo script di verifica per controllare che tutto funzioni:

```bash
cd ~/Code/Personal/configure-work-machine
./popos/verify-dell-hardware.sh
```

### 3. Configura Audio

Se l'audio non è configurato correttamente come output predefinito:

```bash
# Vedi tutti i dispositivi audio disponibili
wpctl status

# Imposta gli speaker interni come predefiniti (sostituisci X con l'ID corretto)
wpctl set-default X

# Regola il volume
wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%

# Testa l'audio
speaker-test -t wav -c 2 -l 1
```

### 4. Configura Sensore Impronte

Se il sensore viene riconosciuto (verifica con lo script di verifica):

```bash
# Registra la tua impronta digitale
fprintd-enroll

# Testa il sensore
fprintd-verify

# Verifica le impronte registrate
fprintd-list $USER
```

## Modelli Dell Supportati

Lo script rileva automaticamente il tuo modello e installa il pacchetto OEM appropriato:

| Modello Dell | Codice | Pacchetto OEM |
|--------------|--------|---------------|
| Dell Pro Max 14 | MC14255 | oem-somerville-jellicent-meta |
| Dell Pro Max 16 | MC16255 | oem-somerville-jellicent-meta |
| Dell Pro 14 Premium | PC14255 | oem-somerville-jellicent-meta |
| Dell Pro 16 Premium | PC16255 | oem-somerville-jellicent-meta |
| Dell Pro Max Slim | FCS1250 | oem-somerville-aggron-meta |
| Dell Pro Max Tower T2 | FCT2250 | oem-somerville-delcatty-meta |
| Dell Latitude 7340 | - | oem-somerville-lapras-13-meta |
| Dell Pro Rugged 13 | RA13250 | oem-somerville-deerling-meta |
| Dell Pro Rugged 14 | RB14250 | oem-somerville-deerling-meta |

## Cosa Viene Installato

### Pacchetto OEM Dell
- Driver specifici per il tuo modello
- Firmware hardware aggiornato
- Configurazioni ottimizzate

### Driver Audio
- Supporto AMD SoundWire
- Codec Realtek RT722 (jack audio/microfono)
- Codec Realtek RT1320 (speaker interni)
- Moduli kernel: `soundwire_amd`, `snd_soc_rt722_sdca`, `snd_soc_rt1320_sdw`

### Driver Sensore Impronte
- `libfprint-2-2` - Libreria base fingerprint
- `libfprint-2-tod1` - Touch OEM Drivers
- `libfprint-2-tod1-broadcom` - Driver Broadcom specifico
- `fprintd` - Demone per gestione impronte

### Firmware
- `linux-firmware` - Firmware kernel aggiornato
- Firmware specifici AMD/Realtek/Broadcom

## Troubleshooting

### Audio Non Funziona Dopo Riavvio

1. Verifica che i moduli siano caricati:
```bash
lsmod | grep -E "(soundwire|rt722|rt1320)"
```

2. Controlla i dispositivi audio disponibili:
```bash
wpctl status
aplay -l
```

3. Verifica i log per errori:
```bash
journalctl -b | grep -iE "(audio|soundwire|rt722|rt1320)"
```

4. Prova a ricaricare i moduli:
```bash
sudo modprobe -r snd_soc_rt722_sdca
sudo modprobe -r snd_soc_rt1320_sdw
sudo modprobe snd_soc_rt722_sdca
sudo modprobe snd_soc_rt1320_sdw
```

### Sensore Impronte Non Riconosciuto

1. Verifica che il dispositivo sia presente:
```bash
lsusb | grep -i broadcom
```

2. Controlla i driver installati:
```bash
dpkg -l | grep libfprint
```

3. Riavvia il servizio fprintd:
```bash
systemctl restart fprintd
fprintd-list $USER
```

4. Se ancora non funziona, potrebbe essere che il tuo modello specifico non è ancora supportato dai driver. Controlla aggiornamenti:
```bash
sudo apt update
sudo apt upgrade
```

5. Prova a usare fwupd per aggiornare il firmware del sensore:
```bash
fwupdmgr get-devices
fwupdmgr update
```

### Pacchetto OEM Non Trovato

Se lo script non riesce a trovare il pacchetto OEM per il tuo modello:

1. Cerca manualmente:
```bash
apt search oem-somerville
```

2. Identifica il tuo modello:
```bash
cat /sys/class/dmi/id/product_name
cat /sys/class/dmi/id/product_sku
```

3. Installa manualmente il pacchetto appropriato:
```bash
sudo apt install oem-somerville-<nome-pacchetto>-meta
```

## Script Disponibili

Il repository include i seguenti script per Dell hardware:

### `popos/dell-oem-drivers.sh`
Script principale per installare driver Dell OEM, audio e impronte.

```bash
./popos/dell-oem-drivers.sh
```

### `install-dell-drivers.sh`
Script standalone per download e installazione rapida.

```bash
./install-dell-drivers.sh
# Oppure via curl
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/develop/install-dell-drivers.sh | bash -
```

### `popos/verify-dell-hardware.sh`
Script di verifica per controllare installazione e funzionalità dopo il riavvio.

```bash
./popos/verify-dell-hardware.sh
```

## Integrazione con Setup Completo

Se stai usando l'intero sistema di configurazione, i driver Dell vengono installati automaticamente quando:
- Il sistema operativo è Pop!_OS
- Viene rilevato un vendor Dell

Gli script vengono eseguiti nell'ordine:
1. `popos/apt.sh` - Pacchetti base e software
2. `popos/dell-oem-drivers.sh` - Driver hardware Dell (se rilevato)
3. `common/zsh.sh` - Shell e strumenti CLI
4. `common/node_java.sh` - Node.js e Java
5. `popos/flatpak_and_service.sh` - Applicazioni e servizi

## Contribuire

Se hai un modello Dell non ancora supportato:
1. Identifica il tuo modello e pacchetto OEM
2. Aggiorna il mapping in `dell-oem-drivers.sh`
3. Testa l'installazione
4. Invia una pull request!

## Link Utili

- [Repository GitHub](https://github.com/osharko/configure-work-machine)
- [Pop!_OS Documentation](https://support.system76.com/articles/pop-basics/)
- [Dell OEM Ubuntu Packages](https://www.ubuntu.com/certified)
- [libfprint Documentation](https://fprint.freedesktop.org/)

## Note per Future Formattazioni

Quando reinstalli il sistema:

1. **Backup dei dati** (ovviamente!)

2. **Installa Pop!_OS** dalla USB

3. **Dopo il primo boot**, esegui:
```bash
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/develop/start-configure.sh | bash -s -- -i
```

4. **Segui le istruzioni** dello script interattivo

5. **Riavvia** quando richiesto

6. **Verifica** con lo script di verifica:
```bash
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/develop/popos/verify-dell-hardware.sh | bash -
```

7. **Configura impronte** e **testa audio**

Tutto dovrebbe funzionare al primo colpo!

---

**Creato per:** Dell Pro Max 16 MC16255
**Sistema Operativo:** Pop!_OS 24.04
**Data:** Dicembre 2024
