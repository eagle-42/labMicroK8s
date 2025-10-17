.PHONY: init install validate security-check clean stop kill help

# Load environment variables
include .env
export

help: ## Show this help message
	@echo "K8SLab - Module 00: Installation"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Copy .env.example to .env (run this first)
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✅ Created .env file - please update VM_HOST if needed"; \
	else \
		echo "⚠️  .env already exists"; \
	fi

install: ## Install MicroK8s and deploy secure namespace on VM
	@echo "📦 Installing K8SLab on $(VM_HOST)..."
	scp -r kustomize $(VM_HOST):~/
	scp install.sh $(VM_HOST):~/
	ssh $(VM_HOST) "chmod +x ~/install.sh && ~/install.sh"
	@echo ""
	@echo "✅ Installation complete!"

validate: ## Validate the deployment
	@echo "🔍 Validating K8SLab deployment..."
	@ssh $(VM_HOST) "sg microk8s -c 'microk8s kubectl get namespace labs'"
	@echo ""
	@ssh $(VM_HOST) "sg microk8s -c 'microk8s kubectl get networkpolicies -n labs'"
	@echo ""
	@ssh $(VM_HOST) "sg microk8s -c 'microk8s kubectl get resourcequota -n labs'"
	@echo ""
	@ssh $(VM_HOST) "sg microk8s -c 'microk8s kubectl get limitrange -n labs'"

security-check: ## Run security validation tests
	@echo "🔒 Running security checks..."
	@echo ""
	@echo "1️⃣  Testing Pod Security Standards (should FAIL - restricted mode)..."
	@ssh $(VM_HOST) "sg microk8s -c 'microk8s kubectl run test-privileged --image=nginx --privileged -n labs'" || echo "✅ Privileged pods blocked as expected"
	@echo ""
	@echo "2️⃣  Testing Network Policy (should timeout - default deny)..."
	@ssh $(VM_HOST) "sg microk8s -c 'microk8s kubectl run test-netpol --image=busybox --rm -i -n labs -- timeout 5 wget -O- http://google.com'" || echo "✅ External traffic blocked as expected"
	@echo ""
	@echo "3️⃣  Checking Resource Quotas..."
	@ssh $(VM_HOST) "sg microk8s -c 'microk8s kubectl describe resourcequota -n labs'"

clean: ## Remove installation files from VM
	@echo "🧹 Cleaning up VM..."
	ssh $(VM_HOST) "rm -rf ~/kustomize ~/install.sh ~/configure-k8slab.sh ~/install-k8slab.sh ~/install-microk8s.sh && ls ~/"
	@echo "✅ Cleanup complete"

stop: ## Stop MicroK8s on VM (requires manual SSH)
	@echo "⚠️  To stop MicroK8s, run manually:"
	@echo "   ssh $(VM_HOST)"
	@echo "   sudo microk8s stop"

kill: ## Delete the labs namespace (destroys all resources)
	@echo "💥 Deleting labs namespace..."
	ssh $(VM_HOST) "sg microk8s -c 'microk8s kubectl delete namespace labs'"
	@echo "✅ Namespace deleted"
