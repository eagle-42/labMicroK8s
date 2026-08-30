include ../common.mk
.PHONY: deploy validate delete

deploy: ## Expose the pod through a Service and an Ingress
	@$(call kube,get pod hello-pod -n labs) >/dev/null || { echo "run make deploy in 01-pods" >&2; exit 1; }
	@$(apply)

validate: ## Show the service, the ingress and the policy that lets it through
	@$(call kube,get service$(,)ingress$(,)networkpolicy -n labs)

delete: ## Remove the service, the ingress and the policy
	@$(call kube,delete service/hello ingress/hello networkpolicy/allow-ingress-controller -n labs --ignore-not-found)

, := ,
