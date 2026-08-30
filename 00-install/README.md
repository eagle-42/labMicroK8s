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
make security-check          # do the controls still hold?      (~4 s)
make test                    # can they fail at all?            (~11 s)
```

`make help` lists every target. `make dashboard` opens the tunnel to the Traefik
dashboard and holds it until Ctrl-C.

## What `security-check` proves

It submits a privileged pod and expects the admission controller's own refusal
(`Forbidden … violates PodSecurity`), deploys a real pod and expects its `wget` to be
refused by `wget` itself (`^wget:`), and reads back the quota objects **by name**.
Reading the YAML would prove none of that — and neither would an exit status: blocked
traffic, a missing binary and a deleted pod all exit 1.

Two habits it carries, both learned by being wrong:

- `require namespace labs` first. When the namespace is absent every probe below fails
  too, and that failure used to read as a refusal — the check reported `3/3` on an
  empty cluster.
- The egress probe is deployed with a `securityContext` that satisfies `restricted`,
  and its readiness is a prerequisite. A bare `kubectl run` is refused at admission
  here, so the probe never existed and its silence looked exactly like a working
  NetworkPolicy.

## What `tests/falsify.sh` proves

That the three controls can actually fail. Each test breaks one on the live cluster,
requires the gate to refuse, then puts the baseline back:

| Test | What it removes |
|---|---|
| `privileged pods are refused` | the PSS `enforce` label |
| `pods cannot reach the internet` | this module's three policies, named one by one — all three declare `Egress`, so removing only the default-deny would leave egress closed and prove nothing; and `--all` would take a neighbouring module's policy with it |
| `consumption is capped` | the ResourceQuota and the LimitRange |

It refuses to run at all if the gate is already failing: testing the tests on a broken
cluster proves nothing about the tests.

## The trap worth knowing

A namespace is not usable the moment it exists: until the controller-manager has
created its default ServiceAccount, every pod is rejected — even one mounting no
token. Enabling the addons restarts that controller, so `install.sh` waits for it.
