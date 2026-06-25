# Spider Phase 3 Handoff

Last updated: 2026-06-25

## Scope

Spider Phase 3 now has the first real climb-aware A* slice for spiders.

The Phase 1 `SetPos` climb spike remains the locomotion executor. The new part is decision-layer routing:

- `sv_pathfinder.lua` emits `action = "climb"` only when `options.allowClimb == true`.
- Climb waypoints carry `wallNormal` and `climbHeight` metadata.
- `bmb_base_mob.lua` treats `climb` as a vertical path action and delegates it through `RunBMBPathVerticalAction`.
- `bmb_spider.lua` opts into climb pathing, converts waypoint `wallNormal` into `BMBSpiderClimbForcedNormal`, and runs the existing spike with reason `path_climb`.
- Because spiders are wider than one MC block, climb edges may start from a configurable horizontal distance instead of only the wall-adjacent grid cell.
- Shared chase caches direct wall hits briefly and handles high-target stalk before A* for non-climbing mobs.

## Key Files

- `gmod_addon/lua/entities/bmb_spider.lua`
- `gmod_addon/lua/entities/bmb_base_mob.lua`
- `gmod_addon/lua/bmb/sv_pathfinder.lua`
- `gmod_addon/lua/bmb/sv_behaviors.lua`
- `scripts/check_spider_phase3.ps1`
- `docs/SPIDER_PHASE3_HANDOFF.md`

## Current Spider Tuning

- `WalkSpeed = 100`
- `RunSpeed = 140`
- `AttackMoveSpeed = 140`
- Leap frequency: `LeapChance = 0.65`, `LeapAttemptInterval = 0.3`, cooldown `1.2-2.4`.

## Phase 3 Climb Convars

- `bmb_spider_climb_cancel_cooldown` default `1.6`
- `bmb_spider_climb_chase_min_target_up` default `18`
- `bmb_spider_climb_chase_wall_dot` default `0.1`
- `bmb_spider_climb_chase_cancel_grace` default `0.45`
- `bmb_spider_climb_chase_active` default `1`
- `bmb_spider_climb_chase_approach_distance` default `260`
- `bmb_spider_climb_chase_approach_timeout` default `0.45`
- `bmb_spider_climb_chase_start_distance` default `84`
- `bmb_spider_climb_max_cells` default `6`
- `bmb_spider_climb_edge_cost` default `2.5`
- `bmb_spider_climb_horizontal_cells` default `2`

These are `FCVAR_ARCHIVE`. New cvars take defaults on first load; old saved values may need console overrides on a tester machine.

## Behavior Notes

`RunBMBSpiderAI()` tries:

1. melee
2. leap
3. `RunBMBSpiderChaseClimb(target)`
4. shared `Chase.Run`
5. if shared chase fails, `RunBMBSpiderChaseClimb(target)` again before `StalkHighTarget` / repath pressure

Shared `Chase.Run()` passes `allowClimb` for spiders. For high targets, normal mobs go to `StalkHighTarget()` before burning a full A* segment timeout; spiders skip stalk and let climb-aware A* attempt a route.

The A* climb edge is intentionally spider-only. Zombies, skeletons, sheep, wolves, and other mobs should never receive climb waypoints unless their entity explicitly opts in through pathfinder options.

`path_climb` can begin from a wide-hull-safe grid cell, usually two cells out from the wall for the current spider hull. Before starting the spike, `ApproachBMBSpiderPathClimbWall()` briefly steers into the wall until `GetBMBSpiderClimbPinnedPosition()` succeeds; then the normal Phase 1 climb spike takes over.

The older proactive chase bridge still exists as fallback. It scans a small fan of target/forward/side directions, walks toward the wall foot using `chase_climb_approach`, and can start the spike immediately when already close to a detected wall.

Important: a wall scan hit is not enough to enter `climb_spike`. `RunBMBSpiderClimbSpike()` must first call `GetBMBSpiderClimbPinnedPosition()` at the current position and seed `BMBSpiderClimbLastPinnedPos` from that pinned point. Without this gate, a far wall can be seen by the wider scan while the pin trace still cannot reach it, causing repeated `start ... finish lost_wall` flashes.

## Cancellation Notes

The chase bridge records whether a combat target existed at climb start. After `bmb_spider_climb_chase_cancel_grace`, it cancels if:

- target is invalid: `target_lost`
- target is no longer meaningfully above the start height: `target_dropped`
- target moved clearly away from the climbed wall: `target_moved_away`

`path_climb` bypasses the old chase-only "target must be above" startup gate so same-level wall-over routes can work. It also does not set target-aware cancellation; the A* route is responsible for deciding that the wall should be climbed.

## Known Caveats

- This is not a full 3D surface pathfinder. It emits a vertical edge to the first standable top cell along a solid wall face, then the existing spike performs climb/mantle.
- Wander/debug movement can use climb if it routes through spider `MoveToWorldPosition`, but tuning and acceptance testing are still chase-focused.
- If the spider stands under a target with no nearby vertical face, it should not invent a climb route.
- Too-high walls above `bmb_spider_climb_max_cells` should remain unrouteable.

## Validation

Run at least:

```powershell
C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe -Command "& 'H:\工作视频\20251115毕业\glualint.exe' lint gmod_addon/lua/entities/bmb_spider.lua"
C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe -Command "& 'H:\工作视频\20251115毕业\glualint.exe' lint gmod_addon/lua/entities/bmb_base_mob.lua"
C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe -Command "& 'H:\工作视频\20251115毕业\glualint.exe' lint gmod_addon/lua/bmb/sv_pathfinder.lua"
C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe -Command "& 'H:\工作视频\20251115毕业\glualint.exe' lint gmod_addon/lua/bmb/sv_behaviors.lua"
powershell -ExecutionPolicy Bypass -File scripts\check_spider_phase0.ps1
powershell -ExecutionPolicy Bypass -File scripts\check_spider_phase1.ps1
powershell -ExecutionPolicy Bypass -File scripts\check_spider_phase2.ps1
powershell -ExecutionPolicy Bypass -File scripts\check_spider_phase3.ps1
powershell -ExecutionPolicy Bypass -File scripts\check_block_shape_pathing.ps1
powershell -ExecutionPolicy Bypass -File scripts\check_zombie_phase1.ps1
powershell -ExecutionPolicy Bypass -File scripts\check_retaliation_targets.ps1
```

When syncing to the live addon, copy:

```powershell
gmod_addon\lua\entities\bmb_spider.lua
gmod_addon\lua\entities\bmb_base_mob.lua
gmod_addon\lua\bmb\sv_pathfinder.lua
gmod_addon\lua\bmb\sv_behaviors.lua
```

Then hot-reload in game:

```lua
lua_refresh_file lua/entities/bmb_spider.lua
lua_refresh_file lua/entities/bmb_base_mob.lua
lua_refresh_file lua/bmb/sv_pathfinder.lua
lua_refresh_file lua/bmb/sv_behaviors.lua
```
