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

The approach hallway's walkable floor is aligned to the main vault exit on both
teams. Mirrored upper turret rooms align with the battlefield-facing outer exits,
with Gatling and HE muzzles clear of the corridor roof and facing outward.


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

Forward drops to captured posts cost an extra 25 oz per unit for each interval
of progress toward the enemy base, rounded up. The distance between bases is
divided into one interval per outpost; both teams use the same rule.
The Squad SPAWN selector shows the selected destination's per-unit surcharge.
Base deployments have no surcharge. Configure the 25 oz tier using
unitSurcharges.forwardDeployment in Frontline.lua.

Both manual and automatic deployment cost funds and share a cooldown. Both brains have Gatling Guns. Buy brain armor,
repairs and a rebuildable upper-room turret on the Base tab. Destroy
the enemy brain to win. The match report tracks deployments, losses, captures,
funds and observed health loss; health loss is not attacker-attributed.

Tweak balance values at the start of Frontline.lua. This build needs further
in-game testing, especially vehicle navigation, forward spawn, shields and the
match report. Research and settings reset each match.

The AI builds a bounded battlefield/resource snapshot and selects interruptible
goals with hysteresis: defend a threatened base or post, regroup, then advance
or rush. It scores only feasible deployments, research, base upgrades and
support actions against the current threat and budget, executing its best
spend through the same purchase/cooldown rules as the player. Personality is a
score bias, not a replacement for tactical context. Successful player
deployments, research and call-ins are tracked for adaptation. A base threat
strength of 4 within 800 pixels interrupts the current goal for home defense;
the goal clears below strength 2.

Both sides issue orders and purchases through the same team commander. Rush,
Advance and Defend apply to the whole team, not separate squads; miners keep
their mining behavior. Defend can target the base or an outpost, selected with
PREV/NEXT on the Squad tab. Advance targets an outpost, holds it until captured,
then attacks the enemy brain. New troops follow the current order when they
deploy or disembark. Forward deployment and all purchases use the same
ownership, cost and cooldown rules for both teams.

Urgent base or owned-post threats are checked every 250 ms and interrupt the
normal decision cadence without running the full AI every frame. Deployment
capacity includes dropship passengers whose unit slots are reserved in transit.

Single-button value cycles use left click for next and right click for previous;
paired plus/minus and previous/next controls act only in their labeled direction
on left click.
