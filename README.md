# Homelab Infrastructure

Automated deployment scripts for a three-node Proxmox cluster (`shanehome`).

## Architecture

### HP DL380 (Workhorse) — `hp` — 10.10.15.240
- **CPUs:** Dual Xeon
- **RAM:** 157GB
- **GPUs:** Tesla P100 16GB, Tesla P40 24GB
- **Storage:** 16.4TB MergerFS pool (4 disks) + 702GB local-lvm
- **Bare metal:** TrueNAS — 10.10.15.56
- **VMs:**
  - `openweb` (VM 100, 10.10.15.209) — 30c / 60GB — P100 + P40 passthrough
    - Ollama — `qwen2.5:32b`, `nomic-embed-text`
    - Open WebUI — port 3000
    - Qdrant (vector database) — port 6333
  - `work` (VM 101, 10.10.15.103) — 16c / 31GB
    - Leantime (project management) — port 8080
  - `n8n` (VM 102, 10.10.15.169) — 4c / 4GB — n8n workflow automation (bound to localhost, access via Tailscale)

### Dell (ComfyUI Node) — `dell` — 10.10.15.133
- **CPU:** Intel Xeon E5-2690 v4
- **RAM:** 102GB
- **GPUs:** RTX 4060 Ti 16GB, Quadro M4000 8GB
- **Storage:** 4.8TB (single disk, XFS)
- **VMs:**
  - `comfy` (VM 104, 10.10.15.113) — 40c / 66GB — RTX 4060 Ti passthrough
    - ComfyUI

### Trigkey Mini PC — `trigkey` — 10.10.15.147
- **CPU:** AMD Ryzen 7 5700U
- **RAM:** 20GB
- **GPU:** AMD Radeon (integrated)
- **Storage:** 338GB local-lvm
- **VMs:** none (available for lightweight services)

## Quick Start

### Fresh node rebuild:

```bash
git clone https://github.com/mattshane1977/home_lab_config.git
cd home_lab_config
```

**HP:**
```bash
cd hp && chmod +x setup.sh && ./setup.sh
```

**Dell:**
```bash
cd dell && chmod +x setup.sh && ./setup.sh
```

**openweb VM (Docker + GPU):**
```bash
cd hp/docker-host && chmod +x setup.sh && ./setup.sh
```

**work VM (productivity services):**
```bash
cd hp/work && chmod +x setup.sh && sudo ./setup.sh
```

## Directory Structure

```
home_lab_config/
├── README.md
├── common/
│   └── base-setup.sh              # Shared packages & configs
├── dell/
│   ├── setup.sh                   # Dell Proxmox host setup
│   ├── config.env                 # Dell-specific variables
│   └── comfyui/
│       └── vm-create.sh           # ComfyUI VM creation
├── hp/
│   ├── setup.sh                   # HP Proxmox host setup
│   ├── config.env                 # HP-specific variables
│   ├── truenas/
│   │   └── vm-create.sh           # TrueNAS setup (bare metal, 10.10.15.56)
│   ├── docker-host/               # legacy bootstrap scripts
│   │   ├── setup.sh
│   │   ├── compose/
│   │   │   └── docker-compose.yml
│   │   └── scripts/
│   │       └── gpu-test.sh        # Verify GPU passthrough
│   ├── openweb/                   # openweb VM (AI services)
│   │   └── docker-compose.yml     # Open WebUI + Qdrant
│   └── work/                      # work VM (productivity)
│       ├── setup.sh
│       └── compose/
│           └── leantime-docker-compose.yml   # Project management
```

## Service URLs

| Service | Host | URL | Notes |
|---|---|---|---|
| TrueNAS | bare metal | http://10.10.15.56 | NAS / storage management |
| Leantime | work | http://10.10.15.103:8080 | Project management |
| Open WebUI | openweb | http://10.10.15.209:3000 | Chat interface for Ollama |
| Ollama | openweb | http://10.10.15.209:11434 | LLM inference — qwen2.5:32b |
| Qdrant | openweb | http://10.10.15.209:6333 | Vector database |
| n8n | n8n VM | http://10.10.15.169:5678 | Workflow automation (Tailscale or localhost only) |
| ComfyUI | comfy | http://10.10.15.113:8188 | Image generation |

## Cluster Info

- **Cluster name:** shanehome
- **Proxmox nodes:** hp (10.10.15.240), dell (10.10.15.133), trigkey (10.10.15.147)
- **Total cluster RAM:** ~279GB
- **Total GPU VRAM:** P100 16GB + P40 24GB + RTX 4060 Ti 16GB + Quadro M4000 8GB = 64GB
