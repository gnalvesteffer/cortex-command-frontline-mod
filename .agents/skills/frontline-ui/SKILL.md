---
name: frontline-ui
description: Guidance for building and maintaining the Frontline Cortex Command mod's Lua UI and command panels.
---

# Frontline UI

Use this skill when changing UI panels, controls, or mouse interactions in `Frontline.rte/Frontline.lua`.

## Cyclic controls

- A single button that cycles a value through an ordered set of multiple states MUST support both mouse buttons: left-click advances to the next value; right-click moves to the previous value.
- Use the same option order in both directions, wrapping at either end. Prefer the existing `cycleOption(options, current, direction)` helper rather than duplicating wraparound logic.
- Mark single-button value-cycling controls as reversible in the panel's button helper call. Keep paired increment/decrement controls (such as separate `+`/`−` or left/right arrow buttons) directional: their right-click actions MUST NOT invert their normal left-click actions. Keep one-shot actions (purchase, deploy, call-in, navigation that does not cycle a value) left-click only.
- When adding or changing a single-button cyclic control, verify left-click, right-click, and wraparound at both ends of the option list. Check that right-click does not trigger left-click behavior. For paired increment/decrement controls, verify each button only performs its indicated direction and is not reversed by right-click.
