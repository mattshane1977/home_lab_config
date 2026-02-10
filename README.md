# Homelab Infrastructure

Automated deployment scripts for a two-node Proxmox homelab.

## Architecture

### Dell (ComfyUI Node)
- **GPU:** RTX 4060 Ti
- **Storage:** 4.8TB (single disk, XFS)
- **VM:** ComfyUI with GPU passthrough

### HP DL380 (Workhorse)
- **GPUs:** Tesla P100, Tesla P40
- **Storage:** 16.4TB MergerFS pool (4 disks) + 702GB local-lvm
- **VM 1:** TrueNAS (virtual disk from local-lvm)
- **VM 2:** Debian 13 Docker host (P100 + P40 passthrough)
  - Ollama (LLM inference)
  - n8n (workflow automation)
  - NocoDB (database/second brain)

## Quick Start

### Fresh node rebuild:
```
git clone https://github.com/mattshane1977/home_lab_config.git
cd home_lab_config
```

**Dell:**
```
cd dell
chmod +x setup.sh
./setup.sh
```

**HP:**
```
cd hp
chmod +x setup.sh
./setup.sh
```

### Docker host (inside HP Debian VM):
```
cd hp/docker-host
chmod +x setup.sh
./setup.sh
```
