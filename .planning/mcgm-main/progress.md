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

## Session: 2026-06-10 (Fable / Claude Code)

> 当前状态权威文件改为 `docs/STATE.md`（CLAUDE.md 指定开工入口），本目录四个文件继续同步维护供 codex 续上下文。

### 第一轮：修"走一会停一下换方向"（用户已验证大部分通过）

- 诊断：codex 的扭动补丁把 Wander 改成"idle 等待 → 随机方向直线走固定 1.0-1.8s → 返回"，每段必刹停换向，是补丁固有节奏不是 bug。
- 找到当初 `path_carrot` 原地扭动（vel=0/70）的真根因：`DefaultGoalTolerance=12` < waypoint 容差 18，离终点 12-18 units 时节点推不进、到达判不过，carrot=终点落在 Approach 减速区，速度归零原地修正朝向。
- 改动：
  - `DefaultGoalTolerance` 12 -> 18（=0.5 方块，对齐 CLAUDE.md）。
  - `FaceTarget` 弃用手动 `SetAngles`（打断客户端插值，CLAUDE.md 禁止），改 `loco:FaceTowards` + `loco:SetMaxYawRate(TurnRate)`。
  - `MoveAlongPath` 起步跳过出发格中心 waypoint（可能在身后，开局会回头拐）。
  - `Wander.Run` 重写：随机可走点 -> `MoveToWorldPosition`（skipSourcePath，自写 A*+carrot）完整走到 -> 到站停顿 -> 下一个点；失败立即换点不插停顿。删除 `UseWanderPathFallback`。
  - `bmb_use_source_path` 默认 1 -> 0（CLAUDE.md：不用 navmesh）。ARCHIVE 可能存旧值，测试前要 `bmb_use_source_path 0`。
- 用户复测：停顿换向消失，但 (1) 到站停顿过短 (2) 目标在身后时面朝前倒退 (3) 吃草太频繁。

### 第二轮：到站停顿 / 倒退 / 吃草频率

- 到站不停顿根因：终点减速区把速度拖到 no-progress watchdog 阈值（16）以下，被误判"卡住"返回失败，Wander 以为没走成跳过停顿。
  - `GetPathCarrot` 在路径尾部把 carrot 沿 mob->终点方向投到终点之外，mob 全速跨过 18u 到达圈再由行为层停，不进减速区。
  - watchdog 失败时若距终点 <= 2x goalTolerance 按到达成功处理（双保险）。
- 倒退根因：`loco:Approach` 不顾朝向直接朝目标加速，身体转得慢就倒着走。
  - 新增 `ENT:SteerTowards(target, progressWatch)` 统一替换全部移动循环的 FaceTarget+Approach：夹角 > `TurnInPlaceAngle`(110°) 只原地转身（转身期间刷新 watchdog 不计时），转到位再 Approach。
  - `TurnRate` 280 -> 400（loco MaxYawRate）。
- 吃草：吃完冷却 5-9s -> 25-45s（`EatGrassCooldownMin/Max` 可按怪覆盖）；非草地重试 1-2.2s -> 2-4s；sheep 出生首吃延迟 8-20s。
- 用户复测：倒退 ✅ 吃草频率 ✅；到站停顿仍只有约 0.5s，太短。

### 第三轮：MC 式游荡节奏（用户已验证 ✅）

- 原版 MC 游荡是"站很久、偶尔走一段"（stroll goal 低概率触发），站立才是常态。
- `WanderPauseMin/Max` 默认 1.0-2.5s -> **4.0-10.0s**；候选点全失败的歇拍 0.4-0.8s -> 1.0-2.0s。
- 用户复测：停顿时长正确、无秒停、无 `path_blocked`/`path_no_goal_progress`；移动时 `path_carrot`、停止时 `idle`。
- 用户新需求/新 bug：(1) 单段路程再改短一点 (2) 停顿再拉长一点（要范围值）(3) **行进中会莫名转圈**。

### 第四轮：游荡距离/停顿微调 + 行进中转圈修复（待复测）

- 转圈根因：`MoveAlongPath` 节点推进只看"2D 距离 <= nodeTolerance(18)"。切弯时 mob 从 waypoint 旁边掠过（横向 19~54 units），节点永远推进不了；下一 tick `GetPathCarrot` 从当前位置先折回身后的漏过节点再前投，carrot 落在身后/侧后方，mob 掉头去追，靠近到 18 以内后节点推进、carrot 又跳回前方，mob 再转回来——观感即"莫名转圈"。
- 修法：节点推进循环加第二判定——距节点 <= 1.5 格（54）且已越过"该节点 -> 下一节点"方向的垂面（dot(seg, toMob) > 0）则视为通过该节点。最后一个节点不受影响（仍按 goalTolerance 判到达）。
- 游荡距离：`Wander.Run` 改用 `WanderDistanceMin/Max`（fallback 2 格 / 5 格），采样半径用 max，距离不在 [min, max] 的候选点弃掉（GetRandomWalkablePoint 在正方形里采样，角落会超出 max）。
- 停顿：fallback 4-10s -> **6-14s**。
- `bmb_sheep` 删除 `WanderRadius = 420`，换成显式 `WanderDistanceMin=72 / WanderDistanceMax=180 / WanderPauseMin=6.0 / WanderPauseMax=14.0`（每怪可调）。
- glualint 通过；已同步到 D 盘 GMod addons 目录。

### 第五轮：flatgrass 平台边缘冻住 / 跳崖（未测试；第四、五轮用户下次一起测）

- 用户报告：羊（尤其 Flee）跑到 flatgrass 平台边缘冻住不动，切回 wander 才恢复；有时直接冲下悬崖。
- 跳崖根因 A：`IsMovementTargetSafe` 固定探前方 48u，Flee 速度 145u/s、减速 260 的刹车距离约 40u，探到悬崖时几乎刹不住。修：探测距离随速度放大 `max(ForwardSafetyDistance, vel2D x SafetyProbeSpeedScale(0.45))`，新增 ENT 参数 `SafetyProbeSpeedScale`；函数加可选第二参 `probeDistance`。
- 跳崖根因 B：安全检查失败只 return false，loco 残留速度靠惯性滑下边缘。修：`FailBMBMove` 主动杀水平动量（`loco:SetVelocity(水平x0.1, z 保留)`，急停兜底，不是用 SetVelocity 驱动移动）。
- Flee 冻住根因：`getSafeDirection` 用短探测（48）放行"再跑几步就是悬崖"的方向，`MoveAlongDirection` 起跑后每个 slice 都在边缘失败，反复"选方向->立刻失败"空转。修：选方向时用更长探测 `min(lookAhead, 110)`，比移动中校验更保守；沿边/向内方向仍可通过，边缘处 Flee 应沿边跑。
- glualint 通过；已同步到 D 盘 GMod addons 目录。

- Files modified:
  - `gmod_addon/lua/bmb/sh_config.lua`
  - `gmod_addon/lua/bmb/sv_behaviors.lua`
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `gmod_addon/lua/entities/bmb_sheep.lua`
  - `docs/STATE.md`（新建，当前状态权威入口）

### 第六轮：Flee 冻住根修 + 游荡距离上调（待复测）

- 用户复测第四、五轮：**转圈 ✅、跳崖 ✅、停顿节奏 ✅**；游荡距离要求再走远一点；**Flee 冻住未修好**——受击后碰到 prop 就不动（与 prop 高矮无关），挪开 prop 恢复；平台边缘也仍冻。截图×3 在仓库根目录 `1 (1~3).png`，HUD 显示 `mode: direct_blocked`、vel 0。
- 诊断：`getSafeDirection` 十个方向全部判不安全 -> 只剩朝障碍方向的 `MoveDirectFallback` 兜底，每 0.16s 失败一次无限循环。两个叠加根因：
  1. 贴住/被挤进 prop（尤其斜放 prop）时 hull trace 从重叠开始（StartSolid），所有方向判 Hit 且 CanStepPastTrace 的抬高复查也在 prop 内 -> 全方向被毙。
  2. 选方向探测 110 是单一阈值：围栏圈/石坡（110 外落差超 MaxStepDown 或坡度超标）全方向失败，没有降级。
- 修法：
  1. `IsMovementTargetSafe`：`wallTrace.StartSolid` 不按墙处理（放行）——撞不动的方向由 loco 碰撞挡住、no-progress watchdog 换向，能走的方向自然脱困。
  2. `getSafeDirection` 探测阶梯 **110 -> 48 -> 24**，长档全失败降档；返回通过档位，Flee 作为 `safetyProbe` 传入 `MoveAlongDirection`，移动循环按同档复查（短档选中、长档复查会"选中即失败"又冻住）。`MoveAlongDirection`/`MoveDirectFallback` 新增 `options.safetyProbe`；Flee 兜底直线用 24 档。
  3. 短档不会重新引入跳崖：每 tick 复查 + `FailBMBMove` 急刹（已实测有效）。
- 游荡距离：`bmb_sheep` `WanderDistanceMin/Max` 72/180 -> **108/288**（3-8 格）。
- glualint 通过；已同步到 D 盘 GMod addons 目录。

- Files modified:
  - `gmod_addon/lua/bmb/sv_behaviors.lua`
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `gmod_addon/lua/entities/bmb_sheep.lua`

### 第七轮：Flee 冻住真根因——单位向量阈值 bug（用户已验证 ✅ 不再冻住）

- 用户复测第六轮：仍冻住。新规律：**面朝 prop/边缘跑会冻，侧着跑没事**；边缘组偶发 vel 骤降 0、转一下跑两步又转回去面朝边缘。另外**受击掉头先转身后跑 ✅（不再倒退，用户已验证）**。
- 新截图 `2.png` / `2 (2).png`（已裁剪放大确认）：HUD 仍是 `mode:direct_blocked`、vel 0.0/145.0 -> 走的还是 MoveDirectFallback 兜底 -> getSafeDirection 依然恒 nil。
- **真根因**：`getSafeDirection` 里 `if direction:LengthSqr() > 1`——baseDirection（away）是归一化单位向量，rotate2D 后 LengthSqr ≈ 1.0，永远不大于 1，**十个候选方向从第一天起一个都没被测过，函数恒返回 nil**。Flee 实际永远只有"朝 away 直线兜底"：away 指开阔地就能跑（侧跑没事的原因），指 prop/边缘就在 24u 内失败（冻住）；每个切片都把朝向拽回 away = "跑两步又转回去面朝边缘"。
- 同款 bug：`MoveAlongDirection` 的 `moveDirection:LengthSqr() <= 1 -> return false` 会把归一化方向拒收。
- 修法：两处阈值改 0.01（只挡零向量）。第五/六轮的探测阶梯、StartSolid 放行、safetyProbe 同档复查机制本身没错，只是从未被执行，本轮起才真正生效——复测如出现新观感问题，先怀疑这些首次运转的逻辑。
- 复盘教训：第五轮就该先验证"getSafeDirection 到底返回了什么"再去调它的参数；HUD 的 mode 一直是 `direct_blocked`（兜底分支）而不是 `direction_blocked`（主分支），这条线索当时就指向主分支根本没跑。
- glualint 通过；已同步到 D 盘 GMod addons 目录。

- Files modified:
  - `gmod_addon/lua/bmb/sv_behaviors.lua`
  - `gmod_addon/lua/entities/bmb_base_mob.lua`

### 第八轮：Flee 对障碍"过度恐惧"——墙/悬崖分治（用户已验证 ✅ 边缘不急停、撞 prop 换方向）

- 用户复测第七轮：**贴脸 prop 不再冻住 ✅**。新问题：离 prop 一小段距离就"犹豫"——vel 骤降、一点一点给油转向；平台边缘同样；三面围起来（集装箱）压根不靠近 prop，有一段距离就开始掉速绕开。逐帧截图 `1~5.png` + `围起来.png`（HUD 裁剪放大确认：第 1 帧 `direction_direct vel:71/145 dist:220`，第 3/5 帧 `direction_blocked vel:78→63 dist:0`——跑动中被安全复查掐断）。
- 根因：第七轮激活十方向选择/MoveAlongDirection 主分支后，**每 tick 安全复查把"远处的墙"当成和悬崖同级的危险**：
  1. `safetyProbe=110` 档时，离 prop 110u 复查即失败 → `FailBMBMove` 急刹（×0.1 杀动量，本是第五轮防跳崖加的）→ Flee 重选方向 → 加速 → 又探到 → 又急刹 = "犹豫、掉速、一点一点给油"。
  2. `getSafeDirection` 长档优先，所有指向 110u 内 prop 的方向全被毙 → mob 永远到不了 prop 跟前，三面围起来直接不敢进。
- 修法（撞墙无害——loco 碰撞自己挡得住；悬崖才需要提前刹）：
  1. `IsMovementTargetSafe` 返回失败原因 `false, "wall"` / `false, "cliff"`。墙只在贴脸 `WallStopDistance`（新 ENT 参数，20u）内才算挡路；更远的墙放行，但把地面探测截到墙跟前（`probe = hitDistance - 4`，避免探测点落进墙体/墙顶误报）。
  2. `FailBMBMove(mode, keepMomentum)`：wall 失败保留动量（顺势转向），cliff 失败照旧急刹。
  3. 新增 `GetBMBTickSafetyProbe(selectionProbe)`：每 tick 复查距离 = `min(选向档位, max(ForwardSafetyDistance 48, vel×0.45))`——悬崖前瞻随速度缩放，不再用 110 固定档提前半屏刹车；仍不超过选向验证过的档位（避免"选中即失败"回归）。
  4. `MoveAlongDirection` / `MoveDirectFallback` / `MoveAlongPath` / `MoveToWaypoint` 复查全部改为按原因决定是否杀动量。
- 预期观感：Flee 全速跑到 prop 跟前（半格内）才滑开；围起来敢进、贴墙滑出；边缘减速点推迟到 ~50-65u 且转向后立刻恢复全速。
- 风险：悬崖复查从 110 固定档变速度缩放 + 墙后地面截断是新逻辑——复测若跳崖回归，先查这两处。
- glualint 通过；已同步到 D 盘 GMod addons 目录。

- Files modified:
  - `gmod_addon/lua/bmb/sv_behaviors.lua`
  - `gmod_addon/lua/entities/bmb_base_mob.lua`

### 第九轮：Flee 重写为 MC PanicGoal 式（对照官方源码，2026-06-10/11，用户已验证 ✅）

- 用户复测第八轮：✅ 边缘不再急停、撞 prop 会换方向；遗留"偶发撞上 prop 停下来"。用户对照 MC 26.1.2 实测提出三点：(1) 友好生物被围在台子上没路跑时，冲几下就放弃，不会无限绕圈乱冲；(2) 平地上也不会跑很远；(3) 受击不是朝反方向跑，而是朝有路的方向跑，大平地就是随机跑。用户提供最新 MC 源码：`C:\Users\ADMIN\Downloads\Compressed\mcswep-main\out`。
- 读源码确认（`net/minecraft/world/entity/ai/goal/PanicGoal.java`、`ai/util/DefaultRandomPos.java`、`ai/util/RandomPos.java`、`LivingEntity.java`）：
  1. PanicGoal 选点 = `DefaultRandomPos.getPos(mob, 5, 4)`：±5 格水平随机，10 次候选（`RANDOM_POS_ATTEMPTS`），过寻路稳定性/malus 校验后按 walk-target 权重取最优。**完全不看受击方向**（`getPosAway` 是 AvoidEntityGoal/怕人生物用的）。
  2. 10 个候选全失败 → `canUse` false → 恐慌不启动（站住）= "没路就放弃"。
  3. 恐慌窗口 = `lastDamageSource` 有效期 40 tick（2s，`LivingEntity.java:1420`），每次受击刷新；`canContinueToUse = !navigation.isDone()`，窗口过了跑完当前段就停 = "平地不跑远"。
  4. 速度倍率：羊 `PanicGoal(this, 1.25)`、猪 1.25、**牛 2.0（用户"牛冲的有点快"的出处）**、兔 2.2。
- BMB 实现（`sv_behaviors.lua` 重写 Flee 区段）：
  1. 删除 `getSafeDirection`/`rotate2D`/`GetThreatPosition` 和方向式 Flee（away 方向 + MoveAlongDirection 切片）整套逻辑。
  2. 新 `pickPanicDestination`：10 次 `GetRandomWalkablePoint`（半径 `FleePanicRadius` 180 = 5 格，最小 `FleePanicMinDistance` 36），候选用前向 `IsMovementTargetSafe`（probe ≤110）做可达性预检（A* 看不到 prop/Source 边缘，MC 的 malus 校验等价物）。
  3. 新 `Flee.Run`：循环"选点 → `MoveToWorldPosition`（skipSourcePath，A*+carrot，与 Wander 同管线）"；**连续 `FleeGiveUpFailures`(4) 次失败（选不出点或起步即被挡）→ 置 `FleeUntil=0` 放弃**；移动被打断（再次受击）不计失败。
  4. `bmb_sheep`：`RunSpeed` 145 → **90**（70×1.25）；`FleeDurationMin/Max` 3.5/6.0 → **2.0/2.5**（40 tick 窗口）；删 `FleeDistance`/`FleeDirectDistance`/`FleeDirectDuration`，加 `FleePanicRadius`/`FleePanicMinDistance`/`FleeGiveUpFailures`。
- 怕人生物（猫/兔"跑得快还躲玩家"）= `AvoidEntityGoal`（`getPosAway` 背离方向 ±90° 选点），将来做新怪时单独做 `Avoid` 行为模块，不塞进 Flee。
- glualint 通过；已同步到 D 盘 GMod addons 目录。

- Files modified:
  - `gmod_addon/lua/bmb/sv_behaviors.lua`
  - `gmod_addon/lua/entities/bmb_sheep.lua`

### 第十轮：RealBlockWorld 接通 MCSWEP——mock 首次切真环境（2026-06-11，待复测）

- 用户确认第九轮 Flee 全部通过，决定进入下一步：接 RealBlockWorld。朋友的 MCSWEP 已装在 `D:\...\addons\mcswep-main`（接口文档 `docs/interface-usage.md`），`MC.SV.SetBlock( bx, by, bz, id, orient, options )` 已就位（源码 `mc/sv_world.lua:392` 验证；options 可直接传实体 = `{actor=ent}`；`MC.GetBlock` 空格返回 0；`MC.WorldToCell` = `floor(world/36)` 无偏移）。
- 接通前修掉的对接隐藏 bug：
  1. mock 直接占用 `BMB.BlockWorld`、real 是不完整旁支表 → mock 改名 `BMB.MockBlockWorld`（功能不动）；real 补全接口（`EnsureInitialized` no-op、`GetRandomWalkablePoint`）；新增 `BMB.SelectBlockWorld()` + `bmb_use_real_world` convar（默认 1，回退 mock）+ `bmb_world mock|real` 命令。MCSWEP 后于 BMB 加载 → BaseInitialize 时再选一次（幂等）。
  2. real `GetBlockAt` 返回数字 id，而 EatGrass 比较 `BMB.BlockTypes.Grass` 字符串 → 永远不相等。adapter 加 `blockTypeToId`/`idToBlockType` 双向映射，行为层只见 BMB 枚举（架构铁律：行为不感知 MC）。
  3. EatGrass 用 `WorldToBlock(GetPos())` → real 里是脚部空气格不是脚下草方块 → 改 `GetPos() - Vector(0,0,4)`（mock 忽略 z 行为不变）；`SetBlockAt` 增加第三参 actor（mob），real 转成 MCSWEP options。
  4. A* 不查头部格 → 新增 `isPassable`（脚部格+头部格都非实心；mock z=1 恒空行为不变）。
  5. `MaxStepDown` 34 < 36（一格）→ 站方块地板上永远不肯下来 → 改 40（>1 格、<2 格）。
- real.IsSolid 保持粗略版（`BlockIsFullCube`，半砖/楼梯/栅栏当可通过，移动层 Source 探测兜底，细化入口 `MC.BlockBoxes`）。
- CLAUDE.md 同步更新：接口文档指向 mcswep-main/docs；adapter 备忘更新（GetBlockAt 映射、SetBlock 就位、切换机制）；"已知缺口"改为"仍然禁止"（Place/Break 玩家专用、SetBlockRaw 禁用）。
- 已知能力缺口（复测后排期）：羊上不去一格台阶（StepHeight 28 < 36，MC 自动跳未实现）；A* 仅同 z 层扩展。
- glualint 通过；已同步到 D 盘 GMod addons 目录。

- Files modified:
  - `gmod_addon/lua/bmb/sv_block_world_real.lua`（重写）
  - `gmod_addon/lua/bmb/sv_block_world_mock.lua`
  - `gmod_addon/lua/bmb/sv_pathfinder.lua`
  - `gmod_addon/lua/bmb/sv_behaviors.lua`
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `CLAUDE.md`

