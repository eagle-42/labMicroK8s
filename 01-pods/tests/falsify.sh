#!/usr/bin/env bash
# Does each control of this module actually fail when someone violates it?
# Every test redeploys the module's own pod with exactly one property changed - a
# stand-in pod would test the stand-in.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
# shellcheck source-path=SCRIPTDIR source=../../lib/falsify.sh
. "../lib/falsify.sh"

# More than the default: these tests replace the pod and lift module 00's label.
restore() {
  kube "delete pod hello-pod -n labs --wait=true --grace-period=1 --ignore-not-found" >/dev/null 2>&1
  kube "label namespace labs pod-security.kubernetes.io/enforce=restricted --overwrite" >/dev/null 2>&1
  make deploy >/dev/null 2>&1
}

deploy_with_one_change() { # deploy_with_one_change <sed expression>
  kube "delete pod hello-pod -n labs --wait=true --grace-period=1 --ignore-not-found" >/dev/null 2>&1
  sed "$1" kustomize/pod.yaml | kube "apply -n labs -f -" >/dev/null 2>&1
  # Running, not Ready: the gate execs into the container, and exec needs a running
  # container - not one that has also passed a readinessProbe five seconds later.
  kube "wait --for=jsonpath='{.status.phase}'=Running pod/hello-pod -n labs --timeout=60s" >/dev/null 2>&1
}

# Two of the four properties are also enforced by Pod Security Standards, so a pod
# violating them is refused at admission and never reaches this module's check.
# Testing them means lifting module 00's baseline first - which is the interesting
# part: half of what this module asserts is already unreachable while 00 holds.
lift_pss() { kube "label namespace labs pod-security.kubernetes.io/enforce-" >/dev/null 2>&1; }

test_the_container_runs_as_the_declared_user() {
  deploy_with_one_change 's/runAsUser: 101/runAsUser: 1000/'
  expect_refusal_then_recovery "the container runs as the declared user" \
    "the gate still passes with the pod running as uid 1000"
}

test_the_root_filesystem_stays_read_only() {
  deploy_with_one_change 's/readOnlyRootFilesystem: true/readOnlyRootFilesystem: false/'
  expect_refusal_then_recovery "the root filesystem stays read-only" \
    "the gate still passes with a writable root filesystem"
}

test_every_capability_is_dropped() {
  lift_pss
  deploy_with_one_change 's/drop: \[ALL\]/drop: [NET_RAW]/'
  expect_refusal_then_recovery "every capability is dropped" \
    "the gate still passes with capabilities left in the bounding set"
}

test_privilege_escalation_stays_denied() {
  lift_pss
  deploy_with_one_change 's/allowPrivilegeEscalation: false/allowPrivilegeEscalation: true/'
  expect_refusal_then_recovery "privilege escalation stays denied" \
    "the gate still passes with escalation allowed"
}

falsify test_the_container_runs_as_the_declared_user \
        test_the_root_filesystem_stays_read_only \
        test_every_capability_is_dropped \
        test_privilege_escalation_stays_denied
