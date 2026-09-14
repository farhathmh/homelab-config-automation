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
  - Changes on `dev` may only be merged into `main` once all tests and validations pass (e.g., `packer validate`, successful test builds, and linting).
  - Merges into `main` must be clean, verified, and pushed to the remote repository.

---

## 2. Git Commit & Staging Rules

- **Granular Commits**:
  - Stage and commit files granularly (`git add <file>` followed by `git commit`).
  - Do not batch unrelated files or multiple disparate configuration updates into a single omnibus commit.
- **Descriptive Commit Messages**:
  - Every commit must have a descriptive, conventional commit message clearly explaining the purpose of the change (e.g., `feat(http): ...`, `fix(template): ...`, `chore(config): ...`).
- **Prompt Remote Synchronization**:
  - Push committed updates to the remote repository (`origin dev`) promptly after committing.

---

## 3. Credential Safety & Zero Leak Policy

- **No Secret Commits**:
  - Files matching `*.auto.pkrvars.hcl`, `secrets.*`, private keys (`*.key`, `*.pem`), or any files containing live API tokens/passwords must never be tracked or committed to Git.
  - All secret variable files must be listed in `.gitignore` and kept exclusively on local disk.
- **Sanitized Examples**:
  - Always provide and track sanitized example templates (e.g., `secrets.example.pkrvars.hcl`) with dummy values for documentation and onboarding.

---

## 4. Packer & Infrastructure Standards

- **Pre-Commit Validation**:
  - Always run `packer validate -var-file=...` against the target template directory before committing Packer configuration updates.
- **Modularity & Standards**:
  - Align with official HashiCorp Packer and provider documentation.
  - Keep configuration files modular (`plugins.pkr.hcl`, `variables.pkr.hcl`, `builds.pkr.hcl`, and individual distro templates).
