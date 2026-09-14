# ==============================================================================
# Proxmox VE Golden Cloud-Init Templates
# ==============================================================================
# Automates the creation of production-grade Cloud-Init templates directly from
# official vendor cloud images:
#   1. Ubuntu 24.04 LTS (Noble Numbat)
#   2. Ubuntu 26.04 LTS (Resolute Raccoon)
#   3. Debian 12 (Bookworm)
#   4. Debian 13 (Trixie)
# Built on modern Q35 PCIe, OVMF UEFI, VirtIO SCSI Single, and SSD emulation.
# ==============================================================================

# ==============================================================================
# 1. Ubuntu 24.04 LTS (Noble Numbat) Cloud Template
# ==============================================================================

resource "proxmox_download_file" "ubuntu_2404_cloud_image" {
  content_type = "import"
  datastore_id = var.proxmox_iso_pool
  node_name    = var.proxmox_node
  url          = var.ubuntu_2404_cloud_image_url
  file_name    = "ubuntu-24.04-server-cloudimg-amd64.qcow2"
}

resource "proxmox_virtual_environment_vm" "ubuntu_2404_template" {
  node_name   = var.proxmox_node
  vm_id       = var.ubuntu_2404_vmid
  name        = "ubuntu-2404-cloud-template"
  description = "Ubuntu 24.04 LTS (Noble) Cloud-Init Template (Q35, OVMF UEFI, VirtIO SCSI Single) built by Terraform"
  template    = true
  started     = false

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
    import_from  = proxmox_download_file.ubuntu_2404_cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    ssd          = true
    size         = 20
  }

  network_device {
    model  = "virtio"
    bridge = var.proxmox_bridge
  }

  serial_device {
    device = "socket"
  }

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
# 2. Ubuntu 26.04 LTS (Resolute Raccoon) Cloud Template
# ==============================================================================

resource "proxmox_download_file" "ubuntu_2604_cloud_image" {
  content_type = "import"
  datastore_id = var.proxmox_iso_pool
  node_name    = var.proxmox_node
  url          = var.ubuntu_2604_cloud_image_url
  file_name    = "ubuntu-26.04-server-cloudimg-amd64.qcow2"
}

resource "proxmox_virtual_environment_vm" "ubuntu_2604_template" {
  node_name   = var.proxmox_node
  vm_id       = var.ubuntu_2604_vmid
  name        = "ubuntu-2604-cloud-template"
  description = "Ubuntu 26.04 LTS (Resolute) Cloud-Init Template (Q35, OVMF UEFI, VirtIO SCSI Single) built by Terraform"
  template    = true
  started     = false

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
    import_from  = proxmox_download_file.ubuntu_2604_cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    ssd          = true
    size         = 20
  }

  network_device {
    model  = "virtio"
    bridge = var.proxmox_bridge
  }

  serial_device {
    device = "socket"
  }

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
# 3. Debian 12 (Bookworm) Cloud Template
# ==============================================================================

resource "proxmox_download_file" "debian_12_cloud_image" {
  content_type = "import"
  datastore_id = var.proxmox_iso_pool
  node_name    = var.proxmox_node
  url          = var.debian_12_cloud_image_url
  file_name    = "debian-12-genericcloud-amd64.qcow2"
}

resource "proxmox_virtual_environment_vm" "debian_12_template" {
  node_name   = var.proxmox_node
  vm_id       = var.debian_12_vmid
  name        = "debian-12-cloud-template"
  description = "Debian 12 Bookworm Cloud-Init Template (Q35, OVMF UEFI, VirtIO SCSI Single) built by Terraform"
  template    = true
  started     = false

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
    import_from  = proxmox_download_file.debian_12_cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    ssd          = true
    size         = 20
  }

  network_device {
    model  = "virtio"
    bridge = var.proxmox_bridge
  }

  serial_device {
    device = "socket"
  }

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
# 4. Debian 13 (Trixie) Cloud Template
# ==============================================================================

resource "proxmox_download_file" "debian_13_cloud_image" {
  content_type = "import"
  datastore_id = var.proxmox_iso_pool
  node_name    = var.proxmox_node
  url          = var.debian_13_cloud_image_url
  file_name    = "debian-13-genericcloud-amd64-daily.qcow2"
}

resource "proxmox_virtual_environment_vm" "debian_13_template" {
  node_name   = var.proxmox_node
  vm_id       = var.debian_13_vmid
  name        = "debian-13-cloud-template"
  description = "Debian 13 Trixie Cloud-Init Template (Q35, OVMF UEFI, VirtIO SCSI Single) built by Terraform"
  template    = true
  started     = false

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
    import_from  = proxmox_download_file.debian_13_cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    ssd          = true
    size         = 20
  }

  network_device {
    model  = "virtio"
    bridge = var.proxmox_bridge
  }

  serial_device {
    device = "socket"
  }

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
