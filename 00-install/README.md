# 00-install — a namespace that starts closed

MicroK8s with three addons (`rbac`, `dns`, `storage`), a pinned Traefik, then a
namespace `labs` where the defaults are refusals.

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
make security-check          # do the controls still hold?
make test                    # can they fail at all?
```

`make help` lists every target. `make dashboard` prints the tunnel command for the
Traefik dashboard — the tunnel belongs to the machine with the browser.

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

## The ingress is not the one the addon ships

`microk8s enable ingress` pins a Traefik with published CVEs, and its own `-V` flag
cannot reach a current chart. So the lab does not enable that addon: `traefik.sh`
installs chart **41.4.0 — Traefik v3.7.12** from `traefik-values.yaml`, and asserts
the running image afterwards, because a version nothing compares is a report rather
than a gate. CI runs the same script.

Those values are smaller than the addon's, since they leave out what the lab never
uses — the NGINX compatibility provider and Gateway API.

**The dashboard is published on the node, and that is a deliberate risk.** It sits on
`web`, the entrypoint owning `hostPort: 80`, guarded by `` Host(`dashboard.localhost`) ``
alone — and a Host header is a string the client chooses, not an access control.
Measured from another machine on the same LAN, `/dashboard/` and `/api/rawdata` both
answer `200`, and `rawdata` returns every router, service and middleware Traefik knows.
On a lab whose network you trust that is a fair trade for a one-hop tunnel; on anything
else it is not. Moving the route to the `traefik` entrypoint, which has no `hostPort`,
closes it — at the cost of a second hop from any machine that cannot reach the node.

## Two traps worth knowing

**A namespace is not usable the moment it exists.** Until the controller-manager has
created its default ServiceAccount, every pod is rejected — even one mounting no
token. Enabling the addons restarts that controller, so `install.sh` waits for it.

**A DaemonSet with a `hostPort` cannot roll with the chart's defaults.** A surge pod
is scheduled on the node it is replacing, so it waits for a port the old one still
holds — `FailedScheduling … didn't have free ports`, at any node count. The values
free the port first, and `traefik.sh` waits on `rollout status` rather than `helm
--wait`: the chart's Service is a LoadBalancer that never gets an address here.
