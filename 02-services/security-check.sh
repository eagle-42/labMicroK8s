#!/usr/bin/env bash
# Opening one path is half the work; the half that matters is that the rest stayed
# shut. Each assertion names what it expects to read, because a non-zero exit alone
# says nothing: blocked traffic, a missing binary and a deleted pod all exit 1.
set -uo pipefail
# shellcheck source-path=SCRIPTDIR source=../lib/check.sh
. "$(dirname "$0")/../lib/check.sh"

# A prerequisite is something this module does not own: without the namespace
# nothing below means anything. The Service and the Ingress are what this module
# deploys, so their absence is an assertion that failed - not a gate that could not
# run. Requiring your own deliverable turns every falsification of it into
# "could not tell".
require_namespace labs

# A Service without an endpoint answers 503 and looks like a broken route.
ep=$(kube "get endpointslice -l kubernetes.io/service-name=hello -n labs -o jsonpath={.items[*].endpoints[*].addresses[*]}"); rc=$?
assert_matches "service has a ready endpoint" '.' "$ep" "$rc"

# An Ingress exists for clients outside the cluster, so the request comes from
# outside it - node_addr, not the node's own loopback.
# Only 503 is retried: Traefik reconciles after the fact, so a backend that has just
# restarted is briefly out of its pool. A deleted Ingress (404) concludes at once.
addr=$(node_addr)
for _ in $(seq 1 10); do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "http://$addr/" 2>/dev/null)
  [ "$code" = 503 ] || break
  sleep 1
done
case "$code" in
  200)    check "ingress serves the pod" ok ;;
  000|"") check "ingress serves the pod" unknown "no answer from $addr" ;;
  503)    check "ingress serves the pod" ko "still 503 after 10s: no backend joined the route" ;;
  *)      check "ingress serves the pod" ko "got HTTP $code" ;;
esac

# The assertion that matters: the path opened is the only one.
assert_unreachable "other namespaces stay blocked" default http://hello.labs.svc.cluster.local

summary
