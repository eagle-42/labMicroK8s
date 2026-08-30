include ../common.mk   # also defines: help, security-check and test
.PHONY: deploy validate exec delete

POD := hello-pod

deploy: ## Deploy the pod into the labs namespace
	@$(call kube,get namespace labs) >/dev/null || { echo "run make install in 00-install" >&2; exit 1; }
	@$(apply)
	@$(call kube,wait --for=condition=Ready pod/$(POD) -n labs --timeout=60s)

validate: ## Show the pod and the controls it declares
	@$(call kube,get pod $(POD) -n labs -o wide)
	@$(call kube,get pod $(POD) -n labs -o jsonpath={.spec.securityContext})
	@echo
	@$(call kube,get pod $(POD) -n labs -o jsonpath={.spec.containers[0].securityContext})
	@echo

exec: ## Open a shell in the pod
	@$(call kube,exec -it $(POD) -n labs -- /bin/sh,-tt)

delete: ## Delete the pod
	@$(call kube,delete pod $(POD) -n labs --ignore-not-found)
