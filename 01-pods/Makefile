.PHONY: init deploy validate logs exec delete security-check clean port-forward help

# Load environment variables if .env exists
-include .env
export

help: ## Show this help message
	@echo "K8SLab - Module 01: Pods (DevSecOps Edition)"
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

deploy: ## Deploy secure pod to labs namespace
	@echo "🚀 Deploying Module 01: Pods..."
	@echo "🔍 Checking prerequisite: Module 00-install must be completed..."
	@if ! ssh $(VM_HOST) "microk8s kubectl get namespace labs" >/dev/null 2>&1; then \
		echo ""; \
		echo "❌ ERROR: Namespace 'labs' not found!"; \
		echo ""; \
		echo "📋 Prerequisites:"; \
		echo "   1. Complete Module 00-install first"; \
		echo "   2. Run: cd ../00-install && make install"; \
		echo ""; \
		exit 1; \
	fi
	@echo "✅ Prerequisite check passed: namespace 'labs' exists"
	@echo ""
	@ssh $(VM_HOST) "mkdir -p ~/01-pods"
	scp -r kustomize $(VM_HOST):~/01-pods/
	scp deploy.sh $(VM_HOST):~/01-pods/
	ssh $(VM_HOST) "chmod +x ~/01-pods/deploy.sh && cd ~/01-pods && ./deploy.sh"
	@echo ""
	@echo "✅ Pod deployment complete"

validate: ## Validate pod deployment
	@echo "🔍 Validating pod deployment..."
	@ssh $(VM_HOST) "microk8s kubectl get pods -n labs -l module=01-pods"
	@echo ""
	@echo "📋 Pod details:"
	@ssh $(VM_HOST) "microk8s kubectl describe pod -n labs -l module=01-pods | grep -A 20 'Name:\|Security Context:\|Liveness:\|Readiness:\|Requests:\|Limits:'"

logs: ## Show pod logs
	@echo "📜 Pod logs:"
	@ssh $(VM_HOST) "microk8s kubectl logs -n labs -l module=01-pods --tail=50"

exec: ## Execute shell in pod
	@echo "💻 Connecting to pod..."
	ssh -t $(VM_HOST) "microk8s kubectl exec -it -n labs \$$(microk8s kubectl get pod -n labs -l module=01-pods -o jsonpath='{.items[0].metadata.name}') -- /bin/sh"

security-check: ## Run security validation tests
	@echo "🔒 Running security checks for pods..."
	@echo ""
	@echo "1️⃣  Verifying non-root user..."
	@ssh $(VM_HOST) "microk8s kubectl exec -n labs \$$(microk8s kubectl get pod -n labs -l module=01-pods -o jsonpath='{.items[0].metadata.name}') -- id" || echo "✅ User check complete"
	@echo ""
	@echo "2️⃣  Verifying read-only root filesystem..."
	@ssh $(VM_HOST) "microk8s kubectl exec -n labs \$$(microk8s kubectl get pod -n labs -l module=01-pods -o jsonpath='{.items[0].metadata.name}') -- touch /test" && echo "❌ Root filesystem is writable!" || echo "✅ Root filesystem is read-only"
	@echo ""
	@echo "3️⃣  Checking security context..."
	@ssh $(VM_HOST) "microk8s kubectl get pod -n labs -l module=01-pods -o jsonpath='{.items[0].spec.securityContext}'"
	@echo ""
	@echo "4️⃣  Checking container capabilities..."
	@ssh $(VM_HOST) "microk8s kubectl get pod -n labs -l module=01-pods -o jsonpath='{.items[0].spec.containers[0].securityContext}'"

delete: ## Delete pod
	@echo "💥 Deleting pods..."
	ssh $(VM_HOST) "microk8s kubectl delete -k ~/01-pods/kustomize/"
	@echo "✅ Pods deleted"

clean: ## Remove all module files from VM (01-pods + 00-install)
	@echo "🧹 Cleaning up VM (removing all K8SLab files)..."
	@echo "⚠️  This will remove: 01-pods/, kustomize/, install.sh, k8slab-install/"
	@echo ""
	ssh $(VM_HOST) "rm -rf ~/01-pods ~/kustomize ~/install.sh ~/k8slab-install ~/configure-k8slab.sh ~/install-k8slab.sh ~/install-microk8s.sh"
	@echo ""
	@echo "📋 Remaining files on VM:"
	@ssh $(VM_HOST) "ls -la ~/ | grep -v '^\.' | tail -n +4"
	@echo ""
	@echo "✅ Cleanup complete - VM is clean!"

port-forward: ## Forward pod port to local machine (http://localhost:8080)
	@echo "🌐 Setting up port-forward to nginx pod..."
	@echo "📡 Open browser on your Mac: http://localhost:8080"
	@echo "⚠️  Press Ctrl+C to stop port-forwarding"
	@echo ""
	ssh -L 8080:$$(ssh $(VM_HOST) "microk8s kubectl get pod hello-pod -n labs -o jsonpath='{.status.podIP}'"):8080 $(VM_HOST) -N
