#!/bin/bash

# Verification script for Dell OEM drivers
# Run this after installing drivers and rebooting

echo "=== Dell Hardware Verification Script ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
}

# System Info
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "System Information:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Vendor: $(cat /sys/class/dmi/id/sys_vendor)"
echo "Model: $(cat /sys/class/dmi/id/product_name)"
echo "SKU: $(cat /sys/class/dmi/id/product_sku)"
echo ""

# Check OEM Package
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking OEM Package Installation:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if dpkg -l | grep -q "oem-somerville.*meta"; then
    OEM_PKG=$(dpkg -l | grep "oem-somerville.*meta" | awk '{print $2}')
    echo -e "${GREEN}✓${NC} OEM Package installed: $OEM_PKG"
else
    echo -e "${YELLOW}⚠${NC} No OEM package found"
fi
echo ""

# Audio Check
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Audio Hardware Check:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check audio devices
if lspci | grep -iq "audio.*amd"; then
    echo -e "${GREEN}✓${NC} AMD Audio hardware detected"
    lspci | grep -i "audio.*amd" | sed 's/^/  /'
else
    echo -e "${YELLOW}⚠${NC} AMD Audio hardware not detected"
fi
echo ""

# Check SoundWire modules
echo "SoundWire Module Status:"
if lsmod | grep -q "soundwire_amd"; then
    echo -e "${GREEN}✓${NC} soundwire_amd module loaded"
else
    echo -e "${RED}✗${NC} soundwire_amd module NOT loaded"
fi
if lsmod | grep -q "snd_soc_rt722_sdca"; then
    echo -e "${GREEN}✓${NC} RT722 codec module loaded"
else
    echo -e "${RED}✗${NC} RT722 codec module NOT loaded"
fi
if lsmod | grep -q "snd_soc_rt1320_sdw"; then
    echo -e "${GREEN}✓${NC} RT1320 codec module loaded"
else
    echo -e "${RED}✗${NC} RT1320 codec module NOT loaded"
fi
echo ""

# Check audio outputs
echo "Audio Output Devices:"
if command -v wpctl &> /dev/null; then
    SINK_COUNT=$(wpctl status | grep -c "Sinks:" || echo "0")
    if [ "$SINK_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} PipeWire audio system active"
        wpctl status | grep -A10 "Sinks:" | grep -E "^\s+\*?\s+[0-9]+" | sed 's/^/  /'
    else
        echo -e "${RED}✗${NC} No audio sinks found"
    fi
elif command -v pactl &> /dev/null; then
    SINK_COUNT=$(pactl list sinks short 2>/dev/null | wc -l)
    echo -e "${GREEN}✓${NC} Found $SINK_COUNT audio sink(s)"
    pactl list sinks short | sed 's/^/  /'
else
    echo -e "${YELLOW}⚠${NC} Cannot detect audio system"
fi
echo ""

# Fingerprint Check
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Fingerprint Reader Check:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check USB device
if lsusb | grep -iq "broadcom"; then
    BROADCOM_DEV=$(lsusb | grep -i "broadcom" | head -1)
    echo -e "${GREEN}✓${NC} Broadcom device detected:"
    echo "  $BROADCOM_DEV"
else
    echo -e "${YELLOW}⚠${NC} No Broadcom device detected"
fi
echo ""

# Check libfprint packages
echo "Fingerprint Driver Status:"
if dpkg -l | grep -q "libfprint-2-2"; then
    echo -e "${GREEN}✓${NC} libfprint-2-2 installed"
else
    echo -e "${RED}✗${NC} libfprint-2-2 NOT installed"
fi
if dpkg -l | grep -q "libfprint-2-tod1"; then
    echo -e "${GREEN}✓${NC} libfprint-2-tod1 installed"
else
    echo -e "${RED}✗${NC} libfprint-2-tod1 NOT installed"
fi
if dpkg -l | grep -q "libfprint-2-tod1-broadcom"; then
    echo -e "${GREEN}✓${NC} libfprint-2-tod1-broadcom installed"
else
    echo -e "${YELLOW}⚠${NC} libfprint-2-tod1-broadcom NOT installed"
fi
echo ""

# Check fprintd service
echo "Fingerprint Service Status:"
if systemctl is-active --quiet fprintd; then
    echo -e "${GREEN}✓${NC} fprintd service is active"
else
    echo -e "${YELLOW}⚠${NC} fprintd service is not active (this is normal until first use)"
fi
echo ""

# Try to list fingerprint devices
echo "Available Fingerprint Devices:"
if fprintd-list $USER 2>&1 | grep -q "No devices available"; then
    echo -e "${RED}✗${NC} No fingerprint devices available"
    echo "  This means the driver doesn't support your hardware yet"
else
    echo -e "${GREEN}✓${NC} Fingerprint device detected!"
    fprintd-list $USER 2>&1 | sed 's/^/  /'
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Recommended Actions:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Audio test
if lsmod | grep -q "soundwire_amd" && lsmod | grep -q "snd_soc_rt722"; then
    echo -e "${GREEN}Audio:${NC}"
    echo "  Test audio with: speaker-test -t wav -c 2 -l 1"
    echo "  Adjust volume with: wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%"
    echo "  Set default sink: wpctl set-default <sink-id>"
else
    echo -e "${RED}Audio:${NC}"
    echo "  Audio modules not loaded. Try rebooting if you haven't yet."
fi
echo ""

# Fingerprint enrollment
if ! fprintd-list $USER 2>&1 | grep -q "No devices available"; then
    echo -e "${GREEN}Fingerprint:${NC}"
    echo "  Enroll your fingerprint with: fprintd-enroll"
    echo "  Verify enrollment with: fprintd-verify"
else
    echo -e "${YELLOW}Fingerprint:${NC}"
    echo "  Device not detected. Possible solutions:"
    echo "  1. Make sure you've rebooted after driver installation"
    echo "  2. Check if your specific model (Broadcom 58200) is supported"
    echo "  3. Check for firmware updates with: fwupdmgr get-devices"
    echo "  4. Try updating firmware: fwupdmgr update"
fi
echo ""
