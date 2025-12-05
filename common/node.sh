#!/bin/bash

set -e

echo "=== Installing Node.js Development Environment ==="
echo ""

# Ensure Homebrew is available
if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew not found. Please run zsh.sh first to install Homebrew."
    exit 1
fi

# Load Homebrew environment
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Ensure nvm is installed via Homebrew
if ! brew list nvm &> /dev/null; then
    echo "Error: nvm not found. Please run zsh.sh first."
    exit 1
fi

echo "Configuring NVM (Node Version Manager)..."
mkdir -p ~/.nvm

# Configure NVM in shell configuration files
for file in ~/.profile ~/.bashrc ~/.zshrc; do
    # Check if NVM configuration already exists
    if ! grep -q "NVM_DIR" "$file" 2>/dev/null; then
        echo "  Adding NVM configuration to $file..."
        {
            echo ''
            echo '# NVM (Node Version Manager)'
            echo 'export NVM_DIR="$HOME/.nvm"'
            echo '[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"'
            echo '[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"'
        } >> "$file"
    fi
done

# Load NVM for current session
echo ""
echo "Loading NVM for current session..."
export NVM_DIR="$HOME/.nvm"
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"

# Install Node.js LTS versions
echo ""
echo "Installing Node.js versions..."

# Install Node.js 20 (LTS)
echo "  Installing Node.js 20 (LTS)..."
nvm install 20
nvm alias default 20

# Install Node.js 22 (Current)
echo "  Installing Node.js 22 (Current)..."
nvm install 22

# Use Node.js 20 as default
nvm use 20

# Install global npm packages
echo ""
echo "Installing useful global npm packages..."
npm install -g \
    yarn \
    pnpm \
    npm-check-updates \
    tldr \
    http-server \
    nodemon

echo ""
echo "=== Node.js installation complete! ==="
echo ""
echo "Installed versions:"
echo "  Node.js 20 (LTS): $(nvm version 20 2>/dev/null || echo 'Installed')"
echo "  Node.js 22 (Current): $(nvm version 22 2>/dev/null || echo 'Installed')"
echo "  Default: $(nvm version default 2>/dev/null || echo 'Node.js 20')"
echo "  npm: $(npm --version 2>/dev/null || echo 'Available after sourcing shell config')"
echo ""
echo "Global packages installed:"
echo "  ✓ yarn, pnpm (alternative package managers)"
echo "  ✓ npm-check-updates (update dependencies)"
echo "  ✓ http-server, nodemon (development tools)"
echo ""
echo "Useful commands:"
echo "  nvm ls              - List installed Node.js versions"
echo "  nvm use <version>   - Switch Node.js version"
echo "  nvm install <ver>   - Install new Node.js version"
echo "  nvm alias default   - Show default Node.js version"
echo ""
echo "Note: Restart your terminal or run 'source ~/.zshrc' to use Node.js immediately"
echo ""
