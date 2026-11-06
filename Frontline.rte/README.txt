FRONTLINE AUTO-BATTLER — EXPERIMENTAL BUILD

Copy Frontline.rte into the game Mods folder and restart. Choose Frontline
Auto-Battler and Frontline Battlefield. Difficulty affects the AI decision rate; both teams use the same income rules. A two-step
wizard lets you choose and review starting funds, income, unit cap, outpost
bonuses and call-ins. Neither team earns or deploys until you click START
BATTLE; the 15-second grace period then begins and settings lock.

All outpost bonuses stack: each income post adds 5 oz/s, while each research
or call-in post multiplies the remaining price or cooldown by 0.8. Two such
discount posts reduce the original value by 36%; rounding up happens once.

Tab toggles the panel. The tabs are Squad, Research, Support, Base, Battle and
Setup, in that order. The panel hides and restores only player 0's HUD, preserving
its previous state when closed or when the activity ends. Squad selection is
manual and has no presets. The default selection is 3 units. Six Squad Size
upgrades increase the maximum by one each, up to 9 units.

Unit research follows the Coalition Light -> Coalition Heavy -> Dummy/Gatling
Drone -> Browncoat chain. Weapon and equipment unlocks are in the Arsenal tree.

Grenade Packs research equips selected human units with three Coalition Frag
Grenades. This preset does not activate on release; its four-second fuze starts
when activated (normally as the native throw begins), so death-release does not
arm the grenade. Frontline human actor variants retain NativeHumanAI and use the
native ThrowTarget behavior after a Frontline-only check for visible, reachable
enemies and friendly clearance around the predicted blast area. Unsafe throws
retain native firearm behavior when available, or native Sentry behavior without
a firearm; neither path changes current orders.
The Research tab cycles through Foundations, Arsenal, Support Network and
Defense Network; lines run downward from prerequisites to unlocks.
`CONFIG.research` is a one-based Lua array: its
indices run from 1 through 30 and match the prerequisite and support references.
Support Jammer is one node at index 13 with levels 1 and 2. Energy Shield is
index 27 and requires Turret research (26) and Support Jammer level 2 (13).
Weapon Cache Pod is index 28 and requires Mining Call-In (14). Squad Size +1
is index 29, with up to six upgrades. Assault Squad is research index 30.

Support call-ins have research unlocks. Orbital Gatling Barrage unlocks Orbital
Precision Strike, then Carpet Bomb. Mines follow Cover and the turret follows
Mines. Medic research unlocks a Medic Drone delivery, and level two increases
the drop to two drones. Mining Call-In delivers a Dummy with a pistol and
Light Digger; it seeks deposits and digs. The Support Jammer's two levels
increase its duration.

Assault Squad research unlocks a 1000 oz call-in with a 120-second base cooldown.
Its dropship delivers three Coalition Light soldiers at 200 current and maximum
health. The eligible arsenal scans HDFirearm presets in every loaded module,
then requires each qualified preset to be creatable with positive game gold
value. Only qualified preset names ending in " Stationary" are excluded.
Base.rte, Coalition.rte, Browncoats.rte, Dummy.rte, Ronin.rte and Techion.rte
form the stock module set. Firearms from all other loaded modules above the
best stock value are eligible. Each Assault Squad randomly samples three
eligible exotic firearms without replacement. Stock firearms fill only if
fewer than three eligible exotics exist. The selected qualified name is stored
per passenger and reattached after dropship extraction if cargo transfer lost it.


Enemy AI personas use distinct research priorities and support preferences.
Offensive strikes, carpet bombs and orbital fire are considered only for
researched, affordable, cooled-down legal enemy concentrations with sufficient
friendly clearance. Cover can also target a threatened off-post friendly squad:
the dropship location is grounded at the squad's field position, away from
nearby enemies, the opposing base exclusion and active enemy jammers.

Cover and Mines research each have three levels, delivering 3, 4 or 5
payloads per call-in. Cover research costs 280 / 560 / 840 oz; Mines costs
360 / 720 / 1080 oz. Mines requires Cover Lv.1, and Turret requires Mines
Lv.1. Call-in prices and cooldowns do not increase with research level.

Weapon Cache Pod is delivered by a landing pod that opens and dispenses three
random firearms using qualified names from all loaded HDFirearm presets, including exotic mods.
Each team receives one free baseline HE turret in its upper bunker room when battle starts; the Base tab can upgrade it to HE Mk2 or rebuild it after destruction.