### 第十一轮：一格宽走廊"出得来、进不去"（2026-06-11，待复测）

- 用户复测真方块世界后发现：羊在一格宽方块走廊里能自己走出来；但从外面不会主动进去。若把羊放在坑/走廊内触发 Flee，会很快放弃 Flee 切回 Wander。吃草功能只剩粒子缺失，草->土、脚下格、mock/real 分离都正常。
- Fable 诊断采纳：这个不对称现象说明 A* 大概率能给出路径，问题在路径跟随层"二次质疑"路径：
  1. `MoveAlongPath` 每 tick 对 `safetyTarget` 调 `IsMovementTargetSafe`。36u 走廊中线离两侧墙各 18u，小于旧逻辑 `WallStopDistance=20`，入口附近容易被 Source hull 探测误判成墙，导致外面进不去；从里面沿走廊出去时前方无遮挡，所以能出来。
  2. carrot 若从当前位置直线瞄向前方节点/终点外投，会在直角入口抄近路撞走廊外壁，触发 blocked/watchdog 放弃路径。
- 代码改动（`bmb_base_mob.lua`）：
  1. `MoveAlongPath` 删除 `IsMovementTargetSafe(safetyTarget)` 路径二次否决。A* 路径跟随只负责跟路径；Source 安全探测仍保留给 debug direct / `MoveDirectFallback` / `MoveAlongDirection` / legacy waypoint 这些裸方向移动。
  2. `GetPathCarrot` 改成 pure pursuit：先把当前位置投影到当前路径折线附近（限制只看当前段后几段，避免 U 形路径跳到后半段），再沿折线前推 carrotDistance。
  3. 增加 `IsPathGridVisible`：mob 到 carrot 的直线逐半格采样 `IBlockWorld.WorldToBlock` + `IsSolid`（脚部格+头部格）。若直线穿方块，二分缩短前瞻距离到最后一个可见的折线点，避免直角入口切角。
  4. 终点外投仍保留，但方向改为沿最后一段路径，且最多外投一个 goalTolerance；若网格视线被挡会被上面的二分缩回。
- 吃草粒子决策：选择原版手感版，不把 MCSWEP 破坏 fx 当吃草效果；后续由羊自己补低头吃草动画、咀嚼音效、草屑粒子。CLAUDE.md 已改成这条规则。
- 本轮未做：坑/封闭结构 Flee 采样仍是旧的"随机世界点再验证"。下一步应按 CLAUDE.md 改为先枚举半径内可站立格，再随机抽样，最后 A* 验证；否则坑里有出口但盲采命中率低，仍可能放弃 Flee。
- glualint 通过；待同步到 D 盘 GMod addons 目录后用户复测。

- Files modified:
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/task_plan.md`
  - `.planning/mcgm-main/progress.md`
  - `.planning/mcgm-main/findings.md`
  - `.planning/mcgm-main/status_summary_2026-06-10.md`

### 第十二轮：方块通行按 mob hull，占格不再按中心点（2026-06-11，待复测）

- 用户复测第十一轮：Tool Gun 右键目标只闪一下 `debug_move` 就回 wander；Wander/Flee 仍会从一格高方块下面钻过去，方块角落也能擦穿。截图显示 sheep 在 `path_carrot` 下贴着/穿过 stone 角。
- 诊断：上一轮退役路径 Source 安全探测后，真正暴露出方块 passable 的语义太弱：A* / carrot 视线只查中心点所在格和头顶格，相当于把羊当一根竖线；成年羊应按 0.9 格宽、44u 高的实体 hull 判断占格。
- 代码改动：
  1. `bmb_base_mob.lua`
     - 新增 `GetBMBPathHullRadius` / `GetBMBPathHeightCells` / `DoesBMBHullOverlapBlock` / `IsBMBHullClearAtPosition` / `IsBMBPathCellPassable`。
     - `IsBMBHullClearAtPosition(pos)` 对 mob 当前/候选位置周围实心方块做 XY AABB vs 圆形 hull 检查，Z 方向检查实体高度覆盖到的方块层。这样 1 格高天花板会挡成年羊，角落切线也会被挡。
     - `IsPathGridVisible` 改为沿直线每 1/4 格采样 exact position 的 hull clear，不再只按采样点 cell 中心判断。
     - Debug target move 改为 path 模式：`BMBDebugMoveUsePath` 时直接调用 `MoveToWorldPosition(..., skipSourcePath=true)`，不再走 direct steering。
  2. `sv_pathfinder.lua`
     - `FindPath(start, goal, { mob = self })`，A* 邻居和目标格用 `mob:IsBMBPathCellPassable(cell)`。
  3. `sv_block_world_mock.lua` / `sv_block_world_real.lua` / `sv_behaviors.lua`
     - `GetRandomWalkablePoint(origin, radius, mob)` 支持 mob hull 过滤；Wander/Flee 传入 mob。
  4. `bmb_debug.lua`
     - Tool Gun 右键点击上表面时目标点上抬 4u，点击侧面时沿法线推出半格；启动 `BMBDebugMoveUsePath=true`。
  5. `bmb_sheep.lua`
     - hull 宽度 28u -> 32u，接近 MC 成年羊 0.9 格（约 32.4u），仍小于 36u 一格走廊。
- 已知保留：hull clear 只判断身体是否和实心方块重叠，不判断脚下是否有 MC 支撑方块（flatgrass/Source 地面仍可支撑）。Flee 坑内采样、BlockHop、3D A* 时补支撑规则。
- glualint 通过；待同步到 D 盘 GMod addons 目录后用户复测。

- Files modified:
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `gmod_addon/lua/bmb/sv_pathfinder.lua`
  - `gmod_addon/lua/bmb/sv_block_world_mock.lua`
  - `gmod_addon/lua/bmb/sv_block_world_real.lua`
  - `gmod_addon/lua/bmb/sv_behaviors.lua`
  - `gmod_addon/lua/entities/bmb_sheep.lua`
  - `gmod_addon/lua/weapons/gmod_tool/stools/bmb_debug.lua`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第十三/十四轮：拐弯漂移 + Source 地图墙/跳崖回归（2026-06-11，待复测）

- 用户确认第十二轮三项通过：Tool Gun 右键能进走廊；成年羊不再从一格高洞下面钻；贴石头/木头角不会擦穿。
- 新手感问题：走廊拐弯时像漂移，带惯性滑出去一点，再不断转向矫正。
  - 修法：`MoveAlongPath` 新增 `path_corner`。`GetBMBPathCornerControl` 提前约 2 格检查折线转角（默认角度 >=35°），靠近转角时动态降低目标速度、缩短 carrot 到约 32u，并临时提高 `loco` deceleration 到 720；直线段恢复 `path_carrot`。
- 用户随后发现两个回归：羊会往 gm_flatgrass 的地图砖墙走；平台边缘又会跳崖。截图 HUD 为 `mode=path_carrot`。
  - 根因：第十一轮完全删除 path 中的 Source 安全复查后，A* 只懂 MC 方块，不知道 Source 地图墙/悬崖。
  - 修法：新增 path 专用 `IsPathSourceTargetSafe`，在 `MoveAlongPath` 每 tick 对 carrot 做前向 Source hull/ground probe：
    1. 前方 wall hit 若能映射到 `IBlockWorld` solid block（`IsSourceHitBMBBlock`）则忽略墙命中，不误伤 MC 一格走廊；
    2. 前方 wall hit 若不是 MC solid（地图墙/prop）则 `path_wall`，返回失败让行为重选；
    3. ground probe 没地/坡太陡/落差 > `MaxStepDown` 则 `path_cliff` 并急刹。
- CLAUDE.md 更新：A* 路径不能被 Source 射线否决 MC 方块通行，但必须保留 path 专用 Source 地图/悬崖安全层。
- glualint 通过；待同步到 D 盘 GMod addons 目录后用户复测。

- Files modified:
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第十五轮：A* 3D 邻接 + BlockHop/drop（2026-06-11，待复测）

- 用户反馈第十四轮已无问题，采纳 Fable 建议：先继续做移动层上下台阶能力，粒子后置。
- `sv_pathfinder.lua`
  - A* waypoint 从纯 Vector 升级为兼容旧字段的 table：保留 `x/y/z`，新增 `coord` 和进入该点的 `action`。
  - real 方块世界启用 3D 4 邻接：同层 `walk`、+1 格 `hop`、向下 ≤3 格 `drop`。
  - `hop` 目标必须可通行且脚下有 MC solid 支撑；`drop` 会在相邻列向下找 1-3 格内的可站立落点。
  - mock world 标记 `SupportsVerticalPath=false`，仍保持 z=0 平面，避免旧 mock 测试被垂直语义影响。
- `bmb_base_mob.lua`
  - 新增 `path_hop` / `path_drop` 消费逻辑。
  - `path_hop` 在接近 hop 节点且落地时触发一次 BlockHop：45u 顶点，`loco:SetVelocity` 加竖直速度并保留水平速度；空中用弱水平速度 Lerp 朝目标修正。
  - `path_drop` 不跳，直接沿路径走出边缘并让重力落下；空中同样弱控水平速度。
  - hop/drop 期间跳过 `IsPathSourceTargetSafe`，避免 hop 被 `path_wall` 点刹、drop 被 `path_cliff` 取消；普通 walk 边仍保留地图墙/悬崖安全层。
  - 终点到达判定补上垂直条件：如果 final 是 hop/drop，必须落地且 `WorldToBlock(GetPos()).z` 到目标层。
- `sv_block_world_real.lua`
  - `GetRandomWalkablePoint` 在 real 世界会抽当前层附近（向下 ≤3、向上 +1）的候选；当前层允许 Source flatgrass 支撑，跨层候选必须有 MC solid 支撑。
- `CLAUDE.md` / `docs/STATE.md` / task plan 已同步：hop/drop 边是 A* 明确授权的垂直动作，跟随层必须豁免 path wall/cliff safety。
- glualint 通过。

- Files modified:
  - `gmod_addon/lua/bmb/sh_config.lua`
  - `gmod_addon/lua/bmb/sv_pathfinder.lua`
  - `gmod_addon/lua/bmb/sv_block_world_mock.lua`
  - `gmod_addon/lua/bmb/sv_block_world_real.lua`
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第十六轮：hop 贴墙重跳 + A* 支撑/预算/部分路径（2026-06-11，待复测）

- 用户实测第十五轮报三个 bug：① hop 贴着方块不跳；② 右键高于 3 格的位置整帧卡一下且 NPC 不下去；③ 右键非 MC 地面同样卡一下且不动。
- `bmb_base_mob.lua`（hop 卡死）
  - 根因：每个 hop 节点只跳一次（`hopStartedAt` 永不复位），第一跳撞方块面落回后永远走 `SteerBMBInAir` 弱转向把羊往方块上蹭，且该分支每 tick 刷新 no-progress watchdog，把卡死兜底也关了；加上起跳"只保留水平速度"，贴墙时水平≈0 → 直上直下必然失败。
  - 修法：落地未推进节点超过 `BlockHopRetryDelay`(0.25s，必须 < watchdog grace 0.35) 复位重跳；连续 `BlockHopMaxAttempts`(3) 次失败 `FailBMBMove("path_hop_fail")` 交还行为层；`StartBMBBlockHop(target, speed)` 朝目标方向水平分量不足行走速度时补足；空中转向只在 `not IsBMBOnGround()` 时接管。
- `sv_pathfinder.lua`（卡顿 + 不可达）
  - 根因：同层 walk 边只要求可通行不要求支撑，目标悬空/落在 Source 地面时搜索顺空中格泛洪扫满 900 迭代；每格 hull 扫描十几次 `MC.GetBlock` 且无缓存，全在一帧。drop 边要求落点下方必须 MC 实心 → 永远落不回 flatgrass。
  - 修法：同层 walk 边要求 `isStandable`（passable + support）；目标格悬空向下吸附 ≤12 格；passable/support per-FindPath 缓存；搜索预算 `f ≤ hStart*2+24`（椭圆界）；每 64 迭代 `coroutine.yield()` 时间切片（FindPath 只在行为协程里调用）。预算管总开销、yield 管单帧，互补。
  - 部分路径：中止时返回离目标最近已展开节点的路径（`waypoints.partial = true`，须比起点更接近目标）。>3 格纯垂直落差仍拒跳（MC 规则），观感从"卡顿拒动"变"走到崖边停住"。
- `sv_block_world_real.lua`
  - 新增 `real.HasSupport(cell)`：先查 MC 实心（纯表查询），无实心才兜底一次 `MASK_SOLID_BRUSHONLY` TraceLine（格顶 → 格底下 6u；StartSolid = 整格埋地不算支撑；prop 不算）。
  - `GetRandomWalkablePoint` 候选支撑统一走 `HasSupport`，高台上的同层悬空候选在源头被拒。
- `sv_behaviors.lua`
  - Flee 的 `MoveToWorldPosition` 显式 `allowPartial = false`：partial 会把撞墙洗成成功冲刺、失败计数清零，破坏第九轮已验证的"被围住会放弃"。`MoveToWorldPosition` 把 `allowPartial` 透传给 FindPath。
- CLAUDE.md 修订两条约定：A* 邻接补支撑/预算/切片/部分路径语义；BlockHop 由"只保留水平速度、触发一次"改为"水平分量补足 + 落地重试"。
- glualint 通过；已同步 D 盘 GMod addons。

- Files modified:
  - `gmod_addon/lua/bmb/sv_pathfinder.lua`
  - `gmod_addon/lua/bmb/sv_block_world_real.lua`
  - `gmod_addon/lua/bmb/sv_behaviors.lua`
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第十七轮：绕路误杀 / 窄沿支撑 / hop 起跳保护窗（2026-06-11，待复测）

- 用户复测第十六轮：卡顿 ✅ 全消（"怎么样都不会卡"）、不跳楼 ✅、下落正常 ✅；并补认旧清单三项（枪击 Flee、prop 冲击衰减、真方块世界全链路 + mock 回退）全部通过。新报三个问题：
  1. **迷宫绕路中途放弃 `path_no_goal_progress`**：goal-progress watchdog 要求每 0.9s 离终点直线距离近 10u，绕墙路径必有"越走越远"段。修：节点推进视为进展，推进时刷新 watchdog（baseline+deadline）；`PathGoalProgressTimeout` 0.9→1.2 给过弯减速留余量。watchdog 保留防绕圈用途（绕圈不推进节点）。
  2. **flatgrass 围墙窗台等窄 Source 路完全走不了**（第十六轮回归）：`HasSupport` 兜底 trace 只打格子中心，窄沿比 36u 格子窄、网格中心悬在沿外 → 整条沿判无支撑。修：中心 StartSolid 仍判埋地；中心悬空没命中再补 4 个 ±12u 轴向偏移采样，任一命中算支撑（StartSolid 样本跳过）。
  3. **`path_hop` 状态有但不起跳、试几次放弃/blocked**（第十六轮回归）：起跳 tick 还在地面，walked into `SteerTowards`→`loco:Approach`，把 `SetVelocity` 直写的竖直速度在物理生效前冲掉（第十五轮起跳 tick 走空中分支所以至少能跳）。修：`BlockHopLaunchWindow=0.15s`（< RetryDelay 0.25）起跳保护窗内强制空中转向；窗口外落地贴墙仍交回 SteerTowards+watchdog。
- glualint 通过；已同步 D 盘；STATE.md / task_plan / findings / status_summary 同步更新。

- Files modified:
  - `gmod_addon/lua/bmb/sv_block_world_real.lua`
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第十八轮：loco:Jump 真起跳 + 物理枪持握一等状态（2026-06-11，待复测）

- 用户复测第十七轮：绕路不再误杀 ✅、窄沿恢复可走 ✅；hop 仍不起跳，四张截图给出关键证据：整块方块 hop 有状态无动作（hop2/3），半砖"跳跃成功"其实是 StepHeight=28>18 走上去的（hop1/4）。
- **hop 真根因**：NextBot 落地态的地面解算会把 `loco:SetVelocity` 直写的竖直速度当帧压回地面——SetVelocity 单独起跳从第十五轮起就从未生效过，保护窗治标不治本。修法：`StartBMBBlockHop` 先 `loco:SetJumpHeight(apex)` + `loco:Jump()` 切进跳跃态，再 `SetVelocity` 覆盖为固定弹道（45u 顶点 + 朝目标补足水平分量）。
- 顺手拔掉两根刺（另一 Fable 建议）：
  1. 删除 0.15s 起跳保护窗：空中分支改查 `loco:IsClimbingOrJumping()`（起跳当帧强制视为真，防引擎标志晚一帧），消灭"窗口与真实物理不一致"的隐患。
  2. 重跳延时改以 `OnLandOnGround` 回调时刻（`BMBLastLandTime`）为基准，不靠 IsOnGround 轮询。
- 查证 MCSWEP `sh_blocks.lua`：`BlockIsFullCube` 对半砖返回 false → BMB 当空气，A* 看不见半砖；混半砖地形会跳整格而非走半砖——观感问题，记录待 `MC.BlockBoxes` 细化。
- **物理枪持握一等状态 `BMBHeld`**（用户反馈抓羊有的抽搐/陷地有的安静悬挂 = 被抓瞬间 loco 醒/睡的函数）：
  - `PhysgunPickup`/`PhysgunDrop` 钩子 → `OnBMBPhysgunPickup/Drop`（`ent.IsBMBMob` 识别）。
  - 持握中：base `Think` 每 tick `loco:SetVelocity(vector_origin)` 缴械（跳过 prop 冲击检测）、羊行为循环挂起（state=held）、`MoveToWorldPosition`/`MoveAlongDirection` 拒新请求。
  - held×hop 握手：拾起时 `InterruptBMBMovement` 掐掉当前 move 协程，hop 重跳计数等局部状态随之销毁，松手不会误判路径失败。
  - 松手：`SetVelocity(0,0,-10)` 踹醒可能睡眠的 loco，挂半空/天上的个体正常下落。
- CLAUDE.md：BlockHop 约定改为 Jump+SetVelocity / IsClimbingOrJumping / OnLandOnGround；新增"物理枪持握是一等状态"约定。
- glualint 通过；已同步 D 盘。

- Files modified:
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `gmod_addon/lua/entities/bmb_sheep.lua`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第十九轮：JumpAcrossGap 原生 hop + held gravity/desired speed 归零（2026-06-11，待复测）

- 用户复测第十八轮：BlockHop 有动作、脚会离地一点，但呈现"一陷一陷"的小跳节奏，最终仍上不去；物理枪抓取抽动已经明显好很多，但还残留轻微弹簧感。
- 采用 Fable 建议：先不用继续手术式 `Jump()` + `SetVelocity`，改用 NextBot 原生 `loco:JumpAcrossGap(landingGoal, landingForward)`。它会一次性计算到指定落点的弹道并进入跳跃状态，避免 Jump 内部冲量、SetVelocity 和地面解算在同 tick 互相覆盖。
- `bmb_base_mob.lua`
  - 新增 `BlockHopJumpHeight = 58`。
  - `StartBMBBlockHop` 优先 `SetJumpHeight(max(BlockHopApex, BlockHopJumpHeight))` 后 `JumpAcrossGap(landing, forward)`；落点用目标 foot cell 的底面/地表点（`target.z - blockSize * 0.5`），朝向用目标方向的水平单位向量。
  - 原生 hop 返回 `true`，`MoveAlongPath` 记录 `hopNative[nodeIndex]`；原生 hop 空中只 `FaceTowards` + 刷新 watchdog，不再 `SteerBMBInAir` 写水平速度。老引擎没有 `JumpAcrossGap` 时才 fallback 到第十八轮 `Jump()+SetVelocity`。
  - 物理枪 held 期间每 tick 进一步 `SetGravity(0)` + `SetDesiredSpeed(0)` + `SetVelocity(vector_origin)`；pickup 保存原 gravity，drop 恢复后再向下踹醒。
- `CLAUDE.md`：BlockHop 约定改为优先 `JumpAcrossGap`；物理枪持握约定加入 `SetGravity(0)` / `SetDesiredSpeed(0)`。
- 若第十九轮仍失败，下轮优先加 0.5s 逐 tick hop 诊断日志（`IsClimbingOrJumping`、`IsOnGround`、`vel.z`、`pos.z`）分型，再决定调 `BlockHopJumpHeight`、落点 z，还是查 hull 碰撞。

- Files modified:
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第二十轮：BlockHop 起跳准入 + 落点余量 + hop 分类 HUD（2026-06-11，待复测）

- 用户复测第十九轮：物理枪上下抽完全修好；BlockHop 仍有问题。平地两个半砖/一格台阶测试点里，反复用 debug 点某个方向才有概率跳上去，弧线很低且会擦进模型；其他地形显示 `path_hop` 但完全上不去。
- 诊断：截图已经进 `mode=path_hop`，所以当前重点不是 A* 没标 hop，而是跟随层触发点/速度/落点导致 `JumpAcrossGap` 给出低弧或擦边弧线。
- `bmb_base_mob.lua`
  - `BlockHopJumpHeight` 改为默认 `BlockHopJumpHeightScale = 1.6`，按 `BlockSize` 算约 58u；保留 `BlockHopJumpHeight` 作为显式覆盖入口。
  - `JumpAcrossGap` landing 从台面正好高度改为台面 +2u，且保持上层格中心 x/y。
  - 新增 `GetBMBHopLaunchControl`：起跳必须在 0.85~1.4 格距离窗口内，且朝目标速度 ≥0.6×pathSpeed；太近或太慢时先 steer 到约 1.15 格的 backoff/助跑点，不再硬跳。
  - 新增 hop 分类数据：每次 attempt 记录起跳距离、到方块面的 face 距离、朝目标速度、实际 apex、native/manual、ok/retry/fail；`bmb_debug_hop_log 1` 可打印控制台日志。
- `cl_debug.lua`
  - HUD 第三行在 hop 后 5 秒显示 `hop# native/manual d face v apex result`，下一轮截图能直接看出决定性变量。
