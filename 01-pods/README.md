# 01-pods — what `restricted` demands

A single nginx pod, admitted into the namespace of module 00. Every line of
`kustomize/pod.yaml` answers one of its refusals.

| Declaration | The refusal it answers |
|---|---|
| `runAsNonRoot`, `runAsUser: 101` | PSS rejects a container that may run as root |
| `allowPrivilegeEscalation: false` | PSS rejects a process that can gain privileges |
| `capabilities: drop [ALL]` | PSS rejects retained kernel capabilities |
| `seccompProfile: RuntimeDefault` | PSS rejects an unconfined syscall filter |
| `readOnlyRootFilesystem: true` | not required by PSS — required by us |
| three `emptyDir` volumes | the consequence: nginx needs `/tmp`, `/var/run`, `/var/cache/nginx` |
| `requests` **and** `limits` | the ResourceQuota rejects a pod that omits either |
| `automountServiceAccountToken: false` | the pod calls no API, so it gets no credentials |

## Run

```bash
make deploy && make security-check
```

## What the check proves

It reads `id -u` inside the running container, tries to `touch /probe` on the
read-only filesystem, and reads the capability list the API server actually stored. A
manifest is an intention; the running container is the fact.

Break one line of the manifest, redeploy, and watch the matching assertion turn red —
that is the fastest way to understand what each setting buys.
