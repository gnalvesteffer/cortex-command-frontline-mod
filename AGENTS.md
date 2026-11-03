# AGENTS.md - Cortex Command Frontline Mod

## Overview
This is a Cortex Command mod called "Frontline" that adds squad-based tactical gameplay with research, call-ins, and outpost capture mechanics.

## Testing Workflow
1. **Syntax check**: Run `ccmake --test` to validate Lua syntax across all mod files.
2. **In-game test**: Run `ccmake --run` to launch Cortex Command with the mod loaded.
3. **Manual verification**: Test each feature in-game (bomb call-in, turret drop, weapon unlocks, etc.).

## Key Files
- `Frontline.rte/Frontline.lua` - Main mod script (~103k chars) containing all gameplay logic
- `Frontline.rte/Scenario.ini` - Scenario configuration including weapon/device presets
- `Frontline.rte/OrbitalRound.lua` - Orbital bombardment projectile behavior
- `Frontline.rte/BombRunBomb.lua` - Bomb run bomb entity (falls and explodes on impact)

## Research System
Research items are 1-indexed in the CONFIG.research array:
- Index 3: Infantry: Heavy Troop (tier 1)
- Index 4: Faction: Dummy / Gatling (tier 2)
- Index 5: Faction: Browncoat (tier 3)
- Index 6: Equipment: SMG
- Index 7: Equipment: Shotgun
- Index 8: Equipment: Sniper Rifle
- Index 9: Equipment: Missile Launcher
- Index 14: Equipment: Assault Rifle

Weapons require both tier unlock AND specific research items (see CONFIG.weapons for details).

## Call-In System
Call-ins use the CreateSupportShip function to spawn dropships that deliver payloads. Bomb runs are handled separately with scripted flight paths in UpdateCallIns.

Key call-in types:
- strike: Precision orbital strike
- bomb: Scripted bomb run (3 bombs dropped at intervals)
- turret: Static Gatling Turret delivery
- mines/cover: Defensive equipment drops
- orbital: Orbital Gatling Cannon barrage

## Gotchas
- Bomb entities must be created as pixel entities (CreateMOPixel), not TDExplosive objects, to avoid immediate detonation
- Turret dropship ships must be saved to the pending drop entry for UpdateCallIns to process them
- Always check if a ship still exists before accessing its properties in UpdateCallIns
- Weapon pricing and unlock progression should be balanced carefully

## Development Notes
- Use `skill_view(name='cortex-command-modding')` for detailed Cortex Command modding guidance
- The mod uses Lua scripting with the Cortex Command engine API
- All changes should be tested before committing