#!/bin/bash

set -e

echo "=== Setting up Zsh and Homebrew ==="
echo ""

# Check if Zsh is installed
if ! command -v zsh &> /dev/null; then
    echo "Error: Zsh not found. Please install it first using your package manager."
    exit 1
fi

# Install Manjaro-style Zsh configuration
echo "Installing Manjaro-style Zsh theme and configuration..."
if [ -f "like_manjaro_zsh.sh" ]; then
    chmod +x like_manjaro_zsh.sh
    bash like_manjaro_zsh.sh
else
    echo "Warning: like_manjaro_zsh.sh not found in current directory"
    echo "Skipping Manjaro Zsh configuration..."
fi

# Install Homebrew
echo ""
if command -v brew &> /dev/null; then
    echo "Homebrew is already installed, skipping installation..."
else
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "✓ Homebrew installed"
fi

# Configure Homebrew in shell configuration files
echo ""
echo "Configuring Homebrew in shell configuration files..."
for file in ~/.bashrc ~/.zshrc; do
    if [ -f "$file" ]; then
        if ! grep -q "/home/linuxbrew/.linuxbrew/bin/brew shellenv" "$file"; then
            echo "  Adding Homebrew to $file..."
            {
                echo ''
                echo '# Homebrew'
                echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
            } >> "$file"
        else
            echo "  Homebrew already configured in $file"
        fi
    fi
done

# Load Homebrew for current session
echo ""
echo "Loading Homebrew environment..."
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install essential tools via Homebrew
echo ""
echo "Installing development tools via Homebrew..."
brew_packages=(
    "fastfetch"
    "virt-manager"
    "libvirt"
    "qemu"
    "lazydocker"
    "lazygit"
    "jenv"
    "nvm"
    "eza"
    "zoxide"
    "thefuck"
)

for package in "${brew_packages[@]}"; do
    if brew list "$package" &> /dev/null; then
        echo "  $package already installed, skipping..."
    else
        echo "  Installing $package..."
        brew install "$package" || echo "  Warning: Failed to install $package"
    fi
done

echo ""
echo "=== Zsh and Homebrew setup complete! ==="
echo ""
echo "Installed:"
echo "  ✓ Zsh with Powerlevel10k theme"
echo "  ✓ Homebrew and development tools"
echo "  ✓ Modern CLI tools (lazygit, lazydocker, eza, zoxide, etc.)"
echo ""
echo "Note: The default shell has NOT been changed yet."
echo "      This will be done at the end of the installation."
