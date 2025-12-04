# Configure Work Machine

Automated scripts to set up a fresh Linux installation with all necessary development tools and applications.

## Supported Distributions

- **Fedora** - Full support with DNF package manager
- **Pop!_OS** - Optimized for System76's Pop!_OS with Pop!_Shell and Pop!_Shop
- **Ubuntu** - Standard Ubuntu support

## Quick Install

Run the following command to automatically download and execute the configuration script:

```bash
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/master/start-configure.sh | bash -
```

**Note:** The script will detect your OS automatically and run the appropriate configuration scripts.

## Installation Modes

The installer supports three different modes to suit your preferences:

### Default Mode (Standard)

Asks for confirmation once at the beginning, then executes all scripts automatically.

```bash
# Via curl (remote installation)
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/master/start-configure.sh | bash -

# Or locally
./start-configure.sh
```

### Interactive Mode (Recommended for first-time users)

**Asks before each script** - gives you full control over what gets installed. Perfect for understanding exactly what's happening on your system.

```bash
# Via curl
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/master/start-configure.sh | bash -s -- -i

# Or locally
./start-configure.sh -i
./start-configure.sh --interactive
```

**What you'll see:**

- Description of what each script does
- Option to run or skip each step
- Summary of completed/failed scripts at the end

### Silent Mode (For automation)

Runs everything without prompts - useful for automated deployments or if you trust the configuration completely.

```bash
# Via curl
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/master/start-configure.sh | bash -s -- -y

# Or locally
./start-configure.sh -y
./start-configure.sh --yes
```

### Getting Help

```bash
./start-configure.sh --help
```

## What Gets Installed

### Package Managers & Development Tools

- Build essentials (gcc, make, development tools)
- Git
- Homebrew (Linux)
- Docker & Docker Compose
- Go

### Text Editors & IDEs

- Visual Studio Code
- Sublime Text

### Browsers

- Brave Browser

### Shell & Terminal

- Zsh with Powerlevel10k theme
- Manjaro-style Zsh configuration
- MesloLGS NF fonts
- Zsh plugins: autosuggestions, syntax-highlighting, history-substring-search

### Programming Languages

- Node.js (via nvm)
  - Node 20 LTS
- Java (via jenv)
  - Amazon Corretto JDK 8
  - Amazon Corretto JDK 21

### Modern CLI Tools

#### System Monitoring & Navigation

- **btop** - Beautiful terminal resource monitor
- **htop** - Interactive process viewer
- **fastfetch** - System information tool
- **ncdu** - Disk usage analyzer

#### File & Text Operations

- **bat** - Cat clone with syntax highlighting
- **eza** - Modern ls replacement with icons
- **fd** - Fast and user-friendly alternative to find
- **ripgrep** - Ultra-fast search tool
- **fzf** - Fuzzy finder for command line
- **ag** (The Silver Searcher) - Fast code search

#### Git & Docker Management

- **lazygit** - Terminal UI for git commands
- **lazydocker** - Terminal UI for Docker

#### Utilities

- **zoxide** - Smarter cd command that learns your habits
- **thefuck** - Magnificent app that corrects console commands
- **jq** - JSON processor
- **tldr** - Simplified man pages

### System Tools

- gparted
- timeshift
- corectrl (Fedora)
- obs-studio
- gnome-tweaks (Pop!_OS/Ubuntu)
- dconf-editor (Pop!_OS/Ubuntu)

### Virtualization

- virt-manager
- libvirt
- qemu

### Services

- Docker (enabled)
- SSH/SSHD (enabled)
- libvirtd (enabled)
- System76 Power (Pop!_OS only)
- XRDP (Fedora only)

### Flatpak Applications

- **Telegram Desktop** - Messaging
- **Discord** - Communication
- **Spotify** - Music streaming
- **Bottles** - Run Windows software (modern Wine wrapper)
- **Popsicle** - USB flasher (Pop!_OS tool)
- **DBeaver Community** - Universal database tool
- **Beekeeper Studio** - Modern database GUI
- **GIMP** - Image editor
- **Inkscape** - Vector graphics editor
- **Flatseal** - Manage Flatpak permissions
- **Podman Desktop** - Container management

### GNOME Extensions (if running GNOME)

- Clipboard History
- Dash to Panel
- Tiling Shell
- System Monitor
- Removable Drive Menu

### Pop!_OS Specific Features

When running on Pop!_OS, additional optimizations are applied:

- **Pop!_Shell** - Advanced tiling window manager
- **System76 Power** - Graphics and power management
- **Pop!_Shop** - Integrated Flatpak and package management
- Hybrid graphics support (Intel/NVIDIA switching)

#### Dell OEM Hardware Support

For Dell systems (automatically detected), the script can install OEM-specific drivers:

- **Dell OEM packages** - Model-specific hardware support
- **Audio drivers** - SoundWire, Realtek codec support (RT722, RT1320)
- **Fingerprint drivers** - Broadcom fingerprint reader support
- **Firmware updates** - Latest hardware firmware

To manually install Dell OEM drivers:

