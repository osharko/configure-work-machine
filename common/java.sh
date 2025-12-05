#!/bin/bash

set -e

echo "=== Installing Java Development Environment ==="
echo ""

# Ensure Homebrew is available
if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew not found. Please run zsh.sh first to install Homebrew."
    exit 1
fi

# Load Homebrew environment
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Ensure jenv is installed via Homebrew
if ! brew list jenv &> /dev/null; then
    echo "Error: jenv not found. Please run zsh.sh first."
    exit 1
fi

# Configure jenv in shell configuration files
for file in ~/.profile ~/.bashrc ~/.zshrc; do
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

# Load jenv for current session
echo ""
echo "Loading jenv for current session..."
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

# Enable jenv plugins
echo "Enabling jenv plugins..."
jenv enable-plugin export
jenv enable-plugin maven
jenv enable-plugin gradle

# Create JDKs directory
JDKS_DIR=/opt/jdks
echo ""
echo "Setting up JDK installation directory: $JDKS_DIR"
sudo mkdir -p "$JDKS_DIR"
sudo chmod 755 "$JDKS_DIR"
sudo chown -R "$(whoami):$(whoami)" "$JDKS_DIR"

# Function to download and install JDK
install_jdk() {
    local version=$1
    local url=$2
    local jdk_dir="$JDKS_DIR/jdk-$version"

    if [ -d "$jdk_dir" ]; then
        echo "  JDK $version already installed at $jdk_dir, skipping..."
        # Ensure it's added to jenv
        jenv add "$jdk_dir" 2>/dev/null || echo "  JDK $version already in jenv"
        return 0
    fi

    echo "  Installing Amazon Corretto JDK $version..."
    mkdir -p "$jdk_dir"

    # Download with progress and extract
    if wget --show-progress -q -O - "$url" | tar -xz --strip-components=1 -C "$jdk_dir"; then
        echo "  ✓ JDK $version extracted to $jdk_dir"

        # Add to jenv
        jenv add "$jdk_dir" || echo "  JDK $version already added to jenv"
        echo "  ✓ JDK $version installed successfully"
    else
        echo "  ✗ Failed to install JDK $version"
        return 1
    fi
}

# Install JDK 8 (Amazon Corretto)
echo ""
echo "Installing JDK 8 (Amazon Corretto)..."
install_jdk 8 "https://corretto.aws/downloads/latest/amazon-corretto-8-x64-linux-jdk.tar.gz"

# Install JDK 21 (Amazon Corretto LTS)
echo ""
echo "Installing JDK 21 (Amazon Corretto LTS)..."
install_jdk 21 "https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.tar.gz"

# Set JDK 21 as global default
echo ""
echo "Setting JDK 21 as global default..."
jenv global 21 || jenv global $(jenv versions --bare | grep "^21" | head -1)

# Install Maven
MAVEN_VERSION="3.9.9"
MAVEN_DIR="$JDKS_DIR/maven"
echo ""
echo "Installing Apache Maven $MAVEN_VERSION..."

if [ -d "$MAVEN_DIR" ]; then
    echo "  Maven already installed at $MAVEN_DIR, skipping..."
else
    echo "  Downloading Maven $MAVEN_VERSION..."
    MAVEN_URL="https://dlcdn.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz"

    if wget --show-progress -q -O - "$MAVEN_URL" | tar -xz -C "$JDKS_DIR"; then
        mv "$JDKS_DIR/apache-maven-$MAVEN_VERSION" "$MAVEN_DIR"
        echo "  ✓ Maven installed to $MAVEN_DIR"
    else
        echo "  ✗ Failed to install Maven"
    fi
fi

# Add Maven to PATH in shell configs
for file in ~/.profile ~/.bashrc ~/.zshrc; do
    if ! grep -q "MAVEN_HOME" "$file" 2>/dev/null; then
        echo "  Adding Maven to $file..."
        {
            echo ''
            echo '# Apache Maven'
            echo 'export MAVEN_HOME="/opt/jdks/maven"'
            echo 'export PATH="$MAVEN_HOME/bin:$PATH"'
        } >> "$file"
    fi
done

# Load Maven for current session
export MAVEN_HOME="$MAVEN_DIR"
export PATH="$MAVEN_HOME/bin:$PATH"

# Install Gradle
GRADLE_VERSION="8.11.1"
GRADLE_DIR="$JDKS_DIR/gradle"
echo ""
echo "Installing Gradle $GRADLE_VERSION..."

if [ -d "$GRADLE_DIR" ]; then
    echo "  Gradle already installed at $GRADLE_DIR, skipping..."
else
    echo "  Downloading Gradle $GRADLE_VERSION..."
    GRADLE_URL="https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip"

    # Download Gradle
    if wget --show-progress -q "$GRADLE_URL" -O /tmp/gradle.zip; then
        unzip -q /tmp/gradle.zip -d "$JDKS_DIR"
        mv "$JDKS_DIR/gradle-$GRADLE_VERSION" "$GRADLE_DIR"
        rm /tmp/gradle.zip
        echo "  ✓ Gradle installed to $GRADLE_DIR"
    else
        echo "  ✗ Failed to install Gradle"
    fi
fi

# Add Gradle to PATH in shell configs
for file in ~/.profile ~/.bashrc ~/.zshrc; do
    if ! grep -q "GRADLE_HOME" "$file" 2>/dev/null; then
        echo "  Adding Gradle to $file..."
        {
            echo ''
            echo '# Gradle'
            echo 'export GRADLE_HOME="/opt/jdks/gradle"'
            echo 'export PATH="$GRADLE_HOME/bin:$PATH"'
        } >> "$file"
    fi
done

# Load Gradle for current session
export GRADLE_HOME="$GRADLE_DIR"
export PATH="$GRADLE_HOME/bin:$PATH"

echo ""
echo "=== Java development environment installation complete! ==="
echo ""
echo "Installed components:"
echo "  ✓ JDK 8 (Amazon Corretto) - $JDKS_DIR/jdk-8"
echo "  ✓ JDK 21 (Amazon Corretto LTS) - $JDKS_DIR/jdk-21"
echo "  ✓ Apache Maven $MAVEN_VERSION - $MAVEN_DIR"
echo "  ✓ Gradle $GRADLE_VERSION - $GRADLE_DIR"
echo ""
echo "Installed versions:"
echo "  Java: $(java -version 2>&1 | head -n 1 || echo 'Run: source ~/.zshrc')"
echo "  Maven: $(mvn --version 2>&1 | head -n 1 || echo 'Run: source ~/.zshrc')"
echo "  Gradle: $(gradle --version 2>&1 | grep "Gradle" || echo 'Run: source ~/.zshrc')"
echo ""
echo "Available JDK versions (jenv):"
jenv versions 2>/dev/null || echo "  Run 'source ~/.zshrc' to load jenv"
echo ""
echo "Useful jenv commands:"
echo "  jenv versions        - List installed JDK versions"
echo "  jenv global <ver>    - Set global JDK version"
echo "  jenv local <ver>     - Set JDK version for current directory"
echo "  jenv shell <ver>     - Set JDK version for current shell session"
echo ""
echo "jenv plugins enabled:"
echo "  ✓ export  - Exports JAVA_HOME automatically"
echo "  ✓ maven   - Integrates with Maven"
echo "  ✓ gradle  - Integrates with Gradle"
echo ""
echo "Note: Restart your terminal or run 'source ~/.zshrc' to use these tools immediately"
echo ""
