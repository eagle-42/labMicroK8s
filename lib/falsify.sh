# shellcheck shell=bash
#
# The scaffolding of a falsification suite, so a module writes only what it breaks.
# It was written three times before this file existed, and it had already drifted:
# one copy carried a two-branch `if gate` with no rc=2 arm, which filed "the gate
# could not run" as "the control was refused" - a false pass, in the suite whose
# whole job is to make false passes impossible.
#
# shellcheck source-path=SCRIPTDIR source=check.sh
. "$(dirname "${BASH_SOURCE[0]}")/check.sh"

# The module's own gate. Its exit status carries three different facts and only one
# of them is a refusal: 0 the controls hold, 1 an assertion was violated, 2 the gate
# could not tell. Reading any non-zero as "refused" is how a suite reports pass for
# a test that never happened.
gate() { bash security-check.sh >/dev/null 2>&1; }

# The baseline comes back with the module's own verb. A suite that breaks more than
# its own objects overrides this, and must then put back everything it breaks, in
# dependency order. The trap is armed here, before a module's override exists: bash
# resolves a trap's command when it fires, not when it is set, so the override wins.
restore() { make deploy >/dev/null 2>&1; }
trap restore EXIT INT TERM

# Both directions, or the suite lies: a restore that fails silently makes every
# later test pass against a cluster this suite broke.
expect_refusal_then_recovery() { # <control name> <what a still-passing gate means>
  gate; local rc=$?
  case $rc in
    0) check "$1" ko "$2";                                  restore; return ;;
    1) ;;
    *) check "$1" unknown "the gate could not tell (rc=$rc)"; restore; return ;;
  esac
  restore
  gate && { check "$1" ok; return; }
  check "$1" unknown "the gate refused, but the baseline did not come back"; summary
}

# Testing the tests on an already-broken cluster proves nothing about the tests.
falsify() { # falsify <test function>...
  gate || { echo "the gate already fails: repair the cluster before running this" >&2; exit 2; }
  local t
  for t in "$@"; do "$t"; done
  summary
}
