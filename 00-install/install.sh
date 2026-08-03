#!/usr/bin/env bash
# Installs MicroK8s and applies the security baseline of the labs namespace.
set -euo pipefail

ADDONS=(rbac dns storage ingress)

die() { echo "error: $*" >&2; exit 1; }

[[ "$(uname -s)" == "Linux" ]] || die "this script runs on Linux, not $(uname -s)"
[[ -d kustomize ]] || die "run this from the module directory: kustomize/ not found"

if ! command -v microk8s >/dev/null 2>&1; then
  echo "installing microk8s"
  sudo snap install microk8s --classic
fi

# Group membership, not cluster status: `microk8s status` also fails on a stopped
# node, which sent the previous version into a re-run loop.
if ! id -nG "$USER" | tr ' ' '\n' | grep -qx microk8s; then
  sudo usermod -a -G microk8s "$USER"
  echo "added $USER to the microk8s group"
  echo "re-run in a shell that has it: sg microk8s -c './install.sh'"
  exit 0
fi

microk8s status --wait-ready --timeout 120 >/dev/null

# `microk8s enable` is idempotent and exits 0 on an already-enabled addon, so a
# non-zero status here is a real failure and must stop the script.
echo "enabling addons: ${ADDONS[*]}"
microk8s enable "${ADDONS[@]}"

echo "applying the security baseline"
microk8s kubectl apply -k kustomize/

# A namespace is not usable the moment it exists: until the controller-manager has
# created its default ServiceAccount, every pod is rejected — including one that
# mounts no token. Enabling the addons restarts that controller, so the first
# `make deploy` after an install lands exactly in that window.
microk8s kubectl wait --for=create serviceaccount/default -n labs --timeout=90s

microk8s kubectl get namespace labs
microk8s kubectl get networkpolicy -n labs
microk8s kubectl get resourcequota,limitrange -n labs

echo "done: namespace labs is ready under Pod Security Standards 'restricted'"
