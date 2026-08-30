# 03-services — publish one path, keep the rest shut

The pod from `01-pods` answers on 8080 and nothing can reach it: module 00 denies by
default. Exposing it means adding one route, from one source, on one port.

| Object | Role |
|---|---|
| `Service` (ClusterIP) | a stable name and IP in front of an ephemeral pod, 80 → 8080 |
| `Ingress` | routes HTTP arriving on the node to that Service |
| `NetworkPolicy` | lets the ingress controller through the default-deny, and only it |

Without the third, the first two apply cleanly and the site answers 503 forever. That
is the lesson: on a namespace that denies by default, publishing is a network
decision, not a routing one.

## Run

```bash
make deploy && make security-check
```

Then `curl http://<vm-ip>/` from your workstation.

## Two choices worth defending

**The policy selects its source by namespace, not by pod label.** MicroK8s 1.35
replaced the NGINX ingress controller with Traefik and the controller labels changed
with it. The `ingress` namespace did not. A policy written against labels breaks on
that upgrade, silently, with a 503.

**It selects its target by `app: hello`, not the whole namespace.** Opening a
namespace-wide path would expose the next pod deployed here the day it starts,
without anyone deciding it.

## What the check proves

A ready endpoint exists, the Ingress serves the pod over HTTP, and a pod in another
namespace still cannot reach the Service. The third assertion is the one that matters:
it proves the path opened is the only one.
