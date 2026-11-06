#!/bin/sh
set -eu

: "${ENGINE_DIR:?Set ENGINE_DIR to the isolated Community Project source/runtime root}"
: "${BUILD_DIR:?Set BUILD_DIR to its separate Meson build directory}"
: "${FRONTLINE_DIR:?Set FRONTLINE_DIR to the local Frontline.rte directory}"
: "${TEST_ROOT:?Set TEST_ROOT to an isolated writable test directory}"

SUITE=${FRONTLINE_TEST_SUITE:-all}
case "$SUITE" in
    deployment|callins) RUN_SUITES=$SUITE ;;
    all) RUN_SUITES="deployment callins" ;;
    *) printf '%s\n' "Unknown FRONTLINE_TEST_SUITE: $SUITE (expected deployment, callins, or all)" >&2; exit 2 ;;
esac

mkdir -p "$TEST_ROOT"
TEST_ROOT=$(CDPATH= cd -- "$TEST_ROOT" && pwd -P)
ENGINE_DIR=$(CDPATH= cd -- "$ENGINE_DIR" && pwd -P)
EXPECTED_ENGINE_DIR="$TEST_ROOT/engine"
if [ "$ENGINE_DIR" != "$EXPECTED_ENGINE_DIR" ]; then
    printf '%s\n' "Refusing unsafe engine path: ENGINE_DIR must resolve exactly to $EXPECTED_ENGINE_DIR" >&2
    exit 2
fi
BUILD_DIR=$(CDPATH= cd -- "$BUILD_DIR" && pwd -P)
FRONTLINE_DIR=$(CDPATH= cd -- "$FRONTLINE_DIR" && pwd -P)

python3 - "$TEST_ROOT" "$FRONTLINE_DIR" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()
frontline_repo = Path(sys.argv[2]).resolve().parent
if root == frontline_repo or frontline_repo in root.parents:
    print("Refusing unsafe TEST_ROOT inside the Frontline repository", file=sys.stderr)
    sys.exit(1)
PY

MODULE_DIR="$ENGINE_DIR/Mods/Frontline.rte"
TEST_HOME="$TEST_ROOT/home"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
[ -x "$BUILD_DIR/CortexCommand" ] || { printf '%s\n' "Missing engine binary: $BUILD_DIR/CortexCommand" >&2; exit 2; }
[ -f "$FRONTLINE_DIR/Frontline.lua" ] || { printf '%s\n' "Missing local Frontline.lua: $FRONTLINE_DIR" >&2; exit 2; }

mkdir -p "$ENGINE_DIR/Mods" "$TEST_HOME" "$TEST_HOME/config" "$TEST_HOME/cache" "$TEST_HOME/data"
RUN_DIR=$(mktemp -d "$TEST_ROOT/.frontline-headless.XXXXXX")
HAD_MODULE=0
cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -e "$MODULE_DIR" ]; then rm -rf -- "$MODULE_DIR"; fi
    if [ "$HAD_MODULE" -eq 1 ] && [ -e "$RUN_DIR/original-Frontline.rte" ]; then
        mv -- "$RUN_DIR/original-Frontline.rte" "$MODULE_DIR"
    fi
    rm -rf -- "$RUN_DIR"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if [ -e "$MODULE_DIR" ]; then
    mv -- "$MODULE_DIR" "$RUN_DIR/original-Frontline.rte"
    HAD_MODULE=1
fi
cp -a "$FRONTLINE_DIR" "$MODULE_DIR"

run_suite() {
    suite=$1
    result="$TEST_ROOT/frontline-test-result-$suite.txt"
    log="$TEST_ROOT/headless-frontline-$suite.log"
    cp "$FRONTLINE_DIR/Frontline.lua" "$MODULE_DIR/Frontline.lua"
    if [ "$suite" = callins ]; then
        cat "$SCRIPT_DIR/headless_callins.lua" >> "$MODULE_DIR/Frontline.lua"
    else
        cat "$SCRIPT_DIR/headless_frontline.lua" >> "$MODULE_DIR/Frontline.lua"
    fi
    rm -f "$result"

    set +e
    (
        cd "$ENGINE_DIR"
        env -u DISPLAY -u WAYLAND_DISPLAY \
            HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/config" \
            XDG_CACHE_HOME="$TEST_HOME/cache" XDG_DATA_HOME="$TEST_HOME/data" \
            CCCP_SETTINGSPATH="$TEST_ROOT/headless-settings-$suite.ini" \
            SDL_VIDEODRIVER=offscreen FRONTLINE_TEST_RESULT="$result" \
            timeout --signal=TERM --kill-after=5s 45s \
            "$BUILD_DIR/CortexCommand" -headless -cout -seed 0 \
            -activity GAScripted 'Frontline Auto-Battler' 'Frontline Battlefield' \
-sim-updates 10
    ) >"$log" 2>&1
    run_status=$?
    set -e

    if [ "$run_status" -ne 0 ]; then
        printf '%s\n' "Headless $suite engine exited with status $run_status; log: $log" >&2
        return 1
    fi
    python3 - "$result" "$suite" "$log" <<'PY'
from pathlib import Path
import sys

result_path = Path(sys.argv[1])
suite = sys.argv[2]
log = sys.argv[3]
expected = {
    "deployment": "PASS deployment units=3 funds=285 inventory=Base.rte/Pistol insufficient-funds=unchanged",
    "callins": "PASS callins strike=PASS medic=PASS cover=PASS mines=PASS bomb=PASS turret=PASS orbital=PASS shield=PASS bubble=PASS mining=PASS weaponPod=PASS assaultSquad=PASS team1=PASS",
}[suite]
if not result_path.is_file():
    print(f"{suite} result file missing: {result_path}; log: {log}", file=sys.stderr)
    sys.exit(1)
result = result_path.read_text(errors="replace").strip()
if result != expected:
    detail = result if result else "<empty>"
    label = "Call-in suite blocked" if result.startswith("BLOCKED callins ") else "Integration result mismatch"
    print(f"{label}: {detail}; log: {log}", file=sys.stderr)
    sys.exit(1)
PY
    printf '%s\n' "$result"
    printf '%s\n' "Full engine log: $log"
}

for suite in $RUN_SUITES; do
    run_suite "$suite"
done