- 若第二十轮仍失败：若 `d/v` 合格但 `apex` 低，优先试底线方案：`Jump()` 开门后下一 tick 再 `SetVelocity` 覆盖弹道；若根本不进 `path_hop`，转查 A* hop 候选拒绝原因。

- Files modified:
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `gmod_addon/lua/bmb/cl_debug.lua`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第二十一轮：错帧手写 BlockHop 弹道 + Wander 下层采样（2026-06-11，待复测）

- 用户复测第二十轮：debug 从较远距离给一点助跑能跳上；wander 状态慢速靠近方块触发 hop 多半跳不上；有一次 wander hop 跳得很远。补充成功日志显示：`JumpAcrossGap` 成功样本 `dist≈47 face≈29 speed≈73 apex≈36`，失败样本多为 `dist≈36 face≈18 speed≈50 apex=0`。结论：native `JumpAcrossGap` 对一格爬升近距离不可靠，不是单纯窗口问题。
- `bmb_base_mob.lua`
  - `StartBMBBlockHop` 默认不再调用 `JumpAcrossGap`；改为 `SetJumpHeight(1.6*BlockSize)` + `loco:Jump()` 打开跳跃态，下一 tick `ApplyBMBPendingBlockHop` 用手写 `SetVelocity` 覆盖弹道。
  - 手写弹道：竖直速度按顶点 `1.6*BlockSize`；水平速度按到上层格中心的距离 / 飞行时间计算，再 clamp 到 `BlockHopManualHorizontalMinSpeed..1.1*pathSpeed`，避免 debug 助跑导致跳很远。
  - 手写速度写入后增加 `BlockHopManualControlTime` 短窗口，强制走空中 steering；否则同一轮 path loop 可能仍判 onGround 并交回 `Approach`，把刚写入的上抛吃掉。
  - 起跳准入取消“已有速度 ≥0.6×pathSpeed”的硬门槛；保留 0.85~1.4 格距离窗口，太贴脸仍先 backoff。这样 wander 慢速靠近也能起跳。
  - `InterruptBMBMovement` 清掉 pending hop，避免物理枪/受击打断后残留速度。
- MC 源码核对：`Entity#getMaxFallDistance()` 默认 3；`LivingEntity#getComfortableFallDistance(0)=floor(3)`；`Mob#getMaxFallDistance()` 无目标时返回 comfortable fall distance；羊未覆写。所以 BMB 保持 `MaxPathDropCells=3`。
- `sv_block_world_real.lua`
  - real `GetRandomWalkablePoint` 尝试次数 24→36；前 14 次优先抽当前层下方 1~3 格的可站立候选，让 Wander 更容易主动选到台下目标并走 A* `drop` 边。A* 本来能走（debug 可下），问题主要是随机目标选不到。

### 第二十二轮：BlockHop 两段式 manual lift（2026-06-12，待复测）

- 用户复测第二十一轮：wander 主动下落 3 格内已实现；BlockHop 仍未成功过，无论助跑还是贴着都会做动作但不上台，半砖测试点也很费劲。
- 关键日志：`hop velocity ... vz=339.4` 已写入，但结果多为 `apex=0.0`，少数仅 `apex=12.0`。结论：竖直速度数值不是主要问题，斜向速度/地面解算在实体真正抬高前就把上抛磨掉。
- `bmb_base_mob.lua`
  - 新增 `BMBActiveBlockHop` 两段控制器：`ApplyBMBPendingBlockHop` 不再直接给完整斜上速度，而是先只给竖直速度并记录 horizontal/vertical/target/窗口时间。
  - lift 阶段：短时间只 `SetVelocity(0,0,vz)`；如果仍判 onGround，局部重复 `loco:Jump()`，目标是先让 hull 离开台阶侧面。
  - forward 阶段：抬升到约 `0.8*BlockSize` 或超过 lift 时间后，再加水平速度和弱转向落向 carrot/目标格；保留 flight-time clamp，防 debug 助跑跳远。
  - 成功/失败/中断时清理 `BMBPendingBlockHop`、`BMBActiveBlockHop` 和 air-control 窗口，避免残留速度。

- Files modified:
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第二十二轮复测：一格 BlockHop 成功，记录调优项（2026-06-12）

- 用户复测确认：NPC 已能跳上一格台阶；wander 主动下 3 格内也已实现。
- 新观察：
  - hop 弧线偏高，成功日志 apex 约 54~65；偶发能误上两格，但 A* 不会主动规划两格 hop。
  - debug 工具给较远目标时，mob 还在路上也可能因时间短而放弃目标；后续调 debug move/path timeout。
  - 跳完后动作会持续一段时间；套皮后可能影响观感，先记录待查 activity/gesture reset。
- 本轮不继续改代码，按用户要求先提交并 push。

- Files modified:
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `gmod_addon/lua/bmb/cl_debug.lua`
  - `gmod_addon/lua/bmb/sv_block_world_real.lua`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第二十三轮：StepHeight / debug timeout / activity 收口（2026-06-12，待复测）

- 采用 Fable 诊断：误上两格来自 `apex≈54~65` 与 `StepHeight=28` 的空中 step 助攻。只降低 apex 会和一格可靠性冲突，因此改为 hop 期间临时压低 `loco:SetStepHeight(18)`，结束/失败/中断恢复默认 28。
- `bmb_base_mob.lua`
  - 新增 `BlockHopStepHeight=18`、`BeginBMBHopStepHeight`、`RestoreBMBStepHeight`；`StartBMBBlockHop` 进入 hop 时压低，`FinishBMBHopDebug` / `FailBMBMove` / `InterruptBMBMovement` / path timeout 等出口恢复。
  - 新增路径 timeout 预算：`pathFlatLength` + `GetBMBMoveTimeoutForDistance` + `GetBMBPathTimeout`，默认按路径长度 / 速度 × scale + base；仍保留 no-progress watchdog 判真卡死。
  - debug path move 不再把右键面板 duration 当硬 timeout，而是作为 minTimeout，debug 专用 scale/base/max 更宽。
  - activity 改为状态驱动兜底：`StartBMBActivity`、`UpdateBMBActivityFromLocomotion`；Think/落地时根据 held/airborne/ground speed 切 idle/walk/run/jump，落地重置 `CurrentMoveActivity` 防跳姿残留。
- `weapons/gmod_tool/stools/bmb_debug.lua`
  - 右键目标 move 的 `BMBDebugMoveUntil` 按直线距离估一个较长接收窗口，真正路径预算由 base mob 按 A* 路径长度再算。

- Files modified:
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `gmod_addon/lua/weapons/gmod_tool/stools/bmb_debug.lua`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第二十三轮复测通过（2026-06-12）

- 用户复测反馈：当前未发现 bug；第二十三轮目标项通过。
- 覆盖项：
  - 一格 BlockHop 仍可用。
  - 临时 `StepHeight=18` 后未再观察到误上两格。
  - debug 远点早停问题未再暴露。
  - 跳后动作残留未再暴露。
- 本轮按用户要求提交并 push；未跟踪截图 `hop1.png`~`hop4.png` 不纳入提交。

### 第二十四轮：36.5 切换与 BS 参数化（2026-06-12，待游戏回归）

- 背景：朋友的 MCSWEP 已把 `MC.Config.BlockSize` / `MC.BS` 切到 36.5（已读取 `D:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\mcswep-main\lua\mc\sh_config.lua` 确认）。BMB 不能再把 36、18、40、72、108 等尺寸派生值写死。
- 新增 `scripts/check_block_size_parameterization.ps1`，先红灯抓到旧 fallback / size-derived defaults，再改到绿灯；以后改尺寸相关代码先跑它。
- `bmb/sh_config.lua`
  - 新增 `BMB.DefaultBlockSize = 36.5`、`BMB.GetBlockSize()`；每次优先读 `(MC and MC.BS)`，同步 `BMB.BS` 与兼容字段 `BMB.Config.BlockSize`。
  - `DefaultGoalTolerance` 改为 `0.5*BS`。
- `bmb_base_mob.lua`
  - 所有尺寸派生默认改为 scale：goal/node tolerance `0.5*BS`，carrot min/max `2*BS` / `25/6*BS`，corner slow `2*BS`，hop apex/jumpheight `1.5*BS`，manual forward start `0.8*BS`，hop 临时 StepHeight `0.49*BS`，MaxStepDown `1.1*BS`。
  - 普通 `StepHeight=28` 保留为 Source locomotion 绝对值（36.5 半砖 18.25，28 仍能走半砖但不能走整格），并加注释说明不是方块尺寸派生。
- `bmb_sheep.lua` / `sv_behaviors.lua`
  - sheep wander/flee 参数改为 cell 数：游荡 3~8 格；panic 半径 5 格、最小 1 格。
- `sv_block_world_mock.lua` / `sv_block_world_real.lua` / debug HUD/tool
  - mock 坐标换算、real 支撑 trace 半格/偏移、debug 方块渲染和右键目标推出都跟随 `BMB.GetBlockSize()`。
  - real `HasSupport` 的窄沿偏移由固定 12u 改为约 `1/3*BS`。
- 待用户游戏回归清单：
  - 控制台确认 `MC.BS` 与 `BMB.BS` 均为 36.5。
  - hop 一格稳定；两格必须上不去；半砖/楼梯平时靠 StepHeight 走上去。
  - 36.5 走廊 hull 32 双向通过。
  - drop 主动下 3 格（109.5u），4 格拒绝且不卡顿。
  - 吃草链路和 `WorldToBlock/BlockToWorld` 坐标往返正常；mock/real 尺度一致。

- Files modified:
  - `gmod_addon/lua/bmb/sh_config.lua`
  - `gmod_addon/lua/bmb/cl_debug.lua`
  - `gmod_addon/lua/bmb/sv_behaviors.lua`
  - `gmod_addon/lua/bmb/sv_block_world_mock.lua`
  - `gmod_addon/lua/bmb/sv_block_world_real.lua`
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `gmod_addon/lua/entities/bmb_sheep.lua`
  - `gmod_addon/lua/weapons/gmod_tool/stools/bmb_debug.lua`
  - `scripts/check_block_size_parameterization.ps1`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第二十五轮：StrandedRecovery 非法起点恢复（2026-06-12，待复测）

- 用户复测第二十四轮：36.5 后一格 hop、普通上台阶、旧 bug 回归项都没问题。新问题：羊不会走上 MC 半砖/台阶（path_cliff）；另一个场景是站到玻璃板上后 idle 冻住。
- 分诊：
  - MC 半砖/台阶是表面高度/shape 语义缺失，当前 MCSWEP 未提供接口，本轮不在 path_wall/path_cliff 里写特判，记录为后续 shape/floor height 接口待办。
  - 玻璃板问题可先修：实体物理上被 Source/MCSWEP 碰撞托着，但 BMB 网格语义认为当前 cell 非 standable。普通 Wander/Flee 从非法起点出发会空转或拿不到路，需要统一的 StrandedRecovery。
- `sv_pathfinder.lua`
  - 新增 `pathfinder.IsStandablePosition(pos, options)`，复用现有 passable + support 缓存语义，供 BaseMob 判断当前脚下是否合法。
  - 新增 `pathfinder.FindNearestStandable(origin, options)`，在半径内搜索最近合法 standable cell，供 recovery 选目标。
  - 新增 recovery 专用 `allowUnsupportedWalk`：普通 A* 仍要求 walk 邻居 standable；只有 recovery path 可把 passable 但无支撑的格子作为 `action="stranded"` 过渡节点，用来从玻璃板/非法起点逃回合法格。
- `bmb_base_mob.lua`
  - 新增 `ShouldRunBMBStrandedRecovery` / `RunBMBStrandedRecovery`。条件：非 held、`IsOnGround`、当前 BMB standable=false。空中下落不抢控制。
  - recovery 进入 `state=stranded` / `mode=stranded_recovery`，找最近合法 target，然后 `MoveToWorldPosition(..., allowStrandedStart=true, allowPartial=false)`。
  - Debug 右键 path 也带 `allowStrandedStart=true`，方便从玻璃板上直接点合法地面拉出来。
- `bmb_sheep.lua`
  - 状态机顺序：held → debug → stranded recovery → flee/eat/wander。debug 保持优先；无 debug 时先恢复合法地面再跑普通目标。
- 新增 `scripts/check_stranded_recovery.ps1`，先红灯确认缺口，再改到绿灯，防止以后移除 recovery 调度或路径语义。
- 用户复测截图显示 `state=stranded mode=stranded_no_target`：检测已命中，但逃生目标搜索/移动策略不够。
- 补丁：
  - `FindNearestStandable` 支持 `minHorizontalCells`，避免选中正下方合法格导致直线逃生水平向量为 0。
  - StrandedRecovery 默认搜索扩大为水平 16 格、向下 12 格、向上 3 格；这是逃生路径，成本优先级低于可用性。
  - 新增 `MoveBMBStrandedDirect`：找到合法目标后不走 A*，直接用 NextBot `SteerTowards` 朝目标 XY 直线逃离；中途离地进入 `stranded_fall`，落地后重新判定 standable。
  - `stranded_no_target` 只表示当前大范围内真没找到合法格，会按 `StrandedRecoveryRetryDelay` 周期重扫，不永久冻结。
- 用户再次复测：直接在玻璃板上生成会明显卡顿，而且会沿玻璃板结构走下去。分诊为两点：
  - 大范围 3D 搜索在 real world 中会触发大量 passable/support 查询，周期性卡顿。
  - 远处合法目标 direct steering 会把玻璃板真实碰撞当成可走路线，破坏"玻璃板不可寻路"语义。
- 修正：
  - StrandedRecovery 默认搜索降回小范围，不在行为层周期性大半径扫格。
  - 新增 `HasBMBPhysicalGroundAt` / `FindBMBStrandedEscapePoint` / `MoveBMBStrandedBailOut`。
  - 恢复策略改为本地 8 方向 bail-out：邻近合法 standable 点优先；否则选无物理支撑的一侧轻推下去，进入 `stranded_fall` 后落地复判。
  - HUD 预期从 `stranded_recovery` 转为 `stranded_bail`，必要时 `stranded_fall`；不再使用远点 `stranded_direct` 作为默认恢复路径。

- Files modified:
  - `gmod_addon/lua/bmb/sv_pathfinder.lua`
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `gmod_addon/lua/entities/bmb_sheep.lua`
  - `scripts/check_stranded_recovery.ps1`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第二十六轮：移动恢复与多 mob 首轮性能优化（2026-06-13，待复测）

- 用户复测第二十五轮：玻璃板上能进入 `stranded_bail`，但撞到障碍会停在 `stranded_bail_blocked`；高处 `path_drop` 下落时会在空中回头给一脚反向速度再转回来；复杂台阶 `path_hop` 会直接贴着能跳/不能跳的位置都试一下；50 只 NPC 帧率掉到十位数。
- 分诊：
  - `FindBMBStrandedEscapePoint` 方向顺序固定，bail-out 被挡后下一轮还会选同方向。
  - `path_drop` 空中仍走通用 `SteerBMBInAir(carrot)`，carrot 落到身后时会 FaceTowards + 改水平速度。
  - `GetBMBHopLaunchControl` 只看距离窗口，不看横向是否对齐 launch line；距离过远时仍朝上层格中心/方块面走。
  - `Think()` 每 tick 做 activity/物理影响维护；activity 又可能查地面状态，多只 idle mob 会放大。
- `bmb_base_mob.lua`
  - 新增 `RecordBMBStrandedEscapeFailure` / `IsBMBStrandedEscapeDirectionBlocked`，bail-out 失败方向短冷却，HUD 模式改 `stranded_bail_retry`，下一轮从游标方向继续找。
  - 新增 `MaintainBMBDropAir`，drop 离地后只刷新 watchdog，不再 FaceTowards/air-steer，保持 MC 式下落观感。
  - `GetBMBHopLaunchControl` 新增 `BlockHopLaunchLateralToleranceScale=0.35`；横向偏离先 `align` 到 backoff，距离过远也走 backoff，不直接冲方块面。
  - 新增 `ThinkInterval=0.1` / `HeldThinkInterval=0`；非 held 的维护 Think 节流，held 仍每 tick 缴械防物理枪抽动回归。
- 新增 `scripts/check_movement_recovery_and_scaling.ps1`，覆盖 stranded retry、drop no-backturn、hop align、Think throttling。

- Files modified:
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `scripts/check_movement_recovery_and_scaling.ps1`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第二十七轮：drop 惯性、debug replan、spawn idle 与多 mob 峰值优化（2026-06-13，待复测）

- 用户复测第二十六轮：
  - 玻璃板撞墙后不会继续卡死 ✅
  - 高处 drop 不再空中转身 ✅，但仍带完整水平惯性，会从高处被甩出去一段。
  - 复杂台阶 hop 已先对准再跳 ✅
  - 性能仍不够：20 多只 sheep/NPC 就掉到十位数 FPS。
  - debug 右键寻路经过 hop/partial 到没有可走地方会放弃 debug。
  - 新放出来的羊应该先 idle 一会儿，像 MC，不应立刻 wander。
- 分诊：
  - `MaintainBMBDropAir` 只移除了 `FaceTowards`/air steer，没有处理离边瞬间保留下来的完整水平速度；Source 空中摩擦小，所以不会自动慢下来。
  - `RunBMBDebugMove` path 分支只调用一次 `MoveToWorldPosition`，不管返回成功/失败都会 `ClearBMBDebugMove()`；partial/dead-end/hop 失败因此直接回普通行为。
  - `bmb_sheep.Initialize` 直接 `SetBMBState("wander")`，行为循环第一轮就可能选目标。
  - 性能尖峰不是单一 `Think`：Wander 单轮最多 8 次完整 A*，A* 默认每 64 iteration 才 yield，20 只同时起步会同帧堆搜索；周期 `ents.FindInSphere` 也过密且未错峰。
- `gmod_addon/lua/entities/bmb_base_mob.lua`
  - 新增 `DropAirMaxHorizontalSpeedScale=0.35`，`MaintainBMBDropAir` 在不转身、不追 carrot 的前提下钳制空中水平速度，避免完整行走/跑步惯性把 mob 甩远。
  - 新增 `DebugPathSegmentMinTimeout` / `DebugPathRepathDelay`；debug path 分支改为 while：目标到达或 debug 过期前持续 `MoveToWorldPosition`，并显式 `allowPartial=true` / `acceptPartial=true`，失败只显示 `debug_repath` 后短暂停顿重算。
  - 新增 `RunBMBInitialIdle`，供友好 mob 出生 idle 复用。
  - 非 held `ThinkInterval` 进一步从 0.1 调到 0.2；`PhysicsImpactInterval` 从 0.08 调到 0.3，生成时 `NextPhysicsImpactCheck = CurTime() + math.Rand(...)` 错峰。`OnContact`/`StartTouch` 仍保留即时 prop impact。
- `gmod_addon/lua/bmb/sh_config.lua` / `sv_pathfinder.lua`
  - 新增 `BMB.Config.PathfinderYieldEvery = 24`；A* 默认 yield budget 从硬编码 64 改走全局配置，降低多 mob 同帧展开量。
