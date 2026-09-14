# ==============================================================================
# Homelab Automation: Proxmox Cloud Template Management
# ==============================================================================

SHELL := /bin/bash
TEMPLATES_DIR := terraform/templates
MODULES_DIR := terraform/modules/vm-instance

.PHONY: help init plan apply apply-auto apply-noble apply-resolute apply-bookworm apply-trixie destroy fmt validate status

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

plan: ## Show execution plan for the active template set (default: Resolute only)
	terraform -chdir=$(TEMPLATES_DIR) plan

apply: ## Build the active template set (default: Resolute only; interactive confirmation)
	terraform -chdir=$(TEMPLATES_DIR) apply

apply-auto: ## Build the active template set without confirmation prompt
	terraform -chdir=$(TEMPLATES_DIR) apply -auto-approve

# NOTE: these override active_templates to EXACTLY the one distro named, not
# add to it — review the printed plan before confirming, since a template
# left out of the override set is proposed for destruction if it currently
# exists in state.
apply-noble: ## Build only the Ubuntu 24.04 LTS (Noble) template (opt-in)
	terraform -chdir=$(TEMPLATES_DIR) apply -var='active_templates=["noble"]'

apply-resolute: ## Build only the Ubuntu 26.04 LTS (Resolute) template (default active)
	terraform -chdir=$(TEMPLATES_DIR) apply -var='active_templates=["resolute"]'

apply-bookworm: ## Build only the Debian 12 (Bookworm) template (opt-in)
	terraform -chdir=$(TEMPLATES_DIR) apply -var='active_templates=["bookworm"]'

apply-trixie: ## Build only the Debian 13 (Trixie) template (opt-in)
	terraform -chdir=$(TEMPLATES_DIR) apply -var='active_templates=["trixie"]'

destroy: ## Destroy all templates (destructive)
	terraform -chdir=$(TEMPLATES_DIR) destroy

status: ## Show generated template IDs and resource attributes
	terraform -chdir=$(TEMPLATES_DIR) output
