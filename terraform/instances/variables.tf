# ==============================================================================
# Input Variables: Proxmox VE Instance Layer
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
  description = "Proxmox node name where instances will be cloned"
}

# --- Cluster Storage & Networking ---

variable "proxmox_storage_pool" {
  type        = string
  default     = "local-lvm"
  description = "Proxmox storage pool for cloned instance virtual disks"
}

variable "proxmox_iso_pool" {
  type        = string
  default     = "local-storage"
  description = "Proxmox storage pool holding the uploaded cloud-init snippet (directory storage, content type: snippets)"
}

variable "proxmox_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Linux network bridge for instance network interfaces"
}

# --- Cloud-Init Default Credentials ---

variable "ci_username" {
  type        = string
  default     = "erenyx"
  description = "Administrative username injected into every cloned instance via Cloud-Init"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key string injected into every cloned instance for passwordless authentication"
}

# --- Golden Template Reference ---

variable "clone_vm_id" {
  type        = number
  default     = 9002
  description = "vmid of the golden template to clone from (currently the Ubuntu 26.04 'resolute' template built by terraform/templates/). Hardcoded by design — not cross-referenced from templates/'s state, since template and instance lifecycles are intentionally decoupled. Update manually if the golden template is ever rebuilt under a different vmid."
}

# --- Node Definitions ---

variable "nodes" {
  type = map(object({
    role         = string
    cores        = number
    memory       = number
    disk_size    = number
    vm_id        = number
    ipv4_address = string
    ipv4_gateway = string
  }))
  description = "Map of instance nodes to clone from the golden template, keyed by hostname. `role` is metadata only (used in the VM description; Ansible inventory grouping consumes it separately once that layer exists)."

  default = {
    "docker-ubuntu-node" = {
      role         = "docker"
      cores        = 6
      memory       = 8192
      disk_size    = 50
      vm_id        = 500
      ipv4_address = "10.10.10.50/24"
      ipv4_gateway = "10.10.10.1"
    }
    "k8s-ctrl-node1" = {
      role         = "k8s_control"
      cores        = 4
      memory       = 4096
      disk_size    = 50
      vm_id        = 501
      ipv4_address = "10.10.10.51/24"
      ipv4_gateway = "10.10.10.1"
    }
    "k8s-worker-node1" = {
      role         = "k8s_worker"
      cores        = 6
      memory       = 8192
      disk_size    = 50
      vm_id        = 502
      ipv4_address = "10.10.10.52/24"
      ipv4_gateway = "10.10.10.1"
    }
    "k8s-worker-node2" = {
      role         = "k8s_worker"
      cores        = 6
      memory       = 8192
      disk_size    = 50
      vm_id        = 503
      ipv4_address = "10.10.10.53/24"
      ipv4_gateway = "10.10.10.1"
    }
  }
}
