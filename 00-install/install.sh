#!/bin/bash
# K8SLab - All-in-one installation script
# Installs MicroK8s, configures permissions, and deploys secure namespace

set -euo pipefail

echo "🔒 K8SLab Installation - DevSecOps Edition"
echo ""

# Check if running on correct system
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "❌ This script must run on Linux (Ubuntu)"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Install MicroK8s if needed
if ! command_exists microk8s; then
    echo "📦 Installing MicroK8s..."
    sudo snap install microk8s --classic
    echo "✅ MicroK8s installed"
else
    echo "✅ MicroK8s already installed"
fi

# Step 2: Configure user permissions
if ! microk8s status &> /dev/null; then
    echo "🔧 Configuring MicroK8s permissions..."
    sudo usermod -a -G microk8s $USER
    sudo chown -R $USER ~/.kube 2>/dev/null || true

    echo ""
    echo "✅ Permissions configured!"
    echo "🔄 Run this script again with: sg microk8s -c './install.sh'"
    exit 0
fi

# Step 3: Enable essential addons
echo "🔌 Enabling MicroK8s addons..."
microk8s enable dns storage ingress 2>/dev/null || echo "Addons already enabled"

# Step 4: Start MicroK8s
echo "▶️  Starting MicroK8s..."
microk8s start 2>/dev/null || echo "MicroK8s already running"

# Step 5: Configure kubectl
echo "📝 Configuring kubectl..."
mkdir -p ~/.kube
microk8s config > ~/.kube/config
chmod 600 ~/.kube/config
echo "✅ kubectl configured (permissions: 600)"

# Step 6: Apply security-hardened namespace
if [ -d "kustomize" ]; then
    echo ""
    echo "🛡️  Deploying secure namespace..."
    microk8s kubectl apply -k kustomize/

    # Verify
    echo ""
    echo "✅ Installation complete! Verifying..."
    echo ""
    microk8s kubectl get namespace labs
    microk8s kubectl get networkpolicies -n labs
    microk8s kubectl get resourcequota -n labs

    echo ""
    echo "🎉 Success! K8SLab environment is ready."
    echo ""
    echo "Security features enabled:"
    echo "  ✅ Pod Security Standards: restricted"
    echo "  ✅ Network Policies: default deny"
    echo "  ✅ Resource Quotas: configured"
else
    echo ""
    echo "✅ MicroK8s installed and configured!"
    echo "⚠️  No kustomize/ directory found - skipping namespace setup"
fi

echo ""
echo "Next: Deploy your applications to the 'labs' namespace"
