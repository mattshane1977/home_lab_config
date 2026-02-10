#!/bin/bash
# dell/setup.sh — Dell Proxmox Host Setup
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.env"

echo "============================================"
echo "  Dell Proxmox Host Setup"
echo "============================================"

# Run common base setup
echo ""
echo "--- Running base setup ---"
bash "$SCRIPT_DIR/../common/base-setup.sh"

# ==========================================
# Storage: Single Disk
# ==========================================
echo ""
echo "--- Setting up storage ---"

read -p "WARNING: This will wipe ${DISK1}. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

echo "Wiping and formatting ${DISK1}..."
wipefs -a "$DISK1"
mkfs.xfs -f "$DISK1"

mkdir -p "$MOUNT"
mount "$DISK1" "$MOUNT"

# Add to fstab
if ! grep -q "$DISK1" /etc/fstab; then
  cat >> /etc/fstab << EOF

# Extra storage
${DISK1} ${MOUNT} xfs defaults,nofail 0 0
EOF
  echo "fstab entry added."
else
  echo "fstab entry already exists, skipping."
fi

# Register with Proxmox
if ! pvesm status | grep -q "$STORAGE_NAME"; then
  pvesm add dir "$STORAGE_NAME" --path "$MOUNT" --content images,rootdir,vztmpl,backup,iso,import
  echo "Proxmox storage '${STORAGE_NAME}' registered."
else
  echo "Proxmox storage '${STORAGE_NAME}' already exists, skipping."
fi

echo ""
echo "--- Storage setup complete ---"
df -h "$MOUNT"

# ==========================================
# GPU Passthrough
# ==========================================
echo ""
echo "--- GPU passthrough ---"
echo "Detected NVIDIA devices:"
lspci -nn | grep -i nvidia || echo "No NVIDIA devices found — fill in config.env manually"

echo ""
echo "============================================"
echo "  Dell Setup Complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Reboot if IOMMU changes were made"
echo "  2. Fill in GPU PCI ID in config.env"
echo "  3. Run: bash dell/comfyui/vm-create.sh"
echo ""
