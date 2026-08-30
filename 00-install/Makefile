include ../common.mk   # also defines: help, security-check and test

# kubectl takes its types comma-separated, and $(call) splits on the commas it can
# see - but not on commas that arrive through a variable.
BASELINE := networkpolicy,resourcequota,limitrange
.PHONY: init install deploy validate kill dashboard

init: ## Create .env from the example
	@test -f .env && echo ".env already exists" || { cp .env.example .env; echo "created .env, set VM_HOST in it"; }

install: ## Install MicroK8s and the security baseline on the VM
	@test -n "$(VM_HOST)" || { echo "VM_HOST unset: run make init first" >&2; exit 1; }
	scp -r kustomize install.sh $(VM_HOST):~/
	ssh $(VM_HOST) "chmod +x ~/install.sh && ~/install.sh"

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
	@# `exec` and not a background job: a shell puts SIGINT on ignore for anything
	@# it starts with `&`, so a backgrounded tunnel would survive the Ctrl-C this
	@# target documents. In the foreground the terminal signals it directly.
	@addr=$$(ssh -G '$(VM_HOST)' | awk '/^hostname /{print $$2}'); \
	 test -n "$$addr" || { echo "cannot resolve $(VM_HOST) from ~/.ssh/config" >&2; exit 1; }; \
	 echo "This tunnel ends on $$(hostname). Open it there:"; \
	 echo "    http://dashboard.localhost:8080/dashboard/"; \
	 echo; \
	 echo "Browsing from another machine? This target is not what you want."; \
	 echo "Ctrl-C, and run this on the machine with the browser instead:"; \
	 echo "    ssh -N -L 8080:$$addr:80 $${GATEWAY:-$$(hostname)}"; \
	 echo; \
	 exec ssh -N -o ExitOnForwardFailure=yes -L 8080:$$addr:80 '$(VM_HOST)'
