---
name: frontline-headless-screenshots
description: Capture and inspect Frontline gameplay screenshots with an isolated offscreen Linux CCP build; never use the visible game or personal Userdata.
---

# Frontline Headless Screenshots

## Safety and prerequisites

- Use a Linux CCP build with SDL3's offscreen video backend and functioning EGL/OpenGL. Use `SDL_VIDEODRIVER=offscreen`; do not use SDL's dummy driver or fall back to a visible display. **Omit `-headless` for screenshots:** this mode deliberately skips `FrameMan:Draw`, so the screen buffer may be blank or stale (`engine/Source/Main.cpp:460-464`). An SDL offscreen context with `DISPLAY` and `WAYLAND_DISPLAY` unset draws without showing a visible window.
- Build and run from an isolated CCP clone/runtime outside the Frontline checkout. Set `TEST_ROOT` to a disposable directory such as `/tmp/frontline-map-offscreen`; use only its `engine/`, `build/`, `home/`, settings file, logs and screenshots. Stage `Frontline.rte` only into that clone's `engine/Mods/Frontline.rte`; keep any screenshot fixture in that disposable copy, never in the repo.
- Keep `DISPLAY` and `WAYLAND_DISPLAY` unset. Point `HOME`, all XDG directories and `CCCP_SETTINGSPATH` into `TEST_ROOT`. In that isolated settings file set `MuteMaster = 1` under `SettingsMan`; this supported setting mutes all audio (`Source/Managers/SettingsMan.cpp:128-134`, `Source/Managers/AudioMan.h:128-138`) and was used in a successful offscreen capture without audio/DSP warnings in the engine log. `SettingsMan` reads `CCCP_SETTINGSPATH` (`SettingsMan.cpp:72-90`) before `AudioMan` initializes and applies the mute (`Main.cpp:110-124`, `AudioMan.cpp:113-127`). Do not assume `-headless` disables audio.
- Never launch the visible AppImage, use a personal game installation, inspect or copy a user's `Userdata`, or point settings/HOME/XDG variables at personal locations. The game writes screenshots relative to its working directory, so a disposable engine clone keeps output separate from user files.

## Screenshot API and output path

- `engine/Source/Lua/LuaBindingsManagers.cpp:75-95` binds `FrameMan:SaveScreenToPNG`. `engine/Source/Managers/FrameMan.h:295-298` documents that it saves the screen backbuffer, takes a filename base **without** an extension and returns `0` for success / a negative value for failure. `engine/Source/Managers/FrameMan.cpp:511-565` constructs the timestamped PNG name under the screenshot directory, copies the screen buffer, then writes PNG on a detached thread; its return only means the save request was scheduled. Wait for the writer and inspect the exact output; our captures produced a decodable scene PNG even though the console also printed `ERROR: Unable to save bitmap to:` for that file, so do not accept or reject from that message alone.

`engine/Source/System/System.cpp:47-50,55-59,98-105` defines `ScreenShots/` and resolves the working directory from the process current directory. Run with `cwd="$ENGINE_DIR"`: a base such as `FrontlineBattlefield` writes to `$ENGINE_DIR/ScreenShots/FrontlineBattlefield_<timestamp>.png` (the extension and timestamp are added by the engine). The observed capture was `/tmp/frontline-map-offscreen/engine/ScreenShots/FrontlineBattlefield_2026-11-06_04-44-03.829286709.png`.

## Disposable Lua capture fixture

- Append a temporary fixture only to the staged `engine/Mods/Frontline.rte/Frontline.lua`. Capture only in the non-headless offscreen run, after the scene/activity is loaded and multiple rendered frames have passed. This tested fixture uses 400 activity updates as a settling delay; it is not a substitute for checking the resulting image:

