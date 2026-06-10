# Progress Log

## Session: 2026-06-09

### Phase 1: Zombie 手感样机

- **Status:** complete
- Actions taken:
  - 创建 `README.md` 和 `docs/roadmap.md`
  - 创建 GMod addon 骨架
  - 创建 `mcgm_zombie.lua`
  - 修复 `FaceTowards` 报错
  - 将修复后的实体同步到 D 盘 GMod addons 目录
  - 确认本地 Minecraft 源码可读，但版本较旧
  - 加入初版动态 prop 局部避障逻辑
  - 用户在复杂 prop 场景中验证：能最终找到追玩家路径，控制台无报错，但路线不是最优
- Files created/modified:
  - `README.md`
  - `docs/roadmap.md`
  - `gmod_addon/addon.json`
  - `gmod_addon/lua/autorun/mcgm_autorun.lua`
  - `gmod_addon/lua/entities/mcgm_zombie.lua`
  - `.planning/mcgm-main/task_plan.md`
  - `.planning/mcgm-main/progress.md`
  - `.planning/mcgm-main/findings.md`

## Test Results

| Test | Input | Expected | Actual | Status |
|------|-------|----------|--------|--------|
| Spawn Zombie | Spawn `mcgm_zombie` in GMod | NPC appears | Appeared, then errored on `FaceTowards` before fix | fixed_pending_retest |
| Spawn Zombie after fix | Spawn `mcgm_zombie` in GMod | No console errors | No console errors reported | pass |
| Dynamic prop avoidance | Put prop between Zombie and player | Zombie tries side-step around prop | Can eventually chase through complex prop layout, route is not optimal | partial |
| Combat tuning | Let Zombie hit player | Shorter range, 10 HP damage, hit sound, knockback | Code added, needs GMod test | pending |
| Attack timing | Observe hit vs attack gesture | Damage lands near visible swing impact | User observed damage felt earlier than current Source zombie animation | needs_tuning |

## Error Log

| Timestamp | Error | Attempt | Resolution |
|-----------|-------|---------|------------|
| 2026-06-09 | `FaceTowards` nil | 1 | Added `FaceTarget` |
| 2026-06-09 | Wrong refresh command | 1 | Use `lua_refresh_file <path/to/file.lua>` |

### Phase 2: 架构重整与方块寻路切片

