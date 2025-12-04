# Testing Guide

This guide explains how to test the configuration scripts without reformatting your machine.

## 🎯 Testing Options

### Option 1: Local Modular Testing (Fastest)

Test individual scripts one at a time on your current system:

```bash
./test-local.sh apt              # Test only package installation
./test-local.sh zsh              # Test only Zsh setup
./test-local.sh node-java        # Test only Node.js and Java
./test-local.sh flatpak          # Test only Flatpak apps
./test-local.sh dell             # Test only Dell drivers (if applicable)
./test-local.sh all              # Test all scripts in order
```

**Pros:**
- Instant feedback
- Test one component at a time
- No VM overhead

**Cons:**
- Will modify your system
- Not a clean slate test

**Recommended for:** Quick testing during development, verifying specific components

---

### Option 2: Pop!_OS VM (Most Realistic)

Test on a fresh Pop!_OS virtual machine:

```bash
# Download Pop!_OS ISO first from: https://pop.system76.com
# Save it to ~/Downloads/

# Install prerequisites
sudo apt install qemu-kvm libvirt-daemon-system virt-manager

# Create and start VM
./test-vm.sh

# Inside the VM after installation:
git clone https://github.com/osharko/configure-work-machine.git
cd configure-work-machine
./start-configure.sh -i
```

**Custom VM configuration:**

```bash
# Custom ISO path
./test-vm.sh -i ~/path/to/pop-os.iso

# More RAM (8GB)
./test-vm.sh -m 8192

# More CPUs (8 cores)
./test-vm.sh -c 8

# Larger disk (50GB)
./test-vm.sh -s 50G

# Combined
./test-vm.sh -i ~/pop-os.iso -m 8192 -c 8 -s 50G
```

**Pros:**
- Clean environment every time
- Realistic testing
- No risk to your main system

**Cons:**
- Requires ISO download (~2.5GB)
- Takes time to set up
- VM overhead

**Recommended for:** Final testing before release, verifying complete installation flow

---

### Option 3: Distrobox (Lightweight Containers)

Test in a Pop!_OS container without VM overhead:

```bash
# Install distrobox
sudo apt install distrobox

# Create Pop!_OS container
distrobox create --name popos-test --image ghcr.io/pop-os/pop:22.04

# Enter container
distrobox enter popos-test

# Inside container
git clone https://github.com/osharko/configure-work-machine.git
cd configure-work-machine
./start-configure.sh -i

# Exit and destroy
exit
distrobox rm popos-test
```

**Pros:**
- Very fast
- Lightweight
- Easy to recreate

**Cons:**
- Some system-level features won't work (systemd services, etc.)
- Not 100% realistic

**Recommended for:** Quick smoke testing, testing package installation logic

---

## 📋 Testing Workflow

### During Development

1. **Make changes to a script**
   ```bash
   vim popos/apt.sh
   ```

2. **Test just that script**
   ```bash
   ./test-local.sh apt
   ```

3. **Fix issues and repeat**

4. **Once stable, test the full flow**
   ```bash
   ./test-local.sh all
   ```

### Before Committing

1. **Test in a clean VM**
   ```bash
   ./test-vm.sh
   ```

2. **Run full installation**
   ```bash
   ./start-configure.sh -i
   ```

3. **Verify everything works**
   - Check installed packages
   - Test Zsh prompt
   - Verify Docker works
   - Test Node.js and Java versions

---

## 🐛 Debugging Tips

### Enable verbose output

Add to the top of any script:
```bash
set -x  # Print each command before executing
```

### Test specific sections

Comment out sections in the script you don't want to test:
```bash
# Temporarily disable
# sudo apt install large-package-list...
```

### Check logs

Many tools have logs you can inspect:
```bash
# Homebrew
brew doctor

# Docker
sudo systemctl status docker
journalctl -u docker

# Pop!_Shell
journalctl -f | grep gnome-shell
```

### Dry-run simulation

For package managers, use dry-run modes:
```bash
# APT dry-run
sudo apt install --dry-run package-name

# Flatpak dry-run
flatpak install --dry-run flathub app-id
```

---

## ✅ Test Checklist

Use this checklist to verify everything works:

### After `apt.sh`
- [ ] Brave browser installed: `brave-browser --version`
- [ ] VS Code installed: `code --version`
- [ ] Docker installed: `docker --version`
- [ ] Modern CLI tools work: `bat --version`, `fd --version`, `rg --version`

### After `zsh.sh`
- [ ] Zsh is default shell: `echo $SHELL` shows `/usr/bin/zsh`
- [ ] Homebrew installed: `brew --version`
- [ ] Powerlevel10k theme active
- [ ] lazygit works: `lazygit --version`
- [ ] lazydocker works: `lazydocker --version`

### After `node_java.sh`
- [ ] Node.js installed: `node --version`
- [ ] npm works: `npm --version`
- [ ] Java 21 is default: `java -version`
- [ ] jenv lists both JDKs: `jenv versions`

### After `flatpak_and_service.sh`
- [ ] Docker service running: `sudo systemctl status docker`
- [ ] User in docker group: `groups | grep docker`
- [ ] Flatpak apps installed: `flatpak list`
- [ ] Bottles launches
- [ ] Pop!_Shell enabled: `gnome-extensions list | grep pop-shell`

---

## 🔄 Quick VM Testing Loop

For rapid iteration:

```bash
# Terminal 1: Keep this open
./test-vm.sh

# Terminal 2: Make changes
vim popos/apt.sh
git add .
git commit -m "fix: update package list"
git push

# In VM: Pull and test
git pull
./start-configure.sh -i
```

---

## 📊 Performance Testing

Track how long each script takes:

```bash
time ./test-local.sh apt
time ./test-local.sh zsh
time ./test-local.sh node-java
time ./test-local.sh flatpak
```

---

## 🆘 Common Issues

### "Permission denied" errors
```bash
# Make scripts executable
chmod +x *.sh popos/*.sh common/*.sh
```

### "Command not found" after install
```bash
# Reload shell
source ~/.zshrc
# or
exec zsh
```

### Docker permission denied
```bash
# Log out and back in for group changes
# or
newgrp docker
```

### Homebrew not in PATH
```bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

---

## 💡 Pro Tips

1. **Use tmux/screen** to keep your test session running
2. **Take VM snapshots** after each successful script
3. **Keep a test notes file** with what works and what doesn't
4. **Test on different Pop!_OS versions** (22.04, 24.04, etc.)
5. **Document any workarounds** you discover

---

## 🚀 Automated Testing (Future)

For CI/CD, you can automate VM testing:

```bash
#!/bin/bash
# automated-test.sh

# Start VM in headless mode
qemu-system-x86_64 -nographic -vnc :1 ...

# SSH into VM and run tests
ssh -p 2222 user@localhost "cd repo && ./start-configure.sh -y"

# Check exit code
if [ $? -eq 0 ]; then
    echo "✓ All tests passed"
else
    echo "✗ Tests failed"
    exit 1
fi
```

---

Happy testing! 🎉
