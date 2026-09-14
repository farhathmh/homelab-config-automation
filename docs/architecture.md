# Virtualization & Cloud-Init Architecture

This document details the architectural design, hardware baselines, storage patterns, and provisioning pipelines used in this repository to automate Proxmox VE VM templates and instances using Terraform and official Cloud Images.

---

## 1. System Architecture Overview

```mermaid
flowchart TD
    subgraph Upstream["Official Vendor Cloud Mirrors"]
        Ubuntu["Ubuntu Cloud Images\n(noble-server-cloudimg-amd64.img)"]
        Debian["Debian GenericCloud\n(debian-12-genericcloud-amd64.qcow2)"]
    end

    subgraph Proxmox["Proxmox VE Cluster (pve1)"]
        subgraph Storage["Storage Pools"]
            PoolISO["local-storage (Directory)\n• Stores downloaded cloud images\n• Content: iso, snippets"]
            PoolLVM["local-lvm (LVM-thin)\n• Stores OS virtual disks (raw)\n• Stores 4M EFI NVRAM disks"]
        end

        subgraph Template["Golden Template (e.g. VMID 9000)"]
            Q35["Chipset: Q35 (PCIe)"]
            OVMF["BIOS: OVMF (UEFI 4M)"]
            SCSI["Controller: virtio-scsi-single"]
            DiskOS["scsi0: Raw Cloud Disk\n(ssd=true, discard=on)"]
            DiskEFI["efidisk0: 4M EFI NVRAM"]
            CI["Cloud-Init Drive (ide2)"]
            Serial["serial0: Unix Socket\n(Terminal Monitoring)"]
            NIC["net0: VirtIO (vmbr0)"]
        end

        subgraph Clones["Live VM Instances"]
            VM1["VM 100: app-server-01\n• Cloned scsi0\n• Injected IP & Hostname"]
            VM2["VM 101: db-server-01\n• Cloned scsi0\n• Injected IP & Hostname"]
        end
    end

    subgraph Automation["Terraform Engine (bpg/proxmox)"]
        TF_DL["proxmox_virtual_environment_download_file"]
        TF_VM["proxmox_virtual_environment_vm (template=true)"]
        TF_CLONE["proxmox_virtual_environment_vm (clone)"]
    end

    Ubuntu -->|Direct API Download| TF_DL
    Debian -->|Direct API Download| TF_DL
    TF_DL --> PoolISO
    TF_VM -->|Import Disk| PoolLVM
    TF_VM --> Template
    Template --> TF_CLONE
    TF_CLONE --> Clones
```

---

## 2. Hardware Standards & Engineering Rationale

Every virtual machine template built in this repository adheres to a standardized, modern hardware baseline:

### A. Machine Type: `q35` (PCI Express Architecture)
- **Rationale**: Legacy `i440fx` emulates a 1996 Intel chipset with PCI buses limited to 32 devices. `q35` provides a modern PCIe native topology with higher I/O bandwidth, PCIe passthrough capabilities, and advanced ACPI power management.
- **Network Interface**: On `q35`, network adapters attach as PCIe endpoints (`enp1s0`) rather than legacy slots (`ens18`).

### B. Firmware: `ovmf` (UEFI)
- **Rationale**: Modern enterprise Linux distributions boot faster and support GPT partition tables natively under UEFI.
- **EFI Disk Configuration**:
  - `datastore_id`: Placed on `local-lvm` alongside the VM virtual disk.
  - `type`: `4m` (the standard OVMF image format in Proxmox VE 8+).
  - `pre_enrolled_keys`: Pre-enrolls Microsoft and standard distro certificate keys for Secure Boot compatibility.

### C. Storage Controller: `virtio-scsi-single`
- **Rationale**: Standard `virtio-scsi` multiplexes all drives across a single shared controller queue. `virtio-scsi-single` allocates a dedicated SCSI controller instance per drive, dramatically increasing parallel I/O concurrency and eliminating queue lock contention under heavy disk load.

### D. SSD Emulation & TRIM (`ssd = true`, `discard = "on"`)
- **SSD Emulation**: Informs the guest operating system's kernel scheduler that the underlying block device has zero seek latency, activating deadline/noop I/O schedulers optimized for flash storage.
- **Discard (TRIM)**: When files are deleted inside the guest VM, the filesystem issues SCSI `UNMAP`/TRIM commands. Proxmox relays these commands to the underlying LVM-thin pool, preventing thin-pool storage bloat and immediately freeing physical SSD blocks.

### E. Headless Serial Console (`serial_device`)
- **Rationale**: Adding a serial port socket (`serial0: socket`) enables direct terminal monitoring from the command line without opening the Proxmox WebUI.
- **Access Command**:
  ```bash
  qm terminal <vmid>
  # Exit session: Ctrl + O
  ```

---

## 3. Storage Pool Decoupling

Storage is decoupled by workload to optimize reliability and performance:

| Storage Pool | Type | Content Types | Purpose in Architecture |
| :--- | :--- | :--- | :--- |
| **`local-storage`** | Directory (`/var/lib/vz`) | `iso`, `snippets` | Stores downloaded raw vendor cloud images and custom Cloud-Init YAML files. |
| **`local-lvm`** | LVM-thin | `images`, `rootdir` | Stores guest VM root hard disks (`scsi0`) and 4MB EFI NVRAM volumes (`efidisk0`). |

---

## 4. Cloud-Init vs. Traditional ISO Build Pipelines

```mermaid
timeline
    title Deployment Comparison
    section Traditional ISO (Packer)
        Media Download : 2 minutes (1.5GB ISO)
        Boot & GRUB Typing : 30 seconds
        Subiquity Package Install : 8-12 minutes
        SSH Cleanup Script : 1 minute
        Template Conversion : 10 seconds
    section Cloud Image (Terraform)
        API Image Download : 20 seconds (600MB compressed img)
        Direct Disk Import : 5 seconds
        Template Conversion : 2 seconds
        Instant First Boot : 5 seconds (Cloud-Init initialization)
```

1. **Zero OS Installation Time**: The vendor cloud image comes with the OS, kernel, and systemd pre-installed.
2. **Zero Cleanup Required**: Official cloud images are pre-sanitized by Canonical and Debian (empty `/etc/machine-id`, cleared package caches, and sealed Cloud-Init state).
3. **Dynamic Customization**: Every cloned instance pulls its identity (IP, hostname, users, SSH keys) at first boot directly from the attached Cloud-Init volume.
