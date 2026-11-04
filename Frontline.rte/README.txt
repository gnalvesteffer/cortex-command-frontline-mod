FRONTLINE AUTO-BATTLER — EXPERIMENTAL BUILD

Copy Frontline.rte into the game Mods folder and restart. Choose Frontline
Auto-Battler and Frontline Battlefield. Difficulty affects the AI decision rate; both teams use the same income rules. A two-step
wizard lets you choose and review starting funds, income, unit cap, outpost
bonuses and call-ins. Neither team earns or deploys until you click START
BATTLE; the 15-second grace period then begins and settings lock.

Tab toggles the panel. In Squad, pick troops and weapons, choose Rush, Advance
or Defend orders and target an outpost. Orders apply to existing troops and
new deployments. Optionally choose an owned forward outpost (+25 oz/unit).
Both teams start with two Ronin Bandits selected; the AI uses that same squad
for its first deployment.
Unit research follows the Coalition Light -> Coalition Heavy -> Dummy/Gatling
Drone -> Browncoat chain. Weapon and equipment unlocks are in the Arsenal tree.
The Research tab has three categorized pages; connector lines mark prerequisites.
Each support call-in has a research unlock. Orbital Gatling Barrage unlocks
Orbital Precision Strike, then Carpet Bomb. Mines follow Cover and the turret
follows Mines. Medic research unlocks a Medic Drone delivery, and its second
level increases the drop to two drones. Shield levels extend the jammer.

The Support tab orders the offense as Orbital Gatling Barrage, Orbital Precision
Strike, then Carpet Bomb. The jammer blocks hostile call-ins aimed within its
180-pixel radius for 20, 60, or 90 seconds depending on research. It refunds an
intercepted call-in before payload release; a Carpet Bomb run intercepted after
releasing bombs loses its remaining drops without a refund. Released bombs and
weapons are not blocked. The Energy Shield destroys hostile projectiles inside
its researched 180-pixel bubble for 30 seconds.
The Gatling barrage fires 72 rounds and 16 fragments per round;
turret research extends it to 108 rounds. Carpet Bomb releases three bombs
across its flight path.

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
for near-term research instead of automatically deploying.
