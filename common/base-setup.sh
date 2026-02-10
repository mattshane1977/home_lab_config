#!/bin/bash
# common/base-setup.sh — Shared setup for all Proxmox nodes
set -euo pipefail

echo "=== Base Setup ==="

# Update system
apt update && apt upgrade -y

# Common packages
apt install -y \
  curl \
  wget \
  git \
  htop \
  iotop \
  net-tools \
  vim \
  tmux \
  lm-sensors \
  smartmontools \
  ethtool \
  pve-headers-$(uname -r)

# Enable IOMMU for GPU passthrough
if ! grep -q "intel_iommu=on" /etc/default/grub; then
  echo "Enabling IOMMU..."
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"/' /etc/default/grub
  update-grub
  REBOOT_NEEDED=true
fi

# Blacklist nouveau driver (for NVIDIA GPU passthrough)
cat > /etc/modprobe.d/blacklist-nouveau.conf << 'MODCONF'
blacklist nouveau
blacklist lbm-nouveau
options nouveau modeset=0
MODCONF

# Load vfio modules
cat > /etc/modules-load.d/vfio.conf << 'MODCONF'
vfio
vfio_iommu_type1
vfio_pci
MODCONF

update-initramfs -u -k all

echo "=== Base Setup Complete ==="
if [ "${REBOOT_NEEDED:-false}" = true ]; then
  echo "*** REBOOT REQUIRED for IOMMU changes ***"
fi
