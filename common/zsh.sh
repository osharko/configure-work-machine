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

# Set Zsh as default shell
echo ""
echo "Setting Zsh as default shell..."
current_shell=$(getent passwd "$USER" | cut -d: -f7)
zsh_path=$(which zsh)

if [ "$current_shell" != "$zsh_path" ]; then
    sudo usermod --shell "$zsh_path" "$USER"
    echo "✓ Zsh set as default shell (will take effect after logout)"
else
    echo "✓ Zsh is already the default shell"
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
    "neofetch"
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
echo "Next steps:"
echo "  1. Log out and log back in to use Zsh as your default shell"
echo "  2. Run node_java.sh to install Node.js and Java"
echo "  3. Run 'p10k configure' to customize your Zsh prompt"
echo ""
echo "Note: Homebrew tools are now available. Run 'brew --version' to verify."
