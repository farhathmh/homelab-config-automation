# ==============================================================================
# Proxmox VE Instance Layer — Clones the Golden Template into Sized Nodes
# ==============================================================================
# Renders and uploads one cloud-init bootstrap snippet per node (admin user
# + SSH key + hostname, qemu-guest-agent, python3 — see
# terraform/snippets/bootstrap.yaml.tftpl) and clones each into the matching
# node via the reusable vm-instance module. One snippet per node (not a
# single shared file) because each needs its own `hostname:` — a shared
# snippet can't give every node a different hostname. Templated (not a
# static source_file) because the admin user/SSH key/hostname have to be
# baked into this snippet's user-data — Proxmox ignores ciuser/sshkeys once
# a custom cicustom snippet is set, so the vm-instance module's user_account
# block can't deliver them here.
# ==============================================================================

resource "proxmox_virtual_environment_file" "bootstrap_snippet" {
  for_each = var.nodes

  content_type = "snippets"
  datastore_id = var.proxmox_iso_pool
  node_name    = var.proxmox_node

  source_raw {
    file_name = "bootstrap-${each.key}.yaml"
    data = templatefile("${path.module}/../snippets/bootstrap.yaml.tftpl", {
      ci_username    = var.ci_username
      ssh_public_key = trimspace(var.ssh_public_key)
      hostname       = each.key
    })
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

  user_data_file_id = proxmox_virtual_environment_file.bootstrap_snippet[each.key].id
}
