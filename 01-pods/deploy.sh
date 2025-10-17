#!/bin/bash
# K8SLab - Module 01: Pods deployment script
# Deploys secure pods with health probes and security contexts

set -euo pipefail

echo "🚀 K8SLab Module 01: Pods - DevSecOps Edition"
echo ""

# Check if running on correct system
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "❌ This script must run on Linux (Ubuntu)"
    exit 1
fi

# Check if MicroK8s is installed
if ! command -v microk8s >/dev/null 2>&1; then
    echo "❌ MicroK8s not found. Run module 00-install first."
    exit 1
fi

# Check if labs namespace exists
if ! microk8s kubectl get namespace labs &>/dev/null; then
    echo "❌ Namespace 'labs' not found. Run module 00-install first."
    exit 1
fi

# Deploy pods
echo "📦 Deploying secure pods to labs namespace..."
microk8s kubectl apply -k kustomize/

# Wait for pod to be ready
echo ""
echo "⏳ Waiting for pod to be ready..."
microk8s kubectl wait --for=condition=Ready pod -n labs -l module=01-pods --timeout=60s

# Verify deployment
echo ""
echo "✅ Deployment complete! Verifying..."
echo ""
microk8s kubectl get pods -n labs -l module=01-pods

echo ""
echo "🔍 Pod details:"
microk8s kubectl describe pod -n labs -l module=01-pods | grep -A 5 "Name:\|Status:\|Security Context:\|Liveness:\|Readiness:"

echo ""
echo "🎉 Success! Module 01 pods are running."
echo ""
echo "Next steps:"
echo "  - View logs: kubectl logs -n labs -l module=01-pods"
echo "  - Exec into pod: kubectl exec -it -n labs <pod-name> -- /bin/sh"
echo "  - Run security check: make security-check"
