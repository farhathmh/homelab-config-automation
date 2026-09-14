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
│   ├── cloud-init-guide.md            # documents a "Method B" (custom snippet via
│   │                                    user_data_file_id) that is NOT wired up in any .tf file
│   └── adding-a-new-template.md
└── terraform/
    ├── templates/                     # Layer 1 — golden template builder
    │   ├── main.tf                    # for_each over local.active_templates (var.templates
    │   │                                filtered by var.active_templates); default active
    │   │                                set is just resolute (Ubuntu 26.04, vmid 9002).
    │   │                                noble/bookworm/trixie remain defined as opt-in.
    │   ├── variables.tf / outputs.tf / providers.tf
    │   └── terraform.tfvars.example
    ├── modules/vm-instance/           # Layer 2 module — clones a template into a sized VM
    │   ├── main.tf                    # fully parameterized: cores, memory, disk_size, ipv4,
    │   │                                vlan_id, ci_username, user_data_file_id, etc.
    │   ├── variables.tf
    │   └── outputs.tf                 # ⚠ NOT INVOKED ANYWHERE — no root module calls this yet
    └── snippets/
        ├── base-ubuntu.yaml           # ⚠ DEAD FILE — never uploaded to Proxmox, never referenced
        └── base-debian.yaml           # ⚠ DEAD FILE — same issue
```

Known gaps:
1. ~~`terraform/templates/main.tf` hardcoded 4 distros as copy-pasted resource
   blocks~~ — **done**: refactored to `for_each` over `var.templates`
   filtered by `var.active_templates` (default: `["resolute"]`). See
   `docs/adding-a-new-template.md` for the new map-entry workflow.
   ⚠ **Live-state migration not yet done** — see note below.
2. `terraform/modules/vm-instance` exists and is fully wired for
   `user_data_file_id`, but nothing calls it — there is no root module that
   consumes it yet (no `terraform/instances/`).
3. `terraform/snippets/*.yaml` are written but not uploaded via
   `proxmox_virtual_environment_file`, and no `.tf` file sets
   `user_data_file_id` — cloned VMs currently get zero package installation
   from cloud-init beyond the built-in `user_account` block. (A prior attempt
   at this — commits `4149041`..`1ee0ca4` — was reverted in `b99f6b8` because
   it mixed role-specific config into the snippet and delivered it via an
   out-of-band `scp` Makefile step instead of a real
   `proxmox_virtual_environment_file` resource. Don't repeat either mistake.)
4. There is no `ansible/` directory yet.

**⚠ Pending: live-state migration for the templates `for_each` refactor.**
All 4 templates (vmid 9000/9002/9010/9012) are already built in Proxmox and
tracked in `terraform/templates/terraform.tfstate` under the old flat
resource addresses (e.g. `proxmox_virtual_environment_vm.ubuntu_2404_template`).
The new addresses are `proxmox_virtual_environment_vm.template["noble"]`
etc. Running `terraform apply` before remapping state will try to destroy
the old-address resources and create new ones at the same vmids — for
`ubuntu_2604_template`/`template["resolute"]` (same vmid 9002) this can
race or fail outright ("VM 9002 already exists"). Before any apply:
```bash
cd terraform/templates
terraform state mv 'proxmox_download_file.ubuntu_2404_cloud_image'  'proxmox_download_file.cloud_image["noble"]'
terraform state mv 'proxmox_download_file.ubuntu_2604_cloud_image'  'proxmox_download_file.cloud_image["resolute"]'
terraform state mv 'proxmox_download_file.debian_12_cloud_image'    'proxmox_download_file.cloud_image["bookworm"]'
terraform state mv 'proxmox_download_file.debian_13_cloud_image'    'proxmox_download_file.cloud_image["trixie"]'
terraform state mv 'proxmox_virtual_environment_vm.ubuntu_2404_template' 'proxmox_virtual_environment_vm.template["noble"]'
terraform state mv 'proxmox_virtual_environment_vm.ubuntu_2604_template' 'proxmox_virtual_environment_vm.template["resolute"]'
terraform state mv 'proxmox_virtual_environment_vm.debian_12_template'   'proxmox_virtual_environment_vm.template["bookworm"]'
terraform state mv 'proxmox_virtual_environment_vm.debian_13_template'   'proxmox_virtual_environment_vm.template["trixie"]'
terraform plan   # must show "No changes" once active_templates covers all 4
```
`terraform.tfvars` currently overrides `active_templates` to all 4 so a plan
stays a no-op during this transition. Narrowing to just `["resolute"]` for
real (to actually destroy noble/bookworm/trixie in Proxmox, freeing vmids
9000/9010/9012) is a separate, deliberate decision — do it with
`terraform plan` reviewed first, not as a side effect of this refactor.

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
static IPs, not DHCP; `clone_vm_id` hardcoded as a var default of `9002`,
not a `terraform_remote_state` lookup into `templates/`'s state.)

**Structural changes planned, in reviewable order:**

1. ~~**`for_each` refactor of templates**~~ — **done.** See section 3's
   "Known gaps" #1 for the live-state migration still required before the
   next `terraform apply` in `templates/`.
2. **`terraform/instances/` scaffold** — new root module (separate
   Terraform state from `templates/`, since template and instance
   lifecycles differ) that calls the existing `vm-instance` module via
   `for_each` over a `nodes` map (the table above), with `clone_vm_id`
   defaulting to `9002`. Needs a `proxmox_virtual_environment_file` upload
   for the bootstrap snippet (step 3) to be functionally complete — plan to
   land 2 and 3 together, not strictly sequentially.
3. **cloud-init bootstrap fix** — `terraform/snippets/base-ubuntu.yaml` /
   `base-debian.yaml` → replaced by one minimal static `bootstrap.yaml`
   (no templating needed — content is identical for every node under the
   "nothing role-specific" rule below), uploaded via
   `proxmox_virtual_environment_file`, wired into `user_data_file_id`. Its
   only job: `qemu-guest-agent` + `python3` (so Ansible can reach the box) +
   enabling the agent. Nothing role-specific goes here — see the reverted
   `erenyx-base.yaml` attempt noted in section 3's "Known gaps" #3 for what
   NOT to do (no `users:`, no groups, no MOTD/write_files in this snippet).
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
