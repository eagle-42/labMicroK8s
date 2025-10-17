# Module 00: Installation - DevSecOps Edition

Deploy a security-hardened MicroK8s environment with production-grade controls.

## Security Features

This module implements defense-in-depth security:

### 1. Pod Security Standards (PSS)
- **Level**: `restricted` (most secure)
- Blocks privileged containers, host access, capabilities escalation
- Enforces read-only root filesystem, non-root users

### 2. Network Policies (Zero Trust)
- **Default**: Deny all ingress/egress traffic
- **Allow**: DNS to kube-system only
- **Allow**: Pod-to-pod within same namespace
- External traffic blocked by default

### 3. Resource Quotas & Limits
- **Namespace limits**: 20 pods max, 4 CPU, 8Gi RAM
- **Per-container limits**: 500m CPU max, 256Mi RAM max
- **Per-container requests**: 100m CPU min, 128Mi RAM min
- Prevents resource exhaustion attacks

## Prerequisites

- **VM**: Ubuntu Server 22.04+ (accessible via SSH)
- **SSH**: Key-based authentication configured in `~/.ssh/config`
- **Local**: Make installed on your Mac

## Quick Start

### 1. Configure SSH Connection

```bash
# Copy environment template
make init

# Edit .env to match your VM
vim .env
```

Your `.env` should reference your SSH config alias:
```bash
VM_HOST=vm-ubuntu
```

Your `~/.ssh/config` should have:
```
Host vm-ubuntu
  HostName <your-vm-ip>
  User <your-username>
  IdentityFile ~/.ssh/id_ed25519_vm
```

### 2. Install K8SLab

```bash
# Deploy MicroK8s + secure namespace
make install
```

This will:
1. Copy files to VM
2. Install MicroK8s (if needed)
3. Configure user permissions
4. Enable DNS, storage, ingress addons
5. Deploy security-hardened `labs` namespace

### 3. Validate Installation

```bash
# Check deployment
make validate

# Run security tests
make security-check
```

## What Gets Deployed

The `labs` namespace includes:

```
labs/
├── Namespace (with Pod Security Standards: restricted)
├── NetworkPolicy: default-deny-all
├── NetworkPolicy: allow-dns
├── NetworkPolicy: allow-same-namespace
├── ResourceQuota: namespace-quota
└── LimitRange: container-limits
```

## Testing Security

### Test 1: Pod Security Standards
```bash
# This SHOULD FAIL (privileged pods blocked)
ssh vm-ubuntu "microk8s kubectl run test --image=nginx --privileged -n labs"
```

Expected: `Error: pods "test" is forbidden: violates PodSecurity "restricted:latest"`

### Test 2: Network Policy
```bash
# This SHOULD TIMEOUT (external traffic blocked)
ssh vm-ubuntu "microk8s kubectl run test --image=busybox --rm -i -n labs -- wget -O- http://google.com"
```

Expected: Connection timeout after 5 seconds

### Test 3: Resource Quotas
```bash
# Check quota usage
ssh vm-ubuntu "microk8s kubectl describe resourcequota -n labs"
```

## Common Commands

```bash
make init            # Initialize .env file
make install         # Install and deploy
make validate        # Check deployment status
make security-check  # Run security tests
make clean           # Remove files from VM
make stop            # Stop MicroK8s
make kill            # Delete labs namespace
```

## Troubleshooting

### Permission Denied
If you get "Permission denied" when running MicroK8s commands on VM:
```bash
ssh vm-ubuntu
sg microk8s -c './install.sh'
```

### SSH Connection Failed
Check your SSH config:
```bash
ssh vm-ubuntu echo "Connection OK"
```

### MicroK8s Not Ready
Wait for MicroK8s to fully start:
```bash
ssh vm-ubuntu "microk8s status --wait-ready"
```

## DevSecOps Principles Applied

- **Shift Left Security**: Security controls applied at deployment time
- **Defense in Depth**: Multiple security layers (PSS + Network + Resources)
- **Zero Trust Network**: Explicit allow-list, deny by default
- **Least Privilege**: Containers run as non-root with minimal capabilities
- **Infrastructure as Code**: All configs versioned and reproducible

## Next Steps

Deploy your applications to the `labs` namespace:
- All pods must comply with restricted Pod Security Standards
- Network policies control traffic flow
- Resource limits prevent noisy neighbors

Example secure pod:
```bash
ssh vm-ubuntu "microk8s kubectl run nginx --image=nginx:alpine -n labs"
```
