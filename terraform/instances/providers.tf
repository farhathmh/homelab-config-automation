# ==============================================================================
# Terraform & Proxmox VE Provider Configuration — Instance Layer
# ==============================================================================
# Separate root module / state from terraform/templates/, since template and
# instance lifecycles differ (templates rebuilt rarely; instances recreated
# or resized far more often).
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
