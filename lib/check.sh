# shellcheck shell=bash
#
# The vocabulary a module uses to assert. A module says WHAT must hold; this file
# decides where the cluster is and how to reach it, and keeps a transport failure
# from ever being read as a verdict. A check that could not tell must not report
# that a control held - that confusion is what every defect here has come from.
#
# No `set -e`: every assertion runs so the report is complete, and the exit status
# comes from the counters below.

failures=0
assertions=0
unknowns=0

# An unset VM_HOST is not a declaration that the cluster is this machine; it is a
# missing prerequisite. Taking it from $1 was worse: a script run without an
# argument silently retargeted this machine and reported on a cluster nobody asked
# about. CI sets CI=true and means it.
if [ -z "${VM_HOST:-}" ] && [ "${CI:-}" != true ]; then
  echo "VM_HOST unset: run this through make, or set CI=true to target this machine" >&2
  exit 2
fi

# ── where, and how ───────────────────────────────────────────────────────────
# Two different decisions, both settled once at load time rather than re-tested on
# every call: how to reach the machine, and how to gain kubectl's privileges there.
SSH_OPTS=(-o ConnectTimeout=5
          -o ServerAliveInterval=5 -o ServerAliveCountMax=3
          -o ControlMaster=auto
          -o ControlPath="${TMPDIR:-/tmp}/labk8s-%r@%h:%p"
          -o ControlPersist=30)

if [ -n "${VM_HOST:-}" ]
then reach=(ssh "${SSH_OPTS[@]}" "$VM_HOST"); as_kube="sg microk8s -c"
else reach=(sh -c);                           as_kube="sudo sh -c"
fi

# stderr is folded into stdout so a transport error becomes the detail an assertion
# prints, while the non-zero status keeps it out of the verdict. It is deliberately
# NOT an early exit: every call site captures output, so an `exit` here would run in
# a command substitution and kill only the subshell - the abort would be swallowed
# into the very variable the assertion then reports on. The first prerequisite of
# every module aborts outside a substitution, which is what actually stops the run.
node() { timeout 90 "${reach[@]}" "$*" 2>&1; }

# `set -f` before kubectl: the command reaches a login shell on the far side, where
# a jsonpath's [0] or * would otherwise be a filename pattern - a file on the node
# could then replace the whole command.
kube() { node "$as_kube 'set -f; microk8s kubectl $*'"; }

# The address a client outside the cluster would use. Not the node's own loopback:
# the hostPort DNAT that publishes the ingress controller does not apply to traffic
# the node originates, so curling 127.0.0.1 there tests a path nobody uses.
node_addr() {
  local a
  a=$(ssh -G "${VM_HOST:-}" 2>/dev/null | awk '/^hostname /{print $2}')
  printf '%s' "${a:-127.0.0.1}"
}

# ── the verdict ──────────────────────────────────────────────────────────────
# Three outcomes, not two. `unknown` exists because "I could not tell" is the answer
# that used to be filed as success - and it costs its own exit code, or the suites
# that consume this contract would read it as a refusal and pass on it.
check() { # check <name> <ok|ko|unknown> [detail]
  assertions=$((assertions + 1))
  case "$2" in
    ok)      echo "pass  $1" ;;
    ko)      echo "FAIL  $1${3:+: $3}"; failures=$((failures + 1)) ;;
    unknown) echo "?     $1${3:+: $3}"; unknowns=$((unknowns + 1)) ;;
    # A mistyped verdict printed nothing and counted as neither. Silence that looks
    # like health, in the function that owns the verdict.
    *)       echo "?     $1: '$2' is not a verdict"; unknowns=$((unknowns + 1)) ;;
  esac
}

# 0 the controls hold, 1 one of them was violated, 2 the gate could not tell.
# Callers depend on the three being distinct: a suite that reads 2 as a refusal
# reports pass for a test that never happened.
summary() {
  echo
  if [ "$assertions" -eq 0 ] || [ "$unknowns" -gt 0 ]
  then echo "the check could not run"; exit 2
  fi
  [ "$failures" -eq 0 ] && { echo "all checks hold"; exit 0; }
  echo "$failures check(s) failed"; exit 1
}