```bash
# If you've cloned the repository
./popos/dell-oem-drivers.sh

# Or run directly without cloning (quick install)
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/develop/install-dell-drivers.sh | bash -
```

Supported Dell models include:
- Dell Pro Max 14/16 (MC14255, MC16255, PC14255, PC16255)
- Dell Pro Max Slim (FCS1250)
- Dell Pro Max Tower (FCT2250)
- Dell Latitude 7340
- Dell Pro Rugged 13/14 (RA13250, RB14250)
- And more (auto-detected)

#### Pop!_Shell Keyboard Shortcuts

- `Super + Y` - Toggle tiling mode
- `Super + O` - Change window orientation
- `Super + G` - Float focused window
- `Super + Arrow` - Move focus between windows
- `Super + Enter` - Adjust window size
- `Super + M` - Maximize window

## Manual Installation

If you prefer to clone the repository and run scripts manually:

```bash
# Clone the repository
git clone https://github.com/osharko/configure-work-machine.git
cd configure-work-machine

# Make the main script executable
chmod +x start-configure.sh

# Run the configuration
./start-configure.sh
```

## Directory Structure

```text
.
├── start-configure.sh          # Main installation script (auto-detects OS)
├── fedora/
│   ├── dnf.sh                 # Fedora package installation
│   └── flatpak_and_service.sh # Fedora services configuration
├── popos/
│   ├── apt.sh                 # Pop!_OS optimized package installation
│   ├── dell-oem-drivers.sh    # Dell OEM hardware drivers (audio, fingerprint, firmware)
│   └── flatpak_and_service.sh # Pop!_OS services & Pop!_Shop apps
├── ubuntu/
│   ├── apt.sh                 # Ubuntu package installation
│   └── flatpak_and_service.sh # Ubuntu services configuration
└── common/
    ├── zsh.sh                 # Zsh, Homebrew & CLI tools setup
    ├── node_java.sh           # Node.js and Java installation
    └── like_manjaro_zsh.sh    # Manjaro-style Zsh configuration
```

## Post-Installation Steps

After the scripts complete:

1. **Reboot your system** to apply all changes

2. **Configure Zsh prompt:**

   ```bash
   p10k configure
   ```

3. **Change terminal font** to "MesloLGS NF" for proper icons display

4. **Log out and log back in** for group changes (docker, libvirt) to take effect

5. **Verify installations:**

   ```bash
   docker --version
   node --version
   java -version
   bat --version
   lazygit --version
   ```

6. **Try out the new CLI tools:**

   ```bash
   # Better ls with icons
   eza -la

   # Better cat with syntax highlighting
   bat README.md

   # Fuzzy find files
   fzf

   # Smart directory jumping
   zoxide add ~/projects
   z proj  # jumps to ~/projects

   # Beautiful system monitor
   btop

   # Git TUI
   lazygit

   # Docker TUI
   lazydocker
   ```

## Running Individual Scripts

You can also run individual scripts for specific components:

### Fedora

```bash
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/master/fedora/dnf.sh | bash -
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/master/common/zsh.sh | bash -
```

### Pop!_OS

```bash
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/master/popos/apt.sh | bash -
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/master/common/zsh.sh | bash -
```

### Ubuntu

```bash
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/master/ubuntu/apt.sh | bash -
curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/master/common/zsh.sh | bash -
```

## Customization

Feel free to fork this repository and modify the scripts to suit your needs. Each script is independent and can be customized separately.

## Troubleshooting

### Docker permission denied

If you get permission errors with Docker after installation:

```bash
sudo usermod -aG docker $USER
# Then log out and log back in
```

### Zsh not loading properly

Make sure you've installed the fonts and configured p10k:

```bash
p10k configure
```

### GNOME extensions not working

Enable them manually:

```bash
gnome-extensions list
gnome-extensions enable <extension-id>
```

### Pop!_OS graphics switching

For systems with hybrid graphics (Intel + NVIDIA):

```bash
# Check current mode
system76-power graphics

# Switch modes
system76-power graphics intel     # Battery-saving mode
system76-power graphics nvidia    # Performance mode
system76-power graphics hybrid    # Switch between both
system76-power graphics compute   # NVIDIA compute only
```

### Bottles not launching Windows apps

Make sure to install the appropriate Windows runtime in Bottles:

1. Open Bottles
2. Create a new bottle
3. Select the appropriate environment (Gaming/Application)
4. Install dependencies as needed

## Cool Tools You Should Try

Here are some recommended workflows with the installed tools:

### Development Workflow

```bash
# Navigate to project
z myproject

# Check git status with beautiful UI
lazygit

# Search for code
rg "function" --type js

# Find files quickly
fd "*.ts" | fzf

# View files with syntax highlighting
bat src/main.ts
```

### System Management

```bash
# Monitor system resources
btop

# Check disk usage
ncdu

# Manage Docker containers
lazydocker

# List files with icons and git status
eza -la --git
```

## .service and .mount files

Any .service and .mount files in the repository are intended to be placed under `/etc/systemd/system/` and enabled via:

```bash
sudo systemctl enable --now <filename>
```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

This project is provided as-is for personal use.
