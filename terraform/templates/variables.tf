# ==============================================================================
# Input Variables: Proxmox VE Cloud Templates
# ==============================================================================

# --- Proxmox Connection Variables ---

variable "proxmox_endpoint" {
  type        = string
  description = "The HTTPS endpoint for the Proxmox VE API, e.g. https://10.10.10.10:8006/"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "Full Proxmox API token string (format: user@realm!tokenid=secret-uuid)"
}

variable "proxmox_insecure" {
  type        = bool
  default     = true
  description = "Allow self-signed TLS certificates for Proxmox API connections"
}

variable "proxmox_node" {
  type        = string
  default     = "pve1"
  description = "Proxmox node name where templates and images will be created"
}

# --- Cluster Storage & Networking ---

variable "proxmox_storage_pool" {
  type        = string
  default     = "local-lvm"
  description = "Proxmox storage pool for virtual hard disks and EFI volumes (LVM-thin or directory)"
}

variable "proxmox_iso_pool" {
  type        = string
  default     = "local-storage"
  description = "Proxmox storage pool for downloading raw vendor cloud images (directory storage)"
}

variable "proxmox_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Linux network bridge for the template network interface"
}

# --- Cloud-Init Default Credentials ---

variable "ci_username" {
  type        = string
  default     = "erenyx"
  description = "Default administrative username injected into the Cloud-Init configuration"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key string injected into the template for passwordless authentication"
}

# --- Ubuntu 24.04 LTS Cloud Template Variables ---

variable "ubuntu_vmid" {
  type        = number
  default     = 9000
  description = "Proxmox VM ID for the Ubuntu 24.04 LTS golden template"
}

variable "ubuntu_cloud_image_url" {
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  description = "Download URL for the official Ubuntu 24.04 LTS Noble Server cloud image"
}

# --- Debian 12 Bookworm Cloud Template Variables ---

variable "debian_vmid" {
  type        = number
  default     = 9010
  description = "Proxmox VM ID for the Debian 12 Bookworm golden template"
}

variable "debian_cloud_image_url" {
  type        = string
  default     = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
  description = "Download URL for the official Debian 12 Bookworm GenericCloud image"
}
