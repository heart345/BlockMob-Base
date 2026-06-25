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
- `AttackRange = 72`
- `AttackVerticalRange = 34`
- Leap frequency: `LeapChance = 0.65`, `LeapAttemptInterval = 0.3`, cooldown `1.2-2.4`.
- Climb speed defaults: `bmb_spider_climb_speed = 105`, `bmb_spider_climb_mantle_speed = 72`, `bmb_spider_climb_descend_speed = 88`.
- Death pose: `DeathTipDegrees = 180` and the root bone uses `Angle(0, tip, 0)` with no side randomization, so spider corpses flip belly-up instead of side-tipping like other mobs.
- Fatal hits now use base `DeathKnockback*`: after `BeginBMBDeath`, the dead mob gets a short horizontal shove plus vertical lift before the frozen death pose takes over. This keeps the spider's 180-degree flip visible instead of rotating into the floor. Spider `OnKilled` restores climb movetype first so wall-climb `MOVETYPE_NONE` cannot swallow the death shove.

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

## Audio Notes

Spider audio is packaged under `sound/bmb/mob/spider/`:

- `say1-4` for ambient and hurt
- `step1-4` for client-side distance-driven footsteps
- `death` for `OnKilled`
- confirmed melee hits on players reuse `sound/bmb/damage/hit1-3.ogg`

`bmb_autorun.lua` registers the spider sound resources for clients. The OGG files were converted from `D:\BMBTools\解包音频\minecraft\sounds\mob\spider` to 44100 Hz mono for Source compatibility.

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

Low one-block chase barriers are handled by the same spike, but they do not satisfy the high-target `bmb_spider_climb_chase_min_target_up` gate. `IsBMBSpiderLowChaseClimbReason()` whitelists blocked movement reasons such as `path_carrot`, `direct`, `move_to`, `source_path`, `path`, `chase_active_wall`, and `chase_active_blocked`; those may start the climb while target Z is level. The climb records `BMBSpiderClimbAllowLowTarget` so target-aware cancellation does not abort the mantle as `target_dropped` halfway through.

`sv_pathfinder.lua` supports `preferClimbOverHop`, but spiders do not enable it by default. `bmb_spider_prefer_climb_over_hop` defaults to `0` because suppressing hop whenever climb reaches the same cell can block normal one-block crawl entrances: if a cave entrance has a climbable wall beside it, the spider may choose the wall instead of entering the low opening. Turn the convar on only as a temporary diagnostic when testing cases where a duplicate hop edge is known to be worse than climb.

The older proactive chase bridge still exists as fallback. It scans a small fan of target/forward/side directions, walks toward the wall foot using `chase_climb_approach`, and can start the spike immediately when already close to a detected wall.

Important: a wall scan hit is not enough to enter `climb_spike`. `RunBMBSpiderClimbSpike()` must first call `GetBMBSpiderClimbPinnedPosition()` at the current position and seed `BMBSpiderClimbLastPinnedPos` from that pinned point. Without this gate, a far wall can be seen by the wider scan while the pin trace still cannot reach it, causing repeated `start ... finish lost_wall` flashes.

`climb_spike` uses `SetPos`, so it must not rely only on Source solid traces. `CanBMBSpiderMoveHull()` and mantle landing checks also scan the target hull with `ents.FindInBox()` and reject live players, BMB mobs, NPCs, and NextBots. If a player stands on the spider while it climbs, the move is treated as blocked/held instead of tunneling through and trapping the player.

Low one-block crawl spaces are not climb targets. `RunBMBSpiderClimbSpike()` now checks `HasBMBSpiderClimbVerticalClearance(startPinned, normal)` before entering `climb_spike`; if the pinned wall position cannot move upward by at least half a block, it logs `skip climb start: low ceiling` and leaves the route to normal ground movement. During the climb spike, `BMBSpiderClimbFloorZ` plus `ClampBMBSpiderClimbPosition()` keep SetPos targets from dropping below the starting floor height.

One-block-high crawl regressions can also come from shared direct movement, not spider climb. On 2026-06-25 the verified blocker was `ENT:IsMovementTargetSafe()`: the forward wall TraceHull was lifted by `GroundProbeHeight` and then extended too high, so a low ceiling at `z+1` became a false `"wall"` for spider, cave spider, wolf, and any other mob shorter than a full block. The fix is `bmb_safety_ceiling_clearance` plus `wallTopZ`, clamping only the wall probe's `maxs.z` below the mob's real `CollisionMaxs.z`. Keep `GroundProbeHeight` high enough for ground/cliff probes; do not move this fix into `sv_pathfinder.lua`, hop launch checks, or spider climb gating unless new logs prove a different blocker.

## Cancellation Notes

The chase bridge records whether a combat target existed at climb start. After `bmb_spider_climb_chase_cancel_grace`, it cancels if:

- target is invalid: `target_lost`
- target is no longer meaningfully above the start height: `target_dropped`
- target moved clearly away from the climbed wall: `target_moved_away`

`path_climb` bypasses the old chase-only "target must be above" startup gate so same-level wall-over routes can work. It also does not set target-aware cancellation; the A* route is responsible for deciding that the wall should be climbed.

Blocked low-wall chase climbs also bypass only the height part of the gate. They still require the wall to be between the spider and the combat target via the wall-dot check, and they still cancel if the target clearly moves away from the climbed wall.

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
