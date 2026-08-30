# Included by every module. A module declares only the verb it is about.
-include $(dir $(lastword $(MAKEFILE_LIST)))00-install/.env
export

# One code path, two targets. With VM_HOST the cluster is a remote VM and the
# manifests travel; without it the cluster is this machine, as in CI.
# Both of these are interpolated into a remote shell. Quoting them through make,
# ssh and `sg -c` is unmanageable - a stray quote silently created a directory
# called "'00-install'-kustomize" - so the dangerous value is refused up front and
# the commands stay readable.
MODULE := $(notdir $(CURDIR))
ifneq ($(words $(MODULE)),1)
  $(error module directory must be a single word, got "$(MODULE)")
endif

ifneq ($(words $(VM_HOST)),1)
  ifneq ($(strip $(VM_HOST)),)
    $(error VM_HOST must be a single ssh alias, got "$(VM_HOST)")
  endif
endif

ifeq ($(strip $(VM_HOST)),)
  # `set -f` on both paths, not just the remote one: the same jsonpath crosses both,
  # and a `[0]` reaching a shell with globbing on is a filename pattern either way.
  kube  = sudo sh -c 'set -f; microk8s kubectl $(1)'
  apply = sudo microk8s kubectl apply -k kustomize/
else
  # $(2) carries ssh flags for the one caller that needs a terminal. A second named
  # macro for that would be byte-identical to this one in the branch above - a clone
  # kept in sync by hand, which is how the falsify helper drifted.
  kube  = ssh $(2) '$(VM_HOST)' "sg microk8s -c 'set -f; microk8s kubectl $(1)'"
  # `scp -r` into an existing directory copies *inside* it, so from the second run
  # the manifests apply -k reads are frozen at their first-run content - a silent
  # no-op with exit 0. The destination is removed first, every time.
  apply = ssh '$(VM_HOST)' "rm -rf ~/$(MODULE)-kustomize" \
          && scp -qr kustomize '$(VM_HOST)':~/$(MODULE)-kustomize \
          && $(call kube,apply -k ~/$(MODULE)-kustomize/)
endif

.NOTPARALLEL:  # one ssh round trip each; -j only reorders them wrongly
.PHONY: help security-check test

help: ## Show this help
	@grep -hE '^[a-z-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/\t/' | column -ts"$$(printf '\t')"

security-check: ## Assert the controls of this module still hold
	@bash security-check.sh

test: ## Prove every assertion of this module can actually fail
	@test -f tests/falsify.sh || { echo "$(MODULE) has no tests/falsify.sh yet" >&2; exit 1; }
	@# One suite at a time on this machine. The cluster is remote, so this does not
	@# serialise two workstations - it covers the case that actually happens here.
	@flock /tmp/labk8s-falsify.lock bash tests/falsify.sh
