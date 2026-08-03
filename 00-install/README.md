# 00-install — a namespace that starts closed

MicroK8s with four addons (`rbac`, `dns`, `storage`, `ingress`), then a namespace
`labs` where the defaults are refusals.

| Control | What it refuses |
|---|---|
| PSS `restricted` (namespace labels) | a non-conforming pod is never **created** — admission, not monitoring |
| `default-deny-all` NetworkPolicy | every flow, in and out; each exception is an explicit decision |
| `allow-dns`, `allow-same-namespace` | the two exceptions a lab needs to function |
| ResourceQuota + LimitRange | a pod that declares no requests/limits is rejected |

## Run

```bash
make init && $EDITOR .env    # VM_HOST = your ssh alias
make install                 # twice the first time: pass 1 adds you to the microk8s group
make security-check
```

## What the check proves

It submits a privileged pod and expects a refusal, creates a real pod and expects its
`wget` to the internet to fail, and verifies the quota objects still exist. Reading
the YAML would prove none of that.

## The trap worth knowing

A namespace is not usable the moment it exists: until the controller-manager has
created its default ServiceAccount, every pod is rejected — even one mounting no
token. Enabling the addons restarts that controller, so `install.sh` waits for it.
