FRONTLINE AUTO-BATTLER — EXPERIMENTAL BUILD

Copy Frontline.rte into the game Mods folder and restart. Choose Frontline
Auto-Battler and Frontline Battlefield. Difficulty affects the AI decision rate; both teams use the same income rules. A two-step
wizard lets you choose and review starting funds, income, unit cap, outpost
bonuses and call-ins. Neither team earns or deploys until you click START
BATTLE; the 15-second grace period then begins and settings lock.

Tab toggles the panel. The tabs are Squad, Research, Support, Base, Battle and
Setup, in that order. Squad selection is manual and has no presets. The default
selection is 3 units. Six Squad Size upgrades increase the maximum by one each,
up to 9 units.

Unit research follows the Coalition Light -> Coalition Heavy -> Dummy/Gatling
Drone -> Browncoat chain. Weapon and equipment unlocks are in the Arsenal tree.
The Research tab has categorized pages, including a Support page; connector
lines mark prerequisites. `CONFIG.research` is a one-based Lua array: its
indices run from 1 through 29 and match the prerequisite and support references.
Support Jammer is one node at index 13 with levels 1 and 2. Energy Shield is
index 27 and requires Turret research (26) and Support Jammer level 2 (13).
Weapon Cache Pod is index 28 and requires Mining Call-In (14). Squad Size +1
is index 29, with up to six upgrades.

Support call-ins have research unlocks. Orbital Gatling Barrage unlocks Orbital
Precision Strike, then Carpet Bomb. Mines follow Cover and the turret follows
Mines. Medic research unlocks a Medic Drone delivery, and level two increases
the drop to two drones. Mining Call-In drops a mining unit. The Support Jammer's
two levels increase its duration.

Weapon Cache Pod is delivered by a landing pod that opens and dispenses three
random firearms from loaded-game HDFirearm presets, including exotic weapons.
The upgradeable base turret progresses from a Gatling Turret at level 1 to the
custom Frontline HE Turret at level 2; its upgrade has 1.5x base range.

The approach hallway floor meets the main vault floor. The mirrored upper
turret room aligns with the vault exit, leaving a clear firing lane toward the
battlefield.


The Support tab orders the offense as Orbital Gatling Barrage, Orbital Precision
Strike, then Carpet Bomb. The Support Jammer blocks hostile call-ins aimed within
its 180-pixel radius; its researched level determines its duration. It refunds an
intercepted call-in before payload release; a Carpet Bomb run intercepted after
releasing bombs loses its remaining drops without a refund. Released bombs and
weapons are not blocked. Energy Shield requires both Turret research and Support
Jammer level 2; it destroys hostile projectiles inside its 180-pixel bubble for
30 seconds. The Gatling barrage fires 72 rounds plus up to 36 from turret
research, with 16 fragments per round. Carpet Bomb releases three bombs across
its flight path.

Both manual and automatic deployment cost funds and share a cooldown. Both brains have Gatling Guns. Buy brain armor,
repairs and a rebuildable upper-room turret on the Base tab. Destroy
the enemy brain to win. The match report tracks deployments, losses, captures,
funds and observed health loss; health loss is not attacker-attributed.

Tweak balance values at the start of Frontline.lua. This build needs further
in-game testing, especially vehicle navigation, forward spawn, shields and the
match report. Research and settings reset each match.

The AI uses the same units, research, base upgrades, orders, forward spawns and call-ins,
with normal prices, cooldowns, capacity limits and prerequisites. It scores
objectives against pressure and resource needs, gathers six units at safe owned
posts before advancing together, retains targets until capture, and saves funds
for near-term research instead of automatically deploying. A four-unit player
rush within 800 pixels of its brain overrides that plan: the AI recalls field
units to defend home and prioritizes troop deployment over optional research.
