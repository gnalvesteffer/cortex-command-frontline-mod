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

## Frontline headless integration tests

The runner requires the built engine, an isolated engine source/runtime clone rooted exactly at `$TEST_ROOT/engine`, and the local Frontline repository's `Frontline.rte` path. It always stages a fresh copy from `FRONTLINE_DIR`, adds the selected fixture only to that disposable copy, and restores the prior `ENGINE_DIR/Mods/Frontline.rte` (or removes the staged mod if none existed) on success, failure, or handled signal. The call-in tests use only the engine's normal loaded game presets; no test-only weapon module is staged. `TEST_ROOT` must be outside the Frontline repository.

```sh
TEST_ROOT=/absolute/path/to/isolated/cccp-test
ENGINE_DIR="$TEST_ROOT/engine"
BUILD_DIR=/absolute/path/to/cccp-build
FRONTLINE_DIR=/absolute/path/to/cortex-command-frontline-mod/Frontline.rte
TEST_ROOT="$TEST_ROOT" ENGINE_DIR="$ENGINE_DIR" BUILD_DIR="$BUILD_DIR" \
  FRONTLINE_DIR="$FRONTLINE_DIR" FRONTLINE_TEST_SUITE=all \
  tests/run_headless_frontline.sh
```

The runner uses isolated HOME/XDG directories, unsets `DISPLAY` and `WAYLAND_DISPLAY`, sets `SDL_VIDEODRIVER=offscreen`, and bounds each engine process with a 45-second timeout. It launches the real `Frontline Auto-Battler` on `Frontline Battlefield` with `-headless -cout -seed 0 -activity GAScripted ... -sim-updates 10`. For each suite it deletes the prior result file, exports an absolute `FRONTLINE_TEST_RESULT`, and requires both exit status 0 and the exact PASS payload; FAIL, empty, missing, stale, or unexpected content fails. Full logs remain at `$TEST_ROOT/headless-frontline-{deployment,callins}.log`. `FRONTLINE_TEST_SUITE` accepts `deployment`, `callins`, or `all` (default).

The deployment fixture invokes the original production `StartActivity`, `StartBattle`, batch calculation, and team-0 `TeamCommander:Deploy` methods. It checks the default squad costs 165 oz, deployment consumes exactly 165 oz from 450 (team funds become 285), deployment stats record three, and insufficient funds (164 oz) rejects without constructing actors or changing funds/stats. Before simulation updates, it verifies each of the three constructed team-0 Frontline Bandits carries one Base.rte Pistol. After updates it matches all three captured UniqueIDs to live actors and rechecks team, module, and preset identity. The result file must contain exactly `PASS deployment units=3 funds=285 inventory=Base.rte/Pistol insufficient-funds=unchanged`.

An earlier run found one registered actor with empty inventory/equipped item after two updates. The test verifies constructed loadout before engine updates and verifies post-update identity/team/module/preset only; inventory persistence after updates is not covered, and the cause of that earlier observation is unverified.

## Real call-in coverage

The call-in fixture invokes the original production `StartActivity` and exercises every supported `TeamCommander:CallIn` kind through the real engine. Production constants live in `Frontline.lua`; this guide references their `CONFIG` keys instead of copying changing numeric values.

### Shared order contract

Research unlocks are defined by `CONFIG.supportResearch[kind]`, and level variants use `CONFIG.research` and `CONFIG.supportEffects`. Each kind's `TeamCommander:CallIn` option selects its own configured cost, timer, and cooldown. A successful order deducts the exact cost, resets its cooldown, and records a player action; outpost bonuses use `ResearchCost` and `CallinCooldown`. Invalid setup/battle state, disabled call-ins, grace period, unknown kind, invalid/restricted target, missing research, hostile Jammer, cooldown, insufficient funds, or unavailable assets must reject without charging or resetting a timer. The fixture checks these gates, research purchases, exact debits, discounts, and cooldown boundaries.

### Per-kind behavior

