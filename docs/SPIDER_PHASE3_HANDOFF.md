# Spider Phase 3 Handoff

Last updated: 2026-06-24

## Scope

Spider Phase 3 is currently an incremental chase-climb integration, not a full A* vertical-edge rewrite.

The current implementation keeps the Phase 1 `SetPos` climb spike and adds target-aware scheduling around it:

- Chase can proactively approach climbable walls when the retaliation target is above the spider.
- Active climb can cancel when the chase target drops, is lost, or clearly moves away.
- The shared pathfinder has not been given spider-only vertical climb neighbors yet.

## Key Files

- `gmod_addon/lua/entities/bmb_spider.lua`
- `scripts/check_spider_phase3.ps1`
- `docs/SPIDER_PHASE3_HANDOFF.md`

## Current Spider Tuning

- `WalkSpeed = 100`
- `RunSpeed = 140`
- `AttackMoveSpeed = 140`
- Leap frequency was previously raised with `LeapChance = 0.65`, `LeapAttemptInterval = 0.3`, cooldown `1.2-2.4`.

## Phase 3 Climb Convars

- `bmb_spider_climb_cancel_cooldown` default `1.6`
- `bmb_spider_climb_chase_min_target_up` default `18`
- `bmb_spider_climb_chase_wall_dot` default `0.1`
- `bmb_spider_climb_chase_cancel_grace` default `0.45`
- `bmb_spider_climb_chase_active` default `1`
- `bmb_spider_climb_chase_approach_distance` default `260`
- `bmb_spider_climb_chase_approach_timeout` default `0.45`
- `bmb_spider_climb_chase_start_distance` default `84`

These are `FCVAR_ARCHIVE`. New cvars take defaults on first load; old existing cvars may need console overrides if a tester has saved values.

## Behavior Notes

`RunBMBSpiderAI()` now tries:

1. melee
2. leap
3. `RunBMBSpiderChaseClimb(target)`
4. shared `Chase.Run`
5. if shared chase fails, `RunBMBSpiderChaseClimb(target)` again before `StalkHighTarget` / repath pressure

`RunBMBSpiderChaseClimb(target)` does two things:

- First tries the existing climb spike directly, target-biased.
- If no immediate wall is found, it scans ahead for a wall, walks to the wall foot with `chase_climb_approach`, then lets movement override / forced wall normal start climb.

The wall scan no longer depends only on the flat vector to the target. That vector can be near zero when the player is directly above the spider. Current scan uses a small fan:

- target direction, when available
- spider forward
- target/forward diagonals
- left/right
- rear as a weak fallback

When the wall hit is already close enough (`bmb_spider_climb_chase_start_distance`), the spider skips the approach point and calls the climb spike with `BMBSpiderClimbForcedNormal`. This fixes frontal `direct_blocked` cases where side movement worked but direct chase did not.

Important: a wall scan hit is not enough to enter `climb_spike`. `RunBMBSpiderClimbSpike()` must first call `GetBMBSpiderClimbPinnedPosition()` at the current position and seed `BMBSpiderClimbLastPinnedPos` from that pinned point. Without this gate, a far wall can be seen by the wider scan (`probe + body radius`) while the pin trace still cannot reach it, causing repeated `start ... finish lost_wall` flashes.

## Cancellation Notes

The climb spike records whether a combat target existed at climb start. After `bmb_spider_climb_chase_cancel_grace`, it cancels if:

- target is invalid: `target_lost`
- target is no longer meaningfully above the start height: `target_dropped`
- target moved clearly away from the climbed wall: `target_moved_away`

These finish paths use `bmb_spider_climb_cancel_cooldown` so the spider can resume ground chase instead of instantly re-entering climb.

## Known Caveats

- This is still not real climb-aware A*. It is a chase-layer bridge around the Phase 1 climb spike.
- Wander climb is still mostly opportunistic wall contact / ambient spike, not full path-integrated wall traversal.
- If the spider stands under a target with no nearby vertical face, it should not invent a climb route.
- If future work adds A* vertical climb edges, keep the Phase 1 spike and cancellation semantics unless the new locomotion fully replaces them.

## Validation

Run at least:

```powershell
C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe -Command "& 'H:\工作视频\20251115毕业\glualint.exe' lint gmod_addon/lua/entities/bmb_spider.lua"
powershell -ExecutionPolicy Bypass -File scripts\check_spider_phase0.ps1
powershell -ExecutionPolicy Bypass -File scripts\check_spider_phase1.ps1
powershell -ExecutionPolicy Bypass -File scripts\check_spider_phase2.ps1
powershell -ExecutionPolicy Bypass -File scripts\check_spider_phase3.ps1
powershell -ExecutionPolicy Bypass -File scripts\check_retaliation_targets.ps1
```

When syncing to the live addon, copy:

```powershell
gmod_addon\lua\entities\bmb_spider.lua
```

to:

```powershell
D:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\gmod_addon\lua\entities\bmb_spider.lua
```

Then hot-reload in game:

```lua
lua_refresh_file lua/entities/bmb_spider.lua
```