```lua
-- Disposable fixture: append only to the isolated staged Frontline.lua.
local screenshotNamesByWidth = {
    [5200] = "FrontlineBattlefield",
    [10400] = "FrontlineExpanse",
    [15600] = "FrontlineHighlands",
}
local originalScreenshotUpdate = Frontline.UpdateActivity
local screenshotUpdateCount = 0
function Frontline:UpdateActivity(...)
    originalScreenshotUpdate(self, ...)
    local screenshotName = screenshotNamesByWidth[SceneMan.SceneWidth]
    if not screenshotName then return end
    screenshotUpdateCount = screenshotUpdateCount + 1
    CameraMan:SetScrollTarget(Vector(SceneMan.SceneWidth / 2, SceneMan.SceneHeight * 0.7), 1, 0)
    FrameMan:SetHudDisabled(true, 0)
    if screenshotUpdateCount == 400 then
        local status = FrameMan:SaveScreenToPNG(screenshotName)
        if status ~= 0 then error("Frontline screenshot failed with code " .. tostring(status)) end
    end
end
```

This is the fixture used in the isolated map capture (`engine/Mods/Frontline.rte/Frontline.lua:3485-3506` there). It selects base names from actual scene width, not a guessed scene name. The Frontline activity's `Scenario.ini` `SceneName` is authoritative: for Expanse or Highlands, change that field only in the staged module to the exact target preset and pass the same scene argument. The default activity selects `Frontline Battlefield`; a mismatched CLI scene argument can be ignored by the activity.
For requested map-area coverage, aim the camera at each chosen representative viewport (for example, base/spawn, route/outpost, cave/gold vicinity) after loading and rendered frames; save distinct filenames and inspect every PNG. A center-only image does not verify other areas. Only the Battlefield center viewport has been verified by this example.

## Launch and verify

Use a fresh isolated clone/build and adjust only the absolute paths below. Stage the module and fixture before launch. Set the staged activity's `SceneName` to the same exact target scene as the command (`Frontline Battlefield` shown):

```sh
TEST_ROOT=/tmp/frontline-map-offscreen
ENGINE_DIR="$TEST_ROOT/engine"
BUILD_DIR="$TEST_ROOT/build"
mkdir -p "$TEST_ROOT/home/config" "$TEST_ROOT/home/cache" "$TEST_ROOT/home/data"
(
  cd "$ENGINE_DIR"
  env -u DISPLAY -u WAYLAND_DISPLAY \
    HOME="$TEST_ROOT/home" \
    XDG_CONFIG_HOME="$TEST_ROOT/home/config" \
    XDG_CACHE_HOME="$TEST_ROOT/home/cache" \
    XDG_DATA_HOME="$TEST_ROOT/home/data" \
    CCCP_SETTINGSPATH="$TEST_ROOT/settings.ini" \
    SDL_VIDEODRIVER=offscreen \
    timeout --signal=TERM --kill-after=5s 45s \
      "$BUILD_DIR/CortexCommand" -cout -seed 0 \
      -activity GAScripted 'Frontline Auto-Battler' 'Frontline Battlefield' \
      -sim-updates 500
) >"$TEST_ROOT/capture-battlefield.log" 2>&1
```

For a different map, use the exact preset name in both the staged activity `SceneName` and `-activity` scene argument: `Frontline Expanse Battlefield` or `Frontline Highlands Battlefield`. `-sim-updates 500` allowed the fixture to capture after its 400th activity update in the verified run. Keep stdout/stderr in the disposable test root.

After the command exits, allow the detached PNG writer to finish, then verify all of the following before accepting the capture:

1. The run log / engine `LogConsole.txt` names the exact intended scene (`SYSTEM: Scene "..." was loaded`) and says the activity successfully started. Reject a failed activity or a different scene, even if an image file exists.
2. Allow the detached write to finish. The exact PNG path must exist and be non-empty under `engine/ScreenShots/`; use the name base and timestamp from the run. This source version printed `ERROR: Unable to save bitmap to:` in runs where the PNG nevertheless existed and decoded correctly, so the message alone is inconclusive—check the exact output.
3. Read/open that exact PNG (for example, with the repository file/image reader) and visually confirm it shows the intended map render, not the loading screen or stale frame. If the log names another scene, the activity failed, the file is absent/empty, or the image is blank/loading/stale, do not report a screenshot pass; recapture only in the isolated clone.

No Userdata inspection or visible-window interaction is part of this workflow. The checked-in map assets, scenario, tests and shared headless-test skill must remain untouched by screenshot capture.