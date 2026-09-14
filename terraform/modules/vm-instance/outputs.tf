# ==============================================================================
# Outputs: Reusable VM Instance Module
# ==============================================================================

output "id" {
  value       = proxmox_virtual_environment_vm.instance.id
  description = "The Proxmox internal resource ID of the VM"
}

output "vm_id" {
  value       = proxmox_virtual_environment_vm.instance.vm_id
  description = "The assigned numeric VM ID in Proxmox"
}

output "name" {
  value       = proxmox_virtual_environment_vm.instance.name
  description = "The hostname and display name of the VM"
}

output "ipv4_addresses" {
  value       = proxmox_virtual_environment_vm.instance.ipv4_addresses
  description = "List of IPv4 addresses reported by QEMU Guest Agent"
}
