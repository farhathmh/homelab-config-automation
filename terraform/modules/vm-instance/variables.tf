# ==============================================================================
# Variables: Reusable VM Instance Module
# ==============================================================================

variable "vm_id" {
  type        = number
  description = "Unique VM ID to assign to the cloned instance"
}

variable "name" {
  type        = string
  description = "Hostname and display name of the VM in Proxmox"
}

variable "description" {
  type        = string
  default     = "VM deployed via Terraform"
  description = "Description displayed in Proxmox WebUI"
}

variable "node_name" {
  type        = string
  default     = "pve1"
  description = "Proxmox node where the VM will be deployed"
}

variable "clone_vm_id" {
  type        = number
  description = "Source template VM ID to clone from (e.g. 9000 for Ubuntu, 9010 for Debian)"
}

variable "full_clone" {
  type        = bool
  default     = true
  description = "Perform a full clone (true) or linked clone (false)"
}

variable "cores" {
  type        = number
  default     = 2
  description = "Number of CPU cores allocated to the VM"
}

variable "memory" {
  type        = number
  default     = 2048
  description = "Dedicated RAM allocated to the VM in Megabytes"
}

variable "disk_size" {
  type        = number
  default     = 20
  description = "Target disk size in Gigabytes (must be >= template disk size)"
}

variable "datastore_id" {
  type        = string
  default     = "local-lvm"
  description = "Target storage pool for the virtual disk"
}

variable "bridge" {
  type        = string
  default     = "vmbr0"
  description = "Network bridge for the VM network interface"
}

variable "vlan_id" {
  type        = number
  default     = null
  description = "Optional VLAN tag for network isolation"
}

variable "ipv4_address" {
  type        = string
  default     = "dhcp"
  description = "IPv4 address with CIDR (e.g. '10.10.10.50/24') or 'dhcp'"
}

variable "ipv4_gateway" {
  type        = string
  default     = null
  description = "IPv4 default gateway (required if static IPv4 address is set)"
}

variable "ci_username" {
  type        = string
  default     = "erenyx"
  description = "Administrative username configured by Cloud-Init"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key string for passwordless login"
}

variable "user_data_file_id" {
  type        = string
  default     = "local-storage:snippets/erenyx-base.yaml"
  description = "Proxmox file ID for the custom Cloud-Init YAML snippet"
}

variable "start_on_boot" {
  type        = bool
  default     = true
  description = "Automatically start the VM when the Proxmox host boots"
}

variable "started" {
  type        = bool
  default     = true
  description = "Power on the VM immediately after creation"
}
