#!/bin/bash
# Setup script for 'work' VM (Debian 13, HP DL380)
# IP: 10.10.15.103
# Services: Leantime, Joplin Server, Whisper

set -e

echo "==> Installing Docker..."
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -qq
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

echo "==> Starting Leantime..."
mkdir -p /opt/leantime
cp compose/leantime-docker-compose.yml /opt/leantime/docker-compose.yml
docker compose -f /opt/leantime/docker-compose.yml up -d

echo "==> Starting Joplin + Whisper..."
mkdir -p /opt/joplin
cp compose/joplin-docker-compose.yml /opt/joplin/docker-compose.yml
docker compose -f /opt/joplin/docker-compose.yml up -d

echo ""
echo "Done. Services:"
echo "  Leantime:      http://10.10.15.103:8080"
echo "  Joplin Server: http://10.10.15.103:22300  (admin@localhost / admin)"
echo "  Whisper API:   http://10.10.15.103:8001/docs"
