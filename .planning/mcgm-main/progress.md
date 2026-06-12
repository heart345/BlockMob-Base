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
