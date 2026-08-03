# Included by every module. A module declares only the verb it is about.
-include $(dir $(lastword $(MAKEFILE_LIST)))00-install/.env
export

# One code path, two targets. With VM_HOST the cluster is a remote VM and the
# manifests travel; without it the cluster is this machine, as in CI.
ifeq ($(strip $(VM_HOST)),)
  kube  = sudo microk8s kubectl $(1)
  apply = sudo microk8s kubectl apply -k kustomize/
else
  kube  = ssh $(VM_HOST) "sg microk8s -c 'microk8s kubectl $(1)'"
  apply = scp -qr kustomize $(VM_HOST):~/$(notdir $(CURDIR))-kustomize \
          && $(call kube,apply -k ~/$(notdir $(CURDIR))-kustomize/)
endif

.PHONY: help security-check

help: ## Show this help
	@grep -hE '^[a-z-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/\t/' | column -ts$$'\t'

security-check: ## Assert the controls of this module still hold
	@bash security-check.sh $(VM_HOST)
