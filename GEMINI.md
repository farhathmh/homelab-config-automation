# ==============================================================================
# Homelab Automation Workspace Rules & Guidelines
# ==============================================================================

This document defines the core development workflows, Git practices, and safety
guidelines for the `homelab-config-automation` workspace. All agents and contributors
must adhere to these rules.

---

## 1. Branching Strategy & Merge Protocol

- **Default Working Branch (`dev`)**:
  - All active development, file updates, bug fixes, and feature additions must take place exclusively on the `dev` branch.
  - **Never commit directly to `main`**.
- **Promotion to `main` (Test Gate)**:
  - Changes on `dev` may only be merged into `main` once all tests and validations pass (e.g., `terraform fmt -check`, `terraform validate`, clean test plans, and linting).
  - Merges into `main` must be clean, verified, and pushed to the remote repository.

---

## 2. Git Commit & Staging Rules

- **Granular Commits**:
  - Stage and commit files granularly (`git add <file>` followed by `git commit`).
  - Do not batch unrelated files or multiple disparate configuration updates into a single omnibus commit.
- **Descriptive Commit Messages**:
  - Every commit must have a descriptive, conventional commit message clearly explaining the purpose of the change (e.g., `feat(templates): ...`, `docs(arch): ...`, `chore(config): ...`).
- **Prompt Remote Synchronization**:
  - Push committed updates to the remote repository (`origin dev`) promptly after committing.

---

## 3. Credential Safety & Zero Leak Policy

- **No Secret Commits**:
  - Files matching `*.tfvars`, `*.auto.tfvars`, `*.tfstate*`, private keys (`*.key`, `*.pem`), or any files containing live API tokens/passwords must never be tracked or committed to Git.
  - All secret and state files must be listed in `.gitignore` and kept exclusively on local disk.
- **Sanitized Examples**:
  - Always provide and track sanitized example templates (e.g., `terraform.tfvars.example`) with dummy values for documentation and onboarding.

---

## 4. Terraform & Infrastructure Standards

- **Pre-Commit Validation**:
  - Always run `terraform fmt -check` and `terraform validate` against the target configuration directory before committing Terraform updates.
- **Modularity & Standards**:
  - Align with modern Terraform best practices and official `bpg/proxmox` provider documentation.
  - Keep configuration files modular (`providers.tf`, `variables.tf`, `main.tf`, `outputs.tf`).
- **Hardware Baselines**:
  - Chipset: `machine = "q35"` (PCI Express architecture).
  - Firmware: `bios = "ovmf"` with 4MB raw EFI NVRAM partition (`pre_enrolled_keys = true`).
  - Storage Controller: `scsi_hardware = "virtio-scsi-single"`.
  - Disks: `ssd = true` and `discard = "on"` (TRIM pass-through).
  - Serial Console: `serial_device` socket enabled for headless terminal access via `qm terminal <vmid>`.
  - Storage Decoupling: Download images to `local-storage` (Directory), store VM disks/EFI on `local-lvm` (LVM-thin).
