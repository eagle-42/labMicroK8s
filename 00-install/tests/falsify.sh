#!/usr/bin/env bash
# Does each control of this module actually fail when someone violates it?
# A control that survives its own violation is not a control.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
# shellcheck source-path=SCRIPTDIR source=../../lib/falsify.sh
. "../lib/falsify.sh"

test_privileged_pods_are_refused() {
  # Pod Security Standards live in a namespace label. Remove the enforcing one and
  # a privileged pod becomes admissible, so the gate must notice.
  kube "label namespace labs pod-security.kubernetes.io/enforce-" >/dev/null 2>&1
  expect_refusal_then_recovery "privileged pods are refused" \
    "the gate still passes with PSS enforcement removed"
}

test_pods_cannot_reach_the_internet() {
  # All three of this module's policies declare Egress, so removing only the
  # default-deny one would leave egress closed and prove nothing. They are named
  # rather than wiped with --all: other modules keep their own policies in this
  # namespace, and a test that breaks a neighbour is a test that lies about it.
  kube "delete networkpolicy default-deny-all allow-dns allow-same-namespace -n labs" >/dev/null 2>&1
  expect_refusal_then_recovery "pods cannot reach the internet" \
    "the gate still passes with every egress policy gone"
}

test_consumption_is_capped() {
  # The quota bounds the namespace, the LimitRange bounds each container and supplies
  # the defaults that make the quota livable. Both must be required.
  kube "delete resourcequota/namespace-quota limitrange/container-limits -n labs" >/dev/null 2>&1
  expect_refusal_then_recovery "consumption is capped" \
    "the gate still passes with quota and limits deleted"
}

falsify test_privileged_pods_are_refused \
        test_pods_cannot_reach_the_internet \
        test_consumption_is_capped
