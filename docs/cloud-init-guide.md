# Cloud-Init Integration & Configuration Guide

This guide details how **Cloud-Init** ([cloud-init.io](https://cloud-init.io/)) integrates with Proxmox VE and Terraform to provide instant, automated first-boot VM configuration.

---

## 1. What is Cloud-Init?

**Cloud-Init** is the industry-standard multi-distribution package that initializes virtual machines during first boot. When a cloned VM powers on for the first time, Cloud-Init reads metadata provided by the hypervisor and automatically:
- Sets the host system hostname and FQDN.
- Generates unique machine IDs and SSH host keys.
- Creates non-root administrative users and injects SSH public keys.
- Expands the root filesystem to fill the virtual disk.
- Applies static or DHCP network interface configurations.
- Runs post-provisioning scripts and installs baseline packages.

---

## 2. Proxmox Cloud-Init Mechanisms

Proxmox VE provides two complementary methods to supply configuration to the guest VM's Cloud-Init daemon via the attached virtual drive (`ide2`):

```mermaid
flowchart LR
    subgraph ProxmoxEngine["Proxmox VE"]
        Drive["Cloud-Init Virtual Drive (ide2)\nFormat: NoCloud ISO"]
        GUI["Built-in Attributes\n(ciuser, sshkeys, ipconfig0)"]
        Snippets["Custom YAML Snippets\n(cicustom: user=local:snippets/...)"]
    end

    subgraph Guest["Guest Operating System"]
        Daemon["Cloud-Init Service Engine"]
        Config["System State\n• Users & Sudo\n• Hostname & Network\n• QEMU Guest Agent"]
    end

    GUI --> Drive
    Snippets --> Drive
    Drive --> Daemon
    Daemon --> Config
```

### Method A: Built-in Terraform Provider Attributes
Ideal for basic VM parameters (usernames, passwords, SSH keys, network IP):
```hcl
initialization {
  datastore_id = "local-lvm"
  ip_config {
    ipv4 {
      address = "10.10.10.50/24"
      gateway = "10.10.10.1"
    }
  }
  user_account {
    username = "erenyx"
    keys     = [var.ssh_public_key]
  }
}
```

### Method B: Custom Cloud-Init YAML Snippets (`cicustom`)
Ideal for advanced configuration adhering to the full [cloud-init.io](https://cloud-init.io/) schema (package installation, write_files, custom systemd services):
```hcl
initialization {
  datastore_id      = "local-lvm"
  user_data_file_id = "local-storage:snippets/erenyx-base.yaml"
}
```

---

## 3. Standard `cloud-init.io` Schema Structure

The unified baseline snippet located at `terraform/snippets/erenyx-base.yaml` provides a production-grade initial setup:

```yaml
#cloud-config
# 1. Base package installation
package_update: true
package_upgrade: false
packages:
  - qemu-guest-agent
  - htop
  - tmux
  - figlet
  - curl

# 2. In-guest automated initialization commands
runcmd:
  - systemctl daemon-reload
  - systemctl enable --now qemu-guest-agent
  - chmod +x /etc/profile.d/99-erenyx-motd.sh

# 3. Custom Dynamic "Erenyx-Lab" MOTD Greeting
write_files:
  - path: /etc/profile.d/99-erenyx-motd.sh
    permissions: '0755'
    owner: root:root
    content: |
      #!/bin/bash
      [[ $- != *i* ]] && return
      # Displays figlet "Erenyx-Lab" ASCII art and system telemetry (Host, OS, IP, Uptime, Memory, Disk)
```

### Automation via `make apply`
Snippets are stored on the Proxmox host under `/var/lib/vz/snippets/` (`local-storage:snippets/`). The root `Makefile` automatically synchronizes `erenyx-base.yaml` to Proxmox before every `make apply` or `make plan`, requiring zero manual file transfers.

---

## 4. In-Guest Verification & Troubleshooting

To monitor or troubleshoot Cloud-Init execution directly inside the guest VM:

```bash
# 1. Connect to terminal without WebUI
qm terminal <vmid>

# 2. Check overall Cloud-Init status
cloud-init status --wait

# 3. View comprehensive execution log
cat /var/log/cloud-init.log

# 4. View stdout/stderr produced by runcmd and package installations
cat /var/log/cloud-init-output.log

# 5. Validate cloud-config YAML syntax
cloud-init schema --system
```
