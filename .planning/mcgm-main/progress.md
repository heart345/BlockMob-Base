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
