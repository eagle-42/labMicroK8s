#!/usr/bin/env bash
# A securityContext is an intention; the running container is the fact. Every
# assertion below reads the container, never the object the API server stored.
set -uo pipefail
# shellcheck source-path=SCRIPTDIR source=../lib/check.sh
. "$(dirname "$0")/../lib/check.sh"

POD=hello-pod
require_namespace labs
require pod "$POD" -n labs

uid=$(kube "exec $POD -n labs -- id -u"); rc=$?
assert_matches "runs as uid 101" '^101[[:space:]]*$' "$uid" "$rc"

# `touch /` fails for a non-root user whether the filesystem is read-only or not -
# "Permission denied" rather than "Read-only file system" - so that assertion could
# never fail. The mount table is the fact, parsed here rather than in a nested shell.
mounts=$(kube "exec $POD -n labs -- cat /proc/mounts"); rc=$?
assert_matches "read-only root filesystem" '^[^ ]+ / [^ ]+ ro[,[:space:]]' "$mounts" "$rc"

# The kernel's own view of the process, read once and asserted twice. CapBnd and not
# CapEff: the effective set is empty for any non-root process whatever the manifest
# says, so asserting on it could never fail - measured, it reads 0 with drop:[ALL]
# and with drop:[NET_RAW] alike. The bounding set is what capabilities.drop controls:
# 0 against 00000000a80405fb.
status=$(kube "exec $POD -n labs -- cat /proc/self/status"); rc=$?
assert_matches "all capabilities dropped" '^CapBnd:[[:space:]]*0+$' "$status" "$rc"
assert_matches "privilege escalation denied" '^NoNewPrivs:[[:space:]]*1$' "$status" "$rc"

summary