The upgradeable base turret uses a custom cannon firing the engine's damaging
explosive fragmentation shell. Both levels have 600 health (six times the stock
Gatling Turret's 100) plus doubled body and mount gib thresholds. Their HE cannon
retains the 1,000-rounds-per-minute cadence, and each 12-round magazine takes
four seconds to reload. The Frontline cannon spins up in 200 ms rather than the
inherited stationary Gatling's 1,300 ms; Mk2 inherits the shorter spin-up.
The main turret's base shell adds ten higher-sharpness Frontline fragments to
the stock ten; Mk2 adds ten stronger Frontline fragments, for 30 per shell.
Their un-sharp target-acquisition ray is twice the stock Gatling ray at the
viewport width when built; sharp aim also adds the weapon's SharpLength. Both
variants use increased Perceptiveness for a broader native scan while preserving
stock aim limits, terrain-blocked sight rays and enemy-team filtering. Both
enemy and player builds retain these benefits when rebuilt.

The approach hallway's walkable floor is aligned to the main vault exit on both
teams. Mirrored upper turret rooms align with the battlefield-facing outer exits;
the stock Gatling head and cover use their original pivot alignment; a single
HE cannon fires outward above the lower corridor roof.

Battlefield and Expanse have surface-only terrain and no underground tunnels.
Highlands retains its nine surface outposts and adds two horizontally mirrored
capture points inside separate roofed bunker halls, each linked by a vertical
ladder shaft. Capture and AI proximity use the hall's Y level; non-climbing
vehicles stage at the surface entry. Forward drops and aircraft call-ins land
at that clear surface entry, while jammer and energy-shield call-ins remain
underground. Dirt backdrop layers fill the non-solid tunnel cavities.
All three hall right ends use the stock Base.rte/End D cap on scene load; the
generator uses its matching indexed mask so collision, artwork and dirt backdrop align.


Randomized surface rocks, barriers and crates follow the ground on all maps.
Their footings are seated into the terrain even where the surface slopes.


The Support tab orders the offense as Orbital Gatling Barrage, Orbital Precision
Strike, then Carpet Bomb. The Support Jammer blocks hostile call-ins aimed within
its 180-pixel radius; its researched level determines its duration. It refunds an
intercepted call-in before payload release; a Carpet Bomb run intercepted after
releasing bombs loses its remaining drops without a refund. Released bombs and
weapons are not blocked. Energy Shield requires both Turret research and Support
Jammer level 2; it destroys hostile projectiles inside its 180-pixel bubble for
30 seconds. The Gatling barrage fires 72 rounds plus up to 36 from turret
research, with 16 fragments per round. Carpet Bomb releases three visible
Standard Bomb-sprite shells; each creates and activates its heavy explosive
payload only on collision.

Forward drops to captured posts cost an extra 25 oz per unit for each interval
of progress toward the enemy base, rounded up. The distance between bases is
divided into one interval per surface outpost; both teams use the same rule.
Highlands cave drops land at their paired surface entries and retain the normal
nine surface cost tiers. The Squad SPAWN selector shows the per-unit surcharge.
Base deployments have no surcharge. Configure the 25 oz tier using
unitSurcharges.forwardDeployment in Frontline.lua.

Both manual and automatic deployment cost funds and share a cooldown. Both brains have Gatling Guns. Each team starts with one free HE turret in its upper bunker room; upgrade it to HE Mk2 or rebuild it after destruction on the Base tab. Destroy the enemy brain to win. The match report tracks deployments, losses, captures, funds and observed health loss; health loss is not attacker-attributed.

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
The AI considers unlocked offensive support against clustered enemies on or
between outposts, favoring groups threatening friendly positions. It avoids
targets near friendly actors, brains or turrets using conservative buffers;
stray fragments can still cause friendly fire.
Each battle randomly chooses one of ten personalities: aggressive, defensive,
economic, balanced, strategic, raider, guardian, artillery, engineer or
vanguard. Their goal, support, investment and research preferences differ;
urgent base threats override those preferences.
The AI fills squads with unlocked units, compares safe forward sites against
the base when a preferred landing is unaffordable, and can spend its deployment
reserve during an urgent defense. It promotes research responses to the
player's observed focus and considers equipment unlocks. These choices still
use normal squad limits, funds, deployment prices and cooldowns.

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
