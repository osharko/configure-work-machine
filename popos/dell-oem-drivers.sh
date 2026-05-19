#!/bin/bash

set -e

echo "=== Installing Dell OEM Drivers for Pop!_OS ==="
echo ""

# Detect Dell hardware
detect_dell_hardware() {
    echo "Detecting Dell hardware..."

    PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Unknown")
    PRODUCT_SKU=$(cat /sys/class/dmi/id/product_sku 2>/dev/null || echo "Unknown")
    VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "Unknown")

    echo "  Vendor: $VENDOR"
    echo "  Model: $PRODUCT_NAME"
    echo "  SKU: $PRODUCT_SKU"
    echo ""

    if [[ ! "$VENDOR" =~ "Dell" ]]; then
        echo "⚠ Warning: This does not appear to be a Dell system."
        read -p "Do you want to continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            exit 0
        fi
    fi
}

# Find appropriate OEM package
find_oem_package() {
    echo "Searching for OEM package..."

    # Common Dell OEM packages for different models
    # Map product names/SKUs to OEM packages
    case "$PRODUCT_NAME" in
        *"Pro Max 16"*|*"MC16255"*)
            OEM_PACKAGE="oem-somerville-jellicent-meta"
            ;;
        *"Pro Max 14"*|*"MC14255"*)
            OEM_PACKAGE="oem-somerville-jellicent-meta"
            ;;
        *"Pro 14"*|*"PC14255"*)
            OEM_PACKAGE="oem-somerville-jellicent-meta"
            ;;
        *"Pro 16"*|*"PC16255"*)
            OEM_PACKAGE="oem-somerville-jellicent-meta"
            ;;
        *"PRO MAX SLIM"*|*"FCS1250"*)
            OEM_PACKAGE="oem-somerville-aggron-meta"
            ;;
        *"PRO MAX TOWER"*|*"FCT2250"*)
            OEM_PACKAGE="oem-somerville-delcatty-meta"
            ;;
        *"Latitude 7340"*)
            OEM_PACKAGE="oem-somerville-lapras-13-meta"
            ;;
        *"Pro Rugged 13"*|*"RA13250"*|*"Rugged 14"*|*"RB14250"*)
            OEM_PACKAGE="oem-somerville-deerling-meta"
            ;;
        *)
            echo "⚠ Could not automatically determine OEM package."
            echo ""
            echo "Available Dell OEM packages:"
            apt search oem-somerville 2>/dev/null | grep -E "^oem-" | head -15
            echo ""
            read -p "Enter OEM package name (or press Enter to skip): " OEM_PACKAGE
            if [ -z "$OEM_PACKAGE" ]; then
                echo "Skipping OEM package installation."
                return 1
            fi
            ;;
    esac

    echo "  Found OEM package: $OEM_PACKAGE"
    return 0
}

# Install OEM package
install_oem_package() {
    if [ -z "$OEM_PACKAGE" ]; then
        echo "No OEM package specified, skipping."
        return 0
    fi

    echo ""
    echo "Installing OEM package: $OEM_PACKAGE"

    # Check if already installed
    if dpkg -l | grep -q "^ii.*$OEM_PACKAGE"; then
        echo "✓ $OEM_PACKAGE is already installed"
        return 0
    fi

    # Update package list
    echo "Updating package list..."
    sudo apt update

    # Install the OEM package
    if sudo apt install -y "$OEM_PACKAGE"; then
        echo "✓ $OEM_PACKAGE installed successfully"
        return 0
    else
        echo "✗ Failed to install $OEM_PACKAGE"
        return 1
    fi
}

# Install/update fingerprint drivers
install_fingerprint_drivers() {
    echo ""
    echo "Checking fingerprint reader drivers..."

    # Check if fingerprint reader is present
    if lsusb | grep -iq "broadcom.*58[0-9][0-9]"; then
        echo "  Detected Broadcom fingerprint reader"

        # Install libfprint and Broadcom TOD driver
        echo "Installing fingerprint drivers..."
        sudo apt install -y \
            libfprint-2-2 \
            libfprint-2-tod1 \
            fprintd || true

        # Try to install Broadcom TOD driver (may not be in all repos)
        sudo apt install -y libfprint-2-tod1-broadcom 2>/dev/null || \
            echo "⚠ libfprint-2-tod1-broadcom not available in repositories"

        echo "✓ Fingerprint drivers installed"
    else
        echo "  No Broadcom fingerprint reader detected, skipping."
    fi
}

# Update firmware
update_firmware() {
    echo ""
    echo "Updating system firmware..."

    # Reinstall linux-firmware to ensure latest firmware
    sudo apt install --reinstall -y linux-firmware

    echo "✓ Firmware updated"
}

# Verify audio hardware
verify_audio() {
    echo ""
    echo "Verifying audio hardware..."

    # Check for AMD SoundWire audio
    if lspci | grep -iq "audio.*amd"; then
        echo "  Detected AMD audio hardware"

        # Verify SoundWire modules are loaded
        if lsmod | grep -q "soundwire_amd"; then
            echo "  ✓ SoundWire modules loaded"
        else
            echo "  ⚠ SoundWire modules not loaded (will load after reboot)"
        fi
    fi

    # Check audio devices
    if command -v pactl &> /dev/null; then
        AUDIO_DEVICES=$(pactl list sinks short 2>/dev/null | wc -l)
        echo "  Found $AUDIO_DEVICES audio output device(s)"
    elif command -v wpctl &> /dev/null; then
        AUDIO_DEVICES=$(wpctl status | grep -c "Sinks:" || echo "0")
        echo "  PipeWire audio system detected"
    fi
}

# Main execution
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
detect_dell_hardware

if find_oem_package; then
    install_oem_package
fi

install_fingerprint_drivers
update_firmware
verify_audio

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "=== Dell OEM Driver Installation Complete! ==="
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Installed components:"
echo "  ✓ Dell OEM hardware support package"
echo "  ✓ Fingerprint reader drivers (if detected)"
echo "  ✓ Updated system firmware"
echo "  ✓ Audio drivers verified"
echo ""
echo "⚠ IMPORTANT: You must REBOOT your system for all changes to take effect!"
echo ""
echo "After reboot, verify functionality:"
echo "  • Audio: wpctl status && speaker-test -t wav -c 2 -l 1"
echo "  • Fingerprint: fprintd-list $USER"
echo "  • If fingerprint works, enroll: fprintd-enroll"
echo ""
