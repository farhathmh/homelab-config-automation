# Proxmox VE Automated Cloud-Init Infrastructure

Production-grade, automated virtual machine template generation and instance provisioning for **Proxmox VE** using **Terraform** ([`bpg/proxmox`](https://github.com/bpg/terraform-provider-proxmox)) and official **Cloud Images**. Built on modern hardware baselines: **Q35 PCIe**, **OVMF UEFI (4M)**, **VirtIO SCSI Single**, **SSD emulation with TRIM/Discard**, and **headless serial console sockets**.

---

## 1. Supported Golden Templates

All four distributions are defined in `var.templates`
(`terraform/templates/variables.tf`), but only one is built by default —
`var.active_templates` gates which map entries actually get created. See
[`docs/adding-a-new-template.md`](file:///home/erenyx/homelab-config-automation/docs/adding-a-new-template.md)
for how to opt others in.

| Distribution | Source Image Format | Default VM ID | Built by default? | Initialization Engine | Firmware |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Ubuntu 24.04 LTS (Noble)** | Official Canonical `.img` | `9000` | No (opt-in) | Cloud-Init (NoCloud) | OVMF (UEFI 4M) |
| **Ubuntu 26.04 LTS (Resolute)** | Official Canonical `.img` | `9002` | **Yes** | Cloud-Init (NoCloud) | OVMF (UEFI 4M) |
| **Debian 12 (Bookworm)** | Official Debian `.qcow2` | `9010` | No (opt-in) | Cloud-Init (NoCloud) | OVMF (UEFI 4M) |
| **Debian 13 (Trixie)** | Official Debian `.qcow2` | `9012` | No (opt-in) | Cloud-Init (NoCloud) | OVMF (UEFI 4M) |


---

## 2. Project Layout

```text
homelab-config-automation/
├── docs/                              # Deep-dive architecture and operational manuals
│   ├── architecture.md                # Virtualization standards & storage design
│   ├── proxmox-setup.md               # PVE cluster prerequisites, API tokens, & RBAC
│   ├── cloud-init-guide.md            # cloud-init.io schema & custom snippets guide
│   └── adding-a-new-template.md       # 4-step checklist to add new cloud distros
│
├── terraform/
│   ├── templates/                     # Layer 1: Golden Cloud Template Builder
│   │   ├── main.tf                    # Downloads cloud images and builds templates
│   │   ├── variables.tf               # Node, storage pool, and distro variables
│   │   ├── outputs.tf                 # Generated template IDs and names
│   │   ├── providers.tf               # Provider configuration (bpg/proxmox)
│   │   └── terraform.tfvars.example   # Sanitized cluster credential template
│   │
│   ├── modules/
│   │   └── vm-instance/               # Reusable module to clone templates into VMs
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   └── snippets/                      # Custom Cloud-Init YAML definitions (cloud-init.io)
│       ├── base-ubuntu.yaml           # Baseline config (agent, curl, htop, etc.)
│       └── base-debian.yaml
│
├── GEMINI.md                          # Repository workflow rules and test gates
└── .gitignore                         # Strict exclusion boundaries for state and secrets
```

---

## 3. Quick Start

### 1. Prerequisites
- **Terraform** $\ge 1.8$ installed locally.
- A Proxmox VE cluster (v8+) with an API token possessing the `Terraform` role privileges (see [`docs/proxmox-setup.md`](file:///home/erenyx/homelab-config-automation/docs/proxmox-setup.md)).
- An SSH key pair (`~/.ssh/id_ed25519` and `~/.ssh/id_ed25519.pub`).

### 2. Configure Credentials
```bash
cp terraform/templates/terraform.tfvars.example terraform/templates/terraform.tfvars
```
Edit `terraform/templates/terraform.tfvars`:
```hcl
proxmox_endpoint  = "https://10.10.10.10:8006/"
proxmox_api_token = "terraform@pve!terraform-token=00000000-0000-0000-0000-000000000000"
proxmox_node      = "pve1"
ssh_public_key    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... user@host"
```

### 3. Initialize & Deploy Golden Templates

**Using Makefile shortcuts:**
```bash
make init             # Initialize Terraform provider
make plan             # Review execution plan (default: Resolute only, ~20 seconds)
make apply            # Build the active template set (default: Resolute only)

# Build a specific distro instead (replaces the active set — see Makefile
# comments; review the plan before confirming):
make apply-noble      # Build only Ubuntu 24.04 LTS (Noble)
make apply-resolute   # Build only Ubuntu 26.04 LTS (Resolute) — the default
make apply-bookworm   # Build only Debian 12 (Bookworm)
make apply-trixie     # Build only Debian 13 (Trixie)
```

**Or using direct Terraform CLI:**
```bash
terraform -chdir=terraform/templates init
terraform -chdir=terraform/templates validate
terraform -chdir=terraform/templates apply
```

---

## 4. Headless Terminal Monitoring

All templates include a dedicated Unix serial socket device (`serial0`). You can monitor the VM screen and console output directly from the host CLI over SSH without opening the Proxmox WebUI:

```bash
# Connect to the guest serial console
qm terminal <vmid>

# To detach / exit the terminal session:
# Press: Ctrl + O
```

---

## 5. Documentation Links

- [Architecture & Design Standards](file:///home/erenyx/homelab-config-automation/docs/architecture.md)
- [Proxmox VE Cluster & RBAC Setup](file:///home/erenyx/homelab-config-automation/docs/proxmox-setup.md)
- [Cloud-Init Schema & Snippet Guide](file:///home/erenyx/homelab-config-automation/docs/cloud-init-guide.md)
- [How to Add a New Distribution Template](file:///home/erenyx/homelab-config-automation/docs/adding-a-new-template.md)
