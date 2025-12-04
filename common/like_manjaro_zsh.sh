#!/bin/bash

set -e

echo "=== Installing Manjaro-style Zsh Configuration ==="
echo ""

TEMP_SOURCE=~/manjaro-zsh-config

# Function to update permissions on directories
update_permission() {
    local dest=$1
    sudo chmod -R 755 "$dest"
    sudo chown -R "$(whoami):$(whoami)" "$dest"
}

# Function to copy files to zsh folder
copy_to_zsh_folder() {
    local source_dir=$1
    local item=$2
    local base_dest=/usr/share/zsh

    echo "  Copying $item to $base_dest..."
    sudo cp -r "$source_dir/$item" "$base_dest/$item"
    update_permission "$base_dest/$item"
}

# Clean up old installations
echo "Cleaning up old Zsh configurations..."
ZSH_DEST=/usr/share/zsh
sudo rm -rf \
    ~/.zshrc \
    "$ZSH_DEST/manjaro-zsh-config" \
    "$ZSH_DEST/manjaro-zsh-prompt" \
    "$ZSH_DEST/p10k-portable.zsh" \
    "$ZSH_DEST/p10k.zsh" \
    "$ZSH_DEST/zsh-maia-prompt"

# Clone Manjaro Zsh config
echo ""
echo "Cloning Manjaro Zsh configuration..."
git clone https://github.com/Chrysostomus/manjaro-zsh-config "$TEMP_SOURCE"

# Install Zsh configuration files
echo ""
echo "Installing Manjaro Zsh configuration files..."
cp "$TEMP_SOURCE/.zshrc" ~/.zshrc
copy_to_zsh_folder "$TEMP_SOURCE" manjaro-zsh-config
copy_to_zsh_folder "$TEMP_SOURCE" manjaro-zsh-prompt
copy_to_zsh_folder "$TEMP_SOURCE" p10k-portable.zsh
copy_to_zsh_folder "$TEMP_SOURCE" p10k.zsh
copy_to_zsh_folder "$TEMP_SOURCE" zsh-maia-prompt

# Clean up temporary directory
rm -rf "$TEMP_SOURCE"

# Install Zsh plugins
echo ""
echo "Installing Zsh plugins..."
PLUGINS_DEST=/usr/share/zsh/plugins
sudo rm -rf "$PLUGINS_DEST"
sudo mkdir -p "$PLUGINS_DEST"
update_permission "$PLUGINS_DEST"

echo "  Installing zsh-history-substring-search..."
git clone https://github.com/zsh-users/zsh-history-substring-search "$PLUGINS_DEST/zsh-history-substring-search"

echo "  Installing zsh-syntax-highlighting..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGINS_DEST/zsh-syntax-highlighting"

echo "  Installing zsh-autosuggestions..."
git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGINS_DEST/zsh-autosuggestions"

# Install Powerlevel10k theme
echo ""
echo "Installing Powerlevel10k theme..."
P10K_DEST=/usr/share/zsh-theme-powerlevel10k
sudo rm -rf "$P10K_DEST"
sudo git clone https://github.com/romkatv/powerlevel10k "$P10K_DEST"
update_permission "$P10K_DEST"

# Download and install MesloLGS NF fonts
echo ""
echo "Installing MesloLGS NF fonts..."
FONTS_DEST=~/.local/share/fonts
mkdir -p "$FONTS_DEST"

fonts=(
    "MesloLGS%20NF%20Regular.ttf:Regular.ttf"
    "MesloLGS%20NF%20Bold.ttf:Bold.ttf"
    "MesloLGS%20NF%20Italic.ttf:Italic.ttf"
    "MesloLGS%20NF%20Bold%20Italic.ttf:BoldItalic.ttf"
)

# Function to download font with retry logic and fallback
download_font() {
    local url=$1
    local output=$2
    local retries=3
    local timeout=30

    # Try curl first (preferred - doesn't create log files)
    for i in $(seq 1 $retries); do
        if curl -L --max-time $timeout -s -S -f "$url" -o "$output" 2>/dev/null; then
            return 0
        fi
        [ $i -lt $retries ] && sleep 2
    done

    # Fallback to wget if curl fails
    for i in $(seq 1 $retries); do
        if wget --timeout=$timeout --tries=1 --quiet --output-document="$output" "$url" 2>/dev/null; then
            return 0
        fi
        # Clean up any wget log files that might have been created
        rm -f wget-log wget-log.* 2>/dev/null
        [ $i -lt $retries ] && sleep 2
    done

    # Final cleanup
    rm -f wget-log wget-log.* 2>/dev/null
    return 1
}

# Download fonts with better error handling
# Temporarily disable 'set -e' for font downloads to prevent crashes
set +e
for font in "${fonts[@]}"; do
    IFS=':' read -r url_name file_name <<< "$font"
    echo "  Downloading $file_name..."

    url="https://github.com/romkatv/powerlevel10k-media/raw/master/$url_name"
    if download_font "$url" "$FONTS_DEST/$file_name"; then
        echo "    ✓ Downloaded $file_name"
    else
        echo "    ✗ Failed to download $file_name after multiple attempts"
        echo "      You can download it manually from: $url"
    fi
done
set -e

echo ""
echo "Refreshing font cache..."
fc-cache -f -v > /dev/null 2>&1

echo ""
echo "=== Manjaro-style Zsh configuration complete! ==="
echo ""
echo "Next steps:"
echo "  1. Change your terminal font to 'MesloLGS NF' for proper icon display"
echo "  2. Restart your terminal or run: source ~/.zshrc"
echo "  3. Run 'p10k configure' to customize your prompt"
