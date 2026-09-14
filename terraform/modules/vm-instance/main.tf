# ==============================================================================
# Reusable Proxmox VM Instance Module
# ==============================================================================
# Clones a golden template into an active, running virtual machine instance with
# custom compute, network, and Cloud-Init identity applied at first boot.
# ==============================================================================

terraform {
  required_version = ">= 1.8.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.68.0, < 1.0.0"
    }
  }
}

resource "proxmox_virtual_environment_vm" "instance" {
  node_name   = var.node_name
  vm_id       = var.vm_id
  name        = var.name
  description = var.description
  on_boot     = var.start_on_boot
  started     = var.started

  # Clone source golden template
  clone {
    vm_id = var.clone_vm_id
    full  = var.full_clone
  }

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  # Scale root disk size if specified larger than the template baseline
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size
    discard      = "on"
    ssd          = true
  }

  network_device {
    model   = "virtio"
    bridge  = var.bridge
    vlan_id = var.vlan_id
  }

  # Serial port socket for 'qm terminal <vmid>' monitoring
  serial_device {
    device = "socket"
  }

  # Cloud-Init configuration
  initialization {
    datastore_id      = var.datastore_id
    user_data_file_id = var.user_data_file_id

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_gateway
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
