# How to Add a New Distribution Template

`terraform/templates/main.tf` builds golden templates with a single
`for_each` over `var.active_templates`, sourced from the `var.templates` map
in `variables.tf`. Adding a new distro (or opting an existing one into an
apply) no longer means copy-pasting a resource block — it means adding or
enabling one map entry.

---

## 1. Upstream Official Cloud Image Sources

Always source minimal generic cloud images directly from official vendor
distribution mirrors:

| Distribution | Official Image URL Format | Recommended VM ID |
| :--- | :--- | :--- |
| **Ubuntu 24.04 LTS** | `https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img` | `9000` |
| **Ubuntu 26.04 LTS** | `https://cloud-images.ubuntu.com/resolute/current/resolute-server-cloudimg-amd64.img` | `9002` |
| **Debian 12 Bookworm** | `https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2` | `9010` |
| **Debian 13 Trixie** | `https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-genericcloud-amd64-daily.qcow2` | `9012` |
| **Fedora 40/41 Cloud** | `https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/...` | `9020` |
| **Rocky Linux 9** | `https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2` | `9030` |
| **Alpine Linux 3.20** | `https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/cloud/generic-alpine-3.20.0-x86_64-bios.qcow2` | `9040` |

Pick a VM ID that doesn't collide with any entry already in `var.templates`
(check `variables.tf`).

---

## 2. Onboarding Workflow

### Step 1: Add an entry to the `templates` map
In `terraform/templates/variables.tf`, add a new key under `variable
"templates" { default = { ... } }`:

```hcl
rocky = {
  vmid            = 9030
  file_name       = "rocky-9-genericcloud-amd64.qcow2"
  cloud_image_url = "https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
  display_name    = "rocky-9-cloud-template"
  description     = "Rocky Linux 9 Cloud-Init Template (Q35, OVMF UEFI, VirtIO SCSI Single) built by Terraform"
}
```

That's it for `main.tf` — the `for_each` picks up any key present in
`var.templates` automatically once it's also listed in
`var.active_templates`. No new resource blocks, no new outputs.

### Step 2: Opt the new entry into an apply
The new key stays inert (opt-in, not built) until it's included in
`active_templates`, either:

- one-off, via the CLI: `terraform apply -var='active_templates=["rocky"]'`
  (note this **replaces** the active set, not adds to it — see the warning
  in the Makefile's per-distro targets)
- persistently, by adding it to `terraform.tfvars`:
  `active_templates = ["resolute", "rocky"]`
- as a permanent Makefile shortcut, by adding a target following the pattern
  of `apply-noble` / `apply-resolute` / `apply-bookworm` / `apply-trixie`

### Step 3: Validate, Plan, and Deploy
```bash
terraform -chdir=terraform/templates fmt
terraform -chdir=terraform/templates validate
terraform -chdir=terraform/templates plan
terraform -chdir=terraform/templates apply
```

Review the plan carefully: since `active_templates` controls the entire
`for_each` set, any currently-built template whose key isn't in the set you
pass is proposed for **destruction**, not just "left alone."

---

## 3. Reference: the hardware baseline every template inherits

All entries in `var.templates` are built through the same resource block in
`main.tf`, so every template automatically gets the repo's standard
baseline: `machine = "q35"`, `bios = "ovmf"` (4M EFI, `pre_enrolled_keys =
true`), `scsi_hardware = "virtio-scsi-single"`, `ssd = true` + `discard =
"on"`, a `serial_device` socket, and the `local-storage` (image download) /
`local-lvm` (disk + EFI) storage split. There's nothing to configure
per-distro beyond the map entry itself — if a new distro needs different
hardware, that's a signal it should be a separate resource, not a map entry.
