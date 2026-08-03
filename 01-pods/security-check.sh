#!/usr/bin/env bash
# A securityContext is an intention; the running container is the fact.
set -uo pipefail
# shellcheck source-path=SCRIPTDIR source=../lib/check.sh
. "$(dirname "$0")/../lib/check.sh"
POD=hello-pod

uid=$(kube "exec $POD -n labs -- id -u" 2>/dev/null | tr -d '\r')
if [ "$uid" = 101 ]; then check "runs as uid 101" ok
else check "runs as uid 101" ko "got '${uid:-nothing}'"; fi

if kube "exec $POD -n labs -- touch /probe" >/dev/null 2>&1
then check "read-only root filesystem" ko "/probe was created"
else check "read-only root filesystem" ok; fi

caps=$(kube "get pod $POD -n labs -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop[*]}'" 2>/dev/null)
if [[ "$caps" == *ALL* ]]; then check "all capabilities dropped" ok
else check "all capabilities dropped" ko "drop list is '${caps:-empty}'"; fi

esc=$(kube "get pod $POD -n labs -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation}'" 2>/dev/null)
if [ "$esc" = false ]; then check "privilege escalation denied" ok
else check "privilege escalation denied" ko "got '${esc:-unset}'"; fi

summary