- `gmod_addon/lua/bmb/sv_behaviors.lua`
  - Wander 单轮完整 path 尝试改为 `mob.WanderPathAttempts`（sheep=2），失败后 `WanderFailurePauseMin/Max` 随机退避，避免同一行为 tick 连刷多次 A*。
- `gmod_addon/lua/entities/bmb_sheep.lua`
  - 新增 `InitialIdleMin=4.0` / `InitialIdleMax=9.0`；生成时状态为 `idle` 并记录 `BMBInitialIdleUntil`。状态机顺序保持 debug/stranded/flee 优先，initial idle 只挡普通 eat/wander。
- 新增 `scripts/check_drop_debug_spawn_perf.ps1`，先红灯确认缺口，再改绿灯；同步更新 `scripts/check_movement_recovery_and_scaling.ps1` 的 ThinkInterval 期望。

- Files modified:
  - `gmod_addon/lua/bmb/sh_config.lua`
  - `gmod_addon/lua/bmb/sv_behaviors.lua`
  - `gmod_addon/lua/bmb/sv_pathfinder.lua`
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `gmod_addon/lua/entities/bmb_sheep.lua`
  - `scripts/check_drop_debug_spawn_perf.ps1`
  - `scripts/check_movement_recovery_and_scaling.ps1`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第二十八轮：恢复 NextBot Think 每 tick，修走路一卡一卡回归（2026-06-13，待复测）

- 用户复测第二十七轮：
  - `path_drop` 空中不再转身 ✅
  - debug 右键寻路正常 ✅
  - 新生成 sheep 先 idle 4~9 秒 ✅
  - 性能优化正常 ✅
  - 新回归：NPC 走路一卡一卡，怀疑优化删减/节流误伤。
- 分诊：
  - 第 27 轮把 `bmb_base_mob:Think()` 末尾从 `NextThink(CurTime())` 改成 `NextThink(CurTime() + self.ThinkInterval)`，且 `ThinkInterval=0.2`。
  - 这等于把整个 NextBot entity Think 降到 5Hz。移动协程仍 yield，但实体级 Think/身体更新/客户端插值会被外层调度拖成肉眼可见的“走一顿一顿”。
  - 旧历史里也有类似经验：`NextThink(CurTime()+0.08)` 会制造移动补油门感；所以 whole Think 不能当性能阀门。
- 修正：
  - 删除 `ThinkInterval` / `HeldThinkInterval` 的外层调度语义。
  - `Think()` 末尾恢复 `self:NextThink(CurTime())`，并加注释：NextBot locomotion/body interpolation 必须逐 tick；贵维护项在内部节流。
  - 性能优化仍保留：`PhysicsImpactInterval=0.3` + 生成时错峰；A* `PathfinderYieldEvery=24`；Wander `WanderPathAttempts=2` + failure pause；spawn idle。
  - 更新 `scripts/check_drop_debug_spawn_perf.ps1` / `scripts/check_movement_recovery_and_scaling.ps1`：要求 `NextThink(CurTime())`，禁止 `NextThink(CurTime()+self.ThinkInterval)` 回归。
- 红绿验证：
  - 改检查脚本后，当前第 27 轮代码红灯：两个脚本都报 `NextBot entity Think must stay every tick` / `many-mob scaling must not throttle the whole entity Think`。
  - 恢复 per-tick Think 后两脚本转绿。

- Files modified:
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `scripts/check_drop_debug_spawn_perf.ps1`
  - `scripts/check_movement_recovery_and_scaling.ps1`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

### 第二十九轮：hop face-distance、debug 命令续命、carrot 防跨洞（2026-06-13，待复测）

- 用户复测第二十八轮：
  - NPC 不再卡，玩家也不卡 ✅
  - 新问题 1：BlockHop 很多时候连续跳不上去，日志里多次失败后才偶尔成功。
  - 新问题 2：debug 右键跳到上面后跑到一半不动，随后回到 wander。
  - 新问题 3：debug 期间能直接跨过一格方块空洞。
- 分诊：
  - hop 日志签名非常明确：失败多为 `dist≈34~38 / face≈16~20 / speed≈0~23 / apex=0~36`；成功样本为 `dist≈49 / face≈31 / speed≈111 / apex≈50`。弹道本身能成功，问题是准入允许在 hull 几乎贴着方块面时硬跳，水平段顶住方块侧面后上抛被吃。
  - debug 半路回 wander 仍是命令寿命层问题：Tool 右键按直线距离给预算，复杂绕路/hop/repath 会超过初始 `BMBDebugMoveUntil`；MoveToWorldPosition 一段失败后如果命令过期就直接退出 debug。
  - 跨一格空洞是 carrot 可见性缺了“支撑”维度：`IsPathGridVisible` 只检查直线 hull 是否撞 solid，不检查中间 sample 是否 standable；A* 绕洞的路径被 carrot 直线抄近路到对面平台，Source safety 只探 carrot 点本身，洞中间漏掉。
- `gmod_addon/lua/entities/bmb_base_mob.lua`
  - 新增 `BlockHopLaunchMinFaceDistanceScale=0.75` / `BlockHopLaunchIdealFaceDistanceScale=0.85`。
  - `GetBMBHopLaunchControl` 的 ready 条件加入 `faceDistance >= minFaceDistance`；`face_close` 时先 steer 到按 ideal face distance 计算出的 backoff/launch 点。36.5 下最小 face≈27u，理想 face≈31u，对齐用户成功样本。
  - 新增 `DebugPathCommandTimeout=120` / `DebugPathProgressGrace=8`；debug path 每段调用前记录 dist/advance，若 `moved`、推进节点或明显靠近目标，则 `BMBDebugMoveUntil = math.max(..., CurTime()+grace)` 续命。
  - 新增 `IsBMBPathLineStandable`；`IsPathGridVisible` 现在每个 sample 同时要求 hull clear 和 A* 同一 standable 语义，单次 carrot 检查共享 `passable/support` cache，避免重复放大开销。
- `gmod_addon/lua/weapons/gmod_tool/stools/bmb_debug.lua`
  - 右键 target move 的初始 `BMBDebugMoveUntil` 改用 `mob.DebugPathCommandTimeout or 120` 作为下限，复杂路径默认不会十几秒就过期。
- 新增 `scripts/check_hop_debug_gap_regressions.ps1`，先红灯确认缺口，再改绿灯。

- Files modified:
  - `gmod_addon/lua/entities/bmb_base_mob.lua`
  - `gmod_addon/lua/weapons/gmod_tool/stools/bmb_debug.lua`
  - `scripts/check_hop_debug_gap_regressions.ps1`
  - `CLAUDE.md`
  - `docs/STATE.md`
  - `.planning/mcgm-main/*`

## 2026-06-13 Second 30th round - debug gap no-progress + MC-like collision first pass

- User follow-up:
  - 普通 path 跨一格空已经没问题。
  - debug 期间如果碰到这个空洞/死路位置会“死机”，卡在 debug 状态不恢复。
  - 新需求：碰撞尽量接近 MC，玩家/羊之间不要像硬刚体支撑；优先尝试 collision group，不够再做软水平推挤，并注意性能。
- Root cause / design:
  - 第二十九轮把 debug target 命令寿命拉到约 120s 是正确的，但缺了“命令级无进展”出口。对于不可达 gap/dead-end，移动段会反复失败并进入 `debug_repath`，命令层仍然有效，于是看起来像假死。
  - MC 式实体碰撞不能写进 path steering/stranded/hop 内部，否则会和移动目标抢速度。它应当是所有移动决策之后的最后一道水平速度叠加。
  - 软推挤不能裸两两循环。用 `ents.FindInSphere` 近邻扫描、per-entity `NextSoftSeparationAt` 错峰限频，避免 50 只时 O(n²) 尖峰。
- `gmod_addon/lua/entities/bmb_base_mob.lua`
  - 新增 `DebugPathNoProgressTimeout=3.5`。
  - `RunBMBDebugMove` path 模式新增 `debugLastProgressAt/debugProgressTarget/debugLastProgressDistance`。只有推进 path node 或明显靠近目标才刷新 `BMBDebugMoveUntil`；连续无进展超过阈值则 `FailBMBMove("debug_no_progress")` + `ClearBMBDebugMove()`，避免卡在 `debug_repath` 到命令过期。
  - 新增 `MobCollisionGroup = COLLISION_GROUP_PLAYER or COLLISION_GROUP_NPC` 与 `GetBMBMobCollisionGroup()`；`BaseInitialize` 不再硬编码 `COLLISION_GROUP_NPC`。
  - 新增软分离参数：`SoftSeparationEnabled/Interval/SearchRadiusScale/RadiusPadding/Strength/PlayerStrength/MaxSpeed/VerticalTolerance`。
  - `BaseInitialize` 初始化 `NextSoftSeparationAt` 随机 offset；`Think` 保持 `NextThink(CurTime())`，在 activity 更新后调用 `ApplyBMBSoftSeparation()`。
  - 新增 `IsBMBSoftSeparationEntity`、`GetBMBEntityHorizontalRadius`、`AreBMBSoftSeparationZRangesNear`、`GetBMBSoftSeparationFallbackDirection`、`ApplyBMBSoftSeparation`。
  - 软分离只处理玩家和 BMB mob；垂直范围只做 near/overlap 判定，推力始终 `Vector(separation.x, separation.y, 0)`，叠加到当前 velocity，保留 z，不制造“站在 mob 上”的竖直支撑。
- Docs/tests:
  - 新增 `scripts/check_debug_gap_and_collision.ps1`，先红灯确认缺口，再改绿灯。
  - `CLAUDE.md` 增加 debug no-progress 与 MC-like collision/soft separation 规则。
  - `docs/STATE.md`、task_plan、progress、findings、status_summary 同步第三十轮状态。
- Validation so far:
  - `scripts/check_debug_gap_and_collision.ps1`

## 2026-06-13 Second 31st round - disable player/BMB hard collision support

- User retest:
  - debug gap/dead-end no-progress fixed ✅.
  - Collision first pass failed: screenshot shows player standing on top of `bmb_sheep` bbox, HUD still `state=idle mode=idle`, so the mob is acting as a hard support platform.
- Root cause:
  - `COLLISION_GROUP_PLAYER` alone does not disable player↔NextBot hard collision/support in this setup.
  - Soft horizontal separation cannot remove vertical support if the engine collision pair still resolves player-on-mob contact first. The hard pair has to be disabled before soft push can produce MC-style overlap/slide behavior.
- Test:
  - Extended `scripts/check_debug_gap_and_collision.ps1` to require `SetCustomCollisionCheck(true)`, a `ShouldCollide` hook named `BMB_SoftEntityCollision`, centralized `ShouldDisableBMBHardEntityCollision`, and `return false` for player/BMB hard collision pairs.
  - Verified red before code: missing custom collision check, hook, and centralized rule.
- `gmod_addon/lua/entities/bmb_base_mob.lua`
  - Added `DisableHardEntityCollision = true`.
  - `BaseInitialize` now calls `SetCustomCollisionCheck(true)` and `CollisionRulesChanged()` after setting collision group.
  - Added `BMB.ShouldDisableBMBHardEntityCollision(ent1, ent2)`: returns true for player↔BMB mob and BMB mob↔BMB mob pairs, unless the mob opts out via `DisableHardEntityCollision=false`.
  - Added `hook.Add("ShouldCollide", "BMB_SoftEntityCollision", ...)` returning `false` for those pairs.
  - Prop/world collision is not touched; soft separation still handles horizontal push as the final velocity overlay.
- Docs/tests:
  - `CLAUDE.md` updated: collision group is insufficient; hard support must be disabled through custom collision + `ShouldCollide`, then soft separation handles horizontal overlap.
  - `docs/STATE.md`, task_plan/progress/findings/status_summary updated to third-first round.

## 2026-06-13 Third 31st round - collision plan rollback, keep GMod feel

- User retest:
  - `debug_no_progress` fix is confirmed good.
  - The collision experiment broke core GMod interactions:
    - Physgun can no longer pick up the mob.
    - Bullets/gun damage no longer damages the mob.
    - The custom collision path conflicts with prop physics damage semantics.
  - User decision: delete the MC-like collision plan and keep GMod feel.
- Root cause / conclusion:
  - Entity collision is not isolated from trace/physgun/damage in this setup. Changing collision group or `ShouldCollide` affects more than player body support.
  - Soft separation adds another velocity path that can interfere with damage/physics behavior. This is not worth pursuing for now.
  - Keep the already-verified debug gap no-progress fix; roll back only the collision plan.
- `gmod_addon/lua/entities/bmb_base_mob.lua`
  - Restored `self:SetCollisionGroup(COLLISION_GROUP_NPC)`.
  - Removed `MobCollisionGroup`, `DisableHardEntityCollision`, all `SoftSeparation*` parameters.
  - Removed `GetBMBMobCollisionGroup`.
  - Removed `SetCustomCollisionCheck(true)` / `CollisionRulesChanged()`.
  - Removed `NextSoftSeparationAt` init and `self:ApplyBMBSoftSeparation()` from `Think`.
  - Removed `BMB.ShouldDisableBMBHardEntityCollision` and `hook.Add("ShouldCollide", "BMB_SoftEntityCollision", ...)`.
  - Removed soft separation helper functions and velocity overlay.
- `scripts/check_debug_gap_and_collision.ps1`
  - Now asserts debug gap no-progress remains.
  - Now asserts GMod default collision remains: `SetCollisionGroup(COLLISION_GROUP_NPC)` present and no `COLLISION_GROUP_PLAYER`, custom collision, `ShouldCollide`, or soft separation code remains.
- Docs:
  - `CLAUDE.md` changed to explicit rule: preserve GMod/NextBot default collision feel; do not reintroduce player-like collision group, `ShouldCollide`, or soft separation without a separate design that proves physgun/trace/damage isolation.
  - `docs/STATE.md` and planning files mark the MC-like collision plan as rolled back.

## 2026-06-13 Second 32nd round - Flee speed/activity stability

- User report:
  - Flee state speed is visibly unstable.
  - This will look bad after sheep skin/model animation is added.
  - Because BMB Base will be reused by future NPCs, this needs to be fixed at Base level, not just sheep-specific tuning.
- Root cause:
  - Flee calls `MoveToWorldPosition(destination, mob.RunSpeed, ...)`, but `MoveAlongPath` uses the shared `path_corner` controller.
  - `path_corner` reduces transient `pathSpeed` to `desiredSpeed * PathCornerSpeedScale` (sheep: `90 * 0.55 = 49.5`), below sheep's run activity threshold `(WalkSpeed + RunSpeed) / 2 = 80`.
  - Before this round, `BMBDesiredSpeed` served both as loco command speed and animation/activity intent speed. Therefore corner slowdown during panic could make activity selection and HUD target speed oscillate between run/walk semantics.
- Design:
  - Split speed into two layers:
    - `BMBDesiredSpeed`: current loco command speed, may change per tick due to cornering/drop/local control.
    - `BMBActivitySpeed`: behavior/animation intent speed, stable across a movement segment unless the behavior intent changes.
  - Flee should preserve run intent for the whole panic segment while still allowing path following to steer/corner.
  - Clamp Flee corner slowdowns above run threshold via `minPathSpeed`, without accelerating above the requested `RunSpeed`.
- `gmod_addon/lua/entities/bmb_base_mob.lua`
  - Added NW float `BMBActivitySpeed`.
  - Added `GetBMBRunActivityThreshold()`.
  - `UpdateMoveActivity(speed, activitySpeed)` and `MaintainBMBMoveSpeed(speed, activitySpeed)` now accept an optional stable intent speed.
  - `UpdateBMBActivityFromLocomotion()` uses `BMBActivitySpeed` rather than only transient `BMBDesiredSpeed`.
  - `MoveAlongPath()` reads `options.moveIntentSpeed` and `options.minPathSpeed`; after corner control, it clamps `pathSpeed = max(pathSpeed, min(desiredSpeed, minPathSpeed))`; per-tick speed maintenance passes `moveIntentSpeed`.
- `gmod_addon/lua/bmb/sv_behaviors.lua`
  - Flee computes `fleeMinPathSpeed` from `mob:GetBMBRunActivityThreshold() + padding`, capped by `mob.RunSpeed`.
  - Flee calls `MoveToWorldPosition(..., { moveIntentSpeed = mob.RunSpeed, minPathSpeed = fleeMinPathSpeed, allowPartial = false })`.
- Tests/docs:
  - Added `scripts/check_flee_speed_stability.ps1`; verified red before implementation and green after.
  - `CLAUDE.md` and `docs/STATE.md` document the intent-vs-command speed split.

## 2026-06-13 Third 33rd round - MC-like hurt flash, iframes, knockback, and flee rehit stability

- User request:
  - Restore Minecraft-like hurt feedback before moving to the next mob/base milestone.
  - Accepted hits should flash red, create a short invulnerability window, and knock the mob away from the attack source.
  - Knockback must only happen on accepted non-invulnerable hits.
  - Do not implement fall damage yet; only record it as later work.
  - Extra flee bug: if a sheep is already fleeing, repeated hits should not constantly interrupt the current flee segment and make it stand around re-deciding where to run.
- Source/reference check:
  - Local MC source `LivingEntity.java` shows `hurtDuration = 10; hurtTime = hurtDuration;` and `invulnerableTime = 20` on full accepted damage.
  - `dealDefaultKnockback` uses horizontal source/projectile direction; physics/fall sources should stay separate.
- Test:
  - Added `scripts/check_damage_iframes_knockback.ps1`.
  - Verified red before implementation: base had no hurt flash/invulnerability/knockback helpers, sheep did not prioritize knockback, docs did not record fall damage as pending.
- `gmod_addon/lua/entities/bmb_base_mob.lua`
  - Added `HurtFlashTime = 0.5` and `DamageInvulnerabilityTime = 1.0`.
  - Added client `ENT:Draw()` red tint using `BMBHurtFlashUntil` / `BMBHurtFlashDuration`; this does not permanently change entity color or material.
  - Added invulnerability tracking (`BMBDamageInvulnerableUntil`, `BMBInvulnerableUntil` NW).
  - `OnTakeDamage` now ignores hits during invulnerability with `return 0`; ignored hits do not deduct health, refresh flee, flash, or knock back.
  - Added source-aware `GetBMBKnockbackDirection`: blast damage prefers damage position, attacker hits use attacker center, fallback uses damage position / force.
  - Added first-class knockback state: `StartBMBKnockback`, `IsBMBKnockbackActive`, `RunBMBKnockback`; speed is reset to a capped horizontal velocity instead of stacking.
  - Normal movement entry points reject new steering while knockback is active.
  - `DMG_CRUSH` prop/physics damage remains identifiable and does not get the BMB knockback overlay, preserving the GMod/prop damage feel.
- `gmod_addon/lua/entities\bmb_sheep.lua`
  - Scheduler priority now checks held -> knockback -> debug -> stranded -> flee.
  - `OnBMBInjured(damageInfo, wasFleeing)` refreshes panic threat/window, but does not call `InterruptBMBMovement` again when the hit happened during an active flee segment.
- `gmod_addon/lua\bmb\sv_behaviors.lua`
  - Flee exits promptly if knockback becomes active, so the behavior scheduler can run the knockback state instead of staying inside the flee loop.
- Docs:
  - `CLAUDE.md`, `docs/STATE.md`, task_plan/findings/status_summary updated.
  - Fall damage recorded as pending and explicitly separate from knockback.

## 2026-06-13 Fourth 34th round - fix hurt flash `vel:70/0` freeze and missing knockback

- User retest:
  - Hurt flash works.
  - Invulnerability frames work.
  - Two regressions:
    - Every flash makes the mob stop; HUD shows examples like `vel:70/0`.
    - No visible knockback effect.
- Root cause:
  - `cl_debug.lua` line 2 is current 2D velocity / `BMBDesiredSpeed`, not a separate maxspeed field.
  - `StartBMBHurtFlash()` is clean: it only writes `BMBHurtFlashDuration` and `BMBHurtFlashUntil`; it does not touch movement/loco/velocity.
  - The `0` was written by `RunBMBKnockback()` via `MaintainBMBMoveSpeed(0)`.
  - That made the public movement/animation intent `BMBDesiredSpeed=0`, producing HUD `70/0`, and likely caused the loco desired-speed budget to swallow the horizontal `SetVelocity` knockback.
- Test:
  - Extended `scripts/check_damage_iframes_knockback.ps1`.
  - Verified red before code: missing `BMBKnockbackDesiredSpeed`; `RunBMBKnockback()` still contained `MaintainBMBMoveSpeed(0)`.
  - New checks:
    - `StartBMBHurtFlash` must not contain movement/loco/velocity/desired-speed writes.
    - `RunBMBKnockback` must not call `MaintainBMBMoveSpeed(0)` or `SetDesiredSpeed(0)`.
