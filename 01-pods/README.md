# Module 01: Pods - DevSecOps Edition

Deploy production-grade pods with comprehensive security controls and health monitoring.

## Security Features

- **Non-root user**: UID 1000 (non-privileged)
- **Read-only root filesystem**: Prevents runtime tampering
- **Dropped capabilities**: ALL capabilities removed
- **No privilege escalation**: `allowPrivilegeEscalation: false`
- **Health probes**: Liveness and readiness checks
- **Resource limits**: CPU/Memory requests and limits
- **Seccomp profile**: Runtime default security profile

## Prerequisites

- **Module 00**: Must be completed first (`labs` namespace required)
- **SSH**: Configured with VM access
- **Environment**: `.env` file with VM_HOST configured

## Quick Start

```bash
# Deploy secure pod
make deploy

# Validate deployment
make validate

# View logs
make logs

# Run security checks
make security-check
```

## What Gets Deployed

```
labs/hello-pod
├── Security Context (non-root, read-only FS)
├── Liveness Probe (HTTP /health)
├── Readiness Probe (HTTP /ready)
├── Resource Limits (500m CPU, 256Mi RAM)
└── Temporary Volumes (cache, run)
```

## Security Validation

```bash
# Verify non-root user
ssh vm-ubuntu "microk8s kubectl exec -n labs hello-pod -- id"
# Expected: uid=1000 gid=3000 groups=2000

# Verify read-only filesystem
ssh vm-ubuntu "microk8s kubectl exec -n labs hello-pod -- touch /test"
# Expected: Read-only file system error

# Check security context
make security-check
```

## Interactive Testing

### Access Nginx Web Interface

```bash
# Port-forward to local machine
make port-forward
```

Open browser: **http://localhost:8080**

Press `Ctrl+C` to stop port-forwarding.

### Execute Shell in Pod

```bash
make exec
```

## Common Commands

```bash
make deploy          # Deploy pod to labs namespace
make validate        # Check deployment status
make logs            # View pod logs
make port-forward    # Access nginx at http://localhost:8080
make exec            # Execute shell in pod
make security-check  # Run security validation tests
make delete          # Delete pod
make clean           # Remove all K8SLab files from VM
```

## Troubleshooting

**Pod not starting:**
```bash
ssh vm-ubuntu "microk8s kubectl describe pod -n labs hello-pod"
```

**Health probe failures:**
```bash
ssh vm-ubuntu "microk8s kubectl get pod -n labs hello-pod -o jsonpath='{.spec.containers[0].livenessProbe}'"
```

**Check events:**
```bash
ssh vm-ubuntu "microk8s kubectl get events -n labs --sort-by=.metadata.creationTimestamp"
```

## Next Steps

- **Module 02**: Documentation strategies
- **Module 03**: Expose pods with services
- **Module 04**: Scale with deployments
