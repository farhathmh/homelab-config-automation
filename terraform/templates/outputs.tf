# ==============================================================================
# Outputs: Proxmox VE Golden Cloud Templates
# ==============================================================================

output "template_ids" {
  value       = { for key, vm in proxmox_virtual_environment_vm.template : key => vm.vm_id }
  description = "VM IDs of the actively built golden templates, keyed by distro codename"
}

output "template_names" {
  value       = { for key, vm in proxmox_virtual_environment_vm.template : key => vm.name }
  description = "Names of the actively built golden templates, keyed by distro codename"
}
