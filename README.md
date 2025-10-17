# K8SLab — MicroK8s DevSecOps

Hands-on Kubernetes learning lab built on MicroK8s, aligned with the LinkedIn Learning course “L’essentiel de Kubernetes,” and focused on security and automation practices tailored for a lab environment.

## Scope and Limits

- Target platform: **MicroK8s** on Ubuntu Server 22.04+ (single-node by default; HA optional).
- Tested versions: MicroK8s **v1.2x** (specify), Ubuntu **22.04**.
- Addons used: **rbac**, **dns**, **storage**, **ingress** (optional **metallb**, **cert-manager** per module).
- Goal: apply **production-inspired** practices (security, observability, automation) in a MicroK8s lab context.
- Out of scope: multi-cloud deployments, advanced service mesh without a dedicated addon, host kernel hardening.

## Course Alignment

| Module | Course Section | MicroK8s DevSecOps Focus |
|--------|----------------|---------------------------|
| 00-install | Install Kubernetes | Secure MicroK8s setup, addon activation, RBAC. |
| 01-pods | Create pods | SecurityContext, health probes, resource limits (microk8s kubectl). |
| 02-docs | Define documentation | IaC documentation and reproducibility. |
| 03-services | Set up services | MicroK8s Ingress, optional TLS via cert-manager, NetworkPolicies (CNI-dependent). |
| 04-deployments | Deploy with Kubernetes | Rolling updates/rollback, metrics via metrics-server. |
| 05-namespaces | Use namespaces | Lightweight multi-tenancy, RBAC, quotas. |
| 06-config-apps | Configure applications | Secrets, ConfigMaps, least privilege. |
| 07-volumes | Understand volumes | Persistent storage via storage addon, backups. |
| 08-advanced | Advanced topics | GitOps (kustomize), hooks, additional hardening.

## Overview

This repository offers a progressive, security-first path for learning Kubernetes with MicroK8s. Each module maps to core topics from the LinkedIn course while applying practical security controls, observability, and automation suited to a lab.

## Prerequisites

- **Local Machine**: macOS with Make installed
- **Remote VM**: Ubuntu Server **22.04+**
- **SSH**: Key-based authentication configured
- **MicroK8s**: Installed via snap on the VM; addons enabled per module

## Quick Start

### 1. Initial Setup

```bash
# Start with Module 00: MicroK8s installation
cd 00-install

# Initialize environment (enables addons: rbac, dns, storage, ingress)
make init

# Edit .env with your VM details
vim .env

# Install and harden MicroK8s
make install

# Validate installation and run security checks
make validate
make security-check
```

### 2. Work Through the Modules

Each module builds on the previous one:

```bash
# Module 01: Secure pods
cd 01-pods
make deploy
make validate

# Continue with Modules 02–08...
```

## DevSecOps Features

### Security First
- **Pod Security**: “restricted” policies enforced at the namespace level
- **Network Policies**: default-deny model (CNI-dependent; specify Calico/Canal if applicable)
- **Security Contexts**: non-root users, read-only filesystems, dropped capabilities
- **Resource Limits**: requests/limits to prevent resource exhaustion
- **Least Privilege**: minimal permissions and capabilities

### Observability
- **Health Probes**: liveness and readiness
- **Metrics**: via **metrics-server** addon (if enabled)
- **Event Logging**: Kubernetes events and pod logs

### Automation
- **Makefiles**: consistent commands across modules
- **Shell Scripts**: automated install and validation
- **Kustomize**: declarative configuration
- **Infrastructure as Code**: version-controlled manifests

## Project Structure

```
K8SLab/
├── 00-install/          # Secure MicroK8s installation
│   ├── Makefile         # Automation commands
│   ├── install.sh       # Installation script
│   └── kustomize/       # Security manifests
├── 01-pods/             # Pod fundamentals + security
│   ├── Makefile
│   ├── deploy.sh
│   └── kustomize/
├── 02-docs/             # Documentation practices
├── 03-services/         # Service networking
├── 04-deployments/      # Deployment strategies
├── 05-namespaces/       # Multi-tenancy
├── 06-config-apps/      # Configuration management
├── 07-volumes/          # Storage management
└── 08-advanced/         # Advanced topics
```

## Learning Path

### Beginner Track
1. Complete Module 00 (Installation)
2. Work through Modules 01–04 (Pods, Services, Deployments)
3. Follow LinkedIn course videos alongside the labs

### Intermediate Track
1. Complete all modules sequentially
2. Apply and understand the security checks in each module
3. Consolidate DevSecOps principles in practice

### Expert Track
1. Explore “Expert Track” sections in each module
2. Implement advanced features (init containers, lifecycle hooks)
3. Add your own security enhancements
4. Contribute improvements via pull requests

## Common Commands

Each module exposes consistent Makefile targets:

```bash
make help            # List available commands
make deploy          # Deploy module resources
make validate        # Validate deployment
make security-check  # Run security tests
make logs            # View logs
make delete          # Delete resources
make clean           # Cleanup VM files
```

## Resources

- LinkedIn Course: “L’essentiel de Kubernetes”
- Kubernetes Docs: https://kubernetes.io/docs/
- Pod Security Standards: https://kubernetes.io/docs/concepts/security/pod-security-standards/
- Kustomize: https://kustomize.io/
- MicroK8s: https://microk8s.io/

## Contributing

This is a learning project. Feel free to:
- Fork and customize for your learning goals
- Open issues for bugs or improvements
- Share enhancements via pull requests

## License

MIT License — see LICENSE file for details.