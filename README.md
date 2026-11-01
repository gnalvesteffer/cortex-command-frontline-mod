# Cortex Command Frontline Mod

An experimental solo auto-battler scenario for Cortex Command Community Project 7.0.0. Deploy batches of soldiers, buy research, and defend your brain against an AI opponent on a long battlefield.

## Installation

Copy `Frontline.rte` into the game's `Mods` directory and restart Cortex Command. In the activity selector, choose **Frontline Auto-Battler** and start on **Frontline Battlefield**.

## Playing

Choose a difficulty in the game setup screen; it affects the AI's decision rate, while both sides use the same income rules. A two-step setup wizard opens before the battle. Set starting funds, base income, team unit cap (32 per side by default), outpost bonuses, and call-in availability, then review and click **Start Battle**. Both teams wait without income or deployments during setup. The 15-second grace period begins when the battle starts, and settings then lock.

Press **Tab** to open or close the panel. It locks the camera and uses the mouse while open. On **Squad**, select counts and weapons, use presets or save one custom batch for the match. Research unlocks the armored Gatling Drone and the missile launcher that counters armor. Select an order and target outpost on the Squad tab. Orders immediately update living troops and also apply to future deployments: Rush attacks the enemy brain, Advance moves to the selected post then resumes the attack, and Defend moves there and holds. Choose a captured outpost as a forward spawn for an extra 25 oz per unit.

West provides +2 income per second, Center reduces research costs by 20%, and East reduces call-in cooldowns by 20%. An uncontested troop captures a post over time; each is marked by a small outpost structure. On **Support**, select an outpost and order an artillery strike, medics, cover, mines, a dropped bomb, an orbital cannon burst, or a shield. The shield requires an owned post and blocks hostile strikes, bombs and orbital cannon fire for 20 seconds. Support research increases cover and mine deliveries or extends the orbital burst.

Click **DEPLOY** or enable **AUTO**; both share a cooldown and require funds and capacity for the whole batch. The closed-panel HUD shows deployment status. Both brains are armed with Gatling Guns and defend their bunkers. The Base tab offers brain armor, repairs and a rebuildable roof turret; the AI can buy these with the same prices and restrictions. Destroy the enemy brain to win. The match report displays deployments, team losses, captures, earned funds, enemy brain health lost and observed enemy troop health loss. Health loss is approximate and is not attributed to a particular attacker.

## Configuration

Edit the `CONFIG` table at the beginning of `Frontline.rte/Frontline.lua` to tune the roster, prices, income, bounty, unit limits, opening grace time, outpost capture and income, and call-in costs and cooldowns. `DEPLOY_COOLDOWN_MS` sets the shared manual and automatic deployment interval; its default is 10,000 ms.

## Status and testing

This is an experimental build. An earlier build loaded in Cortex Command 7.0.0, and the command panel and camera lock were verified interactively. These latest changes, the complete match, balance, AI, and compact HUD still need further play-testing. Bounties currently count enemy deaths rather than verified kill attribution.

Run the isolated rules and HUD checks from the repository root with `luajit tests/test_frontline.lua`. These checks use mocks and do not replace in-game testing.
