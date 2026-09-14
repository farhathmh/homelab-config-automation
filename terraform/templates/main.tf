# ==============================================================================
# Proxmox VE Golden Cloud-Init Templates
# ==============================================================================
# Automates the creation of production-grade Cloud-Init templates directly from
# official vendor cloud images (Ubuntu 24.04 LTS Noble & Debian 12 Bookworm).
# Built on modern Q35 PCIe, OVMF UEFI, VirtIO SCSI Single, and SSD emulation.
# ==============================================================================

# ==============================================================================
# 1. Ubuntu 24.04 LTS (Noble Numbat) Cloud Template
# ==============================================================================

# Download official Ubuntu cloud image directly to Proxmox directory storage
resource "proxmox_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = var.proxmox_iso_pool
  node_name    = var.proxmox_node
  url          = var.ubuntu_cloud_image_url
  file_name    = "ubuntu-24.04-server-cloudimg-amd64.img"
}

# Create Ubuntu 24.04 Golden Template
resource "proxmox_virtual_environment_vm" "ubuntu_template" {
  node_name   = var.proxmox_node
  vm_id       = var.ubuntu_vmid
  name        = "ubuntu-2404-cloud-template"
  description = "Ubuntu 24.04 LTS Cloud-Init Template (Q35, OVMF UEFI, VirtIO SCSI Single) built by Terraform"
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

  # Root disk imported directly from the downloaded vendor image
  disk {
    datastore_id = var.proxmox_storage_pool
    import_from  = proxmox_download_file.ubuntu_cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    ssd          = true
    size         = 20
  }

  # Network Interface
  network_device {
    model  = "virtio"
    bridge = var.proxmox_bridge
  }

  # Headless serial console socket for 'qm terminal <vmid>' access
  serial_device {
    device = "socket"
  }

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
      keys     = [trimspace(var.ssh_public_key)]
    }
  }

  agent {
    enabled = true
  }
}

# ==============================================================================
# 2. Debian 12 (Bookworm) Cloud Template
# ==============================================================================

# Download official Debian GenericCloud image directly to Proxmox directory storage
resource "proxmox_download_file" "debian_cloud_image" {
  content_type = "iso"
  datastore_id = var.proxmox_iso_pool
  node_name    = var.proxmox_node
  url          = var.debian_cloud_image_url
  file_name    = "debian-12-genericcloud-amd64.qcow2"
}

# Create Debian 12 Golden Template
resource "proxmox_virtual_environment_vm" "debian_template" {
  node_name   = var.proxmox_node
  vm_id       = var.debian_vmid
  name        = "debian-12-cloud-template"
  description = "Debian 12 Bookworm Cloud-Init Template (Q35, OVMF UEFI, VirtIO SCSI Single) built by Terraform"
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

  # Root disk imported directly from the downloaded vendor image
  disk {
    datastore_id = var.proxmox_storage_pool
    import_from  = proxmox_download_file.debian_cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    ssd          = true
    size         = 20
  }

  # Network Interface
  network_device {
    model  = "virtio"
    bridge = var.proxmox_bridge
  }

  # Headless serial console socket for 'qm terminal <vmid>' access
  serial_device {
    device = "socket"
  }

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
      keys     = [trimspace(var.ssh_public_key)]
    }
  }

  agent {
    enabled = true
  }
}
