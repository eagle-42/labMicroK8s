#!/usr/bin/env bash
# The one check no published hook covers: build every module, then judge the result.
#
# Modules are found on disk, not with `git ls-files`: an untracked module is exactly
# the one nobody has reviewed yet.
set -euo pipefail
cd "$(dirname "$0")/.."

: > /tmp/all.yaml
find . -name kustomization.yaml -print0 | while IFS= read -r -d "" k; do
  kubectl kustomize "$(dirname "$k")" | tee -a /tmp/all.yaml | kubeconform -strict -summary
done

# Every module at once: a pod scanned alone looks unprotected because the
# NetworkPolicy covering it lives in module 00. Together they score 100.
kubescape scan framework NSA /tmp/all.yaml --severity-threshold Medium
