# AGENTS.md - Cortex Command Frontline Mod

## Overview
This is a Cortex Command mod called "Frontline" that adds squad-based tactical gameplay with research, call-ins, and outpost capture mechanics.

## Testing Workflow
1. **Syntax check**: Run `for f in Frontline.rte/*.lua; do luajit -b "$f" /dev/null || exit; done`.
2. **Regression tests**: Run `luajit tests/test_ai.lua`, `luajit tests/test_units.lua`, `luajit tests/test_support_callins.lua`, `luajit tests/test_frontline.lua`, and `luajit tests/test_ui_layout.lua`.
3. **Optional real-engine headless integration tests**: Follow `.agents/skills/frontline-headless-tests/SKILL.md` and run `tests/run_headless_frontline.sh` for deployment and all 12 call-in branches when an isolated offscreen OpenGL environment and built engine are available. These complement, and do not replace, the mocked regression tests or manual in-game testing.
4. **In-game test**: Launch `/var/home/xorberax/CortexCommand.linux/CortexCommand.AppImage` with the mod loaded, then verify the changed feature paths in-game.

## Key Files
- `Frontline.rte/Frontline.lua` - Main mod script (~103k chars) containing all gameplay logic
- `Frontline.rte/Scenario.ini` - Scenario configuration including weapon/device presets
- `Frontline.rte/OrbitalRound.lua` - Orbital bombardment projectile behavior
- `Frontline.rte/BombRunBomb.lua` - Visible shell impact creates and activates the heavy explosive payload
- `Frontline.rte/FrontlineGrenadeAI.lua` - Frontline-only native HumanAI grenade throw hook

## Research System
`CONFIG.research` is an ordered Lua array: its research indices are one-based, matching Lua array positions and the `requires`, `requiresAll`, `supportResearch`, and UI label references. The research tree runs from 1 through 30. Support Jammer is one node at index 13 with levels 1 and 2; Cover (22) and Mines (23) each have three levels delivering 3, 4, or 5 payloads. Energy Shield is index 27 and requires both Turret (index 26) and Support Jammer level 2 (index 13). Weapon Cache Pod is index 28 and requires Mining Call-In (index 14). Squad Size +1 is index 29, repeatable up to six times; Assault Squad is support research index 30.

The research UI has four categorized pages: Foundations, Arsenal, Support Network, and Defense Network. Support Jammer upgrades extend duration. Medic Drone research provides delivery, with its second level increasing the delivery to two drones. Mining Call-In drops a mining unit.

Grenades use the Coalition.rte Frag Grenade (ActivatesWhenReleased=0) and its timed fuze, which starts when activated (normally at throw); Frontline deployments retain three per selected human. Frontline actor variants hook native HumanAI's attack-behavior selection to use ThrowTarget only for visible, reachable enemies with friendly clearance at the predicted landing area; unsafe targets retain native firearm behavior when available or native Sentry behavior without one, preserving orders.

## Call-In System
Weapon Cache Pod is delivered by a landing pod, which opens and dispenses three random firearms from loaded-game HDFirearm presets, including exotic weapons. It is distinct from dropship-delivered payloads.
- Assault Squad (index 30) delivers three 200-HP Coalition Light soldiers for 500 oz on a 60-second base cooldown. Its pool scans loaded HDFirearm presets, requires creation and positive value, excludes only qualified names ending in " Stationary", and selects every other loaded-module firearm above the best stock value; rotating windows reach the full pool, with best stock guns filling only if fewer than three eligible exotics exist.

Key call-in types:
- strike: Orbital Precision Strike
- bomb: Carpet Bomb, a three-shell visible run with heavy explosives activated only on impact
- turret: Static Gatling Turret delivery
- mines/cover: Defensive equipment drops
- orbital: Orbital Gatling Barrage
- energyShield: Bubble field that destroys hostile projectiles
- assaultSquad: Assault Squad, three Coalition Light passengers with exotic loaded-game firearms

Bomb runs release three visible inert Frontline Carpet Bomb MOSRotating shells along their flight path; each shell's supported MOSRotating collision callbacks create and activate the Frontline Heavy Bomb TDExplosive on impact. Released payloads are not intercepted by the Support Jammer. Orbital Gatling Barrage fires 72 rounds, with a 36-round research bonus and 16 fragments per round.

## Base Upgrades
Both factions use an HE turret for their upgradeable base turret; the upgrade path is HE→HE Mk2 (200 health). The acquisition ray is doubled from stock but remains unsharp at construction viewport range.

The tabs are ordered Squad, Research, Support, Base, Battle, Setup. Squad selection uses manual unit configuration without presets. Squad size starts at 3 and can reach 9 through six Squad Size upgrades.

## Gotchas
- Carpet Bomb releases inert, renderable MOSRotating shells; their impact callback alone creates and activates Frontline Heavy Bomb TDExplosives
- Grenade packs use the safe Coalition timed-fuze preset; FrontlineGrenadeAI only invokes native ThrowTarget after visible, reachable, friendly-clearance checks pass
- Turret dropship ships must be saved to the pending drop entry for UpdateCallIns to process them
- Always check if a ship still exists before accessing its properties in UpdateCallIns
- Weapon pricing and unlock progression should be balanced carefully

## Development Notes
- Use `skill_view(name='cortex-command-modding')` for detailed Cortex Command modding guidance
- The mod uses Lua scripting with the Cortex Command engine API
- All changes should be tested before committing
