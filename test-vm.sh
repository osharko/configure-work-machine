#!/bin/bash

# Pop!_OS VM Test Script
# Creates a disposable VM to test the configuration scripts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_NAME="popos-test-$(date +%s)"
POP_OS_ISO="$HOME/Documenti/ISO/pop-os_24.04_amd64_intel_20.iso"
VM_DISK_SIZE="30G"
VM_MEMORY="4096"
VM_CPUS="4"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo "Pop!_OS VM Test Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --iso PATH      Path to Pop!_OS ISO (default: ~/Documenti/ISO/pop-os_24.04_amd64_intel_20.iso)"
    echo "  -m, --memory MB     RAM in MB (default: 4096)"
    echo "  -c, --cpus NUM      Number of CPUs (default: 4)"
    echo "  -s, --size SIZE     Disk size (default: 30G)"
    echo "  -h, --help          Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use defaults"
    echo "  $0 -i ~/pop-os.iso -m 8192           # Custom ISO and 8GB RAM"
    echo ""
    echo "Prerequisites:"
    echo "  - QEMU/KVM installed: sudo apt install qemu-kvm libvirt-daemon-system"
    echo "  - Pop!_OS ISO downloaded from: https://pop.system76.com"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--iso)
            POP_OS_ISO="$2"
            shift 2
            ;;
        -m|--memory)
            VM_MEMORY="$2"
            shift 2
            ;;
        -c|--cpus)
            VM_CPUS="$2"
            shift 2
            ;;
        -s|--size)
            VM_DISK_SIZE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

echo -e "${GREEN}=== Pop!_OS VM Test Environment ===${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo -e "${RED}QEMU not found!${NC}"
    echo "Install with: sudo apt install qemu-kvm libvirt-daemon-system virt-manager"
    exit 1
fi

if [ ! -f "$POP_OS_ISO" ]; then
    echo -e "${RED}Pop!_OS ISO not found at: $POP_OS_ISO${NC}"
    echo ""
    echo "Download Pop!_OS from: https://pop.system76.com"
    echo "Or specify a different path with: $0 -i /path/to/pop-os.iso"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites OK${NC}"
echo ""

# VM Configuration
echo -e "${BLUE}VM Configuration:${NC}"
echo "  Name:    $VM_NAME"
echo "  ISO:     $POP_OS_ISO"
echo "  Memory:  ${VM_MEMORY}MB"
echo "  CPUs:    $VM_CPUS"
echo "  Disk:    $VM_DISK_SIZE"
echo ""

# Create VM disk
VM_DISK="/tmp/${VM_NAME}.qcow2"
echo -e "${YELLOW}Creating VM disk...${NC}"
qemu-img create -f qcow2 "$VM_DISK" "$VM_DISK_SIZE"

echo ""
echo -e "${GREEN}Starting Pop!_OS VM...${NC}"
echo ""
echo -e "${BLUE}Quick Setup Instructions:${NC}"
echo "  1. Install Pop!_OS in the VM (follow the installer)"
echo "  2. After reboot, log in"
echo "  3. Open Terminal and run:"
echo ""
echo "     git clone https://github.com/osharko/configure-work-machine.git"
echo "     cd configure-work-machine"
echo "     ./start-configure.sh -i"
echo ""
echo "  4. Test your scripts!"
echo "  5. Close the VM when done (changes are not saved)"
echo ""
echo -e "${YELLOW}Press Enter to start VM (or Ctrl+C to cancel)${NC}"
read

# Start VM
qemu-system-x86_64 \
    -machine type=pc,accel=kvm \
    -cpu host \
    -smp $VM_CPUS \
    -m $VM_MEMORY \
    -cdrom "$POP_OS_ISO" \
    -drive file="$VM_DISK",format=qcow2,if=virtio \
    -boot d \
    -vga virtio \
    -display gtk,grab-on-hover=on \
    -device intel-hda \
    -device hda-duplex \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::2222-:22 \
    -enable-kvm

# Cleanup
echo ""
echo -e "${YELLOW}VM closed. Cleaning up...${NC}"
rm -f "$VM_DISK"
echo -e "${GREEN}Done!${NC}"
