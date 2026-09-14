# Proxmox API connection variables
variable "proxmox_api_url" {
  type        = string
  description = "Proxmox VE API endpoint URL, e.g. https://10.10.10.10:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Proxmox API token ID, e.g. packer@pve!packer-token"
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Proxmox API token secret"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name to build the VM on"
}

# Template and hardware configuration variables
variable "vm_id" {
  type        = number
  default     = 9000
  description = "VM ID for the template in Proxmox"
}

variable "proxmox_storage_pool" {
  type        = string
  default     = "local-lvm"
  description = "Storage pool for the virtual disk"
}

variable "proxmox_iso_pool" {
  type        = string
  default     = "local-storage"
  description = "Storage pool where installation ISO is stored"
}

variable "proxmox_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Network bridge for the VM"
}

# SSH communicator credentials
variable "ssh_username" {
  type        = string
  default     = "erenyx"
  description = "Username created in autoinstall and used by Packer SSH"
}

variable "ssh_private_key_file" {
  type        = string
  default     = "~/.ssh/id_ed25519"
  description = "Path to SSH private key used by Packer"
}

variable "ssh_public_key_file" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "Path to SSH public key injected into the VM"
}

# Installer ISO media variables
variable "iso_url" {
  type        = string
  default     = "https://releases.ubuntu.com/26.04/ubuntu-26.04-live-server-amd64.iso"
  description = "URL to Ubuntu 26.04 Server ISO"
}

variable "iso_checksum" {
  type        = string
  default     = "file:https://releases.ubuntu.com/26.04/SHA256SUMS"
  description = "Checksum or checksum file URL for the ISO"
}