- Fix:
  - `StartBMBKnockback` now snapshots:
    - `BMBKnockbackDesiredSpeed`
    - `BMBKnockbackActivitySpeed`
    - `BMBKnockbackLocoSpeed`
  - Added `MaintainBMBKnockbackSpeedBudget()`:
    - Keeps networked `BMBDesiredSpeed` / `BMBActivitySpeed` at the pre-hit non-zero movement intent for HUD/animation.
    - Sets loco's internal desired speed to a high enough knockback budget so direct horizontal `SetVelocity` can take effect.
  - Removed `MaintainBMBMoveSpeed(0)` from `RunBMBKnockback`.
  - `StartBMBKnockback` now applies one immediate horizontal velocity write in the damage tick, so visible push does not wait for the next behavior scheduler iteration.
- Verification:
  - `scripts/check_damage_iframes_knockback.ps1`
  - `scripts/check_flee_speed_stability.ps1`
  - `scripts/check_debug_gap_and_collision.ps1`
  - `scripts/check_hop_debug_gap_regressions.ps1`
  - `scripts/check_drop_debug_spawn_perf.ps1`
  - `scripts/check_movement_recovery_and_scaling.ps1`
  - `scripts/check_stranded_recovery.ps1`
  - `scripts/check_block_size_parameterization.ps1`
  - `glualint` on changed Lua files.

## 2026-06-13 Fifth 35th round - MC knockback lift, 0.5s damage cooldown, airborne flee resume

- User retest:
  - `vel` no longer becomes `.../0`.
  - Still sees the mob stop after being hit.
  - Damage cooldown feels too long; user checked current MC and expects about 0.5s.
  - MC mobs continue trying to flee while airborne after getting hit.
  - Knockback exists after the second hit but is too flat/weak; the first hit after spawning only flashes/damages, with no visible knockback.
- Source check:
  - `LivingEntity.hurt` sets `invulnerableTime = 20`, but the cooldown branch only ignores same/lower damage while `invulnerableTime > 10`.
  - Effective same-damage invulnerability/cooldown is therefore the first 10 ticks = 0.5s, not a full 1.0s.
  - MC knockback sets vertical motion when grounded: `onGround ? min(0.4, y/2 + power) : y`, so grounded hits should have a small lift, airborne hits keep current vertical motion.
- Test:
  - Extended `scripts/check_damage_iframes_knockback.ps1` and verified red before code.
  - New checks require:
    - `DamageInvulnerabilityTime = 0.5`.
    - Short `KnockbackDuration = 0.12`.
    - `KnockbackVerticalSpeedScale` and `GetBMBKnockbackVerticalVelocity`.
    - Grounded knockback calls `self.loco:Jump()` before applying vertical lift.
    - Flee detects `airborneStart` and passes `allowStrandedStart = airborneStart`.
- `gmod_addon/lua/entities/bmb_base_mob.lua`
  - Changed `DamageInvulnerabilityTime` from 1.0 to 0.5.
  - Changed `KnockbackDuration` from 0.35 to 0.12. This keeps a short arbitration window to protect the initial impulse, then lets flee/airborne movement resume.
  - Added vertical lift settings: `KnockbackVerticalSpeedScale = 6`, min 170u/s, max 240u/s.
  - Added `GetBMBKnockbackVerticalVelocity(currentVelocity)`:
    - Grounded: returns clamped vertical lift.
    - Airborne: preserves current z velocity.
  - `StartBMBKnockback` now stores `BMBKnockbackVerticalSpeed`, calls `self.loco:Jump()` when applying lift from ground, and immediately writes horizontal + vertical velocity in the damage tick.
- `gmod_addon/lua/bmb/sv_behaviors.lua`
  - Flee now computes `airborneStart = mob.IsBMBOnGround and not mob:IsBMBOnGround() or false`.
  - Flee passes `allowStrandedStart = airborneStart` so a mob knocked airborne can still try to pick/follow a flee path instead of waiting frozen for ground contact.
- Verification:
  - Damage/knockback script.
  - Flee speed script.
  - Debug gap/collision rollback script.
  - Hop/debug/gap script.
  - Drop/debug/spawn/perf script.
  - Movement recovery/scaling script.
  - Stranded recovery script.
  - Block-size parameterization script.
  - glualint on changed Lua files.

## 2026-06-13 Zombie phase 1 - BMB Base migration slice

- User confirmed round 35 sheep/base damage feedback has no visible bugs, then started the next stage: new mob / Zombie.
- External `H:\工作视频\20251115毕业\specV3_zombie_phase1.md` could not be read because the approval service rejected the H drive read with an auto-review error. Proceeded from repo docs/CLAUDE Phase 3 direction and kept the slice intentionally small.
- Goal:
  - Validate BaseMob with a hostile mob.
  - Do not reuse the old `mcgm_zombie.lua` navmesh prototype except as rough parameter history.
  - Add reusable hostile modules instead of putting chase/attack logic inside one zombie file.
- Added `scripts/check_zombie_phase1.ps1`.
  - Requires new `bmb_zombie.lua` to inherit `bmb_base_mob`.
  - Requires shared `SeekTarget`, `Chase`, and `MeleeAttack` behaviors.
  - Forbids `Path("Follow")`, `navmesh`, and `SetAngles` in the new zombie.
  - Checks spawn menu registration and docs/planning entries.
- `gmod_addon/lua/bmb/sv_behaviors.lua`
  - Added `BMB.Behaviors.SeekTarget`.
    - Keeps current valid target within lose range.
    - Scans alive players on a configurable interval.
    - Lets mobs override target filtering through `CanBMBTarget`.
  - Added `BMB.Behaviors.Chase`.
    - Runs short BMB A* chase segments toward the target's current position.
    - Uses `skipSourcePath=true`, `allowPartial=true`, `acceptPartial=true`, `moveIntentSpeed=RunSpeed`, and run-threshold `minPathSpeed`.
    - Replans naturally every chase segment instead of using the old Source `Path("Follow")`.
  - Added `BMB.Behaviors.MeleeAttack`.
    - Handles range, cooldown, windup/hit delay, attack lock, gesture, `DamageInfo`, and target knockback.
    - Damage attribution uses the mob as attacker/inflictor.
- `gmod_addon/lua/entities/bmb_zombie.lua`
  - New spawnable `BMB Prototype Zombie`.
  - Inherits `bmb_base_mob`.
  - Parameters first-pass migrated from legacy feel: 20 HP, speed 92/115, target 900/1150, attack range 38, 10 damage, 1.05s cooldown, 0.38s hit delay.
  - MC-sized-ish hull for zombie: width 22u, height 72u.
  - Scheduler priority mirrors sheep/base: held -> knockback -> debug -> stranded -> hostile AI.
  - Targets players only for phase 1.
  - On damage, retaliates by setting attacker as target and uses BaseMob hurt flash/iframes/knockback.
- `gmod_addon/lua/autorun/mcgm_autorun.lua`
  - Registered `BMB Prototype Sheep` and `BMB Prototype Zombie` under `BlockMob Base`.
  - Kept old `MCGM Prototype Zombie` registration for legacy comparison.
- Docs updated:
  - `docs/STATE.md`
  - `CLAUDE.md`
  - `.planning/mcgm-main/task_plan.md`
  - `.planning/mcgm-main/progress.md`
  - `.planning/mcgm-main/findings.md`
  - `.planning/mcgm-main/status_summary_2026-06-10.md`
- Verification planned:
  - New zombie phase script.
  - Existing movement/damage regression scripts.
  - glualint on changed Lua files.
  - Sync addon to GMod for user retest.

## 2026-06-13 Zombie phase 1 first retest fixes

- User retest found:
  - Zombie can enter `chase` at range but does not obviously move toward the player.
  - While moving, Classic zombie legs do not animate.
  - With vertical height difference, Zombie stands below the player in `attack_ready` / `vel:0/0` and looks upward instead of finding a route.
  - Hurt flash appears to have a fade curve, but MC hurt flash should be instant red for the whole short window.
  - Attack range feels too short /贴脸.
- Root cause / fix:
  - `Chase.Run` used horizontal range only for `attack_ready`; added vertical melee range semantics in `MeleeAttack.IsInRange`.
  - Zombie now uses `AttackRange = 52` and `AttackVerticalRange = 28`; one full block above should keep chasing instead of attack-ready idling.
  - `ChaseSegmentTimeout = 1.0` separates movement segment budget from target scan/repath cadence.
  - BaseMob activity selection now supports `IdleActivity`, `WalkActivity`, `RunActivity`, and `JumpActivity`; Zombie maps `RunActivity = ACT_WALK` because the current Classic zombie placeholder can freeze its legs on `ACT_RUN`.
  - Base hurt flash draw changed from remaining-time fade to constant red while `BMBHurtFlashUntil > CurTime()`.
- Regression checks:
  - Extended `scripts/check_zombie_phase1.ps1`.
  - Extended `scripts/check_damage_iframes_knockback.ps1`.
  - glualint on changed Lua files.

## 2026-06-13 Zombie phase 1 second retest fixes

- User retest found:
  - Standing two blocks above makes Zombie stop.
  - At distance it can move, but walks a few steps and pauses.
  - Attack speed should be faster.
  - During attack, HUD target speed becomes 0, unlike MC.
  - Complex stair block shows `path_hop`, but jump does not actually trigger; state soon returns to `idle`.
- Fix:
  - Removed melee hard lock (`BMBMeleeLockUntil`) from shared hostile attack flow.
  - Removed `MaintainBMBMoveSpeed(0)` from attack/attack_ready.
  - Added/used `AttackMoveSpeed=92` so Zombie keeps pressure while swinging.
  - Tuned Zombie attack: cooldown 1.05 -> 0.8, hit delay 0.38 -> 0.28.
  - When chase fails but the target remains valid, Zombie keeps `TargetEntity`, publishes `chase_repath`, and retries shortly instead of clearing target and idling.
  - Added `IsBMBVerticalPathNodeReached` in BaseMob; hop/drop node advance and final reached now require actual target foot height, not only 2D distance/cell.
- Tests:
  - Extended `scripts/check_zombie_phase1.ps1`.
  - Extended `scripts/check_hop_debug_gap_regressions.ps1`.
  - glualint on changed Lua files.

## 2026-06-14 Sheep Flee full-speed retune

- User report:
  - Sheep Flee HUD target speed sometimes shows `81`, sometimes `90`.
  - Flee duration feels too short.
  - Desired tuning: Flee speed `100` and a longer panic window.
- Diagnosis:
  - Sheep had `WalkSpeed=70` and `RunSpeed=90`.
  - Flee path following used `GetBMBRunActivityThreshold() + padding` as `minPathSpeed`; for 70/90 this is about `81`.
  - Straight segments therefore showed the old full run target `90`, while path corner / local control could clamp the target down to `81`.
  - This was intended to keep run animation above the walk/run threshold, but for the sheep HUD/model pass we want panic target speed itself to stay full-speed.
- Implemented:
  - Sheep `RunSpeed` changed to `100`.
  - Sheep now sets `FleeKeepFullSpeed=true`.
  - Sheep `FleeDurationMin/Max` changed to `3.5/5.0`.
  - Shared Flee checks `mob.FleeKeepFullSpeed` before the run-threshold fallback, so only mobs that opt in keep full path-corner speed.
  - `scripts/check_flee_speed_stability.ps1` now guards the sheep-specific 100/full-speed/longer-window tuning.
- Next game retest:
  1. Hit a sheep and confirm HUD target speed remains `100` through straight movement and corners.
  2. Confirm Flee lasts longer than the old 2s window, then naturally returns to normal behavior.
  3. Confirm enclosed/no-path Flee give-up, cliff/wall safety, hop/drop, and debug-gap behavior still hold.

## 2026-06-14 BMB sequence animation adapter

- User coordination:
  - Converter side will export `$sequence` names from entity.json animation aliases verbatim, e.g. `walk`.
  - Converter will only bake movement loops such as walk/swim/fly and skip target-driven clips such as look_at_target.
  - BMB only needs to consume the exported sequence names.
- Implemented:
  - BaseMob now has optional `AnimationSequences` per entity class, mapping logical actions to model sequence aliases.
  - If no `AnimationSequences` table is present, legacy `StartActivity` behavior is unchanged.
  - `LookupSequence` results are cached per model.
  - Missing action aliases or missing model sequences fall back to idle; if idle is also missing, BaseMob falls back to the old Activity layer.
  - Sequence changes use `ResetSequence` / `SetCycle(0)`.
  - walk/run playback rate is `current horizontal speed / reference speed`, clamped by per-mob tunables, so a fixed walk loop can track actual movement speed.
- New guard:
  - Added `scripts/check_sequence_animation_adapter.ps1`.
- First model note:
  - A mob can opt in with e.g. `AnimationSequences = { idle = "idle", walk = "walk", run = "walk", attack = "attack", hurt = "hurt", death = "death" }`.
  - Sequence names should match the converter's printed export list exactly.

## 2026-06-15 Zombie hurt knockback jump-state hotfix

- User report:
  - When a Zombie is chasing the player on MC blocks, hitting it can sometimes make it unexpectedly jump.
  - User later clarified it mainly happens while chasing.
- Diagnosis:
  - Base hurt knockback still used the sheep-friendly grounded lift path: `loco:Jump()` then `SetVelocity(horizontal + z)`.
  - During chase, Zombie resumes hostile steering immediately after the short knockback window.
  - On MC block tops, that temporary locomotion jump state can be picked up visually/behaviorally as a stray jump or connect awkwardly to chase/hop logic.
- Implemented:
  - Added `KnockbackUseJump` to BaseMob. Default remains `true`, preserving sheep/friendly mob hurt lift behavior.
  - Zombie sets `KnockbackUseJump=false`.
  - Zombie also sets hurt knockback vertical lift scale/min/max to 0, so normal damage knockback is horizontal-only.
  - Zombie attacking the player is unaffected; player knockback/vertical launch is still controlled by `AttackVerticalKnockback` / `AttackGroundedVerticalKnockback` in shared `MeleeAttack`.
- Next game retest:
  1. Let Zombie chase on a flat MC block platform, hit it repeatedly, and confirm it only slides/gets pushed horizontally.
  2. Confirm legitimate path_hop still works when Zombie must climb a one-block step during chase.
  3. Confirm Zombie melee still launches the player slightly and does not lose the previous 2-3 block tuning.

## 2026-06-15 Sheep sequence locomotion hookup parked

- User requirements:
  - Roll back the baked sequence hookup for sheep for now.
  - Comment out `AnimationSequences` / `AnimationReferenceSpeeds` until converter pivots and low-speed playback/cycle are fixed.
  - Keep the new persistent `BMBSheepLimbSwingAmount` + `BMBSheepLimbSwingPhase` smoothing logic.
  - Restore procedural leg `setBoneAngle` using the smoothed phase/amount, capped at 7 degrees.
- Implemented:
  - Parked sheep sequence locomotion behind commented code in `bmb_sheep`.
  - Restored `leg0..3` bone cache/manipulation in normal `UpdateBMBVisualBones`.
  - Leg pairs now use `sin(phase) * 7 * swingAmount`, with opposite legs counter-swinging.
  - Kept the old hard branch and old `rate` removed: swing amount still lerps by `FrameTime`, phase still advances from current 2D speed.
  - Updated `scripts/check_sequence_animation_adapter.ps1` to keep guarding the Base adapter while requiring sheep's temporary procedural leg state.
- Next game retest:
  1. Spawn sheep and confirm legs no longer freeze after the baked hookup rollback.
  2. Confirm stopping eases the legs back instead of snapping.
  3. Keep sheep `AnimationSequences` disabled until exporter pivot/rate work lands.

## 2026-06-14 Zombie Phase 2 range/head-overlap tuning

- User retest confirmed deterministic melee launch is fixed.
- Requested feel tweaks:
  - Lower Zombie horizontal knockback a bit.
  - Increase player acquisition range by 1.5x.
  - Slightly widen attack distance.
  - Allow Zombie to hit a player standing directly on its head.
- Implemented:
  - Zombie `TargetRange` changed from 900 to 1350 and `TargetLoseRange` from 1150 to 1725.
  - Zombie same-level `AttackRange` changed from 52 to 60.
  - Zombie `AttackKnockback` changed from 240 to 210 while keeping vertical lift at 155 / grounded 190.
  - Shared `MeleeAttack.IsInRange` now supports optional narrow vertical-overlap hits via `AttackVerticalOverlapRange` and `AttackVerticalOverlapFlatRange`.
  - Zombie sets overlap range to 86u vertical and 24u flat, so standing on its head can be hit without widening normal `AttackVerticalRange=28`.
- Tests:
  - Extended `scripts/check_zombie_phase2_attack_audio.ps1` to guard the new tuning and overlap branch.

## 2026-06-14 Zombie Phase 2 knockback distance retune

- User retest found:
  - `AttackKnockback=210` still sends the player about 4-5 blocks when combined with the stable grounded z launch.
  - Desired total travel is closer to 2-3 blocks.
  - Manual file edits appeared to have no effect, likely because GMod was reading the synced addon copy and/or already-spawned entities still had old Lua values.
- Implemented:
  - Reduced Zombie horizontal `AttackKnockback` from 210 to 150.
  - Kept `AttackVerticalKnockback=155` and `AttackGroundedVerticalKnockback=190` unchanged so the fixed launch does not regress.
  - Updated phase 1/phase 2 static checks to guard the new 150 horizontal tuning.
- Retest note:
  - Sync `gmod_addon/` into the Garry's Mod addon folder and respawn the Zombie after changing tuning values.

## 2026-06-14 Hop vertical reach hotfix

- User rolled back later chase experiments and retested hop first. One-block hop still showed `path_hop` followed by `debug_repath`; HUD could report a normal manual hop apex, so A* and the two-stage lift were not the primary failure.
- Log review: after Round 29 the hop trajectory itself was mostly unchanged. Round 38 added `IsBMBVerticalPathNodeReached` for final hop/drop correctness and included a `WorldToBlock(self:GetPos()).z == node.coord.z` level equality check.
- Diagnosis: `MC.WorldToCell` floors positions. A bot settled on a block top can sit exactly on the boundary or a hair below it for a tick, quantizing to the lower cell even though the physical foot height is correct. That makes successful hop landings fail node advancement and fall into debug replan.
- Fix:
  - `IsBMBVerticalPathNodeReached` now requires ground contact and compares actual foot `pos.z` to the target foot z within `VerticalPathReachZTolerance`.
  - It no longer depends on block-cell z equality for vertical action completion.
- Checks:
  - glualint on `bmb_base_mob.lua`
  - `scripts/check_hop_debug_gap_regressions.ps1`
  - `scripts/check_block_size_parameterization.ps1`
  - `scripts/check_debug_gap_and_collision.ps1`

## 2026-06-14 Hop blocked-backoff launch hotfix

- User compared two `bmb_debug_hop_log 1` traces:
  - Successful first jump: `ready=true reason=ready face≈29 minFace≈27.4`.
  - Failing cramped one-block jump: repeated `ready=false reason=face_close face≈20-22 minFace≈27.4`, while the intended backoff/steer point was hull-blocked.
- Diagnosis:
  - The two-stage manual hop still works when it launches.
  - The failure is launch admission: the bot wants to retreat to the ideal face-distance, but cramped geometry makes that backoff point invalid. It then refuses to hard jump, so `path_hop` / `debug_repath` loops.
- Fix:
  - Base hop launch now has guarded `blocked_close_lift`.
  - It only fires when the bot is laterally aligned, still within hop range, not extremely face-stuck (`face >= 0.52*BS`), and the ideal backoff point is blocked by hull/safety.
  - Ordinary `face_close` behavior is unchanged when backoff is available, preserving the Round 29 fix against random贴脸硬跳.
  - `hop setup` logs now include `closeMin`, `backoffBlocked`, `backoffHull`, `backoffSafe`, and `backoffReason`.
  - Drop vertical completion uses separate down/up tolerances so a grounded drop that settles slightly above the exact target foot z is not misread as unfinished.
- Checks:
  - glualint on `bmb_base_mob.lua`
  - `scripts/check_hop_debug_gap_regressions.ps1`
  - `scripts/check_block_size_parameterization.ps1`

## 2026-06-14 Hop launch ceiling-clearance hotfix

