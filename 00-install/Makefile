include ../common.mk   # also defines: help, security-check and test

# kubectl takes its types comma-separated, and $(call) splits on the commas it can
# see - but not on commas that arrive through a variable.
BASELINE := networkpolicy,resourcequota,limitrange
.PHONY: init install deploy validate kill dashboard

init: ## Create .env from the example
	@test -f .env && echo ".env already exists" || { cp .env.example .env; echo "created .env, set VM_HOST in it"; }

install: ## Install MicroK8s and the security baseline on the VM
	@test -n "$(VM_HOST)" || { echo "VM_HOST unset: run make init first" >&2; exit 1; }
	@# One destination, the name `apply` uses: two copies on the VM meant `install` and
	@# `deploy` could apply different manifests.
	ssh '$(VM_HOST)' 'rm -rf ~/$(MODULE)-kustomize'
	scp -qr kustomize '$(VM_HOST)':~/$(MODULE)-kustomize
	scp -q install.sh traefik.sh traefik-values.yaml '$(VM_HOST)':~/
	ssh '$(VM_HOST)' "chmod +x ~/install.sh ~/traefik.sh && ~/install.sh ~/$(MODULE)-kustomize"

deploy: ## Re-apply the baseline, without reinstalling MicroK8s
	@$(apply)

validate: ## Show what the baseline deployed
	@$(call kube,get namespace labs)
	@$(call kube,get $(BASELINE) -n labs)

kill: ## Delete the labs namespace and everything in it
	@printf 'delete namespace labs on $(VM_HOST)? [y/N] '; read -r a; [ "$$a" = y ]
	@$(call kube,delete namespace labs)

dashboard: ## Print the tunnel command for the Traefik dashboard
	@test -n "$(VM_HOST)" || { echo "no VM: the cluster is this machine" >&2; exit 1; }
	@# Prints, holds nothing: the tunnel belongs to the machine with the browser, and
	@# a target that holds it on the machine with the repo helps neither.
	@node=$$(ssh -G '$(VM_HOST)' | awk '/^hostname /{print $$2}'); \
	 test -n "$$node" || { echo "cannot resolve $(VM_HOST) from ~/.ssh/config" >&2; exit 1; }; \
	 echo "Run one of these where the browser is, then open"; \
	 echo "    http://dashboard.localhost:8080/dashboard/"; \
	 echo; \
	 echo "    ssh -N -L 8080:$$node:80 $(VM_HOST)"; \
	 echo "    ssh -N -L 8080:$$node:80 $${GATEWAY:-$$(hostname)}   # if that host is out of reach"
