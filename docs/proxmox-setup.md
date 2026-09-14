# Proxmox VE Prerequisites & API Setup Guide

This guide documents the Proxmox VE cluster requirements, storage prerequisites, and granular RBAC permissions required to automate VM templates and instances with the [`bpg/proxmox`](https://github.com/bpg/terraform-provider-proxmox) Terraform provider.

---

## 1. Storage Pool Configuration

Ensure your Proxmox VE cluster has storage pools configured with the required content types:

| Storage Name | Type | Required Content Type | Purpose |
| :--- | :--- | :--- | :--- |
| **`local-storage`** | Directory | **`ISO image`** (`iso`), **`Snippets`** (`snippets`) | Storing downloaded cloud images (`.img`) and custom Cloud-Init YAML files. |
| **`local-lvm`** | LVM-thin | **`Disk image`** (`images`) | Hosting root virtual disks (`scsi0`) and EFI volumes (`efidisk0`). |

To verify in the Proxmox WebUI:
1. Navigate to **Datacenter** $\to$ **Storage**.
2. Confirm `local-storage` lists `ISO image` and `Snippets` in the **Content** column.
3. Confirm `local-lvm` lists `Disk image` in the **Content** column.

---

## 2. API Token & Granular RBAC Setup

Terraform interacts with the Proxmox VE REST API exclusively using token authentication over HTTPS.

### Step 1: Create the Custom RBAC Role
On your Proxmox VE node shell (or over SSH as root), create a dedicated `Terraform` role:

```bash
pveum role add Terraform -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Audit VM.PowerMgmt VM.Console VM.GuestAgent.Audit Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit SDN.Use Sys.Audit Sys.Modify"
```

> [!IMPORTANT]
> **Privilege Highlights**:
> - `Datastore.AllocateTemplate`: Required by `proxmox_virtual_environment_download_file` to download vendor cloud images directly to storage.
> - `VM.GuestAgent.Audit`: Allows Terraform to query guest IP addresses over the QEMU guest agent socket.
> - `Sys.Modify`: Required for cluster status validation and resource tagging.

### Step 2: Create Automation User & API Token
```bash
# Create local service account 'terraform' under the 'pve' authentication realm
pveum user add terraform@pve -comment "Terraform Automation Service Account"

# Generate API token named 'terraform-token' with privilege separation disabled
pveum user token add terraform@pve terraform-token --privsep 0
```

> [!CAUTION]
> Proxmox will display the token secret (UUID) **only once**. Save this value securely for your local configuration.

### Step 3: Grant Cluster-Wide Permissions
Bind the `Terraform` role to the automation user at root `/`:
```bash
pveum acl modify / -user terraform@pve -role Terraform
```

---

## 3. Configuring Local Automation Secrets

In your target Terraform directory (e.g. `terraform/templates/`):

1. Copy the example variable file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Edit `terraform.tfvars` with your live cluster values:
   ```hcl
   proxmox_endpoint  = "https://10.10.10.10:8006/"
   proxmox_api_token = "terraform@pve!terraform-token=00000000-0000-0000-0000-000000000000"
   proxmox_node      = "pve1"
   ssh_public_key    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... user@host"
   ```
3. `terraform.tfvars` is permanently ignored by Git via `.gitignore`. Never commit live API tokens or credentials.