- **Precision Strike (`strike`)** — gated by `CONFIG.supportResearch.strike`; queue the selected target, wait `CONFIG.CALLIN_STRIKE_DELAY_MS`, create a team-owned `Frontline Precision Projectile` at the configured target ground point/height/velocity, then remove the pending strike at flight completion. A real projectile is forced into a real hostile actor and must detonate, disappear, and create live blast objects.
- **Medic (`medic`)** — gated by `CONFIG.supportResearch.medic`; a real dropship carries and releases the configured live `Medic Drone` actors at the target with the ordering team's ownership. The support research and its higher-count Medic variant are both tested.
- **Cover (`cover`)** — gated by `CONFIG.supportResearch.cover`; all configured research levels must queue and physically release exactly `CONFIG.supportEffects.dropCountByLevel.cover[level]` team-owned Cover Pods at the selected target.
- **Minefield (`mines`)** — gated by `CONFIG.supportResearch.mines`; all configured research levels must queue and physically release exactly `CONFIG.supportEffects.dropCountByLevel.mines[level]` team-owned active mines at the target.
- **Carpet Bomb (`bomb`)** — gated by `CONFIG.supportResearch.bomb`; a team-owned dropship releases every configured shell along its run, then returns and leaves no pending order. Each real shell must collide with terrain or a real actor, be removed, and produce the configured live blast/fragment effects at its own impact.
- **Turret (`turret`)** — gated by `CONFIG.supportResearch.turret`; a real dropship releases one team-owned Gatling Turret at the target ground point, configured for pinned sentry behavior.
- **Orbital Barrage (`orbital`)** — gated by `CONFIG.supportResearch.orbital`; `UpdateCallIns` emits all `CONFIG.CALLIN_ORBITAL_SHOTS`, plus `CONFIG.CALLIN_ORBITAL_BONUS_SHOTS` when the configured Turret research is unlocked. Every live round must retain the target radius, ground-relative height, configured velocity, team and fragment metadata; the completed salvo removes its pending record.
- **Jammer (`shield`)** — gated by `CONFIG.supportResearch.shield`; create a team-owned hostile-support exclusion field whose duration uses the configured Jammer research level. The fixture checks inclusive radius boundaries, friendly-support acceptance, hostile rejection, and field removal after expiry.
- **Energy Shield (`bubble`)** — gated by `CONFIG.supportResearch.bubble`; create a team-owned projectile field using `CONFIG.supportEffects.bubbleShield`. It intercepts hostile projectiles at and inside the configured radius, preserves friendly/outside projectiles, and is removed after expiry.
- **Mining (`mining`)** — gated by `CONFIG.supportResearch.mining`; use the configured mining cost and shared Minefield cooldown, deliver the same real `Dummy` miner with its Base Pistol and Light Digger, then register the released miner for production mining behavior.
- **Weapon Cache (`weaponPod`)** — gated by `CONFIG.supportResearch.weaponPod`; queue distinct loaded firearm preset names, not unmanaged live weapon objects. Spawn a visually distinct metal `MOSRotating` pod, detect actual terrain landing from its collision signal or production ground-contact check, hold through `CONFIG.supportEffects.weaponPod.openDelayMs`, then create/register all configured team-owned HDFirearms at the configured ground spread before removing the pod and pending order. The fixture exercises engine physics without setting `WeaponPodLanded`, verifies all released devices and positions, and checks that the Weapon Pod sprite differs from the Cover Pod.
- **Assault Squad (`assaultSquad`)** — gated by `CONFIG.supportResearch.assaultSquad`; stage the configured count of real Coalition Light Soldiers and deliver them in a real team-owned dropship, then verify each passenger's selected firearm, target placement, and assigned order. Loaded exotic firearms above the stock value ceiling are preferred; if there are fewer than the required count, the remaining slots use the best real loaded stock firearms, so a stock game does not require optional weapon mods.

### Interception, loss, ownership, and scope

Jammer transitions are tested through production updates: delayed Precision Strike interception refunds and removes the order; Orbital interception suppresses the barrage without refund; Bomb Run interception before the first release refunds, while interception after release does not and returns the dropship; Cover is intercepted before launch and in flight; Mining interception disposes of its staged passenger; Weapon Pod is intercepted before spawn and in flight; and Assault delivery is canceled with its staged passengers disposed. Tests also cover lost Cover/Bomb ships, a destroyed unopened Weapon Pod (no refund), and unopened pod disposal. The team-1 success scenario purchases its research through the real commander, orders a targeted Precision Strike and Cover delivery, then checks team ownership, payload, and target placement. The suite directly issues orders through both real commanders; the AI policy that chooses whether or when to request a call-in is outside scope.

The successful integration payload is `PASS callins strike=PASS medic=PASS cover=PASS mines=PASS bomb=PASS turret=PASS orbital=PASS shield=PASS bubble=PASS mining=PASS weaponPod=PASS assaultSquad=PASS team1=PASS`. Real test objects are tracked by unique IDs across engine collections; no source-text assertions, mocked gameplay calls, or injected weapon module is used. The only real input/UI gap is driving production `BeginTargeting`/`UpdateTargeting` with mouse click and Tab: this CCP build exposes UInputMan state readers and cursor positioning to Lua, but no key/button event setters or SDL event enqueueing API. The offscreen Lua fixture cannot inject real input through the engine's supported API; mocked input-state tests are not counted as headless interaction coverage.



