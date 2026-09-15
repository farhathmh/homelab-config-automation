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

# --- Golden Template Definitions ---

variable "templates" {
  type = map(object({
    vmid            = number
    file_name       = string
    cloud_image_url = string
    display_name    = string
    description     = string
  }))
  description = <<-EOT
    Map of every known golden template definition, keyed by distro codename.
    Defining an entry here does not build it — only keys listed in
    var.active_templates are actually created. This lets Debian/Ubuntu-24.04
    stay available as opt-in without being deleted from the codebase.
  EOT

  default = {
    noble = {
      vmid            = 9001
      file_name       = "ubuntu-24.04-server-cloudimg-amd64.qcow2"
      cloud_image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
      display_name    = "ubuntu-2404-cloud-template"
      description     = "Ubuntu 24.04 LTS (Noble) Cloud-Init Template (Q35, OVMF UEFI, VirtIO SCSI Single) built by Terraform"
    }
    resolute = {
      vmid            = 9000
      file_name       = "ubuntu-26.04-server-cloudimg-amd64.qcow2"
      cloud_image_url = "https://cloud-images.ubuntu.com/resolute/current/resolute-server-cloudimg-amd64.img"
      display_name    = "ubuntu-2604-cloud-template"
      description     = "Ubuntu 26.04 LTS (Resolute) Cloud-Init Template (Q35, OVMF UEFI, VirtIO SCSI Single) built by Terraform"
    }
    bookworm = {
      vmid            = 9011
      file_name       = "debian-12-genericcloud-amd64.qcow2"
      cloud_image_url = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
      display_name    = "debian-12-cloud-template"
      description     = "Debian 12 Bookworm Cloud-Init Template (Q35, OVMF UEFI, VirtIO SCSI Single) built by Terraform"
    }
    trixie = {
      vmid            = 9010
      file_name       = "debian-13-genericcloud-amd64-daily.qcow2"
      cloud_image_url = "https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-genericcloud-amd64-daily.qcow2"
      display_name    = "debian-13-cloud-template"
      description     = "Debian 13 Trixie Cloud-Init Template (Q35, OVMF UEFI, VirtIO SCSI Single) built by Terraform"
    }
  }
}

variable "active_templates" {
  type        = set(string)
  default     = ["resolute"]
  description = "Keys from var.templates to actually build in this apply. Keys left out stay defined but are not created (or are removed from state if previously applied — see docs before narrowing this on a cluster with existing templates)."
}
