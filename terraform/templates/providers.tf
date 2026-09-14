# ==============================================================================
# Terraform & Proxmox VE Provider Configuration
# ==============================================================================
# Uses the official modern bpg/proxmox provider to automate cloud image
# downloads, VM hardware definitions, and Cloud-Init templates via REST API.
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

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  ssh {
    agent = true
  }
}
