source "proxmox-iso" "ubuntu-2604" {
  # Connection configuration
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node

  # VM identity
  vm_id                = var.vm_id
  vm_name              = "ubuntu-2604-template"
  template_description = "Ubuntu 26.04 LTS template built with Packer"

  # Hardware configuration
  cores    = 2
  memory   = 2048
  cpu_type = "host"

  machine = "q35"
  bios    = "ovmf"

  efi_config {
    efi_storage_pool  = var.proxmox_storage_pool
    efi_format        = "raw"
    efi_type          = "4m"
    pre_enrolled_keys = true
  }

  scsi_controller = "virtio-scsi-single"
  boot            = "order=scsi0;scsi1"

  # Disk configuration
  disks {
    type         = "scsi"
    disk_size    = "20G"
    storage_pool = var.proxmox_storage_pool
    format       = "raw"
    discard      = true
    ssd          = true
  }

  # Network configuration
  network_adapters {
    model  = "virtio"
    bridge = var.proxmox_bridge
  }

  # Boot ISO media
  boot_iso {
    type             = "scsi"
    iso_url          = var.iso_url
    iso_checksum     = var.iso_checksum
    iso_storage_pool = var.proxmox_iso_pool
    iso_download_pve = true
    unmount          = true
  }

  # Autoinstall HTTP server
  http_content = {
    "/meta-data" = file("${path.root}/http/ubuntu/meta-data")
    "/user-data" = templatefile("${path.root}/http/ubuntu/user-data.pkrtpl.hcl", {
      ssh_username   = var.ssh_username
      ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_file)))
    })
  }
  http_port_min = 8802
  http_port_max = 8802

  boot_wait = "10s"

  boot_command = [
    "<esc><wait>",
    "<esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz quiet autoinstall 'ds=nocloud-net;s=http://{{.HTTPIP}}:{{.HTTPPort}}/' ---<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  # SSH communicator
  ssh_username         = var.ssh_username
  ssh_private_key_file = var.ssh_private_key_file
  ssh_timeout          = "20m"
}
