# labMicroK8s

A Kubernetes lab on MicroK8s where every module carries the security controls the
same feature would need in production, a check that fails when they stop working, and
a test that proves the check can fail at all.

Built alongside the LinkedIn course *L'essentiel de Kubernetes*, one module per section.

## Modules

| | Subject | Security angle | State |
|---|---|---|---|
| `00-install` | install MicroK8s | PSS `restricted`, default-deny network, quotas | done |
| `01-pods` | run a pod | what `restricted` demands of a manifest | done |
| `02-services` | expose a service | Ingress, and the policy that lets it through | done |
| `03-provision` | the same cluster on GCP | Terraform, and the same checks off the laptop | next |
| `04-observe` | watch it under load | Prometheus, Grafana, and what breaks first | planned |

## Layout

A module owns its manifests, its verb, its assertions and their proof. Everything else
is shared, so a new module costs only what is new about it. The gate is not a module:
it judges the whole repository, so it lives at the root.

```
common.mk        the help, security-check, test and dashboard targets, and remote kubectl
lib/check.sh     three jobs, kept apart: where the cluster is and how to reach it,
                 the vocabulary a module asserts in, and the verdict
scripts/         what the gate runs and no published hook covers
NN-name/
  Makefile       the verb this module is about
  kustomize/     what it deploys
  security-check.sh   its assertions, nothing else
  tests/falsify.sh    the proof that those assertions can fail
```

A module says *what* must hold. It never learns where the cluster is, and it is never
handed a transport failure to interpret — the moment an assertion can see the difference
between a dead ssh and a refusing cluster, it gets it wrong.

## Start

```bash
cd 00-install
make init              # creates .env
$EDITOR .env           # set VM_HOST to your ~/.ssh/config alias
make install
make security-check
```

Then each module in order: `cd ../01-pods && make deploy && make security-check`.

`make help` lists the targets of any module.

## The rule this repo follows

`security-check` is a gate, not a report. It exits non-zero when a control it asserts
has stopped holding, and every assertion tries to *violate* the control rather than
read its configuration. **A check that cannot fail proves nothing.**

Which is a claim, until something tests it. `make test` breaks each control on the live
cluster, requires the gate to refuse **for the reason it expects**, and puts the baseline
back. Four corollaries, all four learned by being wrong:

- **A missing prerequisite is not a passing control.** When the namespace or the pod is
  absent the probe fails too, and that failure used to read as a refusal. `require`
  fails the whole check loudly instead.
- **A probe that never started proves nothing either.** Under PSS `restricted` a bare
  `kubectl run` is refused at admission, so the egress probe never existed and its
  silence looked exactly like a working NetworkPolicy. `probe` deploys a pod that
  satisfies the same baseline, and treats its readiness as a prerequisite.
- **An exit status is not an answer.** `kubectl get resourcequota,limitrange` exits 0 on
  an empty namespace. Assertions read back the objects **by name**, never the status of
  a command that had nothing to report.
- **"I could not tell" is not "the control held".** Measured on this cluster: blocked
  traffic, a missing binary and a deleted pod all exit 1, so no negative assertion can
  conclude from a status. Each one names the refusal it expects and calls anything else
  `unknown` — a third verdict that counts as a failure. A transport error never reaches
  an assertion at all: the library aborts with a distinct exit code, and `summary`
  refuses to pass a run in which no assertion ran.

## The gate, before anything reaches a cluster

```bash
pre-commit install       # once: the hooks now run at every commit
pre-commit run --all-files
```

One threat, one hook. The same configuration runs in CI, so local and pipeline cannot
drift: every tool is pinned to the version the workflow installs.

| Threat | Hook |
|---|---|
| a credential reaches the history and stays forever | `gitleaks` |
| a script fails the way its author never tested | `shellcheck` |
| YAML that parses differently than it reads | `yamllint` |
| a manifest the API server would reject | `kubeconform`, on every module built |
| a manifest it would admit while insecure | `kubescape`, NSA baseline |
| an apiVersion valid today and gone at the next upgrade | `pluto`, pinned to the cluster version |

The last three live in `scripts/manifests.sh`, the part no published hook covers: build
each module with kustomize, validate the result, then score the **concatenation**. All
modules at once, because a pod scanned alone looks unprotected: the NetworkPolicy
covering it lives in module 00.

Modules are found on disk rather than through git, because an untracked module is
exactly the one nobody has reviewed yet.

## A note on speed

Every assertion is an SSH round trip, and the handshake used to cost more than the
command it carried: 8 connections per run at 0.36 s each, 61% of the time spent
connecting rather than checking. `kube()` now opens one connection and reuses it, which
took a full `make test` from 48 s to 11 s without weakening a single assertion — each
optimisation was followed by breaking a control again to confirm the gate still screams.

## Reference

- Pod Security Standards — https://kubernetes.io/docs/concepts/security/pod-security-standards/
- MicroK8s — https://microk8s.io/
- DevSecOps practices — https://blog.stephane-robert.info/docs/

## License

MIT, see [LICENSE](LICENSE).
