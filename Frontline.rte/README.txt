FRONTLINE AUTO-BATTLER — EXPERIMENTAL BUILD

Copy Frontline.rte into Cortex Command's Mods directory. Restart the game and
choose Frontline Auto-Battler and the Frontline Battlefield scenario. Play as
team 1 against the CPU. The panel opens automatically; Tab toggles it. Move
the mouse to position the small square cursor and left-click controls.

Choose counts using +/-, cycle through unlocked weapons, then click DEPLOY.
AUTO repeats the selected batch whenever funds, capacity, and cooldown permit.
A batch is all-or-nothing. The same cooldown applies in both modes. Each
team earns income over time and a bounty when an opposing actor dies. The
research tree improves income and bounties, and unlocks more unit types and
weapons. Research unlocks must be bought in order. Destroy the enemy brain.

Balance: edit the CONFIG table near the start of Frontline.lua. In particular,
DEPLOY_COOLDOWN_MS = 10000 controls the deployment interval in milliseconds.
Roster and equipment entries, costs, income, bounty, and caps are alongside it.

This build has passed Lua rule tests but has not been play-tested in the game:
the game's graphics initialization crashed in the build environment. Scene
loading, engine API compatibility, mouse behavior, AI navigation, and balance
still need in-game verification. Research and purchases reset each match.
