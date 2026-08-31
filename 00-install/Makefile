include ../common.mk   # also defines: help, security-check and test

# kubectl takes its types comma-separated, and $(call) splits on the commas it can
# see - but not on commas that arrive through a variable.
BASELINE := networkpolicy,resourcequota,limitrange

# Everything this repo puts on the VM, listed rather than globbed: a wildcard
# interpolated into a remote shell is what the VM_HOST guard exists to prevent.
VM_FILES := ~/00-install-kustomize ~/01-pods-kustomize ~/02-services-kustomize \
            ~/install.sh ~/traefik.sh ~/traefik-values.yaml
.PHONY: init install deploy validate kill dashboard

init: ## Create .env from the example
	@test -f .env && echo ".env already exists" || { cp .env.example .env; echo "created .env, set VM_HOST in it"; }

install: ## Install MicroK8s and the security baseline on the VM
	@test -n "$(VM_HOST)" || { echo "VM_HOST unset: run make init first" >&2; exit 1; }
	@# Purged before it is written, like `kill` purges: an install is meant to start
	@# from nothing, and a file the repo stopped shipping would otherwise stay forever.
	ssh '$(VM_HOST)' 'rm -rf ~/$(MODULE)-kustomize ~/install.sh ~/traefik.sh ~/traefik-values.yaml'
	scp -qr kustomize '$(VM_HOST)':~/$(MODULE)-kustomize
	scp -q install.sh traefik.sh traefik-values.yaml '$(VM_HOST)':~/
	ssh '$(VM_HOST)' "chmod +x ~/install.sh ~/traefik.sh && ~/install.sh ~/$(MODULE)-kustomize"

deploy: ## Re-apply the baseline, without reinstalling MicroK8s
	@$(apply)

validate: ## Show what the baseline deployed
	@$(call kube,get namespace labs)
	@$(call kube,get $(BASELINE) -n labs)

kill: ## Tear the lab down: its namespaces, its ingress, and its files on the VM
	@test -n "$(VM_HOST)" || { echo "VM_HOST unset: run make init first" >&2; exit 1; }
	@printf 'tear down the lab on $(VM_HOST), files included? [y/N] '; read -r a; [ "$$a" = y ]
	@$(call kube,delete namespace labs --ignore-not-found)
	@# helm, not just `delete namespace ingress`: the release owns a ClusterRole, a
	@# ClusterRoleBinding and the `public` IngressClass, none of which live in it.
	@ssh '$(VM_HOST)' "sg microk8s -c 'microk8s helm3 uninstall traefik -n ingress --ignore-not-found'"
	@$(call kube,delete namespace ingress --ignore-not-found)
	@ssh '$(VM_HOST)' 'rm -rf $(VM_FILES)'

dashboard: ## Print the tunnel command for the Traefik dashboard
	@test -n "$(VM_HOST)" || { echo "no VM: the cluster is this machine" >&2; exit 1; }
	@test -n "$(GATEWAY)" || { echo "GATEWAY unset in .env: the ssh alias your workstation uses to reach this machine" >&2; exit 1; }
	@# One line, ending here rather than on the VM: the workstation that needs the
	@# tunnel has no key on the node, and this machine already reaches it.
	@node=$$(ssh -G '$(VM_HOST)' | awk '/^hostname /{print $$2}'); \
	 test -n "$$node" || { echo "cannot resolve $(VM_HOST) from ~/.ssh/config" >&2; exit 1; }; \
	 echo "ssh -N -L 8080:$$node:80 $(GATEWAY)"; \
	 echo "then open http://dashboard.localhost:8080/dashboard/"
