# ==============================================================================
# Proxmox VE Golden Cloud-Init Templates
# ==============================================================================
# Builds golden Cloud-Init templates from official vendor cloud images. Driven
# by var.templates (every known distro definition) filtered down to
# var.active_templates (the subset actually built by this apply — defaults to
# just Ubuntu 26.04 "Resolute"; other distros stay defined as opt-in).
# Built on modern Q35 PCIe, OVMF UEFI, VirtIO SCSI Single, and SSD emulation.
# ==============================================================================

locals {
  active_templates = {
    for key, tmpl in var.templates : key => tmpl if contains(var.active_templates, key)
  }
}

resource "proxmox_download_file" "cloud_image" {
  for_each = local.active_templates

  content_type = "import"
  datastore_id = var.proxmox_iso_pool
  node_name    = var.proxmox_node
  url          = each.value.cloud_image_url
  file_name    = each.value.file_name
}

resource "proxmox_virtual_environment_vm" "template" {
  for_each = local.active_templates

  node_name   = var.proxmox_node
  vm_id       = each.value.vmid
  name        = each.value.display_name
  description = each.value.description
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
    import_from  = proxmox_download_file.cloud_image[each.key].id
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
