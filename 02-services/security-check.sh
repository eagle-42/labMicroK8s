#!/usr/bin/env bash
# Opening one path is half the work; the half that matters is that the rest stayed shut.
set -uo pipefail
# shellcheck source-path=SCRIPTDIR source=../lib/check.sh
. "$(dirname "$0")/../lib/check.sh"

# A Service without an endpoint answers 503 and looks like a broken route.
ep=$(kube "get endpointslice -l kubernetes.io/service-name=hello -n labs -o jsonpath='{.items[*].endpoints[*].addresses[*]}'" 2>/dev/null)
if [ -n "$ep" ]; then check "service has a ready endpoint" ok
else check "service has a ready endpoint" ko "none, is the pod from 01-pods running?"; fi

code=$(node "curl -s -o /dev/null -w %{http_code} -m 10 http://127.0.0.1/" 2>/dev/null)
if [ "$code" = 200 ]; then check "ingress serves the pod" ok
else check "ingress serves the pod" ko "got HTTP ${code:-nothing}"; fi

# The assertion that matters: the path opened is the only one.
kube "run netprobe --image=busybox:1.36 -n default --restart=Never --command -- sleep 60" >/dev/null 2>&1
kube "wait --for=condition=Ready pod/netprobe -n default --timeout=60s" >/dev/null 2>&1
if kube "exec netprobe -n default -- wget -q -T 5 -O- http://hello.labs.svc.cluster.local" >/dev/null 2>&1
then check "other namespaces stay blocked" ko "a pod in default reached the service"
else check "other namespaces stay blocked" ok; fi
kube "delete pod netprobe -n default --ignore-not-found --wait=false" >/dev/null 2>&1

summary
