#!/bin/bash
# hp/docker-host/scripts/gpu-test.sh — Verify GPU passthrough and Docker GPU access
set -euo pipefail

echo "=== GPU Passthrough Verification ==="
echo ""

echo "--- nvidia-smi ---"
if command -v nvidia-smi &>/dev/null; then
  nvidia-smi
else
  echo "FAIL: nvidia-smi not found. NVIDIA drivers not installed."
  exit 1
fi

echo ""
echo "--- Docker GPU Test ---"
docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi

echo ""
echo "--- Ollama GPU Check ---"
if docker ps | grep -q ollama; then
  docker exec ollama nvidia-smi
  echo ""
  echo "Ollama is running with GPU access."
else
  echo "Ollama container not running. Start with: docker compose up -d"
fi

echo ""
echo "=== All checks passed ==="
