include ../common.mk   # also defines: help, security-check and test

# kubectl takes its types comma-separated, and $(call) splits on the commas it can
# see - but not on commas that arrive through a variable.
BASELINE := networkpolicy,resourcequota,limitrange
.PHONY: init install deploy validate kill dashboard

init: ## Create .env from the example
	@test -f .env && echo ".env already exists" || { cp .env.example .env; echo "created .env, set VM_HOST in it"; }

install: ## Install MicroK8s and the security baseline on the VM
	@test -n "$(VM_HOST)" || { echo "VM_HOST unset: run make init first" >&2; exit 1; }
	@# One destination, the name `apply` uses: two copies on the VM meant `install` and
	@# `deploy` could apply different manifests.
	ssh '$(VM_HOST)' 'rm -rf ~/$(MODULE)-kustomize'
	scp -qr kustomize '$(VM_HOST)':~/$(MODULE)-kustomize
	scp -q install.sh traefik.sh traefik-values.yaml '$(VM_HOST)':~/
	ssh '$(VM_HOST)' "chmod +x ~/install.sh ~/traefik.sh && ~/install.sh ~/$(MODULE)-kustomize"

deploy: ## Re-apply the baseline, without reinstalling MicroK8s
	@$(apply)

validate: ## Show what the baseline deployed
	@$(call kube,get namespace labs)
	@$(call kube,get $(BASELINE) -n labs)

kill: ## Delete the labs namespace and everything in it
	@printf 'delete namespace labs on $(VM_HOST)? [y/N] '; read -r a; [ "$$a" = y ]
	@$(call kube,delete namespace labs)

dashboard: ## Tunnel to the Traefik dashboard (Ctrl-C to close)
	@test -n "$(VM_HOST)" || { echo "no VM: the cluster is this machine" >&2; exit 1; }
	@# Named up front: ssh's own "Address already in use" plus make's Error 255 is
	@# two errors for one cause, and neither says what to do about it. The pid comes
	@# from ss rather than a pgrep pattern, which would match this very command line.
	@holder=$$(ss -lntp 2>/dev/null | sed -n 's/.*127\.0\.0\.1:8080 .*pid=\([0-9]*\).*/\1/p' | head -1); \
	 test -z "$$holder" || { echo "port 8080 is already held here by pid $$holder:" >&2; \
	                         ps -o args= -p "$$holder" >&2; \
	                         echo "close that tunnel, or: kill $$holder" >&2; exit 1; }
	@# Straight to the pod: traefik.sh moves the dashboard off the node's port 80. A
	@# remote `kubectl port-forward` orphans a process every time the tunnel dies; with
	@# `-N` there is no remote command to orphan.
	@#
	@# `exec` and not a background job: a shell puts SIGINT on ignore for anything
	@# it starts with `&`, so a backgrounded tunnel would survive the Ctrl-C this
	@# target documents. In the foreground the terminal signals it directly.
	@ip=$$($(call kube,get pods -n ingress -l app.kubernetes.io/name=traefik -o jsonpath='{.items[0].status.podIP}')); \
	 test -n "$$ip" || { echo "no traefik pod on $(VM_HOST): run make install" >&2; exit 1; }; \
	 echo "This tunnel ends on $$(hostname). Open it there:"; \
	 echo "    http://dashboard.localhost:8080/dashboard/"; \
	 echo; \
	 echo "Browsing from another machine? Run this target on that machine."; \
	 echo; \
	 exec ssh -N -o ExitOnForwardFailure=yes -L "8080:$$ip:8080" '$(VM_HOST)'
