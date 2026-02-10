#!/bin/bash
# dell/comfyui/vm-create.sh — Create ComfyUI VM on Dell
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.env"

VMID="$COMFYUI_VMID"
VM_NAME="comfyui"
RAM="$COMFYUI_RAM"
CORES="$COMFYUI_CORES"
ISO_STORAGE="local"
DISK_STORAGE="local-lvm"
BOOT_DISK_SIZE="64"

echo "============================================"
echo "  Creating ComfyUI VM (VMID: ${VMID})"
echo "============================================"

# Check if VM already exists
if qm status "$VMID" &>/dev/null; then
  echo "VM ${VMID} already exists. Skipping creation."
  exit 0
fi

# Check for Debian/Ubuntu ISO
echo ""
echo "Available ISOs:"
ls /var/lib/vz/template/iso/ 2>/dev/null || echo "No ISOs found."
echo ""

OS_ISO=$(ls /var/lib/vz/template/iso/debian* /var/lib/vz/template/iso/ubuntu* 2>/dev/null | head -1)
if [ -z "$OS_ISO" ]; then
  echo "ERROR: No Debian/Ubuntu ISO found."
  echo "Download one first:"
  echo "  wget -P /var/lib/vz/template/iso/ https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.0.0-amd64-netinst.iso"
  exit 1
fi

ISO_FILE="$(basename "$OS_ISO")"

# Create VM
qm create "$VMID" \
  --name "$VM_NAME" \
  --ostype l26 \
  --memory "$RAM" \
  --cores "$CORES" \
  --sockets 1 \
  --cpu host \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-single \
  --boot order=scsi0 \
  --cdrom "${ISO_STORAGE}:iso/${ISO_FILE}" \
  --onboot 1 \
  --start 0

# Add boot disk
qm set "$VMID" --scsi0 "${DISK_STORAGE}:${BOOT_DISK_SIZE},discard=on,iothread=1,ssd=1"

# GPU Passthrough
if [ -n "$GPU_4060TI_ID" ]; then
  qm set "$VMID" --hostpci0 "${GPU_4060TI_ID},pcie=1"
  qm set "$VMID" --machine q35
  echo "GPU passthrough configured: RTX 4060 Ti"
else
  echo "WARNING: GPU PCI ID not set in config.env — passthrough skipped"
  echo "Run 'lspci -nn | grep -i nvidia' and update config.env"
fi

echo ""
echo "============================================"
echo "  ComfyUI VM Created (VMID: ${VMID})"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Start VM: qm start ${VMID}"
echo "  2. Install Debian 13"
echo "  3. SSH in and run the ComfyUI setup script"
echo ""
