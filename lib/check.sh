# shellcheck shell=bash
# Sourced by every module check. A module writes only its assertions, then `summary`.
#
# No `set -e`: every assertion runs so the report is complete, and the exit status
# comes from the failure count.
VM_HOST="${1:-}"
failures=0

# Remote when a host is given, local otherwise — so the same checks run in CI.
# Both branches hand the command to a shell as one string, so quoting behaves
# identically whether the cluster is a VM or this machine.
# shellcheck disable=SC2029
kube() {
  if [ -n "$VM_HOST" ]; then
    ssh "$VM_HOST" "sg microk8s -c 'microk8s kubectl $*'"
  else
    sudo sh -c "microk8s kubectl $*"
  fi
}

# Run a shell command on the machine hosting the cluster.
# shellcheck disable=SC2029
node() {
  if [ -n "$VM_HOST" ]; then
    ssh "$VM_HOST" "$*"
  else
    sh -c "$*"
  fi
}

check() { # check <name> <ok|ko> [detail]
  if [ "$2" = ok ]; then
    echo "pass  $1"
  else
    echo "FAIL  $1${3:+: $3}"
    failures=$((failures + 1))
  fi
}

summary() {
  echo
  [ "$failures" -eq 0 ] && { echo "all checks hold"; exit 0; }
  echo "$failures check(s) failed"
  exit 1
}