- **Status:** in_progress
- Actions taken:
  - Reduced Zombie attack range from `55` to `38`
  - Increased Zombie attack damage from `3` to `10`
  - Added player hit sound table
  - Added light horizontal knockback on successful player hit
  - Increased knockback and vertical lift
  - Delayed hit application to better match visible attack animation
  - Further increased knockback and vertical lift for a more Minecraft-like pop
  - Reviewed `gmod_mc_mob_spec(2).md`
  - Updated project direction from single Zombie tuning to BaseMob + behavior modules + mock block world + A* architecture
  - Created BMB autorun loader
  - Created mock `BMB.BlockWorld`
  - Created `BMB.Pathfinder` A*
  - Created first behavior modules: Wander, Flee, EatGrass
  - Created `bmb_base_mob`
  - Created `bmb_sheep`
  - Synced full addon to the GMod addons directory
  - Reviewed MCSWEP interface docs
  - Updated BMB block size to `36`
  - Added non-active `BMB.RealBlockWorld` adapter draft
  - User verified `bmb_sheep` spawns with no console errors
  - User found Sheep only spins in place and does not flee on hit
  - Adjusted waypoint Z handling and 2D distance checks
  - Added movement interrupt on damage
  - Added explicit BMB `OnTakeDamage` health and injury handling
  - Added `bmb_mock_show` debug overlay command
  - User found Sheep can hit Source walls and walk off platform edges
  - Added Source hull trace and ground probe checks before approaching waypoints
  - Reworked mock block visualization to client-side net/render drawing
  - Added `bmb_mock_show all <duration>` support to show all mock blocks
  - User reported Source safety layer became too conservative near close props
  - Reduced Source safety check to a short forward probe instead of the whole waypoint segment
  - Shrunk safety hull scale to reduce false positives near side props
  - Fixed mock debug block Z by storing ground Z at initialization
  - Added `bmb_mock_reset` to rebuild and show mock world near the player
  - User noted friendly mobs should not dodge players by default
  - Updated BMB safety traces to ignore players, NPCs, and NextBots
  - User found Sheep can bump low walkable props/platform lips but will not step onto them
  - Increased BMB `StepHeight` to `28`
  - Added step-up safety check that allows low obstacles when raised path and landing are clear
  - Added `MaxStepDown = 34` so small downward steps are allowed but cliff drops are rejected
  - User verified step up/down works
  - User verified EatGrass changes mock Grass to Dirt
  - User verified mock block visualization works
  - User found Flee sometimes triggers and sometimes does not
  - Added Flee direct fallback when A* pathing fails
  - Expanded Flee candidate directions and added shorter fallback distances
  - User found physics props pass through BMB mobs and do not cause physics-kill damage
  - Added periodic high-speed physics prop impact detection to BMB base
  - Added `DMG_CRUSH` damage from fast movable physics props
  - Added prop bounce/force feedback on physics impact
  - User verified fast physics props can kill `bmb_sheep`
  - User found prop feedback was wrong: prop bounced backward and flew away too fast after impact
  - Replaced prop reverse bounce force with forward velocity damping
  - Added interruptible behavior waits so hit reactions can break Wander/EatGrass delays
  - Added Sheep flee fallback source from attacker position, damage position, or damage force
  - User verified prop damping feels natural and no longer launches props backward
  - User reported Flee is still inconsistent and walk/flee movement looks jerky
  - Reduced waypoint goal tolerance from `28` to `12` for 36-unit blocks
  - Made Wander wait shorter and allow direct movement fallback
  - Made Flee start with a short direct escape burst before trying longer A* paths
  - Fixed interrupted Wander so it cannot clear the injury interrupt and swallow the next Flee reaction
  - User reported Flee now triggers but runs in visible start/stop segments, and normal walking still looks choppy
  - Added `MoveAlongDirection` to chase a moving look-ahead target instead of fixed segment endpoints
  - Changed Wander to continuous direction cruising with safety checks
  - Changed Flee to stay inside one continuous flee loop until `FleeUntil`, recalculating safe direction in short slices without the visible 0.65s stop/restart cycle
  - Reviewed user video `H:\游戏视频\OBS\2026-06-09 22-12-19.mkv`
  - Confirmed Flee now triggers, but movement still appears choppy
  - Identified weird "dodging player" behavior around 14s as Flee tracking the player's current position during the whole flee window
  - Changed Sheep Flee to use a snapshot of the threat position at injury time instead of live-tracking the player
  - Reduced Sheep Flee duration from `7` seconds to `3.5` seconds
  - Increased Flee direction slice to `0.85` seconds and softened Sheep acceleration/deceleration
  - Re-read architecture docs:
    - `H:\工作视频\20251115毕业\gmod_mc_mob_spec(2).md`
    - `H:\工作视频\20251115毕业\interface-usage.md`
    - `H:\工作视频\20251115毕业\bmb_mcswep_对接补充.md`
  - Confirmed BMB should keep its own `IBlockWorld` interface and use an adapter for MCSWEP `MC.*`
  - Changed Sheep flee time to random `3.5` to `6.0` seconds
  - Added smoothed yaw turning in `FaceTarget` instead of instant per-frame angle snapping
  - Added explicit walk/run activity switching for movement primitives
  - User confirmed Flee behavior is now acceptable; remaining issue is movement position stutter / low update smoothness
  - Found VS Code glualint extension was only a wrapper; user downloaded real `glualint.exe`
  - Verified `H:\工作视频\20251115毕业\glualint.exe` works and linted current BMB Lua files with no errors
  - Added optional Source `Path("Follow")` movement backend behind `bmb_use_source_path`
  - `bmb_use_source_path 1` uses GMod PathFollower when navmesh is available and falls back to manual movement otherwise
  - `bmb_use_source_path 0` restores the prior manual `loco:Approach` movement path for A/B testing
  - User tested `bmb_use_source_path 1` and `0`; both still show movement stutter, so issue is lower than movement backend choice
  - Added BMB debug tools:
    - `bmb_debug_hud 1` client overlay for class/health/state/velocity
    - `bmb_debug_info`
    - `bmb_debug_health <value>`
    - `bmb_debug_speed <walk> <run> <accel> <decel>`
    - `bmb_debug_move <duration> <speed>`
    - `bmb_debug_stop`
    - `bmb_debug_flee [duration]`
  - Added `lua/bmb/sv_debug_tools.lua`
  - Added debug movement hook to `bmb_sheep`
  - Ran `H:\工作视频\20251115毕业\glualint.exe lint` on changed files; passed
  - User reported console `bmb_debug_move` did not move the mob, likely because aim-based command targeting missed the NextBot entity
  - Added Tool Gun STool `lua/weapons/gmod_tool/stools/bmb_debug.lua`
  - STool behavior:
    - Left click selects a BMB mob, including nearest mob around the trace hit point
    - Right click moves selected mob to clicked point
    - Reload stops selected mob debug movement
    - Control panel exposes debug HUD, health, movement speed, acceleration/deceleration, stop, and force flee
  - Extended base debug movement to support `BMBDebugMoveTarget`, not only direction movement
  - Re-ran glualint on changed files; passed
  - User relayed diagnosis from Fable: one-block `loco:Approach` goals can keep NextBot inside the deceleration zone, causing velocity sawtooth
  - Found `bmb_base_mob:Think()` was scheduling the next Think at `CurTime() + 0.08`, which can also reduce behavior coroutine update frequency
  - Changed BMB base Think scheduling back to every tick while keeping physics impact checks internally throttled by `PhysicsImpactInterval`
  - Replaced manual A* waypoint walking with a continuous carrot-point path follower:
    - Waypoint index still advances on proximity
    - `loco:Approach` now receives a projected target 72-150 units ahead along the path
    - Desired speed is maintained every movement tick
  - Added HUD diagnostics for desired speed, movement mode, `dist_to_goal`, current path node, and path node advance count
  - Fixed Tool Gun debug panel ConVar collisions with existing `bmb_debug_health` and `bmb_debug_speed` console commands
  - Changed Tool Gun client convars to `bmb_debug_move_*` and `bmb_debug_edit_*`
  - Cleared stale `BMBDebugMoveTarget` when using console direction debug movement
  - Re-ran `H:\工作视频\20251115毕业\glualint.exe lint` on BMB Lua files; passed
  - User verified movement stutter / velocity sawtooth is solved and Tool Gun debug panel works
  - User reported a new issue: mob sometimes stands still and twists/turns in place without walking
  - Added no-progress watchdog to BMB movement loops so blocked/stuck movement returns failure instead of turning in place forever
  - Added idle activity reset for wait/idle states so walk/run activity does not visually linger while stopped
  - Changed short-distance `MoveAlongDirection` to direct steering by default instead of Source PathFollower, reserving SourcePath for explicit use or long destination movement
  - Added `.planning/mcgm-main/status_summary_2026-06-10.md` with current progress, file responsibilities, velocity sawtooth diagnosis, verified state, and next checklist
  - User reported standing twist still exists; screenshot HUD showed `state=wander`, `mode=path_carrot`, and `vel=0.0/70.0`
  - Disabled A* path fallback for ordinary Wander by default; passive random walking now stays on direct steering unless `UseWanderPathFallback` is explicitly enabled
  - Tightened no-progress watchdog thresholds and copied watch positions explicitly so stationary path movement exits faster
  - Added path goal-progress watchdog; `path_carrot` must reduce final-goal distance or it fails with `path_no_goal_progress`
  - Added `.gitignore` before first GitHub push
