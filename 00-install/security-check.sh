#!/usr/bin/env bash
# The baseline is only worth what it refuses. Each assertion tries to violate it,
# and names the refusal it expects: a non-zero exit alone proves nothing, because
# blocked traffic, a missing binary and a deleted pod all exit 1.
set -uo pipefail
# shellcheck source-path=SCRIPTDIR source=../lib/check.sh
. "$(dirname "$0")/../lib/check.sh"

require_namespace labs

# Pod Security Standards must reject a privileged pod, at admission. Anchored on the
# Forbidden error, not on the audit/warn Warning the same namespace also emits: the
# falsification suite removes only the enforcing label, so a looser pattern would
# match the surviving warning and quietly stop detecting anything.
out=$(kube "run pss-probe --image=nginx:1.29-alpine --privileged -n labs --restart=Never --dry-run=server"); rc=$?
assert_refused "pod security standards" 'Forbidden.*violates PodSecurity' "$out" "$rc"

assert_unreachable "egress deny" labs https://example.com

# Without both, nothing caps what a pod may consume. Named, not counted: a
# multi-resource `get` exits 0 on an empty namespace, so its status proves nothing.
# Two assertions rather than one, so a failure says by name which half is missing.
quota=$(kube "get resourcequota -n labs -o jsonpath={.items[*].metadata.name}"); rc=$?
assert_matches "the namespace has a quota" '.' "$quota" "$rc"
limits=$(kube "get limitrange -n labs -o jsonpath={.items[*].metadata.name}"); rc=$?
assert_matches "containers have limits" '.' "$limits" "$rc"

summary
