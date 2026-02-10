#!/bin/bash
# hp/truenas/vm-create.sh — Create TrueNAS VM on HP
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.env"

VMID="$TRUENAS_VMID"
VM_NAME="truenas"
RAM="$TRUENAS_RAM"
DISK_SIZE="$TRUENAS_DISK_SIZE"
ISO_STORAGE="local"
DISK_STORAGE="local-lvm"

echo "============================================"
echo "  Creating TrueNAS VM (VMID: ${VMID})"
echo "============================================"

# Check if VM already exists
if qm status "$VMID" &>/dev/null; then
  echo "VM ${VMID} already exists. Skipping creation."
  exit 0
fi

# Check for TrueNAS ISO
echo ""
echo "Available ISOs:"
ls /var/lib/vz/template/iso/ 2>/dev/null || echo "No ISOs found."
echo ""

TRUENAS_ISO=$(ls /var/lib/vz/template/iso/TrueNAS* 2>/dev/null | head -1)
if [ -z "$TRUENAS_ISO" ]; then
  echo "ERROR: No TrueNAS ISO found."
  echo "Download one first:"
  echo "  wget -P /var/lib/vz/template/iso/ https://download.truenas.com/TrueNAS-SCALE-Dragonfish/24.04.2.2/TrueNAS-SCALE-24.04.2.2.iso"
  exit 1
fi

ISO_FILE="$(basename "$TRUENAS_ISO")"

# Create VM
qm create "$VMID" \
  --name "$VM_NAME" \
  --ostype l26 \
  --memory "$RAM" \
  --cores 4 \
  --sockets 1 \
  --cpu host \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-single \
  --boot order=scsi0 \
  --cdrom "${ISO_STORAGE}:iso/${ISO_FILE}" \
  --onboot 1 \
  --start 0

# Add boot disk
qm set "$VMID" --scsi0 "${DISK_STORAGE}:${DISK_SIZE},discard=on,iothread=1,ssd=1"

# Add a large data disk for TrueNAS storage pools
qm set "$VMID" --scsi1 "${DISK_STORAGE}:200,discard=on,iothread=1,ssd=1"

echo ""
echo "============================================"
echo "  TrueNAS VM Created (VMID: ${VMID})"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Start VM: qm start ${VMID}"
echo "  2. Open console and install TrueNAS"
echo "  3. Configure NFS shares for Docker VM"
echo ""