# An unmet prerequisite is the same verdict as an unreadable fact. It only ends the
# report early, because nothing after it would mean anything.
abort() { check "$1" unknown "${2-}"; summary; }

# ── the shapes of assertion ──────────────────────────────────────────────────
# Reading a fact can fail for reasons that have nothing to do with the control, so
# an unreadable fact is `unknown` and never `ko`: ABSENT is not VIOLATED. The
# pattern '.' is the non-empty test, so this is also how a module asserts presence.
assert_matches() { # assert_matches <name> <pattern> <output> <status>
  if   [ "$4" -ne 0 ]; then check "$1" unknown "could not read: $(printf '%s' "$3" | head -1)"
  elif printf '%s' "$3" | grep -qE "$2"; then check "$1" ok
  else check "$1" ko "no line matching /$2/"
  fi
}

# "This must be refused" cannot conclude from an exit status: measured on this
# cluster, blocked traffic, a missing binary and a deleted pod all exit 1. So the
# caller names the refusal it expects, and anything else is `unknown`.
assert_refused() { # assert_refused <name> <expected-refusal-pattern> <output> <status>
  if   [ "$4" -eq 0 ]; then check "$1" ko "it was allowed"
  elif printf '%s' "$3" | grep -qE "$2"; then check "$1" ok
  else check "$1" unknown "$(printf '%s' "$3" | head -1)"
  fi
}

# A NetworkPolicy is only exercised by real traffic, so the probe is a real pod -
# and the whole dance is one assertion rather than a helper a module has to sequence
# correctly. The pod satisfies the same baseline as any other here: under PSS
# restricted a bare `kubectl run` is refused at admission, and that refusal looked
# exactly like a working NetworkPolicy. It declares its own resources, because
# depending on a LimitRange the falsification suite deletes would make it fail for a
# reason unrelated to what it probes. Its name carries the pid: two runs sharing one
# name means one run's cleanup lands in the other's assertion window.
assert_unreachable() { # assert_unreachable <name> <namespace> <url>
  local pod="probe-$$" out rc
  out=$(kube "apply -n $2 -f -" <<EOF
apiVersion: v1
kind: Pod
metadata: {name: "$pod"}
spec:
  securityContext: {runAsNonRoot: true, runAsUser: 65534, seccompProfile: {type: RuntimeDefault}}
  containers:
  - name: probe
    image: busybox:1.38.0
    command: [sleep, "120"]
    securityContext: {allowPrivilegeEscalation: false, capabilities: {drop: [ALL]}}
    resources: {requests: {cpu: 100m, memory: 128Mi}, limits: {cpu: 250m, memory: 128Mi}}
EOF
  ) || abort "probe in $2" "not admitted: $(printf '%s' "$out" | head -1)"

  if ! kube "wait --for=condition=Ready pod/$pod -n $2 --timeout=60s" >/dev/null 2>&1; then
    out=$(kube "get pod $pod -n $2 -o jsonpath={.status.containerStatuses[0].state}")
    kube "delete pod $pod -n $2 --ignore-not-found --wait=false" >/dev/null 2>&1
    abort "probe in $2" "never became ready: ${out:-no status}"
  fi

  out=$(kube "exec $pod -n $2 -- wget -q -T 2 -O- $3"); rc=$?
  kube "delete pod $pod -n $2 --ignore-not-found --wait=false" >/dev/null 2>&1
  assert_refused "$1" '^wget:' "$out" "$rc"
}

# ── prerequisites ────────────────────────────────────────────────────────────
require() { # require <kind> <name> [-n namespace]
  local out
  out=$(kube "get $*") || abort "prerequisite: $*" "$(printf '%s' "$out" | head -1)"
}

# A namespace that exists is not a namespace you can use: `get` exits 0 while it is
# Terminating, and every pod created in it is then refused - a refusal an assertion
# would have counted as its control working.
require_namespace() { # require_namespace <name>
  local phase
  phase=$(kube "get namespace $1 -o jsonpath={.status.phase}") \
    || abort "prerequisite: namespace $1" "$(printf '%s' "$phase" | head -1)"
  [ "$phase" = Active ] || abort "prerequisite: namespace $1" "phase is ${phase:-unknown}, not Active"
}
