#!/bin/bash

set -e

echo "=== Installing Node.js and Java Development Environments ==="
echo ""

# Ensure Homebrew is available
if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew not found. Please run zsh.sh first to install Homebrew."
    exit 1
fi

# Load Homebrew environment
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Ensure nvm and jenv are installed via Homebrew
if ! brew list nvm &> /dev/null || ! brew list jenv &> /dev/null; then
    echo "Error: nvm or jenv not found. Please run zsh.sh first."
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

    # Check if jenv configuration already exists
    if ! grep -q "jenv init" "$file" 2>/dev/null; then
        echo "  Adding jenv configuration to $file..."
        {
            echo ''
            echo '# jenv (Java Environment Manager)'
            echo 'export PATH="$HOME/.jenv/bin:$PATH"'
            echo 'eval "$(jenv init -)"'
        } >> "$file"
    fi
done

# Load NVM for current session
echo ""
echo "Loading NVM for current session..."
export NVM_DIR="$HOME/.nvm"
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"

# Load jenv for current session
echo "Loading jenv for current session..."
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"
jenv enable-plugin export

# Install Java JDKs
echo ""
echo "Installing Amazon Corretto JDK..."

# Create JDKs directory
JDKS_DIR=/usr/share/jdks
sudo mkdir -p "$JDKS_DIR"
sudo chmod 755 "$JDKS_DIR"
sudo chown -R "$(whoami):$(whoami)" "$JDKS_DIR"

# Install JDK 8
if [ ! -d "$JDKS_DIR/jdk-8" ]; then
    echo "  Installing Amazon Corretto JDK 8..."
    mkdir -p "$JDKS_DIR/jdk-8"
    wget -q --show-progress -O - https://corretto.aws/downloads/latest/amazon-corretto-8-x64-linux-jdk.tar.gz | \
        tar -xz --strip-components=1 -C "$JDKS_DIR/jdk-8"
    jenv add "$JDKS_DIR/jdk-8" || echo "  JDK 8 already added to jenv"
    echo "  ✓ JDK 8 installed"
else
    echo "  JDK 8 already installed, skipping..."
fi

# Install JDK 21
if [ ! -d "$JDKS_DIR/jdk-21" ]; then
    echo "  Installing Amazon Corretto JDK 21..."
    mkdir -p "$JDKS_DIR/jdk-21"
    wget -q --show-progress -O - https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.tar.gz | \
        tar -xz --strip-components=1 -C "$JDKS_DIR/jdk-21"
    jenv add "$JDKS_DIR/jdk-21" || echo "  JDK 21 already added to jenv"
    echo "  ✓ JDK 21 installed"
else
    echo "  JDK 21 already installed, skipping..."
fi

# Set JDK 21 as global default
echo ""
echo "Setting JDK 21 as global default..."
jenv global 21

# Install Node.js
echo ""
echo "Installing Node.js LTS (version 20)..."
nvm install 20
nvm use 20
nvm alias default 20

echo ""
echo "=== Node.js and Java installation complete! ==="
echo ""
echo "Installed versions:"
echo "  Node.js: $(node --version 2>/dev/null || echo 'Run: source ~/.zshrc && nvm use 20')"
echo "  npm: $(npm --version 2>/dev/null || echo 'Available after sourcing shell config')"
echo "  Java: $(java -version 2>&1 | head -n 1 || echo 'Run: source ~/.zshrc')"
echo ""
echo "Available JDK versions (jenv):"
jenv versions 2>/dev/null || echo "  Run 'source ~/.zshrc' to load jenv"
echo ""
echo "Note: Restart your terminal or run 'source ~/.zshrc' to use these tools immediately"