- User retested after blocked-close fix:
  - Ordinary one-block hop now works.
  - In a stricter multi-step/low-overhead setup, the bot succeeds for a few hops, then backs up for the next hop and clips into a block above/behind its head.
  - Log signature at the failing hop: it backs from `face≈16` to an ideal `face≈31`, starts the hop with normal `vz≈330`, but HUD/log only reaches low apex (`≈14`) before failing. The backoff point was `hull=true` and `backoffBlocked=false`, so the old check proved it could stand there, not that it could lift from there.
- Diagnosis:
  - Two-stage manual hop has a first vertical lift segment before horizontal travel.
  - A launch point needs overhead lift clearance, not just standable/hull clearance.
  - If ideal backoff has a low ceiling, the bot should launch from a nearer face-distance point that still has lift clearance, instead of backing under the ceiling.
- Fix:
  - Added `IsBMBHopLaunchCeilingClear`: Source `TraceHull` plus BMB hull samples over roughly `0.95*BS` vertical clearance.
  - `ready`, `close_lift`, and `blocked_close_lift` now require `currentLiftClear`.
  - The ideal backoff is considered blocked when `backoffLiftClear=false`; if a closer blocked-close launch point has lift clearance, setup steering uses that point instead of the full ideal backoff.
  - Hop setup logs now include `currentLift/currentLiftReason`, `backoffLift/backoffLiftReason`, and `closeLift/closeLiftReason`.
- Checks:
  - glualint on `bmb_base_mob.lua`
  - `scripts/check_hop_debug_gap_regressions.ps1`
  - `scripts/check_block_size_parameterization.ps1`

## 2026-06-14 Hop low-ceiling oscillation hotfix

- User retested with `log1fail` and `log2`:
  - `log1fail` uses the pre-`currentLift/backoffLift` log format, so treat it as an old/stale sample.
  - `log2` is current. It shows the bot eventually completes, but sometimes spins/repaths: low-ceiling setup has `backoffLift=false`; at `face≈18.x` the current launch point is clear, but the old `closeMin≈19.0` rejects launch; continuing movement pushes it to `face≈21.x`, where `currentLift=false`, so it bounces between `face_close` and `lift_blocked`.
  - The first hop in the log also landed grounded about one block above the requested hop node (`dz≈34.5`), which was treated as a failed hop and forced debug replan even though the bot had clearly made vertical progress.
- Fix:
  - Added `BlockHopCeilingBlockedCloseMinFaceDistanceScale=0.48`.
  - `GetBMBHopLaunchControl` now computes `effectiveBlockedCloseMinFaceDistance`: normal blocked close still uses `0.52*BS`, but when `backoffLift=false`, the effective low-ceiling launch threshold drops to `0.48*BS`.
  - Hop setup logs now include `effClose` so `face < closeMin` launches are explainable in low-ceiling cases.
  - Hop vertical completion now uses `BlockHopVerticalOvershootToleranceScale=1.25`: if the bot is grounded, horizontally at the node, and up to about one block above the target foot z, it counts as progress instead of triggering debug replan.
- Checks:
  - glualint on `bmb_base_mob.lua`
  - `scripts/check_hop_debug_gap_regressions.ps1`
  - `scripts/check_block_size_parameterization.ps1`

## 2026-06-14 Prop support stranded bypass

- User found a new movement-layer bug:
  - When a mob stands on a normal GMod prop, the current BMB grid cell is not standable because `HasSupport` intentionally ignores props.
  - `ShouldRunBMBStrandedRecovery` therefore enters `state=stranded`, but local bail-out cannot find an escape on the prop top and HUD can settle on `stranded_no_escape`.
- Diagnosis:
  - Prop support and glass-pane/invalid-grid support are different cases.
  - A* must still not treat props as terrain, because it cannot plan prop topology and should not choose prop tops as ordinary nodes.
  - If the entity is already physically standing on a prop, the current-step edge/wall decision should be Source safety (`IsMovementTargetSafe` / `path_cliff`), not BMB standable semantics.
- Fix:
  - Added `IsBMBPropSupportEntity` / `IsBMBOnPropSupport`.
  - `ShouldRunBMBStrandedRecovery` now bypasses recovery when current physical support is a GMod prop / `func_physbox` / VPhysics entity, while keeping world/brush support under normal standable rules and excluding players/NPCs/NextBots.
  - If `MoveToWorldPosition` cannot get a BMB A* path from a prop-supported start, it uses short `prop_direct` fallback with normal Source hull/ground safety; cliff/wall checks still stop unsafe edges.
  - Stranded bail-out also exits if it lands on prop support, avoiding stale stranded state after recovery movement.
- Checks:
  - `scripts/check_stranded_recovery.ps1` now guards the prop-support bypass and `prop_direct` mode.

## 2026-06-14 Zombie Phase 2 attack/audio

- User moved Zombie into Phase 2 tuning:
  - Melee should hit immediately when the player enters attack range.
  - Attack interval should be about 0.75s.
  - Each hit should knock the player back, lift them slightly, and play a player hurt sound.
  - Zombie should make ambient sounds in any state; if MC's exact interval is available, use it.
- MC source check:
  - `Zombie#getAmbientSound()` returns `SoundEvents.ZOMBIE_AMBIENT`.
  - `Mob#getAmbientSoundInterval()` returns `80`.
  - `Mob#baseTick()` plays ambient when `random.nextInt(1000) < ambientSoundTime++`, then resets `ambientSoundTime = -getAmbientSoundInterval()`.
  - So the interval is not a simple fixed 8-20s random range; it is 80 ticks minimum plus an increasing per-tick chance.
- Implemented:
  - Shared `MeleeAttack` now has `ResolveHit`, keeping damage, `DamageInfo`, knockback, and hit sound in one path.
  - `AttackHitDelay <= 0` resolves the hit immediately; non-zero delay still uses `timer.Simple` for future mobs with windup.
  - Knockback direction now falls back to the attacker's forward vector when the target is overlapping, so close melee does not lose pushback.
  - Zombie params changed to `AttackCooldown=0.75`, `AttackHitDelay=0`, `AttackKnockback=330`, `AttackVerticalKnockback=155`.
  - Zombie ambient sound now simulates the MC 20Hz tick/chance model, and BaseMob `Think` calls optional `MaybePlayIdleSound` so held/debug/stranded/chase/wander states do not suppress ambient sounds.
- User retested:
  - Attack interval, immediate attack, and sounds are OK.
  - Horizontal knockback works.
  - Vertical lift only appears if the player is already jumping; grounded player hits do not visibly lift.
- Follow-up fix:
  - Grounded player vertical knockback now detaches the player from Source ground movement with `SetGroundEntity(NULL)` before applying velocity.
  - Added `AttackGroundedVerticalKnockback=190` as a grounded-player minimum lift threshold while keeping airborne `AttackVerticalKnockback=155`.
  - A next-tick correction only tops up missing z velocity if Source ground movement still swallowed the first lift; it does not repeat horizontal knockback.
- Second user retest:
  - Vertical lift is now visible and old bugs did not return.
  - Horizontal knockback is too strong at 330.
  - In Source cliff / narrow bridge situations, Zombie can bypass normal path cliff safety and walk off the edge while directly chasing/pressing the player.
- Second follow-up fix:
  - Reduced Zombie horizontal `AttackKnockback` from 330 to 240 while keeping grounded vertical lift.
  - Added shared `Chase.ApplySafePressure` / `IsSteerTargetSafe`.
  - `chase_direct`, `attack_ready`, and Zombie `chase_repath` now re-check `IsMovementTargetSafe` against the actual steering target before applying direct pressure.
  - Unsafe direct pressure publishes `*_cliff`, faces the player, and damps horizontal velocity so previous momentum does not carry the Zombie off the edge.
- Checks:
  - Added `scripts/check_zombie_phase2_attack_audio.ps1`.

## 2026-06-14 Zombie Phase 2 knockback/grid-cliff hotfix

- User retest:
  - Zombie melee knockback is now visible, but feels inconsistent at point blank.
  - Screenshot HUD often showed `dist:0.0`, meaning player and Zombie horizontal positions overlap during hit resolution.
  - Source map cliff and prop cliff safety now work (`chase_repath_cliff`), but MCSWEP block edges can still bypass the direct-pressure safety.
- Root causes:
  - `MeleeAttack.ApplyTargetKnockback` recomputed direction from `target:GetPos() - mob:GetPos()` at hit time. In overlap, that vector can be near zero and fallback to a possibly stale mob forward direction.
  - Direct chase safety was trace-first. It catches Source world/prop ground, but direct pressure can still bypass BMB's MC block standable semantics.
- Fix:
  - `MeleeAttack` now caches the last valid horizontal target direction during chase/attack (`BMBLastMeleeDirection`) and reuses it in `ResolveHit` and `ApplyTargetKnockback`.
  - Player knockback still applies one full horizontal + vertical impulse immediately; the next tick only tops up missing horizontal/vertical components if Source ground movement or overlap swallowed them.
  - Added `HasBMBGridBlockSupportAt` / `IsBMBGridMovementTargetSafe` in BaseMob.
  - `IsMovementTargetSafe` still runs Source wall/ground trace first; if current/forward samples are on or near MC block support, it then samples along the direct movement line using BMB standable semantics.
  - Prop support explicitly bypasses the MC grid layer so the previous prop-stranded fix does not regress.
- Checks:
  - glualint on `sv_behaviors.lua`.
  - glualint on `bmb_base_mob.lua`.
  - `scripts/check_zombie_phase2_attack_audio.ps1`.

## 2026-06-14 Zombie Phase 2 melee feel hotfix

- User retest:
  - MCSWEP block cliff issue is solved.
  - Zombie melee knockback is still intermittent: when it fails, horizontal knockback and vertical lift both disappear.
  - User asked to change attack interval to 1s and add a very light screen shake on player hit, much weaker than HL2 Zombie.
- Diagnosis:
  - Direction caching fixed the zero-vector case, but the all-or-nothing failure means Source player ground/overlap movement can still swallow both the immediate impulse and the single next-tick correction.
- Fix:
  - `MeleeAttack.ApplyTargetKnockback` now runs a tiny correction window for player hits: default 3 ticks, 0.03s apart.
  - Each correction only tops up missing horizontal projection and missing z velocity; it does not reapply the whole 240u horizontal knockback if the first impulse already worked.
  - Zombie `AttackCooldown` changed from 0.75 to 1.0.
  - Zombie actual hit feedback now adds mild `ViewPunch` and small `util.ScreenShake` after the hit sound.
- Checks:
  - Updated `scripts/check_zombie_phase1.ps1`.
  - Updated `scripts/check_zombie_phase2_attack_audio.ps1`.

## 2026-06-14 Zombie Phase 2 point-blank knockback nudge/log hotfix

- User retest:
  - 1s attack interval is OK.
  - Screen shake should be slightly stronger.
  - Knockback/lift still sometimes fail completely.
- Diagnosis:
  - Because horizontal and vertical both disappear together, this is no longer likely to be a stale direction problem.
  - The remaining signature points at the player being too deeply overlapped with the Zombie hull / Source ground solver, so player movement swallows the impulse path itself.
- Fix:
  - Added `bmb_debug_melee_knockback` server convar. When enabled, it logs direction, horizontal/vertical target, player velocity before/after correction, missing horizontal/z, nudge result, and on-ground state.
  - Added `MeleeAttack.NudgeTargetForKnockback`: before applying player knockback, do a small trace-protected separation nudge along the stable knockback direction.
  - Zombie nudge params are 6u horizontal and 2u up; if the trace is blocked or starts solid, no teleport is performed.
  - If the initial nudge did not happen and correction ticks still see a missing impulse, correction tries one more safe nudge.
  - Increased Zombie hit feedback slightly: stronger but still mild `ViewPunch` and `ScreenShake`.
- Checks:
  - Updated `scripts/check_zombie_phase2_attack_audio.ps1` to guard the nudge and log cvar.

## 2026-06-14 Zombie Phase 2 deterministic player launch hotfix

- User report:
  - The previous melee knockback log was hard to enable/find.
  - Zombie horizontal knockback mostly exists, but vertical lift/launch remains intermittent.
  - 4.8 pointed out the key Source behavior: `Player:SetVelocity` adds to current velocity; it does not set absolute velocity.
- Diagnosis:
  - If the player is squeezed against a hull / being categorized on ground during the hit tick, they can carry downward residual z velocity.
  - Adding `Vector(0,0,190)` to a residual `-100z` leaves only about `90z`, below Source's grounded-player non-jump threshold, so the next tick snaps the player back to ground.
  - The old 3-tick correction and trace-protected nudge were trying to fight that timing problem after the fact.
- Fix:
  - Player melee knockback now detaches ground, captures `velocityBefore`, calls `SetVelocity(-velocityBefore)` to cancel residual velocity, then calls `SetVelocity(desiredVelocity)` once.
  - Removed `NudgeTargetForKnockback`, multi-tick correction loops, and Zombie correction/nudge params.
  - Kept stable knockback direction caching and the 240 horizontal / 190 grounded vertical tuning.
  - Added `bmb_melee_knockback_debug 1/0` as a user-friendly server command that toggles `bmb_debug_melee_knockback`.
- Checks:
  - Updated `scripts/check_zombie_phase2_attack_audio.ps1` to require deterministic player velocity writes and forbid stale nudge/correction code.

## 2026-06-14 Zombie Phase 2 knockback direction epsilon hotfix

- User retest:
  - Five attacks all produced `try=ok` and `resolve=hit`, but none produced `knockback apply`.
  - Therefore attack/cooldown/range were not the blocker; `ApplyTargetKnockback` was returning before logging.
- Diagnosis:
  - `ApplyTargetKnockback` normalized the direction, then checked `direction:LengthSqr() <= 1`.
  - A normalized direction has length squared 1, so it was rejected as invalid every time.
  - Cached direction and `mob:GetForward()` fallback also used `> 1`, rejecting normalized vectors.
- Fix:
  - Added `MIN_VALID_DIRECTION_SQR = 0.0001`.
  - Cached/fallback directions now accept vectors above epsilon.
  - `ApplyTargetKnockback` now rejects only near-zero directions and logs `direction_nil` / `direction_invalid` if that ever happens again.
- Checks:
  - Extended `scripts/check_zombie_phase2_attack_audio.ps1` to prevent unit-vector threshold regressions.

## 2026-06-14 Zombie Phase 2 MC flat-ground cliff false positive

- User retest:
  - On a flat MCSWEP block plane, Zombie HUD can show `state=chase mode=chase_repath_cliff vel=0/115` and refuse to move.
  - This is not a real cliff; it happens on full MC grass/oak block ground.
- Diagnosis:
  - The MC-grid direct safety added for block cliffs sampled the exact foot/ground position.
  - At full-block top faces or boundaries, `MC.WorldToCell` / `WorldToBlock` can resolve that exact point into the solid block under the mob instead of the air foot cell above it.
  - `IsBMBHullClearAtPosition` / `Pathfinder.IsStandablePosition` then see solid/not-standable and report `cliff` even on flat ground.
- Fix:
  - Added `GetBMBGridFootSample`, `IsBMBGridFootHullClear`, and `IsBMBGridFootStandable` in BaseMob.
  - Runtime grid safety and carrot grid visibility now check a lifted foot sample (`max(4u, 0.12*BS)`) for hull/standable queries.
  - `IsBMBCurrentPositionStandable` also uses the lifted foot sample so StrandedRecovery does not misclassify full-block top faces.
  - Actual MC block edges still fail standable because the lifted sample maps to an air cell with no support.
- Checks:
  - Extended `scripts/check_zombie_phase2_attack_audio.ps1` to guard lifted-foot grid safety sampling.

## 2026-06-14 Revert low-ceiling hop edge pruning attempt

- User retest:
  - The A* hop-edge clearance attempt caused a broad hop regression: ordinary hop no longer triggered.
- Action:
  - Reverted the new `isHopEdgeClear` pathfinder gate and BaseMob `IsBMBPathHopEdgeClear` helpers.
  - Removed the regression-script assertions and docs that claimed low-ceiling hop should be pruned in A*.
  - Kept the previous lifted-foot MC flat-ground cliff fix, because user confirmed cliff behavior is OK.
- Follow-up:
  - Low-ceiling/head-blocked hop still needs a different design. Do not reintroduce broad A* hop-edge pruning without a much more precise proof/test.

## 2026-06-13 Zombie phase 1 direct chase / high-target stalk

- User retest found:
  - Far chase still visibly walks and pauses.
  - On open ground the Zombie does not feel like MC, which stares at the player and presses directly when it has line of sight.
  - The old `mcgm_zombie` direct pursuit felt more target-focused, but its navmesh/old obstacle avoidance is not suitable for BMB.
  - When the player stands high and no route is available, MC-like behavior is to stay below/near the block and wait or pace locally, not clear the target.
- Implemented:
  - Shared `Chase` now has `CanDirect` / `RunDirect` / `StalkHighTarget`.
  - Direct chase requires line of sight by default and still checks `IsMovementTargetSafe` with a short forward probe before bypassing A*.
  - Open visible pursuit publishes `mode=chase_direct` and runs `FaceTarget + SteerTowards(player)` every tick for short refreshed segments.
  - If direct pursuit is blocked or visibility is lost, chase falls back to the existing BMB block A* pathing, preserving maze/hop/drop behavior.
  - If A* fails and the target is near but vertically above attack range, chase publishes `mode=chase_stalk`, keeps the target, faces the player, and repolls shortly instead of steering into a zero horizontal vector.
  - Zombie enables `ChasePreferDirect`, sets a 0.28s direct segment, a 4-cell safety probe, and high-target stalk timing/hold cells.
- Checks updated:
  - `scripts/check_zombie_phase1.ps1` now requires `chase_direct`, `chase_stalk`, line-of-sight gating, and direct safety probing.
- Next game retest:
  1. Open-ground visible player: HUD should show `chase_direct` often and movement should be continuous/direct.
  2. Maze/wall/corner: should fall back to BMB A* and still route around obstacles.
  3. High unreachable close player: should show `chase_stalk`, keep the target, and wait below instead of idle/wander.

## 2026-06-13 Zombie phase 1 third retest fixes

- User retest found:
  - Attack speed and non-zero attack target speed are now OK.
  - Far chase still visibly pauses after walking for a bit.
  - At close ledges/stairs, Zombie alternates between `path_hop` and `chase_repath` instead of jumping.
  - Two-block high target in face still does not move meaningfully.
- Fix:
  - Zombie chase segment timeout increased to 2.0s.
  - Zombie chase failure replan delay reduced to 0.05s.
  - Zombie `TurnInPlaceAngle` widened to 170 to avoid ordinary chase heading changes becoming full stop-and-turn.
  - `chase_repath` now continues `SteerTowards(target)` + `BodyMoveXY` during the short replan wait.
  - Base hop launch supports optional `BlockHopAllowCloseLaunch`; Zombie enables it for cramped close ledges.
  - Close launches are labeled `close_lift` and still use the existing two-stage manual hop.
- Tests:
  - Extended `scripts/check_zombie_phase1.ps1`.
  - Extended `scripts/check_hop_debug_gap_regressions.ps1`.
  - glualint on changed Lua files.

## 2026-06-15 Procedural limb swing → continuous (Base) + sheep eat-grass head pitch

- User requirement (first model hooked up: `sheep.mdl` + walk anim):
  - Differentiate walk vs run leg animation; drop the binary two-value swing and make amplitude scale continuously with speed.
  - The continuous swing math is generic, so promote it to Base for future cow/pig.
  - Sheep eats grass with its head up instead of bending down; add a head pitch (nod) that lowers to the ground during the eat duration and returns.
- Implemented:
  - BaseMob `UpdateBMBLimbSwing(speed2D)`: maps horizontal speed to a continuous phase (frequency proportional to speed) and a continuous amplitude `[0,1]` (replaces `speed > 8 and 1 or 0`); persists `BMBLimbSwingPhase/Amount`.
  - Params `LimbSwingMinSpeed/FullSpeed/MinAmount/PhaseScale/BlendSpeed`, per-mob overridable; `FullSpeed` defaults to `RunSpeed`, `MinAmount` defaults to 0 (pure ratio).
  - `bmb_sheep` consumes the helper for head/leg overlay and drops its own `BMBSheepLimbSwing*`; keeps `legSwingMax=7` / `headWalkSwingMax=2` and the roll swing axis.
  - `bmb_sheep` `eat_grass` keyframes moved from roll (`Angle(0,0,X)`, actually a head tilt/up) to pitch (`Angle(X,0,0)`) bending down, lowest at 0.42s (bite), returning by 1.05s; head pos sink kept.
  - `scripts/check_sequence_animation_adapter.ps1`: limb-swing guard migrated to Base and hardened with a no-binary `and 1 or 0` assertion; sheep guard now requires consuming the Base helper.
