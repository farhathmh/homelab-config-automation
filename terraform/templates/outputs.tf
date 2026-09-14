# ==============================================================================
# Outputs: Proxmox VE Golden Cloud Templates
# ==============================================================================

# --- Ubuntu 24.04 LTS (Noble) Outputs ---

output "ubuntu_2404_template_id" {
  value       = proxmox_virtual_environment_vm.ubuntu_2404_template.vm_id
  description = "VM ID of the generated Ubuntu 24.04 LTS (Noble) golden template"
}

output "ubuntu_2404_template_name" {
  value       = proxmox_virtual_environment_vm.ubuntu_2404_template.name
  description = "Name of the generated Ubuntu 24.04 LTS (Noble) golden template"
}

# --- Ubuntu 26.04 LTS (Resolute) Outputs ---

output "ubuntu_2604_template_id" {
  value       = proxmox_virtual_environment_vm.ubuntu_2604_template.vm_id
  description = "VM ID of the generated Ubuntu 26.04 LTS (Resolute) golden template"
}

output "ubuntu_2604_template_name" {
  value       = proxmox_virtual_environment_vm.ubuntu_2604_template.name
  description = "Name of the generated Ubuntu 26.04 LTS (Resolute) golden template"
}

# --- Debian 12 (Bookworm) Outputs ---

output "debian_12_template_id" {
  value       = proxmox_virtual_environment_vm.debian_12_template.vm_id
  description = "VM ID of the generated Debian 12 Bookworm golden template"
}

output "debian_12_template_name" {
  value       = proxmox_virtual_environment_vm.debian_12_template.name
  description = "Name of the generated Debian 12 Bookworm golden template"
}

# --- Debian 13 (Trixie) Outputs ---

output "debian_13_template_id" {
  value       = proxmox_virtual_environment_vm.debian_13_template.vm_id
  description = "VM ID of the generated Debian 13 Trixie golden template"
}

output "debian_13_template_name" {
  value       = proxmox_virtual_environment_vm.debian_13_template.name
  description = "Name of the generated Debian 13 Trixie golden template"
}
