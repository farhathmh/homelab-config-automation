# ==============================================================================
# Homelab Automation: Proxmox Cloud Template Management
# ==============================================================================

SHELL := /bin/bash
TEMPLATES_DIR := terraform/templates
MODULES_DIR := terraform/modules/vm-instance
SNIPPET_FILE := terraform/snippets/erenyx-base.yaml
PVE_HOST := 10.10.10.10
PVE_SNIPPETS_DIR := /mnt/local-storage/snippets

.PHONY: help init plan apply apply-auto apply-ubuntu-24 apply-ubuntu-26 apply-debian-12 apply-debian-13 sync-snippets destroy fmt validate status

.DEFAULT_GOAL := help

help: ## Display this help menu
	@echo "======================================================================"
	@echo " Proxmox VE Cloud Templates Automation Menu"
	@echo "======================================================================"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform provider and modules
	terraform -chdir=$(TEMPLATES_DIR) init

fmt: ## Format check all Terraform files across the repository
	terraform fmt -recursive

validate: ## Validate Terraform syntax and configurations
	terraform -chdir=$(TEMPLATES_DIR) validate
	terraform -chdir=$(MODULES_DIR) validate

sync-snippets: ## Synchronize Cloud-Init snippet to Proxmox local-storage
	@echo "==> Synchronizing Cloud-Init snippet to Proxmox ($(PVE_HOST):$(PVE_SNIPPETS_DIR))..."
	@ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$(PVE_HOST) "mkdir -p $(PVE_SNIPPETS_DIR) && rm -f /var/lib/vz/snippets/erenyx-base.yaml"
	@scp -o StrictHostKeyChecking=no -o ConnectTimeout=5 $(SNIPPET_FILE) root@$(PVE_HOST):$(PVE_SNIPPETS_DIR)/erenyx-base.yaml
	@echo "==> Snippet synced: local-storage:snippets/erenyx-base.yaml (/mnt/local-storage/snippets/erenyx-base.yaml)"

plan: sync-snippets ## Show execution plan for all 4 cloud templates
	terraform -chdir=$(TEMPLATES_DIR) plan

apply: sync-snippets ## Build and configure all 4 cloud templates (interactive confirmation)
	terraform -chdir=$(TEMPLATES_DIR) apply

apply-auto: sync-snippets ## Build and configure all 4 cloud templates without confirmation prompt
	terraform -chdir=$(TEMPLATES_DIR) apply -auto-approve

apply-ubuntu-24: sync-snippets ## Build only the Ubuntu 24.04 LTS (Noble) template
	terraform -chdir=$(TEMPLATES_DIR) apply -target=proxmox_virtual_environment_vm.ubuntu_2404_template

apply-ubuntu-26: sync-snippets ## Build only the Ubuntu 26.04 LTS (Resolute) template
	terraform -chdir=$(TEMPLATES_DIR) apply -target=proxmox_virtual_environment_vm.ubuntu_2604_template

apply-debian-12: sync-snippets ## Build only the Debian 12 (Bookworm) template
	terraform -chdir=$(TEMPLATES_DIR) apply -target=proxmox_virtual_environment_vm.debian_12_template

apply-debian-13: sync-snippets ## Build only the Debian 13 (Trixie) template
	terraform -chdir=$(TEMPLATES_DIR) apply -target=proxmox_virtual_environment_vm.debian_13_template

destroy: ## Destroy all templates (destructive)
	terraform -chdir=$(TEMPLATES_DIR) destroy

status: ## Show generated template IDs and resource attributes
	terraform -chdir=$(TEMPLATES_DIR) output
