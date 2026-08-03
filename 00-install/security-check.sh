#!/usr/bin/env bash
# The baseline is only worth what it refuses. Each assertion tries to violate it.
set -uo pipefail
# shellcheck source-path=SCRIPTDIR source=../lib/check.sh
. "$(dirname "$0")/../lib/check.sh"

# Pod Security Standards must reject a privileged pod, at admission.
if kube "run pss-probe --image=nginx --privileged -n labs --restart=Never --dry-run=server" >/dev/null 2>&1
then check "pod security standards" ko "a privileged pod was admitted"
else check "pod security standards" ok; fi

# A NetworkPolicy is only exercised by real traffic, so the probe is a real pod.
kube "run netpol-probe --image=busybox:1.36 -n labs --restart=Never --command -- sleep 30" >/dev/null 2>&1
kube "wait --for=condition=Ready pod/netpol-probe -n labs --timeout=60s" >/dev/null 2>&1
if kube "exec netpol-probe -n labs -- wget -q -T 5 -O- https://example.com" >/dev/null 2>&1
then check "egress deny" ko "the pod reached the internet"
else check "egress deny" ok; fi
kube "delete pod netpol-probe -n labs --ignore-not-found --wait=false" >/dev/null 2>&1

# Without both, nothing caps what a pod may consume.
if kube "get resourcequota,limitrange -n labs" >/dev/null 2>&1
then check "quota and limits" ok
else check "quota and limits" ko "ResourceQuota or LimitRange is missing"; fi

summary
