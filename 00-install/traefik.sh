#!/usr/bin/env bash
# Installs the ingress controller. Runs on the cluster host.
set -euo pipefail

CHART=41.4.0
APP=v3.7.12

die() { echo "error: $*" >&2; exit 1; }

command -v microk8s >/dev/null 2>&1 || PATH=$PATH:/snap/bin

microk8s helm3 repo add traefik https://traefik.github.io/charts --force-update >/dev/null
microk8s helm3 repo update traefik >/dev/null

echo "installing traefik $APP (chart $CHART)"
microk8s helm3 upgrade --install traefik traefik/traefik \
  -n ingress --create-namespace --version "$CHART" \
  --values "$(dirname "$0")/traefik-values.yaml"

# Not helm --wait: the chart's Service is a LoadBalancer with no address here.
microk8s kubectl rollout status daemonset/traefik -n ingress --timeout=300s

image=$(microk8s kubectl get daemonset traefik -n ingress \
        -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$image" == *:"$APP" ]] || die "the ingress runs $image, not $APP"
echo "ingress: $image"
