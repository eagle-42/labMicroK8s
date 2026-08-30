#!/usr/bin/env bash
# Does each control of this module actually fail when someone violates it?
# This suite breaks objects belonging to three modules, so it puts back all three.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
# shellcheck source-path=SCRIPTDIR source=../../lib/falsify.sh
. "../lib/falsify.sh"

# Every module's deploy guards on the one below it, so the stack comes back
# bottom-up or not at all. This runs from the trap too, after a Ctrl-C.
restore() {
  make -C ../00-install deploy >/dev/null 2>&1
  make -C ../01-pods    deploy >/dev/null 2>&1
  make                  deploy >/dev/null 2>&1
}

# Traefik reconciles asynchronously: deleting the Ingress does not close the route in
# the same instant, and a gate run too early tests a route that is still alive.
wait_until_route_closes() {
  local addr
  addr=$(node_addr)
  for _ in $(seq 1 20); do
    [ "$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://$addr/")" = 200 ] || return 0
    sleep 1
  done
  return 1
}

test_the_service_needs_a_ready_endpoint() {
  # No pod behind the Service means no endpoint, and an Ingress that answers 503 -
  # a broken route that looks like a routing problem rather than a missing backend.
  kube "delete pod hello-pod -n labs --wait=true --grace-period=1 --ignore-not-found" >/dev/null 2>&1
  expect_refusal_then_recovery "the service needs a ready endpoint" \
    "the gate still passes with no pod behind the service"
}

test_the_ingress_is_what_publishes_the_pod() {
  kube "delete ingress hello -n labs --ignore-not-found" >/dev/null 2>&1
  wait_until_route_closes \
    || { check "the ingress is what publishes the pod" unknown "the route never closed"; restore; return; }
  expect_refusal_then_recovery "the ingress is what publishes the pod" \
    "the gate still passes with no ingress at all"
}

test_no_other_namespace_gets_through() {
  # Four policies select this pod and every one of them contributes to the isolation
  # - allow-same-namespace declares Ingress from podSelector {} and keeps other
  # namespaces out on its own, so removing only the default-deny would leave the pod
  # shut and prove nothing.
  kube "delete networkpolicy allow-ingress-controller default-deny-all allow-dns allow-same-namespace -n labs --ignore-not-found" >/dev/null 2>&1
  expect_refusal_then_recovery "no other namespace gets through" \
    "the gate still passes with every policy in the namespace gone"
}

falsify test_the_service_needs_a_ready_endpoint \
        test_the_ingress_is_what_publishes_the_pod \
        test_no_other_namespace_gets_through
