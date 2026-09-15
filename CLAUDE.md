# CLAUDE.md

Guidance for Claude Code (or any agent) working in this repository. This file
is the authoritative on-boarding doc — read it fully before making changes.

## 1. What this repo is

`homelab-config-automation` (private repo) automates Proxmox VE VM template
creation and cloning using Terraform (the `bpg/proxmox` provider) and official
cloud images. It's the "infrastructure" layer of a broader personal
automation pipeline the owner calls **ForgeStack**
(metal → packer → infrastructure → gitops), though this repo only covers the
provisioning stage.

Target division of labor (see section 4 for what's actually implemented):
**Terraform provisions Proxmox objects → cloud-init does first-boot
bootstrap only → Ansible layers configuration → ArgoCD deploys workloads**
(ArgoCD is out of scope of this repo).

Not part of this workspace, no need to read it: `github.com/farhathmh/homelab`
(a fork of `khuedoan/homelab`) — a separate, unrelated bare-metal PXE +
Ansible + k3s + ArgoCD reference repo that inspired the target architecture
above.

## 2. Rules (binding — do not loosen)

**Branching**
- All work happens on `dev`. Never commit directly to `main`.
- `dev` → `main` only after `terraform fmt -check`, `terraform validate`, a
  clean plan, and linting all pass.

**Commits**
- Granular: `git add <file>` then commit — no omnibus commits spanning
  unrelated files.
- Conventional-commit messages (`feat(templates): ...`, `docs(arch): ...`,
  `chore(config): ...`).
- Push to `origin dev` promptly after each commit.
- Only commit when explicitly asked to — otherwise leave changes unstaged
  for the owner to review.

**Secrets**
- Never commit `*.tfvars`, `*.auto.tfvars`, `*.tfstate*`, private keys
  (`*.key`, `*.pem`), or anything containing live tokens/passwords — all
  must be `.gitignore`d.
- Always keep a sanitized `*.tfvars.example` alongside any real `.tfvars`.

**Terraform standards**
- Run `terraform fmt -check` and `terraform validate` before every commit
  touching `.tf` files.
- Keep configs modular: `providers.tf` / `variables.tf` / `main.tf` /
  `outputs.tf`.
- Every VM (template or clone) must use:
  - `machine = "q35"`
  - `bios = "ovmf"` with 4M EFI disk, `pre_enrolled_keys = true`
  - `scsi_hardware = "virtio-scsi-single"`
  - `ssd = true` + `discard = "on"` on disks
  - a `serial_device` socket (for `qm terminal <vmid>`)
  - storage split: downloaded images → `local-storage` (directory),
    VM disks/EFI → `local-lvm` (LVM-thin)

**Tool boundaries** (don't deviate without checking with the owner)
- Terraform/OpenTofu = provisions Proxmox objects only (template + clones).
- cloud-init = first-boot bootstrap only (guest agent + python3 for
  Ansible), nothing role-specific.
- Ansible = all configuration layering (base / role-specific / security).
- ArgoCD, Woodpecker, Packer = explicitly out of scope for now.

**Undecided — don't assume**
- OpenTofu vs Terraform has not been decided; either works with the current
  provider and file layout unchanged.
- The `security` Ansible role's contents are not researched yet.

## 3. Current state (verified)

```
homelab-config-automation/
├── CLAUDE.md
├── GEMINI.md                          # legacy rules doc, superseded by this file
├── Makefile                           # builds templates only; no instance/clone targets
├── README.md
├── docs/
│   ├── architecture.md
│   ├── proxmox-setup.md
│   ├── cloud-init-guide.md            # documents Method A/B; Method B now matches the real
│   │                                    proxmox_virtual_environment_file resource in instances/
│   └── adding-a-new-template.md
└── terraform/
    ├── templates/                     # Layer 1 — golden template builder
    │   ├── main.tf                    # for_each over local.active_templates (var.templates
    │   │                                filtered by var.active_templates); default active
    │   │                                set is just resolute (Ubuntu 26.04, vmid 9000).
    │   │                                noble/bookworm/trixie remain defined as opt-in.
    │   ├── variables.tf / outputs.tf / providers.tf
    │   └── terraform.tfvars.example
    ├── modules/vm-instance/           # Layer 2 module — clones a template into a sized VM
    │   ├── main.tf                    # fully parameterized: cores, memory, disk_size, ipv4,
    │   │                                vlan_id, ci_username, user_data_file_id, etc. — and,
    │   │                                since the fix below, machine/bios/efi_disk/scsi_hardware
    │   │                                match the golden template's hardware baseline.
    │   ├── variables.tf
    │   └── outputs.tf                 # exposes vm_id, name, ipv4_addresses
    ├── instances/                     # Layer 2 root module — clones the golden template
    │   ├── main.tf                    # uploads bootstrap.yaml snippet + for_each over `nodes`
    │   ├── variables.tf                #   nodes map: docker-ubuntu-node, k8s-ctrl-node1,
    │   │                                #   k8s-worker-node{1,2} — static IPs 10.10.10.50-53/24,
    │   │                                #   vmids 500-503, clone_vm_id default 9000
    │   ├── outputs.tf / providers.tf
    │   └── terraform.tfvars.example
    └── snippets/
        └── bootstrap.yaml             # minimal first-boot bootstrap: qemu-guest-agent + python3
                                          only, nothing role-specific — uploaded by instances/
```

Known gaps:
1. ~~`terraform/templates/main.tf` hardcoded 4 distros as copy-pasted resource
   blocks~~ — **done**: refactored to `for_each` over `var.templates`
   filtered by `var.active_templates` (default: `["resolute"]`). See
   `docs/adding-a-new-template.md` for the new map-entry workflow.
   Live-state migration for the 4 already-built templates is done too (8
   `terraform state mv` commands, verified with a clean `terraform plan`).
2. ~~`terraform/modules/vm-instance` existed but nothing called it~~ —
   **done**: `terraform/instances/` now calls it via `for_each` over the
   4-node map. While wiring this up, a real bug was found and fixed: the
   module never set `machine`/`bios`/`scsi_hardware`/`efi_disk`, so
   Terraform was explicitly overwriting every clone's inherited config with
   its own resource defaults (`bios=seabios`, `scsi_hardware=virtio-scsi-pci`,
   no EFI disk) instead of matching the OVMF/q35 golden template — confirmed
   via a live `terraform plan` against the real cluster before the fix.
   Fixed to match `templates/main.tf`'s baseline exactly.
3. ~~`terraform/snippets/*.yaml` were dead files, nothing set
   `user_data_file_id`~~ — **done**: replaced with one minimal
   `bootstrap.yaml` (qemu-guest-agent + python3 only), uploaded via a real
   `proxmox_virtual_environment_file` resource in `terraform/instances/`
   and wired into every node's `user_data_file_id`. (A prior fuller attempt
   — commits `4149041`..`1ee0ca4` — was reverted in `b99f6b8` because it
   mixed role-specific config into the snippet and delivered it via an
   out-of-band `scp` Makefile step instead of a real Terraform resource.
   Neither mistake was repeated: content stays bootstrap-only, delivery is
   a real `proxmox_virtual_environment_file` resource.)
4. There is no `ansible/` directory yet.
5. `terraform/instances/` is scaffolded and verified against the live
   cluster (`terraform plan`: 5 to add, 0 to change, 0 to destroy) but has
   **not been applied** — left for the owner to run. The assumed gateway
   `10.10.10.1` for all 4 nodes was not explicitly confirmed (only the IP
   range and vmid range were) — worth a glance in `variables.tf`'s `nodes`
   map before applying.

**Note on the templates live-state migration (superseded 2026-09-14):** the
narrowing decision flagged below as a separate/deliberate owner call has now
been made. The owner manually deleted all 4 template VMs in Proxmox outside
Terraform (to exercise a clean rebuild), and `terraform/templates/terraform.tfvars`
now sets `active_templates = ["resolute"]` — only Ubuntu 26.04 gets built
going forward; noble/bookworm/trixie stay defined in `variables.tf` as
opt-in but are no longer created by default. At the same time, all 4
template vmids were renumbered: `resolute` 9002→**9000**, `noble` 9000→9001,
`trixie` 9012→**9010**, `bookworm` 9010→9011. `terraform/instances/`'s
`clone_vm_id` (default and the real `terraform.tfvars` override) was updated
from 9002 to 9000 to match. A `terraform plan` in `templates/` now correctly
shows 1 to add (resolute only) and 0 to change/destroy — this was verified
after the edits below.

## 4. Planned / not yet implemented

**This is a design-discussion plan, not an approved backlog.** Nothing below
should be implemented without explicit go-ahead per step from the owner.

Goal: replace the "4 test templates" state with one low-spec golden Ubuntu
26.04 template, cloned into 4 differently-sized nodes, configured via
layered Ansible roles instead of ad-hoc cloud-init.

**Target node set** (Terraform Layer 2, driven by a map variable, not
hardcoded resources). IPs and vmid range confirmed with the owner:

| Node | Role | Cores | Memory | Disk | IPv4 | VMID |
|---|---|---|---|---|---|---|
| docker-ubuntu-node | docker | 6 | 8 GB | 50 GB | 10.10.10.50/24 | 500 |
| k8s-ctrl-node1 | k8s_control | 4 | 4 GB | 50 GB | 10.10.10.51/24 | 501 |
| k8s-worker-node1 | k8s_worker | 6 | 8 GB | 50 GB | 10.10.10.52/24 | 502 |
| k8s-worker-node2 | k8s_worker | 6 | 8 GB | 50 GB | 10.10.10.53/24 | 503 |

(IP/vmid assignment above is sequential in listed order — confirm before
implementing step 2 if a different mapping is wanted. Owner also confirmed:
static IPs, not DHCP; `clone_vm_id` hardcoded as a var default of `9000`
(renumbered 2026-09-14 — see the note above), not a `terraform_remote_state`
lookup into `templates/`'s state.)

**Structural changes planned, in reviewable order:**

1. ~~**`for_each` refactor of templates**~~ — **done.**
2. ~~**`terraform/instances/` scaffold**~~ — **done.** New root module
   (separate state from `templates/`) calls `vm-instance` via `for_each`
   over the `nodes` map, `clone_vm_id` defaulting to `9000`. Landed
   together with step 3 as planned. Verified against the live cluster
   (`terraform plan`: 5 to add, 0 to change, 0 to destroy) but **not
   applied** — left for the owner. While wiring this up, found and fixed a
   real bug in `vm-instance` (missing hardware baseline — see "Known gaps"
   #2 above).
3. ~~**cloud-init bootstrap fix**~~ — **done.** `base-ubuntu.yaml` /
   `base-debian.yaml` replaced by one minimal static `bootstrap.yaml`
   (qemu-guest-agent + python3 only), uploaded via a real
   `proxmox_virtual_environment_file` resource in `terraform/instances/`
   and wired into `user_data_file_id`. No templating needed — content is
   identical for every node under the "nothing role-specific" rule.
4. **Ansible scaffold** — new `ansible/` directory does everything
   currently described as "base config / node-specific config / security
   config":
   ```
   ansible/
   ├── ansible.cfg
   ├── inventories/prod.yml        # groups: docker, k8s_control, k8s_workers
   ├── group_vars/all.yml
   ├── playbooks/
   │   ├── site.yml                # base → role-specific → (import) security
   │   └── security.yml            # kept separate so it can be re-run independently
   └── roles/
       ├── base/                   # tmux, htop, qemu-guest-agent, figlet + generic motd
       ├── docker/                 # docker engine, user added to docker group, docker motd
       ├── k8s_control/            # control-plane prep + motd
       ├── k8s_worker/             # worker prep + motd
       └── security/               # empty placeholder — firewall/fail2ban not yet researched
   ```
5. **Makefile chain** — `apply` target becomes a chain:
   `terraform templates apply` (no-op if unchanged) → `terraform instances
   apply` → `ansible-playbook site.yml` — so one `make apply` does
   template-if-needed → clone → configure.

Do not start implementing any of these without explicit sign-off from the
owner on that specific step.
