# labMicroK8s

A Kubernetes lab on MicroK8s where every module carries the security controls the
same feature would need in production, and a check that fails when they stop working.

Built alongside the LinkedIn course *L'essentiel de Kubernetes*, one module per section.

## Modules

| | Subject | Security angle | State |
|---|---|---|---|
| `00-install` | install MicroK8s | PSS `restricted`, default-deny network, quotas | done |
| `01-pods` | run a pod | what `restricted` demands of a manifest | done |
| `02-docs` | check before deploying | one threat, one hook, in CI and at commit | done |
| `03-services` | expose a service | Ingress, and the policy that lets it through | done |
| `04-deployments` | roll out and back | surviving an update without losing the controls | next |
| `05-namespaces` | isolate tenants | RBAC and per-namespace quotas | planned |
| `06-config-apps` | configure apps | Secrets and ConfigMaps, least privilege | planned |
| `07-volumes` | persist data | storage addon, and who can read it | planned |

## Layout

A module owns its manifests, its verb and its assertions. Everything else is shared,
so a new module costs only what is new about it.

```
common.mk        the help and security-check targets, and remote kubectl
lib/check.sh     kube(), check(), summary() — sourced by every module check
NN-name/
  Makefile       the verb this module is about
  kustomize/     what it deploys
  security-check.sh   its assertions, nothing else
```

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
read its configuration. A check that cannot fail proves nothing.

## Before deploying

```bash
pre-commit install     # once
pre-commit run --all-files
```

Secrets, shell, YAML and manifest validity are judged before anything reaches a
cluster. The same hooks run in CI.

## Reference

- Pod Security Standards — https://kubernetes.io/docs/concepts/security/pod-security-standards/
- MicroK8s — https://microk8s.io/
- DevSecOps practices — https://blog.stephane-robert.info/docs/

## License

MIT, see [LICENSE](LICENSE).
