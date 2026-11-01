# Cortex Command Frontline Mod

An experimental solo auto-battler scenario for Cortex Command Community Project 7.0.0. Deploy batches of soldiers, buy research, and defend your brain against an AI opponent on a long battlefield.

## Installation

Copy `Frontline.rte` into the game's `Mods` directory and restart Cortex Command. In the activity selector, choose **Frontline Auto-Battler** and start on **Frontline Battlefield**.

## Playing

Press **Tab** to open or close the command panel. While it is open, the camera is locked and the mouse controls the panel. Choose unit counts and equipment, then click **DEPLOY**, or enable **AUTO** to deploy the selected batch whenever it is affordable and capacity is available. Each deployment starts a shared cooldown. Income accrues over time, and enemy deaths award bounties. Research upgrades income, bounties, and available units and equipment. Destroy the enemy brain to win.

When the panel is closed, a compact HUD shows funds, income, bounty, batch cost, unit count, and deployment status. The normal observation controls move the camera.

## Configuration

Edit the `CONFIG` table at the beginning of `Frontline.rte/Frontline.lua` to tune the roster, prices, income, bounty, and unit limits. `DEPLOY_COOLDOWN_MS` sets the shared manual and automatic deployment interval; its default is 10,000 ms.

## Status and testing

This is an experimental build. The scenario has loaded in Cortex Command 7.0.0, and the command panel and camera lock have been verified interactively. The complete match, balance, AI, and compact HUD still need further play-testing. Bounties currently count enemy deaths rather than verified kill attribution.

Run the isolated rules and HUD checks from the repository root with `luajit tests/test_frontline.lua`. These checks use mocks and do not replace in-game testing.
