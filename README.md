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

```bash
git clone https://github.com/<your-user>/homelab-infra.git
cd homelab-infra
```

**Dell:**
```bash
cd dell
chmod +x setup.sh
./setup.sh
```

**HP:**
```bash
cd hp
chmod +x setup.sh
./setup.sh
```

### Docker host (inside HP Debian VM):
```bash
cd hp/docker-host
chmod +x setup.sh
./setup.sh
```

## Directory Structure

```
homelab-infra/
├── README.md
├── common/
│   └── base-setup.sh          # Shared packages & configs
├── dell/
│   ├── setup.sh               # Dell Proxmox host setup
│   ├── config.env              # Dell-specific variables
│   └── comfyui/
│       └── vm-create.sh        # ComfyUI VM creation
├── hp/
│   ├── setup.sh                # HP Proxmox host setup
│   ├── config.env              # HP-specific variables
│   ├── truenas/
│   │   └── vm-create.sh        # TrueNAS VM creation
│   └── docker-host/
│       ├── setup.sh            # Debian VM bootstrap (Docker, NVIDIA, etc.)
│       ├── compose/
│       │   └── docker-compose.yml
│       └── scripts/
│           └── gpu-test.sh     # Verify GPU passthrough
```