- Files created/modified:
  - `gmod_addon/lua/entities/mcgm_zombie.lua`
  - `gmod_addon/lua/autorun/bmb_autorun.lua`
  - `gmod_addon/lua/bmb/sh_config.lua`
  - `gmod_addon/lua/bmb/sv_block_world_mock.lua`
  - `gmod_addon/lua/bmb/sv_block_world_real.lua`
  - `gmod_addon/lua/bmb/sv_pathfinder.lua`
  - `gmod_addon/lua/bmb/sv_behaviors.lua`
  - `gmod_addon/lua/bmb/cl_debug.lua`
  - `gmod_addon/lua/bmb/sv_debug_tools.lua`
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `gmod_addon/lua/entities/bmb_sheep.lua`
  - `gmod_addon/lua/weapons/gmod_tool/stools/bmb_debug.lua`
  - `.planning/mcgm-main/task_plan.md`
  - `.planning/mcgm-main/progress.md`
  - `.planning/mcgm-main/findings.md`
  - `.planning/mcgm-main/status_summary_2026-06-10.md`

## 5-Question Reboot Check

| Question | Answer |
|----------|--------|
| Where am I? | Phase 2: 架构重整与方块寻路切片 |
| Where am I going? | 建立 BaseMob、行为模块、mock IBlockWorld 和方块 A*，先用 Sheep 验证整条骨架 |
| What's the goal? | 把 Minecraft 26.1 系列生物做成 GMod NPC，并让行为手感接近原版 |
| What have I learned? | NextBot 不是物理刚体，不能天然承受重力枪 prop 物理杀；BMB base 需要主动检测高速物理 prop 冲击 |
| What have I done? | 给 BMB base 增加高速物理 prop 冲击伤害和反弹反馈 |