- Verified: glualint (repo + live addon), all 11 `scripts/check_*.ps1` pass, synced to live addon.
- Next game retest:
  1. Leg/head swing amplitude should scale continuously with speed (small slow walk -> near-full run), with walk/run frequency differing; no binary snap at a speed threshold.
  2. Sheep should bend its head down to reach the grass (lowest ~0.42s, return ~1.05s), not tilt/raise.
  3. Confirm/adjust the eat-grass head pitch sign+degrees with `bmb_sheep_pose_preview` + `bmb_sheep_pose_head_rot_x` (flip pitch sign if it raises the head).

## 2026-06-15 Limb swing +2 retune + eat-grass roll-axis three-stage animation (game-tested)

- User game-test feedback:
  - Walk and run leg swing both look too small now; add ~2 degrees to both.
  - Eat-grass does bend down but not far enough, and the head turns to the player's right -- wrong axis/sign.
  - From the in-game preview the correct reaching pose is `Head rot Z = -55` (roll axis, negative) + `Head pos Y = -12`.
  - Eat-grass should be an ordered sequence: pos Y down to -12 first, then a rot animation looping -55 <-> -40 twice, then rot and pos return to 0 together.
- Implemented:
  - Correction: the head bone's nod/pitch is actually the roll axis negative (last round's pitch change is reverted). Reaching pose = `roll -55` + `posY -12`.
  - `bmb_sheep` `legSwingMax` 7 -> 9 and `LimbSwingMinAmount = 0.25`, so walk amount ~0.76 (~6.8 deg) and run 9 deg (both about +2).
  - `eat_grass` rebuilt as a 1.8s three-stage clip: pos Y 0->-12 (0-0.25s, rot still), roll 0->-55 reaching ground (0.25-0.45s), roll chew loop -55<->-40 twice (0.45-1.45s), roll+pos ease back to 0 together (1.45-1.8s).
  - `EatGrassAnimationDuration` 1.05 -> 1.8, `EatGrassBiteDelay` 0.42 -> 0.45 (aligned with reaching the lowest point / biting).
  - `scripts/check_sequence_animation_adapter.ps1` `legSwingMax` locked value 7 -> 9.
- Verified: glualint (repo + live addon), all 11 `scripts/check_*.ps1` pass, synced to live addon.
- Next game retest:
  1. Walk/run leg swing both ~2 deg larger, still continuous with speed.
  2. Eat-grass: head pushes forward/down (posY -12), then bends to roll -55 reaching the grass, chews -55<->-40 twice, then eases back; no tilt/right-turn.
  3. Tune chew speed/depth via `sheepAnimations.eat_grass.frames` if needed.

## 2026-06-15 Sheep leg amplitude/frequency retune + locomotion head swing off

- User feedback:
  - Set `legSwingMax` to 25.0.
  - Lower leg frequency for both walking and running.
  - Disable locomotion-driven head swing because vanilla sheep head does not bob with the body, but do not lock the head bone; a later feature will own it.
- Implemented:
  - `bmb_sheep` `legSwingMax` 9 -> 25.0.
  - Added sheep override `LimbSwingPhaseScale = 0.13` (Base default is 0.18), so both walk and run phase advance more slowly while remaining speed-proportional.
  - Removed `walkHead` / `idleHead` locomotion bob from normal `UpdateBMBVisualBones`.
  - Added one-shot head pose clearing after preview/eat-grass so stale pose is reset without writing head angle every frame.
  - Updated `scripts/check_sequence_animation_adapter.ps1` to guard 25.0 / 0.13 and forbid locomotion head swing helpers.
- Next game retest:
  1. Walk/run legs should swing wider but with a slower cadence than the previous 9-degree version.
  2. Normal movement should not bob the head.
  3. Eat-grass and preview should still move the head, and future look/head control should not be blocked by locomotion.

## 2026-06-15 Sheep leg frequency lower again + fix unsynced head swing

- User feedback (after the previous round):
  - Lower leg frequency a bit more (both walk and run still felt fast).
  - Head swing is still happening in game even though it was supposedly turned off -- "don't know why".
- Root cause of the still-swinging head: the live addon (D drive) was not fully synced. The C-drive sheep and the check script already had the head swing removed (`clearSheepHeadPoseOnce`, no `walkHead/idleHead`), but D-drive `bmb_sheep.lua` still had the old `walkHead`/`idleHead` head bob, so the running game read stale code.
- Implemented:
  - `bmb_sheep` `LimbSwingPhaseScale` 0.13 -> 0.09 (Base default 0.18); ~45% slower cadence for both walk and run, still speed-proportional.
  - `scripts/check_sequence_animation_adapter.ps1` phase-scale guard 0.13 -> 0.09.
  - robocopy full sync of `gmod_addon` to the live addon; verified D-drive `bmb_sheep.lua` now has `clearSheepHeadPoseOnce`, `LimbSwingPhaseScale=0.09`, and no `walkHead/idleHead`.
- Lesson: every code change must sync the whole `gmod_addon` to D drive, or the in-game test runs stale code (this is what made the head "swing despite being turned off").
- Verified: glualint (repo + live addon), all 11 `scripts/check_*.ps1` pass.
- Next game retest:
  1. Leg cadence clearly slower than the 0.13 version.
  2. Head no longer bobs during normal movement (now that D drive is synced); eat-grass/preview head still works.

## 2026-06-16 Death sequence redo: scripted bone tip-over + 1.9s linger + Java poof particles

- User request, three parts together:
  - Tip-over: stop using physics-corpse forces (unstable, random direction). Script the lean in the client `UpdateBMBVisualBones` death branch: lerp the root bone 0->90 about a side-fall axis over ~0.8s, then hold; fixed direction; freeze head/legs.
  - Linger: ~1s on the side after falling, server remove delay ~1.8-2s.
  - Particles: replace the Bedrock smoke with a Java poof -- ~20 white puffs at WorldSpaceCenter at the moment of removal, slight up + outward, ~0.6s fade, using the jar's generic_0..7 (8 frames) as an animated material.
- Implemented:
  - SMD hierarchy confirmed: root -> body -> leg0..3, head -> root. Rotating root carries the whole sheep; rotating body would leave the head behind. `CacheBMBSheepBones` now caches root/body too.
  - `bmb_sheep` `UsePhysicsCorpseOnDeath=false`; death branch lerps root 0->90 over `DeathTipDuration=0.8` using `CurTime()-BMBStateStartedAt`, head/legs zeroed to ride along. Side-fall axis is roll for now (Angle(0,0,tip)); flip to pitch/yaw or negate if it nose-dives/spins.
  - `DeathRemoveDelay=1.9`; no physics corpse so the NextBot stays drawn and the client renders the tip-over, then Remove at 1.9s.
  - `mc2source/vtf.py` gained `write_animated_bgra8888_vtf` (single mip, numFrames=N, NOMIP/NOLOD). `qs/make_poof_vtf.py` turns generic_0..7 (8x8, LA) into `materials/bmb/particles/mc_poof.vtf` (2160 bytes) + `mc_poof.vmt` (UnlitGeneric multi-frame).
  - `bmb_death_poof` effect rewritten: count from magnitude (sheep 18-22 ~ MC 20), scatter in bbox, outward+up drift, per-particle `SetInt("$frame", floor(t*8))` over 8 frames, ~0.6s tail fade.
- Verified: glualint (repo + live), all 11 BMB checks pass, qs `Ran 61 tests OK`, synced to live addon (mc_poof.vtf/vmt present).
- Next game retest:
  1. Whole sheep tips to its side (not nose-dive/spin/headless), holds ~1.1s, then vanishes ~1.9s with a ~20-puff white poof.
  2. Confirm the poof animates through 8 frames (per-particle $frame), not a frozen single frame.
  3. Confirm the side-fall axis; flip if wrong.

## 2026-06-16 Death retest fixes: side-fall axis, faster lean, MC-matched poof

- User retest:
  - Tip-over was a BACKWARD lean -- wrong; should lie on its SIDE, randomly left or right. Lean a bit faster.
  - Linger: fine.
  - Poof not great vs MC; user exported per-frame PNGs (ours + MC) to `H:\工作视频\20251115毕业\project\PNG导出` for comparison.
- Frame comparison (MC vs ours):
  - MC poof = dense soft cloud of overlapping puffs clustered at the body, nearly stationary, puffs at different frames -> fluffy cloud.
  - Ours = sparse isolated crisp crosses spread too wide (velocity too high), too few overlapping, lifetimes too uniform (same frame -> identical crosses).
- Implemented:
  - Side-fall axis: roll (3rd) is the backward lean; lying on side is YAW (2nd). `Angle(0, ±tip, 0)`, left/right fixed per entity via `EntIndex`.
  - `DeathTipDuration` 0.8 -> 0.55 (faster lean).
  - Poof toward MC: scatter radius ~width/2 (`DeathPoofRadiusScale` 22 -> 15, effect floor BS*0.5 -> 0.4), nearly stationary velocity (0.45 BS -> 0.12, up 0.6 -> 0.14), bigger overlapping puffs (baseSize 0.22-0.4 -> 0.3-0.52 BS), lifetimes 0.5-0.7 -> 0.4-0.8 so per-particle frames desync into a soft cloud; growth 1+t*0.25 -> 1+t*0.1.
- Verified: glualint (repo + live), all 11 BMB checks pass; synced to live addon.
- Next game retest:
  1. Sheep lies on its side (left/right random), not backward/spin; if it spins, swap yaw->pitch.
  2. Poof reads as a clustered soft cloud like MC, not sparse crosses; confirm 8-frame playback.

## 2026-06-16 Death poof rewritten to MC ExplodeParticle behavior + linger 1.7s

- User: linger -0.2s; poof still off -- wrote MC behavior doc `D:\BMBTools\mc26_1_poof_particle_behavior.md`, match it.
- Corrections vs my earlier poof (per the doc):
  - Size: `0.1*(rand*rand*6+1)` block (mostly tiny smoke dots, few big puffs) -- I had uniform large.
  - Lifetime: `16/(rand*0.8+0.2)+2` tick = 0.9-4.1s, very uneven (frames desync naturally) -- I had 0.4-0.8s uniform.
  - Color: grey-white 0.7-1.0, not pure white.
  - No alpha fade (OPAQUE); dissipation = frame change + removal at lifetime.
  - Frames play generic_7 -> generic_0 (poof.json order), not 0->7.
  - Per-tick physics: friction 0.9, gravity -0.1 (slight upward), spawn = bbox-random - vel*10.
- Implemented:
  - `DeathRemoveDelay` 1.9 -> 1.7 (lean 0.55 + ~1.15 on side).
  - Rewrote `bmb_death_poof` to simulate MC ExplodeParticle per-tick (20Hz, 0.05s accumulator in Think): velocity gaussian*0.02 + +-0.05 jitter, spawn bbox-random - vel*10, size 0.1*(rand*rand*6+1), lifetime 18-82 tick, grey-white 0.7-1.0, friction 0.9 + up-drift 0.004/tick, frame = (7 - age*7/lifetime) so generic_7->0 on our generic_0..7 VTF, opaque (no alpha fade).
- Verified: glualint (repo + live), all 11 BMB checks pass; synced to live addon.
- Next game retest:
  1. Poof like MC: mostly-small grey-white smoke dots + a few bigger, slight up-drift, thinning via frames; some particles linger longer.
  2. Confirm 8-frame playback (generic_7->0); if frozen single frame, switch to sprite-sheet UV.
  3. Linger ~1.7s.

## 2026-06-16 Poof frame interpolation (de-stutter) + linger 1.5s

- User: poof looks good but a bit choppy -- is the Hz too low, can it be raised? And trim linger another 0.2s.
- Diagnosis: particle physics is 20Hz (MC tick) and Render used discrete tick positions with no interpolation, so at 60fps particles jump every 3rd frame. MC itself runs 20Hz ticks but interpolates on render (partialTick).
- Implemented:
  - Render extrapolates each particle by `pos + vel * (Accumulator / PARTICLE_TICK)`, smoothing motion between ticks without changing the 20Hz physics (friction/gravity per-tick values stay MC-accurate).
  - `DeathRemoveDelay` 1.7 -> 1.5.
- Verified: glualint (repo + live), all 11 BMB checks pass; synced to live addon.
- Next retest: poof motion smooth (no per-tick jumping); linger ~1.5s.

## 2026-06-16 Death corpse stops moving (no follow-run/jump) + poof defaults lifted to Base

- User: corpse follows the flee run on death; dying mid-jump makes the corpse follow the jump arc. Also "the poof is used by basically every mob -- should it go in Base?"
- Root cause (follow run/jump): `StopBMBMovementOnDeath` zeros loco velocity once, but after death the server Think returns early and never re-clamps, so loco keeps integrating its leftover horizontal (flee) / ballistic (BlockHop) velocity -- same class as the physgun-held jitter that needed per-tick disarm.
- Implemented:
  - base Think BMBDead branch disarms loco every tick: `SetGravity(0)` + `SetVelocity(vector_origin)` + `SetDesiredSpeed(0)`. Corpse stops dead at the death position. (Mid-air/mid-jump deaths hover, since SOLID_NONE makes gravity-landing clip through the floor -- accepted minor limitation.)
  - Poof was already a Base capability (`DeathPoofEffect` + `EmitBMBDeathPoofAt` in Base, effect is global). Lifted Base defaults to Java poof values: `DeathPoofParticleCountMin/Max` 5/8 -> 18/22, `DeathPoofRadiusScale` 44 -> 15. Sheep dropped its duplicate overrides (and the redundant `UsePhysicsCorpseOnDeath=false`, already Base default). Cow/pig/etc. now get MC poof out of the box.
- Verified: glualint (repo + live), all 11 BMB checks pass; synced to live addon.
- Next retest: corpse no longer follows flee run or jump arc; new mobs inherit the poof.

## 2026-06-17 Zombie model + procedural biped animation

- User: open the zombie (model + animation). Zombie animation stays procedural like the sheep -- converter outputs model only, no baked sequences. Confirm zombie is biped (body not rotated, not treated as quadruped). Arms hang in the model; forward-hold pose added procedurally, not baked. Reuse base for death tip + poof, lookat, look-around, step. Attack uses the sheep eat-grass keyframe sampler (generalized into base), defined as a forward arm-swing.
- Converter (arms down):
  - Confirmed biped: `body` bind rotation 0 (not the quadruped `body -90° stand`); `root` 90°X is the universal Y-up->Z-up (sheep has it too). The only non-zero bind was the arms, baked from `animation.zombie.attack_bare_hand` as a forward "raised-arm" rest pose.
  - `geo.py` `REST_POSE_ANIMATION_*` dropped the zombie attack entries, so zombie family (zombie/husk/drowned/zombie_pigman/baby_zombie) arms hang neutral (`bind_pose_rotation=0`); skeleton/wither keep their raised arms.
  - Golden updated (`test_*raised_arm` split into skeleton + zombie-family-neutral); 62 tests OK. Restaged + full-compiled zombie to the addon (arms down).
- Base generalization (client block): `BMB.SampleKeyframeAnimation` + `BMB.LerpKeyframeAngle/Vector` + `ENT:SetBMBVisualBoneAngle/Position` + `ENT:ApplyBMBKeyframePose` (extracted from sheep eat-grass, shared), plus `ENT:ApplyBMBBipedLocomotion` (legs counter-swing + arm forward-hold + counter-swing; params `BipedLegSwingMax/ArmSwingMax/ArmForwardAngle`). Death tip / lookat / look-around / step / poof / death disarm all reused from base.
- Zombie rewrite: `Model` -> `models/mcgm/zombie/zombie.mdl`, dropped `RunActivity=ACT_WALK`, `PlayBMBMeleeGesture` -> `SetNWFloat("BMBAttackStartedAt")`, new client `UpdateBMBVisualBones`: dead tips root over (yaw, reused from sheep), normal does lookat + limb swing + biped locomotion, attack window swaps arms to a forward-swing keyframe (over the forward baseline, legs keep walking). `check_zombie_phase1.ps1` guard moved from ACT_WALK to procedural biped + converted model + attack keyframe (forbids Classic.mdl/ACT_WALK/RestartGesture regress). Behavior (SeekTarget/Chase/MeleeAttack/sounds/hurt) untouched.
- Verified: glualint (repo + live), all 11 BMB checks pass, qs 62 tests pass; lua synced to live addon, model packaged by converter.
- Next game retest: legs counter-swing + arms forward-hold/swing (tune `ApplyBMBBipedLocomotion` axis / `BipedArmForwardAngle` if wrong); attack arm-swing; death side-fall (yaw, swap to pitch if it spins); lookat head-only; chase/attack behavior unchanged.

## 2026-06-17 Zombie facing fix: biped QC rotate 180 -> 0

- User: the biped zombie is flipped 180° around the vertical axis -- in game it only shows its back while chasing. Sheep (quadruped) QC uses `$sequence ... rotate 180` to compensate the body 90° stand; biped has no body stand and shouldn't inherit the 180. Fix the biped branch only; leave quadruped 180.
- Root cause: `source.py make_qc_text` hardcoded `rotate 180` for every entity. Quadruped (sheep, body bind 90°) needs +180 yaw; biped (zombie, body bind 0) faces backward with it.
- Fix: `make_qc_text` takes a `rotate` param (default 180). `converter.py` computes it from the body bone `bind_pose_rotation` X: `>45°` (quadruped stand) -> 180, else 0. Sheep 90 -> 180 (unchanged), zombie 0 -> 0.
- Recompiled zombie: `zombie.qc` now `rotate 0`, new `.mdl` packaged to addon. Added a `test_cli` golden asserting zombie QC `rotate 0` / no `rotate 180`. 62 tests OK.
- Next: confirm zombie faces the player in game.

## 2026-06-17 Zombie Minecraft sound pass

- User request:
  - Another agent updated files; read latest logs first, then add Zombie sounds like sheep.
  - Use `D:\BMBTools\解包音频\minecraft\sounds\mob\zombie` for `death`, `hurt`, `say`, and `step`.
  - Use `D:\BMBTools\解包音频\minecraft\sounds\damage\hit1-3.ogg` for player hurt sounds when Zombie hits a player.
- Assets copied and normalized:
  - `gmod_addon/sound/bmb/mob/zombie/death.ogg`
  - `gmod_addon/sound/bmb/mob/zombie/hurt1-2.ogg`
  - `gmod_addon/sound/bmb/mob/zombie/say1-3.ogg`
  - `gmod_addon/sound/bmb/mob/zombie/step1-5.ogg`
  - `gmod_addon/sound/bmb/damage/hit1-3.ogg`
  - All 14 new OGGs were re-encoded to `44100 Hz mono` with `D:\oopz\ffmpeg.exe`, matching Source's normal sound sample-rate constraints.
- Implemented:
  - `bmb_autorun.lua` registers all new Zombie/damage sound resources with `resource.AddFile`.
  - `bmb_zombie` `Sounds` now points only at mod-local MC assets: `Say`, `Hurt`, `Death`, `Step`, `Hit`.
  - Ambient uses `PlayBMBZombieSay()` from the existing MC 80 tick / random.nextInt(1000) probability model.
  - Accepted damage uses `OnBMBHurtSound()` for non-lethal Zombie hurt only; Zombie checks current health vs incoming damage and skips hurt on lethal hits so death does not stack with hurt. `OnBMBInjured` now only handles retaliation target state and avoids double-playing hurt on non-lethal hits.
  - Player hit feedback still plays only after a real melee hit, now using `bmb/damage/hit1-3.ogg`.
  - Zombie footsteps are client-side and distance-driven like sheep: `UpdateBMBZombieStepSound(speed)` accumulates `speed * FrameTime()` in `UpdateBMBVisualBones`; `StepSoundDistance=26` matches the current biped limb half-wave (`pi / LimbSwingPhaseScale`). Zombie overrides `MaybePlayStep()` so Base's fixed 0.5s Source zombie footstep placeholder is silent.
  - `scripts/check_zombie_phase2_attack_audio.ps1` guards MC sound paths, resource registration, distance-driven footsteps, `OnBMBHurtSound`, and forbids `npc/zombie/` / `player/pl_pain` regressions.
- Next game retest:
  1. Ambient Zombie say uses MC `say1-3` in any state.
  2. Non-lethal accepted hits play MC `hurt1-2`; lethal accepted hits play `death.ogg` without also stacking hurt.
  3. Actual player melee hits play MC `damage/hit1-3`.
  4. Footsteps line up with procedural biped foot plants; tune `StepSoundDistance` if the contact point feels early/late.

## 2026-06-16 Base LookAtPlayerGoal + Sheep head hookup

