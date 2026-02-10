#!/bin/bash
# hp/docker-host/setup.sh — Bootstrap Debian 13 Docker Host VM
# Run this INSIDE the Debian VM after OS installation
set -euo pipefail

echo "============================================"
echo "  Docker Host Setup (Debian 13)"
echo "============================================"

# ==========================================
# System Updates
# ==========================================
echo ""
echo "--- System updates ---"
apt update && apt upgrade -y
apt install -y \
  curl \
  wget \
  git \
  htop \
  vim \
  tmux \
  net-tools \
  gnupg \
  ca-certificates \
  nfs-common

# ==========================================
# Docker Installation
# ==========================================
echo ""
echo "--- Installing Docker ---"

if ! command -v docker &>/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  echo "Docker installed."
else
  echo "Docker already installed, skipping."
fi

# ==========================================
# NVIDIA Container Toolkit
# ==========================================
echo ""
echo "--- Installing NVIDIA drivers & container toolkit ---"

if ! command -v nvidia-smi &>/dev/null; then
  # Install NVIDIA drivers
  apt install -y linux-headers-$(uname -r)
  apt install -y nvidia-driver firmware-misc-nonfree
  echo "NVIDIA driver installed."
else
  echo "NVIDIA driver already installed."
  nvidia-smi
fi

if ! dpkg -l | grep -q nvidia-container-toolkit; then
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

  apt update
  apt install -y nvidia-container-toolkit
  nvidia-ctk runtime configure --runtime=docker
  systemctl restart docker
  echo "NVIDIA Container Toolkit installed."
else
  echo "NVIDIA Container Toolkit already installed."
fi

# ==========================================
# Docker Compose App Stack
# ==========================================
echo ""
echo "--- Setting up app directory ---"

APP_DIR="/opt/homelab"
mkdir -p "$APP_DIR"

# Copy compose file if running from the repo
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/compose/docker-compose.yml" ]; then
  cp "$SCRIPT_DIR/compose/docker-compose.yml" "$APP_DIR/docker-compose.yml"
  echo "docker-compose.yml copied to ${APP_DIR}"
fi

# Create data directories
mkdir -p "$APP_DIR/data/ollama"
mkdir -p "$APP_DIR/data/n8n"
mkdir -p "$APP_DIR/data/nocodb"

# ==========================================
# NFS Mount (for TrueNAS shared storage)
# ==========================================
echo ""
echo "--- NFS mount placeholder ---"
echo "After TrueNAS is configured, add NFS mount to /etc/fstab:"
echo "  <truenas-ip>:/mnt/<pool>/<dataset> /mnt/nas nfs defaults,nofail 0 0"
mkdir -p /mnt/nas

echo ""
echo "============================================"
echo "  Docker Host Setup Complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Reboot if NVIDIA drivers were installed"
echo "  2. Verify GPUs: nvidia-smi"
echo "  3. Test Docker GPU: docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi"
echo "  4. Start stack: cd ${APP_DIR} && docker compose up -d"
echo ""
