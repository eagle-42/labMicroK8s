include ../common.mk
.PHONY: init install validate clean kill

init: ## Create .env from the example
	@test -f .env && echo ".env already exists" || { cp .env.example .env; echo "created .env, set VM_HOST in it"; }

install: ## Install MicroK8s and the security baseline on the VM
	@test -n "$(VM_HOST)" || { echo "VM_HOST unset: run make init first" >&2; exit 1; }
	scp -r kustomize install.sh $(VM_HOST):~/
	ssh $(VM_HOST) "chmod +x ~/install.sh && ~/install.sh"

validate: ## Show what the baseline deployed
	@$(call kube,get namespace labs)
	@$(call kube,get networkpolicy$(,)resourcequota$(,)limitrange -n labs)

clean: ## Remove the module files from the VM
	ssh $(VM_HOST) "rm -rf ~/kustomize ~/install.sh"

kill: ## Delete the labs namespace and everything in it
	@printf 'delete namespace labs on $(VM_HOST)? [y/N] '; read -r a; [ "$$a" = y ]
	@$(call kube,delete namespace labs)

, := ,