- User request:
  - Put LookAt into `bmb_base_mob` as a shared feature.
  - Server decision layer: every ~0.5s, if a player is in range and the mob is not already looking, ~15% chance to start looking for 2-4s. Sync target EntIndex and timeout through NW vars. Do not make nearby players force constant staring.
  - Client render layer: `UpdateBMBVisualBones` head branch reads the NW target, computes relative body yaw/pitch, clamps and smooths with Lerp, and applies the head bone. Eat grass/death must suppress LookAt. Movement must keep running in parallel.
  - Sheep-tested axis mapping: head rot X positive = left, negative = right; head rot Z positive = up, negative = down.
- Implemented:
  - Initial base defaults: `LookAtEnabled`, `LookAtHeadBoneName`, `LookAtRangeCells`, `LookAtPollInterval=0.5`, `LookAtStartChance=0.15`, `LookAtDurationMin/Max=2/4`, `LookAtYawLimit=70`, `LookAtPitchLimit=35`, `LookAtLerpSpeed=8`; later retuned below to 0.06 chance and 24 pitch limit after first game test.
  - Base NW state: `BMBLookAtTarget` and `BMBLookAtUntil`.
  - Server helper `UpdateBMBLookAtController()` runs from base `Think` independently of behavior movement, clears targets when suppressed, expired, invalid, out of range, or dead.
  - Client helper `UpdateBMBLookAtHeadPose(headBone)` computes `Angle(yaw, 0, pitch)` using the sheep axis mapping, clamps/smooths it, applies `ManipulateBoneAngles`, and eases back to zero after target loss.
  - Sheep normal visual branch now calls `self:UpdateBMBLookAtHeadPose(bones.head)`; death and eat-grass branches still return before normal head control.
  - Static check coverage added to `scripts/check_sequence_animation_adapter.ps1`.
- Verified:
  - `glualint` passes for `bmb_base_mob.lua` and `bmb_sheep.lua`.
  - Full `scripts/check_*.ps1` suite passes.
  - Synced full `gmod_addon` to the live D-drive addon and confirmed LookAt strings exist in live files.
- Next game retest:
  1. Stand near a sheep: it should occasionally glance for 2-4s, not stare constantly.
  2. Confirm left/right/up/down axes match the sheep preview mapping.
  3. Confirm Wander/Flee/normal walking continue while the head looks.
  4. Confirm eating grass and death suppress LookAt and the head eases back when no target is active.

## 2026-06-16 LookAt retune after first game test

- User retest: LookAt exists, but the sheep looks too often; head rot Z is too high.
- Changed:
  - Base `LookAtStartChance` 0.15 -> 0.06. Poll interval stays 0.5s; duration stays 2-4s.
  - Base `LookAtPitchLimit` 35 -> 24, reducing vertical head rot Z amplitude while keeping yaw at ±70.
  - Updated static guards and docs to match the new defaults.
- Next game retest:
  1. Near-player LookAt should feel noticeably rarer than the first 15% version.
  2. Vertical head movement should no longer over-raise; left/right range remains unchanged.

## 2026-06-16 Random look-around + keep player LookAt network-cheap

- User request:
  - Confirm whether player LookAt already syncs only target EntIndex. If yes, only add random look-around.
  - When not looking at a player, server should every random 1-3s choose yaw ±60 and small pitch ±15, sometimes straight ahead, and low-frequency NW sync those angles.
  - Random look-around should be active when idle/slow walking; fast running should look straight ahead.
  - Client mode: valid target entity -> look at player; else valid look-around angle -> look around; else straight ahead. Reuse the same Lerp path.
- Confirmed:
  - Player LookAt was already network-cheap: server syncs `BMBLookAtTarget` EntIndex and `BMBLookAtUntil`; the client computes direction from the player's synced position every frame. No per-tick angle NW existed.
- Implemented:
  - Added base defaults: `LookAroundEnabled`, `LookAroundIntervalMin/Max=1/3`, `LookAroundYawLimit=60`, `LookAroundPitchLimit=15`, `LookAroundForwardChance=0.35`, `LookAroundMaxSpeed=nil` (`WalkSpeed+10` fallback).
  - Added NW vars `BMBLookAroundYaw`, `BMBLookAroundPitch`, `BMBLookAroundUntil`. These update only when a new slow/idle look-around target is chosen, not every tick.
  - Added `UpdateBMBLookAroundController(now)` and client `GetBMBLookAroundHeadAngle()`.
  - `UpdateBMBLookAtHeadPose` now resolves player target -> look-around angle -> zero and reuses one smoothing path.
- Next game retest:
  1. Idle/slow sheep should subtly glance around every 1-3s, with some straight-ahead beats.
  2. Fast run/Flee should keep the head forward unless an active player LookAt is intentionally in effect.
  3. Player LookAt should still work from EntIndex and should not become more network-heavy.

## 2026-06-16 Sheep final sound pass

- User request:
  - Use unpacked Minecraft sheep sounds from `D:\BMBTools\解包音频\minecraft\sounds\mob\sheep`: currently need `say` and `step`.
  - Eat-grass sound uses `D:\BMBTools\解包音频\minecraft\sounds\dig\grass1-4.ogg`.
  - Footsteps should be distance-driven, not timer-driven: same source as client leg animation (`speed * FrameTime()`), play when accumulated distance crosses a tuned half-gait threshold, then subtract threshold. Faster run naturally plays denser footsteps.
  - Basic step version may use sheep's own step OGG before full foot-block step-sound lookup is wired.
- Assets copied:
  - `gmod_addon/sound/bmb/mob/sheep/say1-3.ogg`
  - `gmod_addon/sound/bmb/mob/sheep/step1-5.ogg`
  - `gmod_addon/sound/bmb/dig/grass1-4.ogg`
  - `bmb_autorun.lua` registers them with `resource.AddFile`.
- Implemented:
  - Sheep `Sounds` table for `Say`, `Step`, and `EatGrass`.
  - Sheep ambient say uses the same MC-style 80 tick / random.nextInt(1000) model already used by Zombie. Injury now plays sheep say instead of headcrab pain.
  - Sheep overrides `MaybePlayStep()` as no-op so Base's old timer-driven `NextStepSoundTime` zombie footstep placeholder cannot play for sheep.
  - Client `UpdateBMBSheepStepSound(speed)` accumulates `BMBSheepStepDistance += speed * FrameTime()`, threshold `StepSoundDistance=35`, volume 0.28->0.48 by speed, pitch random 88-112.
  - `EatGrass.Try` now calls `mob:PlayBMBEatGrassSound()` when present; sheep plays random `bmb/dig/grass1-4.ogg` at the bite/block-change moment.
- Verified:
  - `glualint` passes for `bmb_sheep.lua`, `sv_behaviors.lua`, and `bmb_autorun.lua`.
  - `check_sequence_animation_adapter.ps1` guards distance-driven sheep step timing and MC sound paths.
- Next game retest:
  1. Walking/running footsteps line up with visual foot plants; adjust `StepSoundDistance` if off.
  2. Running automatically produces denser steps without timer desync.
  3. Ambient/injury sound is sheep say; eat grass uses random grass dig 1-4.

## 2026-06-16 Sheep sound volume bump

- User retest: sheep sounds are functionally good; overall volume should be a bit louder.
- Changed:
  - Step volume range 0.28-0.48 -> 0.38-0.65.
  - Ambient say volume 0.62 -> 0.78.
  - Injury say volume 0.70 -> 0.85.
  - Eat-grass grass-dig volume 0.48 -> 0.65.
- No timing changes; footsteps remain distance-driven with `StepSoundDistance=35`.

## 2026-06-16 Sheep OGG sample-rate fix

- User screenshot showed GMod error: `Invalid sample rate (48000) for sound 'bmb\dig\grass4.ogg', must be 44100, 22050 or 11025`.
- Cause: the sound files were already inside the addon, but at least `grass4.ogg` came from the unpacked assets at 48000Hz, which Source rejects for normal sounds.
- Fixed:
  - Re-encoded all addon sheep/dig OGG files under `gmod_addon/sound/bmb` to Vorbis `44100 Hz` using `D:\oopz\ffmpeg.exe`.
  - Synced the re-encoded files to the D-drive live addon.
  - Verified live `grass4.ogg` and `step1.ogg` report `Audio: vorbis, 44100 Hz, mono`.

## 2026-06-16 Sheep sound volume bump 2

- User: overall sound can be a bit louder again.
- Changed:
  - Step volume range 0.38-0.65 -> 0.50-0.82.
  - Ambient say volume 0.78 -> 0.92.
  - Injury say volume 0.85 -> 0.98.
  - Eat-grass grass-dig volume 0.65 -> 0.82.
- No timing or pitch changes.

## 2026-06-16 Lethal sheep hit still plays hurt say

- User found: if the final attack kills the sheep, there is no hurt say on that hit.
- Cause: sheep say lived in `OnBMBInjured`, which only runs after base confirms the mob survived the accepted damage. Lethal hits go straight to `OnKilled`.
- Fixed:
  - Base accepted-damage path calls optional `OnBMBHurtSound(damageInfo)` immediately after hurt flash and before `SetHealth(...)` / lethal branch.
  - Sheep implements `OnBMBHurtSound` and plays `PlayBMBSheepSay(0.98)`.
  - Sheep `OnBMBInjured` no longer plays say, so non-lethal hits do not double-play.
- Verified: glualint for base/sheep and all `scripts/check_*.ps1` pass; live addon synced.

## 2026-06-16 Physgun drop resumes wander

- User found: after grabbing a sheep with physgun and dropping it, HUD can return to `wander` but the sheep does not move until hit.
- Diagnosis:
  - `OnBMBPhysgunPickup()` correctly calls `InterruptBMBMovement()` to stop any active move while held.
  - `OnBMBPhysgunDrop()` restored gravity and kicked the loco downward, but did not clear `BMBMoveInterrupt`.
  - It also left desired speed at 0 from held disarm and could leave `BMBInitialIdleUntil` active. A later hit clears/restarts movement, which is why damage “fixes” it.
- Fixed:
  - `OnBMBPhysgunDrop()` now calls `ClearBMBMovementInterrupt()`.
  - Restores `MaintainBMBMoveSpeed(self.WalkSpeed or 80)`.
  - Sets `BMBInitialIdleUntil = 0`.
  - Keeps the existing `SetVelocity(0,0,-10)` loco wake-up.
- Verified: glualint for base and all `scripts/check_*.ps1` pass; live addon synced.

## 2026-06-17 Skeleton M1 - ranged combat core + model rebake + procedural arms (track 1+2)

- Third mob: Skeleton (pure ranged bow). Spec `H:\工作视频\20251115毕业\BMB骷髅_实现spec.md`. User chose two-milestone delivery; M1 split into two independent risk tracks (logic on placeholder model / model rebake) so neither blocks the other. M1 testing judges correctness only (no strafe yet, so no kiting feel).
- New SENT `lua/entities/bmb_arrow.lua`: pure GMod-trace projectile. Manual gravity integration (`ArrowGravity=320`) + per-tick TraceLine; hit world -> remove, hit player/NPC/NextBot -> TakeDamageInfo (`ArrowDamage=6`). `SetupArrow(owner,dir,speed,spread,damage,gravity)` sets initial velocity + spread cone. Placeholder model sphere025x025. No voxel dependency.
- New `BMB.Behaviors.RangedAttack` in `sv_behaviors.lua`: `Update`/`UpdateSightMemory`/`ResolveMovement`/`UpdateDrawFire`/`Fire`/`HasLineOfSight`/`GetArrowSpawnPos`. Decouples "where to stand" (chase via blocking `Chase.Run`; aim = stop + FaceTarget) from "when to shoot" (draw timing). Sight memory `mob.BMBSeeTime` seconds. Coroutine fit: chase blocks, aim is one tick, `RunBehaviour` yield/wait gives cadence. M1 aim does not strafe.
- `Flee.Run(mob, threat)` gained optional threat param; `pickPanicDestination(mob, threat)` only accepts candidates farther from threat (AvoidEntityGoal getPosAway). No threat = unchanged generic panic (sheep/zombie unaffected). Paves M2 wolf-flee.
- New `lua/entities/bmb_skeleton.lua`: mirrors zombie structure (RunBehaviour priority chain + RunBMBSkeletonAI: FindNearestWolfThreat->flee, SeekTarget, Wander, RangedAttack.Update). `FindNearestWolfThreat` matches class containing "wolf" (returns nil now, no wolf entity). `CanBMBTarget` players only. `GetBMBForcedLookTarget` locks target. Ranged constants in cells. Biped arms down (`BipedArmForwardAngle=0`) / raised when target (`RangedAimArmAngle=-90`, M1 placeholder both-arms). LookAt reuses zombie `LookAtPitchSign=-1/EyeHeight=64`. MC ambient model copied from zombie. M1 sounds = engine placeholders (`npc/zombie/*` + crossbow shoot); MC skeleton OGGs to be added by sound batch.
- Registered `bmb_skeleton` in `mcgm_autorun.lua`.
- Track 2 converter: `qs/mc2source/geo.py` removed `skeleton_attack`/`animation.skeleton.attack` from REST_POSE sets (mirror zombie family; wither_skeleton kept). Tests renamed to neutral assertions, 62 tests OK. Rebaked `skeleton.mdl` to D (reference.smd arms rotation 0). `ENT.Model` swapped from placeholder zombie to `models/mcgm/skeleton/skeleton.mdl`.
- IMPORTANT incident: earlier `robocopy /MIR` deleted converter-only models on D (sheep/zombie); recovered by rebaking. Sync is now `cp -rf` only (never /MIR) — converter outputs models/materials ONLY to D, not in the C repo.
- Verified: glualint on changed Lua; unittest 62 OK; cp -rf to D; D has bmb_skeleton/bmb_arrow + skeleton model; sheep/zombie models intact; C/D zombie identical (sound agent's work preserved).
- Files: NEW bmb_skeleton.lua, bmb_arrow.lua; MODIFIED sv_behaviors.lua, mcgm_autorun.lua, geo.py, test_mc2source_pipeline.py, docs/STATE.md, CLAUDE.md, qs/CURRENT_HANDOFF.md, .planning/*.

## 2026-06-20 Hostile chase direct cliff memory

- User found hostile mobs on winding/cliff paths repeatedly tried to abandon A* and run straight at the player, hit the same real cliff, fall back to A*, then retry the same dead shortcut.
- Diagnosis: cliff detection and A* route are doing the right thing; `chase_direct` had no memory that the current straight line to this target had already failed.
- Fixed in shared `BMB.Behaviors.Chase`:
  - `ApplySafePressure(..., "chase_direct")` writes `BMBChaseDirectCliffBlock` after cliff hysteresis confirms a direct cliff failure.
  - `CanDirect` checks that memory before attempting the direct shortcut.
  - Memory is keyed by target EntIndex plus mob/target positions, with cooldown, expiry, and movement thresholds.
  - `attack_ready` and `chase_repath` do not write this shortcut memory.
- Base defaults were later retuned after live cliff testing; see 2026-06-21 follow-up below.
- Guard: `scripts/check_block_shape_pathing.ps1` now asserts direct cliff memory remains wired.
- Follow-up tuning: `Chase.CanDirect` now accepts optional `ChaseDirectMaxDistance` / `ChaseDirectMaxDistanceCells`; Zombie family sets `ChaseDirectMaxDistanceCells=6` so long-range chase stays on A* and direct only takes over nearby. Skeleton/Stray/Parched are unchanged.

## 2026-06-21 Hostile chase repath cliff memory follow-up

- User found the remaining flicker was `path` <-> `chase_repath_cliff`, not only `chase_direct_cliff`.
- Diagnosis: the first cliff memory only covered `chase_direct`; Zombie's A*-failure fallback still did `ApplySafePressure(..., "chase_repath")`, so it retried the same dead straight line after each path attempt.
- Fixed in shared `BMB.Behaviors.Chase` without touching A* or cliff/support detection:
  - `ShouldRememberCliffMode()` now writes the same `BMBChaseDirectCliffBlock` for `chase_direct` and `chase_repath`, but still excludes `attack_ready`.
  - New `TryRepathPressure()` checks `IsDirectCliffBlocked()` before applying `chase_repath` direct pressure; blocked attempts publish `chase_repath_blocked` instead of flickering `chase_repath_cliff`.
  - Memory duration default is now 25s, a long dynamic-world fallback retry instead of removing time expiry.
  - If A* remains false and repath direct pressure is blocked for `ChaseRepathCliffBlockedGiveUpTime` (default 4s), the mob briefly drops the target/retargets so it can return to wander instead of pinning itself to the cliff.
- Guard: `scripts/check_block_shape_pathing.ps1` now asserts chase_repath memory/give-up wiring.
- Live retune: Zombie fallback already uses `TryRepathPressure`; the remaining `chase_repath_cliff` loop was because old thresholds were too eager. A* detour movement exceeded 2 cells after the 1.2s cooldown and cleared the memory before the mob had actually rounded the cliff. Defaults are now `ChaseDirectCliffMemoryCooldown=3.0`, `Duration=25.0`, mob move threshold `6.0` cells, target move threshold `2.0` cells, with `bmb_chase_cliff_memory_*` and `bmb_chase_repath_cliff_giveup_time` convars for in-game tuning.

## 2026-06-20 Base retaliation targets

- User wanted skeleton-family arrows that hit zombies to make zombies prioritize the shooter over the player, and then skeletons hit by zombies to shoot the zombie back.
- Confirmed arrow damage already credits the shooter: `bmb_arrow` sets `DamageInfo` attacker to `BMBArrowOwner`, not the arrow entity.
- Implemented one base rule instead of zombie-vs-skeleton special cases:
  - `bmb_base_mob` now has `IsBMBCombatTarget`, `CanBMBRetaliateAgainst`, and `TryBMBRetaliate`.
  - Non-lethal accepted damage reads `damageInfo:GetAttacker()`, validates it through the mob's `CanBMBTarget`, and writes the shared `TargetEntity`.
  - Retaliation is sticky through the existing target validity rules: keep target until dead/invalid/out of lose range, then fall back to normal player scan.
  - `RetaliateSameClass=true` by default allows same-class friendly-fire chaos; set false per mob for MC-style suppression.
- Zombie/Skeleton `CanBMBTarget` now accepts generic combat targets via base, not only players; forced look follows any current target.
- Husk/Stray player-only local injury targeting was removed so they inherit the base rule. Parched inherits Skeleton.
- Guard: new `scripts/check_retaliation_targets.ps1`.

## 2026-06-20 Screenshot helpers: notarget + bmb_freeze

- Problem: Source `notarget` and `ai_disabled` do not affect BMB Lua NextBot logic. BMB scans players itself and runs its own behavior coroutines.
- Fixed:
  - `SeekTarget.IsValid` treats `player:IsFlagSet(FL_NOTARGET)` as invalid, so `notarget` players are skipped and current player targets are dropped.
  - Base `IsBMBCombatTarget` also respects `FL_NOTARGET`, preventing damage retaliation from re-locking a notarget player.
  - Added server convar `bmb_freeze 1/0` for screenshots. Base `MaintainBMBFreeze` interrupts active movement, clears look-at, zeroes desired/actual velocity, and publishes `state/mode=frozen`.
  - Sheep/Zombie/Skeleton `RunBehaviour` loops check `MaintainBMBFreeze` at the top; Husk/Stray/Parched inherit through Zombie/Skeleton.
- Guard: new `scripts/check_notarget_freeze.ps1`.

## 2026-06-20 MCSWEP lighting compatibility

- Friend's lighting addon lives at `D:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\mcswep-codex-light-source-version`.
- Confirmed interface:
  - Console `mc_light_enable 1/0` writes client cvar `mc_light_enabled`.
  - Blocks use `MC.SampleLighting(bx, by, bz, selfEmission)` while building `vertexcolor` IMeshes.
  - When lighting is disabled, `MC.SampleLighting` returns brightness `1`, so callers can safely always sample.
- BMB mobs are models, not MC chunk meshes, so they do not inherit block vertex colours automatically.
- Implemented draw-time compatibility in base:
  - `GetBMBMCLightBrightness()` samples `MC.WorldToCell(self:GetBMBMCLightSamplePos())` around the mob body center.
  - `DrawBMBModelWithMCLight()` multiplies `render.SetColorModulation` by sampled brightness, draws, then restores white.
  - Normal draw and hurt/death red flash both use the helper.
  - Skeleton-family held bow uses the same helper so the bow does not stay bright in dark caves.
- Missing MC addon or `mc_light_enable 0` naturally yields brightness `1` / no visual change.
- Guard: new `scripts/check_mc_lighting_compat.ps1`.
