#!/usr/bin/env bash
# The one check no published hook covers: build every module, then judge the result.
#
# Modules are found on disk, not with `git ls-files`: an untracked module is exactly
# the one nobody has reviewed yet.
set -euo pipefail
cd "$(dirname "$0")/.."

# The version the lab installs, so the schemas are the ones this cluster enforces
# rather than the newest kubeconform happens to know about.
K8S=1.35.6

# Nothing escapes a `find | while` subshell, so the loop is fed instead of piped:
# the count has to survive. A run that judged no module is not a passing gate - the
# same rule lib/check.sh applies to assertions, applied to the gate itself.
modules=0
while IFS= read -r -d "" k; do
  # The separator is not cosmetic: `kubectl kustomize` does not end its output with
  # one, so appending the next module merges its first document into the previous
  # module's last. Measured: 10 resources became 8, and the two that disappeared -
  # the Namespace and the Pod - are the ones the baseline is about. kubescape then
  # scored 100% on a scan that had quietly lost them.
  printf -- '---\n'
  kubectl kustomize "$(dirname "$k")"
  modules=$((modules + 1))
done < <(find . -name kustomization.yaml -print0) > /tmp/all.yaml
[ "$modules" -gt 0 ] || { echo "no module found: this gate judged nothing" >&2; exit 1; }

# One run, over the exact bytes kubescape and pluto are handed below: a merge at a
# module boundary shows up here and nowhere else.
kubeconform -strict -summary -kubernetes-version "$K8S" /tmp/all.yaml

kubescape scan framework NSA /tmp/all.yaml --severity-threshold Medium

# An apiVersion valid today and gone at the next upgrade: kubeconform judges a schema,
# kubescape judges a control, neither judges a countdown. Pinned to the version the lab
# runs, so the answer is about this cluster and not about the newest one.
pluto detect /tmp/all.yaml -t k8s=v1.35 --output wide
