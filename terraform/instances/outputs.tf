# ==============================================================================
# Outputs: Proxmox VE Instance Layer
# ==============================================================================

output "node_vm_ids" {
  value       = { for key, node in module.node : key => node.vm_id }
  description = "VM IDs of the cloned instance nodes, keyed by hostname"
}

output "node_ipv4_addresses" {
  value       = { for key, node in module.node : key => node.ipv4_addresses }
  description = "IPv4 addresses reported by QEMU Guest Agent for each node, keyed by hostname"
}
