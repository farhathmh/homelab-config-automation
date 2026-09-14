# ==============================================================================
# Proxmox VE Instance Layer — Clones the Golden Template into Sized Nodes
# ==============================================================================
# Uploads the minimal cloud-init bootstrap snippet (qemu-guest-agent +
# python3 only — see terraform/snippets/bootstrap.yaml) and clones it into
# every node in var.nodes via the reusable vm-instance module.
# ==============================================================================

resource "proxmox_virtual_environment_file" "bootstrap_snippet" {
  content_type = "snippets"
  datastore_id = var.proxmox_iso_pool
  node_name    = var.proxmox_node

  source_file {
    path = "${path.module}/../snippets/bootstrap.yaml"
  }
}

module "node" {
  source = "../modules/vm-instance"

  for_each = var.nodes

  node_name   = var.proxmox_node
  vm_id       = each.value.vm_id
  name        = each.key
  description = "${each.key} (role: ${each.value.role}) — cloned via Terraform from golden template vm_id ${var.clone_vm_id}"

  clone_vm_id = var.clone_vm_id

  cores     = each.value.cores
  memory    = each.value.memory
  disk_size = each.value.disk_size

  datastore_id = var.proxmox_storage_pool
  bridge       = var.proxmox_bridge

  ipv4_address = each.value.ipv4_address
  ipv4_gateway = each.value.ipv4_gateway

  ci_username    = var.ci_username
  ssh_public_key = var.ssh_public_key

  user_data_file_id = proxmox_virtual_environment_file.bootstrap_snippet.id
}
