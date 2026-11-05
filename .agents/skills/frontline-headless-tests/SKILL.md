---
name: frontline-headless-tests
description: Guidance for building the Cortex Command Community Project engine and smoke-testing Frontline activities headlessly on Linux.
---

# Frontline Headless Tests

## Build prerequisites and safety

- Use the requested Cortex Command Community Project fork: `https://github.com/gnalvesteffer/Cortex-Command-Community-Project`.
- Linux builds use Meson and Ninja, with GCC (the project documents GCC >=13 and Meson >=1.6). Required system dependencies include OpenGL, FLAC, minizip, TBB, LZ4 >=1.9, and libpng. SDL3, LuaJIT, and luabind are built from bundled sources; a system LuaJIT is not required.
- Build out-of-tree and run the game from an isolated engine clone/runtime. The headless test runner stages the current Frontline module into the clone's `Mods/Frontline.rte` and restores/removes that staged copy on exit; no manual staging is needed.
- Keep `DISPLAY` and `WAYLAND_DISPLAY` unset, isolate `HOME` and `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, and `XDG_DATA_HOME`, and bound the process with a timeout. Do not use the user's display for headless tests.

## Linux clone and build

Choose an isolated temporary root and set `FRONTLINE_DIR` to the local Frontline repository's `Frontline.rte` directory. The fork README's Linux workflow is `meson setup` followed by `ninja`; this keeps the build separate from the source clone:

```sh
TEST_ROOT=/absolute/path/to/isolated/cccp-test
ENGINE_DIR="$TEST_ROOT/engine"
BUILD_DIR="$TEST_ROOT/build"
FRONTLINE_DIR=/absolute/path/to/cortex-command-frontline-mod/Frontline.rte
mkdir -p "$TEST_ROOT"
git clone --branch development https://github.com/gnalvesteffer/Cortex-Command-Community-Project.git "$ENGINE_DIR"
meson setup "$BUILD_DIR" "$ENGINE_DIR"
ninja -C "$BUILD_DIR"
```

The build uses the Meson/Ninja steps documented by the fork README. Resolve the listed build dependencies before running these commands; do not install packages without authorization. Retain `ENGINE_DIR` and `BUILD_DIR` for the integration test below.

## Offscreen OpenGL requirement

`-headless` suppresses presentation and runs simulation without real-time pacing, but the engine still initializes SDL video, creates an OpenGL window/context, and initializes GL rendering resources. The SDL dummy video driver does not support the OpenGL context this engine requires; `SDL_VIDEODRIVER=dummy` failed during window/context startup. Do not use it for this engine.

A Linux SDL3 offscreen backend backed by EGL can provide the required context on an environment with working offscreen EGL/OpenGL support. Set `SDL_VIDEODRIVER=offscreen` while keeping `DISPLAY` and `WAYLAND_DISPLAY` unset. If offscreen GL context creation fails, stop; do not fall back to a visible display or install packages without authorization.

## Frontline headless deployment integration test

The runner requires the built engine, an isolated engine source/runtime clone rooted exactly at `$TEST_ROOT/engine`, and the local Frontline repository's `Frontline.rte` path. It always stages a fresh copy from `FRONTLINE_DIR`, adds the test fixture only to that disposable copy, and restores the prior `ENGINE_DIR/Mods/Frontline.rte` (or removes the staged test module if none existed) on success, failure, or handled signal. `TEST_ROOT` must be outside the Frontline repository.

```sh
TEST_ROOT=/absolute/path/to/isolated/cccp-test
ENGINE_DIR="$TEST_ROOT/engine"
BUILD_DIR=/absolute/path/to/cccp-build
FRONTLINE_DIR=/absolute/path/to/cortex-command-frontline-mod/Frontline.rte
TEST_ROOT="$TEST_ROOT" ENGINE_DIR="$ENGINE_DIR" BUILD_DIR="$BUILD_DIR" \
  FRONTLINE_DIR="$FRONTLINE_DIR" tests/run_headless_frontline.sh
```

The runner uses isolated HOME/XDG directories, unsets `DISPLAY` and `WAYLAND_DISPLAY`, sets `SDL_VIDEODRIVER=offscreen` and `FRONTLINE_TEST_RESULT=$TEST_ROOT/frontline-test-result.txt`, and applies a 45-second timeout. It launches the real `Frontline Auto-Battler` on `Frontline Battlefield` with `-headless -cout -seed 0 -activity GAScripted ... -sim-updates 5`. The result file is removed before launch and is authoritative: the runner accepts only the exact PASS payload, and treats FAIL, empty, missing, stale, or unexpected content as failure. The full console log remains at `$TEST_ROOT/headless-frontline.log` for diagnostics.

The test invokes the actual `StartBattle`, batch calculation, and team-0 `TeamCommander:Deploy` methods. To exercise deployment within five updates, the fixture sets activity timers past the grace and cooldown gates. It checks the default squad costs 165 oz, the real deploy path consumes exactly 165 oz from 450 (engine and Frontline team funds become 285), deployment stats record three, and insufficient funds (164 oz) rejects without constructing actors or changing funds/stats. It verifies the three constructed team-0 Frontline Bandits have the expected identity and each has one Base.rte Pistol before engine updates. After updates, it matches all three captured UniqueIDs to live `MovableMan.Actors` and rechecks team, module, and preset identity (not inventory, which AI/simulation may change). The fixture writes PASS/FAIL to `FRONTLINE_TEST_RESULT`; the runner requires the exact payload `PASS deployment units=3 funds=285 inventory=Base.rte/Pistol insufficient-funds=unchanged` and a zero engine exit status.

The corrected real run passed. On an earlier run, one registered actor had an empty inventory/equipped item after two updates. The test verifies constructed loadout before updates; post-update inventory persistence is not covered and remains under investigation. No cause for the observed change has been established.

The real engine emitted Generic Battle Music sound/DSP-not-ready warnings during previous runs; they did not prevent engine startup or exit. This test advances only five simulation updates and deliberately sets timers past their gates, so it does not verify normal grace/cooldown timing, player input, AI decision-making, or full-match gameplay. Existing mocked Lua tests remain separate and cover additional logic without invoking the engine.

