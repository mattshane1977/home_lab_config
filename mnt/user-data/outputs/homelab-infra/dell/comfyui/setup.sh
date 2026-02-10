#!/bin/bash
# dell/comfyui/setup.sh — Bootstrap ComfyUI inside the VM
# Run this INSIDE the Debian VM after OS installation
set -euo pipefail

echo "============================================"
echo "  ComfyUI Setup (Debian 13)"
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
  python3 \
  python3-pip \
  python3-venv \
  gnupg \
  ca-certificates

# ==========================================
# NVIDIA Drivers
# ==========================================
echo ""
echo "--- Installing NVIDIA drivers ---"

if ! command -v nvidia-smi &>/dev/null; then
  apt install -y linux-headers-$(uname -r)
  apt install -y nvidia-driver firmware-misc-nonfree
  echo "NVIDIA driver installed. REBOOT REQUIRED."
  echo "After reboot, re-run this script to continue setup."
  exit 0
else
  echo "NVIDIA driver already installed."
  nvidia-smi
fi

# ==========================================
# ComfyUI Installation
# ==========================================
echo ""
echo "--- Installing ComfyUI ---"

COMFYUI_DIR="/opt/comfyui"

if [ ! -d "$COMFYUI_DIR" ]; then
  git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
  cd "$COMFYUI_DIR"
  python3 -m venv venv
  source venv/bin/activate
  pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124
  pip install -r requirements.txt
  deactivate
  echo "ComfyUI installed."
else
  echo "ComfyUI already exists at ${COMFYUI_DIR}."
fi

# ==========================================
# Systemd Service
# ==========================================
echo ""
echo "--- Creating systemd service ---"

cat > /etc/systemd/system/comfyui.service << 'EOF'
[Unit]
Description=ComfyUI
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/comfyui
ExecStart=/opt/comfyui/venv/bin/python main.py --listen 0.0.0.0 --port 8188
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable comfyui
systemctl start comfyui

echo ""
echo "============================================"
echo "  ComfyUI Setup Complete!"
echo "============================================"
echo ""
echo "Access ComfyUI at: http://<vm-ip>:8188"
echo "Service status: systemctl status comfyui"
echo ""
echo "Model directories:"
echo "  Checkpoints: ${COMFYUI_DIR}/models/checkpoints/"
echo "  LoRAs:       ${COMFYUI_DIR}/models/loras/"
echo "  VAE:         ${COMFYUI_DIR}/models/vae/"
echo ""
