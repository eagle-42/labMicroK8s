# 02-docs — judge before deploying

Every other module checks what is *running*. This one checks the *files*, before
anything reaches a cluster. Same discipline, earlier and cheaper.

| Threat | Hook |
|---|---|
| a credential reaches the history and stays forever | `gitleaks` |
| a script fails the way its author never tested | `shellcheck` |
| YAML that parses differently than it reads | `yamllint` |
| a manifest the API server would reject, or admit while insecure | `manifests.sh` (kubeconform + kubescape) |

## Run

```bash
pre-commit install       # once: the hooks now run at every commit
pre-commit run --all-files
```

The same configuration runs in CI, so local and pipeline cannot drift.

## Why `manifests.sh` exists at all

The first three are published hooks — using them is the whole point. The fourth is
the part no one publishes: build each module with kustomize, validate the result
against the Kubernetes schema, then score the **concatenation** with kubescape. All
modules at once, because a pod scanned alone looks unprotected: the NetworkPolicy
covering it lives in module 00.

Modules are found on disk rather than through git, because an untracked module is
exactly the one nobody has reviewed yet.
