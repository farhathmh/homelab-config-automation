# ==============================================================================
# Homelab Automation: Proxmox Cloud Template, Instance & Config Management
# ==============================================================================

SHELL := /bin/bash
TEMPLATES_DIR := terraform/templates
INSTANCES_DIR := terraform/instances
MODULES_DIR := terraform/modules/vm-instance
ANSIBLE_DIR := ansible

.PHONY: help init fmt validate \
	plan plan-templates plan-instances \
	apply apply-auto \
	apply-templates apply-templates-auto \
	apply-noble apply-resolute apply-bookworm apply-trixie \
	apply-instances apply-instances-auto \
	apply-ansible \
	destroy-templates destroy-instances \
	status-templates status-instances

.DEFAULT_GOAL := help

help: ## Display this help menu
	@echo "======================================================================"
	@echo " Proxmox VE Homelab Automation Menu"
	@echo "======================================================================"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform providers for both the templates and instances layers
	terraform -chdir=$(TEMPLATES_DIR) init
	terraform -chdir=$(INSTANCES_DIR) init

fmt: ## Format check all Terraform files across the repository
	terraform fmt -recursive

validate: ## Validate Terraform (templates, module, instances) and syntax-check Ansible playbooks
	terraform -chdir=$(TEMPLATES_DIR) validate
	terraform -chdir=$(MODULES_DIR) validate
	terraform -chdir=$(INSTANCES_DIR) validate
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/site.yml --syntax-check
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/security.yml --syntax-check

# --- Layer 1: Golden Templates (terraform/templates) ---

plan-templates: ## Show execution plan for the active template set (default: Resolute only)
	terraform -chdir=$(TEMPLATES_DIR) plan

apply-templates: ## Build the active template set (default: Resolute only; interactive confirmation)
	terraform -chdir=$(TEMPLATES_DIR) apply

apply-templates-auto: ## Build the active template set without confirmation prompt
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

destroy-templates: ## Destroy all templates (destructive)
	terraform -chdir=$(TEMPLATES_DIR) destroy

status-templates: ## Show generated template IDs and resource attributes
	terraform -chdir=$(TEMPLATES_DIR) output

# --- Layer 2: Instances (terraform/instances) ---

plan-instances: ## Show execution plan for cloning the golden template into the node set
	terraform -chdir=$(INSTANCES_DIR) plan

apply-instances: ## Clone the golden template into the node set (interactive confirmation)
	terraform -chdir=$(INSTANCES_DIR) apply

apply-instances-auto: ## Clone the golden template into the node set without confirmation prompt
	terraform -chdir=$(INSTANCES_DIR) apply -auto-approve

destroy-instances: ## Destroy all cloned instance nodes (destructive)
	terraform -chdir=$(INSTANCES_DIR) destroy

status-instances: ## Show cloned instance VM IDs and IP addresses
	terraform -chdir=$(INSTANCES_DIR) output

# --- Layer 3: Configuration (ansible/) ---

apply-ansible: ## Run the Ansible site playbook (base -> role config -> security) against the node set
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/site.yml

# --- Combined plan/apply across layers ---

plan: plan-templates plan-instances ## Show execution plans for both Terraform layers

# `apply`/`apply-auto` touch three layers in sequence: template (no-op if
# unchanged) -> clone nodes -> configure via Ansible. Each Terraform step
# still asks for its own confirmation unless you use the -auto variant;
# there is deliberately no combined destroy target — tear down each layer
# explicitly via destroy-instances / destroy-templates.
apply: apply-templates apply-instances apply-ansible ## Full chain: build template if needed, clone nodes, configure via Ansible

apply-auto: apply-templates-auto apply-instances-auto apply-ansible ## Full chain with Terraform auto-approve (Ansible always runs unprompted)
