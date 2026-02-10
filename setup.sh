#!/bin/bash
# hp/setup.sh — HP DL380 Proxmox Host Setup
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.env"

echo "============================================"
echo "  HP DL380 Proxmox Host Setup"
echo "============================================"

# Run common base setup
echo ""
echo "--- Running base setup ---"
bash "$SCRIPT_DIR/../common/base-setup.sh"

# ==========================================
# Storage: MergerFS Pool
# ==========================================
echo ""
echo "--- Setting up MergerFS storage pool ---"

# Install mergerfs
apt install -y mergerfs

# Format disks (DESTRUCTIVE - will wipe all data)
read -p "WARNING: This will wipe ${DISK1}, ${DISK2}, ${DISK3}, ${DISK4}. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

for DISK in "$DISK1" "$DISK2" "$DISK3" "$DISK4"; do
  echo "Wiping and formatting ${DISK}..."
  wipefs -a "$DISK"
  mkfs.xfs -f "$DISK"
done

# Create mount points
mkdir -p "$MOUNT_DISK1" "$MOUNT_DISK2" "$MOUNT_DISK3" "$MOUNT_DISK4" "$MERGE_MOUNT"

# Mount disks
mount "$DISK1" "$MOUNT_DISK1"
mount "$DISK2" "$MOUNT_DISK2"
mount "$DISK3" "$MOUNT_DISK3"
mount "$DISK4" "$MOUNT_DISK4"

# Create MergerFS pool
mergerfs "${MOUNT_DISK1}:${MOUNT_DISK2}:${MOUNT_DISK3}:${MOUNT_DISK4}" "$MERGE_MOUNT" \
  -o defaults,allow_other,use_ino,category.create=mfs,moveonenospc=true,minfreespace=20G,fsname=mergerfs

# Add to fstab (if not already there)
if ! grep -q "mergerfs" /etc/fstab; then
  cat >> /etc/fstab << EOF

# Individual disks for mergerfs
${DISK1} ${MOUNT_DISK1} xfs defaults,nofail 0 0
${DISK2} ${MOUNT_DISK2} xfs defaults,nofail 0 0
${DISK3} ${MOUNT_DISK3} xfs defaults,nofail 0 0
${DISK4} ${MOUNT_DISK4} xfs defaults,nofail 0 0

# MergerFS pool
${MOUNT_DISK1}:${MOUNT_DISK2}:${MOUNT_DISK3}:${MOUNT_DISK4} ${MERGE_MOUNT} fuse.mergerfs defaults,allow_other,use_ino,category.create=mfs,moveonenospc=true,minfreespace=20G,fsname=mergerfs 0 0
EOF
  echo "fstab entries added."
else
  echo "fstab entries already exist, skipping."
fi

# Register with Proxmox
if ! pvesm status | grep -q "$STORAGE_NAME"; then
  pvesm add dir "$STORAGE_NAME" --path "$MERGE_MOUNT" --content images,rootdir,vztmpl,backup,iso,import
  echo "Proxmox storage '${STORAGE_NAME}' registered."
else
  echo "Proxmox storage '${STORAGE_NAME}' already exists, skipping."
fi

echo ""
echo "--- Storage setup complete ---"
df -h "$MERGE_MOUNT"

# ==========================================
# GPU Passthrough Setup
# ==========================================
echo ""
echo "--- Configuring GPU passthrough ---"

# Get NVIDIA GPU PCI IDs
echo "Detected NVIDIA devices:"
lspci -nn | grep -i nvidia || echo "No NVIDIA devices found — fill in config.env manually"

echo ""
echo "============================================"
echo "  HP Setup Complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Reboot if IOMMU changes were made"
echo "  2. Fill in GPU PCI IDs in config.env"
echo "  3. Run: bash hp/truenas/vm-create.sh"
echo "  4. Run: bash hp/docker-host/vm-create.sh"
echo ""
