# AGENTS.md - Cortex Command Frontline Mod

## Overview
This is a Cortex Command mod called "Frontline" that adds squad-based tactical gameplay with research, call-ins, and outpost capture mechanics.

## Testing Workflow
1. **Syntax check**: Run `for f in Frontline.rte/*.lua; do luajit -b "$f" /dev/null || exit; done`.
2. **Regression tests**: Run `luajit tests/test_ai.lua`, `luajit tests/test_units.lua`, `luajit tests/test_support_callins.lua`, and `luajit tests/test_frontline.lua`.
3. **In-game test**: Launch `/var/home/xorberax/CortexCommand.linux/CortexCommand.AppImage` with the mod loaded, then verify the changed feature paths in-game.

## Key Files
- `Frontline.rte/Frontline.lua` - Main mod script (~103k chars) containing all gameplay logic
- `Frontline.rte/Scenario.ini` - Scenario configuration including weapon/device presets
- `Frontline.rte/OrbitalRound.lua` - Orbital bombardment projectile behavior
- `Frontline.rte/BombRunBomb.lua` - Bomb run bomb entity (falls and explodes on impact)

## Research System
Research is 1-indexed in `CONFIG.research`:
- 1: Coalition Light
- 2: Income +2/s; 3: Bounty +15
- 4: Coalition Heavy; 5: Dummy / Gatling Drone; 6: Browncoat Light
- 7–10: SMG, Shotgun, Sniper Rifle, Missile Launcher
- 11–14: Medic Drone levels and Shield levels
- 15: Mining call-in; 16: Perception training
- 17–21: Assault Rifle, Medikit Packs, Grenade Packs, Sidearms, Unit Armor
- 22: Orbital Gatling Barrage; 23: Cover; 24: Mines
- 25: Orbital Precision Strike; 26: Carpet Bomb; 27: Static Turret; 28: Energy Shield

Unit unlocks follow the tier chain (1 → 4 → 5 → 6). Support availability is controlled by `CONFIG.supportResearch`.

## Call-In System
Call-ins use the CreateSupportShip function to spawn dropships that deliver payloads. Bomb runs are handled separately with scripted flight paths in UpdateCallIns.

Key call-in types:
- strike: Orbital Precision Strike
- bomb: Carpet Bomb, a scripted three-bomb run
- turret: Static Gatling Turret delivery
- mines/cover: Defensive equipment drops
- orbital: Orbital Gatling Barrage
- energyShield: Bubble field that destroys hostile projectiles

## Gotchas
- Bomb entities must be created as pixel entities (CreateMOPixel), not TDExplosive objects, to avoid immediate detonation
- Turret dropship ships must be saved to the pending drop entry for UpdateCallIns to process them
- Always check if a ship still exists before accessing its properties in UpdateCallIns
- Weapon pricing and unlock progression should be balanced carefully

## Development Notes
- Use `skill_view(name='cortex-command-modding')` for detailed Cortex Command modding guidance
- The mod uses Lua scripting with the Cortex Command engine API
- All changes should be tested before committing