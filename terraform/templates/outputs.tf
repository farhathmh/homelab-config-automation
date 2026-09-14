# ==============================================================================
# Outputs: Proxmox VE Golden Cloud Templates
# ==============================================================================

output "ubuntu_template_id" {
  value       = proxmox_virtual_environment_vm.ubuntu_template.vm_id
  description = "VM ID of the generated Ubuntu 24.04 LTS golden template"
}

output "ubuntu_template_name" {
  value       = proxmox_virtual_environment_vm.ubuntu_template.name
  description = "Name of the generated Ubuntu 24.04 LTS golden template"
}

output "debian_template_id" {
  value       = proxmox_virtual_environment_vm.debian_template.vm_id
  description = "VM ID of the generated Debian 12 Bookworm golden template"
}

output "debian_template_name" {
  value       = proxmox_virtual_environment_vm.debian_template.name
  description = "Name of the generated Debian 12 Bookworm golden template"
}
