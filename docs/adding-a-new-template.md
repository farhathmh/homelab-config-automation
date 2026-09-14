# How to Add a New Distribution Template

This guide provides a standardized, 4-step checklist for onboarding a new operating system cloud image into the Terraform template architecture.

---

## 1. Upstream Official Cloud Image Sources

Always source minimal generic cloud images directly from official vendor distribution mirrors:

| Distribution | Official Image URL Format | Recommended VM ID |
| :--- | :--- | :--- |
| **Ubuntu 24.04 LTS** | `https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img` | `9000` |
| **Ubuntu 26.04 LTS** | `https://cloud-images.ubuntu.com/resolute/current/resolute-server-cloudimg-amd64.img` | `9002` |
| **Debian 12 Bookworm** | `https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2` | `9010` |
| **Debian 13 Trixie** | `https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-genericcloud-amd64-daily.qcow2` | `9012` |
| **Fedora 40/41 Cloud** | `https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/...` | `9020` |
| **Rocky Linux 9** | `https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2` | `9030` |
| **Alpine Linux 3.20** | `https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/cloud/generic-alpine-3.20.0-x86_64-bios.qcow2` | `9040` |

---

## 2. 4-Step Onboarding Workflow

### Step 1: Declare Template Variables in `variables.tf`
Add default variables for the distribution's VM ID, file name, and download link:

```hcl
variable "debian_vmid" {
  type        = number
  default     = 9010
  description = "Proxmox VM ID for the Debian 12 cloud template"
}

variable "debian_cloud_image_url" {
  type        = string
  default     = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
  description = "Download link for official Debian 12 GenericCloud image"
}
```

---

### Step 2: Download the Cloud Image via Proxmox API
In `main.tf`, declare the download resource targeting your directory storage pool:

```hcl
resource "proxmox_virtual_environment_download_file" "debian_cloud_image" {
  content_type = "iso"
  datastore_id = var.proxmox_iso_pool # "local-storage"
  node_name    = var.proxmox_node
  url          = var.debian_cloud_image_url
  file_name    = "debian-12-genericcloud-amd64.qcow2"
}
```

---

### Step 3: Define the Golden Template VM Resource
In `main.tf`, declare the VM resource referencing the downloaded image:

```hcl
resource "proxmox_virtual_environment_vm" "debian_template" {
  node_name   = var.proxmox_node
  vm_id       = var.debian_vmid
  name        = "debian-12-cloud-template"
  description = "Debian 12 Bookworm Cloud-Init Template (Q35, UEFI, VirtIO SCSI Single) built by Terraform"
  template    = true
  started     = false

  # Modern Hardware Baseline
  machine = "q35"
  bios    = "ovmf"

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  efi_disk {
    datastore_id      = var.proxmox_storage_pool
    type              = "4m"
    pre_enrolled_keys = true
  }

  scsi_hardware = "virtio-scsi-single"

  disk {
    datastore_id = var.proxmox_storage_pool
    import_from  = proxmox_virtual_environment_download_file.debian_cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    ssd          = true
    size         = 20
  }

  network_device {
    model  = "virtio"
    bridge = var.proxmox_bridge
  }

  # Serial port socket for terminal monitoring via 'qm terminal'
  serial_device {}

  # Cloud-Init Initialization Drive
  initialization {
    datastore_id = var.proxmox_storage_pool
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      username = var.ci_username
      keys     = [var.ssh_public_key]
    }
  }

  agent {
    enabled = true
  }
}
```

---

### Step 4: Validate, Plan, and Deploy
```bash
# Format HCL files
terraform fmt

# Validate configuration syntax
terraform validate

# Review execution plan
terraform plan

# Apply changes (downloads image and builds template in ~15 seconds)
terraform apply
```
