# BMB Status Summary - 2026-06-10

> **当前状态的权威文件是 `docs/STATE.md`**（CLAUDE.md 指定的开工入口，每次改动后更新）。本文件保留 codex 时期的详细诊断记录，并在下方追加 Fable 接手后的增量；细节流水见同目录 `progress.md` 的 2026-06-10 session。

## Fable 接手后的增量（2026-06-10，最新）

- "走一会停一下换方向"已修：Wander 改回 A* 完整路径 + 到站停顿，根因和修法见 `findings.md` 开头一节。
- 原地扭动真根因已定位并修复：goalTolerance 12->18 消减速区死区；FaceTarget 改 `loco:FaceTowards`（弃 SetAngles）。
- 新增 `SteerTowards`：目标在身后先原地转身再走，修"面朝前方倒退"。`TurnRate=400`、`TurnInPlaceAngle=110`。
- carrot 终点外投 + watchdog 近终点兜底：修"到站被 watchdog 误杀导致不停顿"。**MC 游荡节奏用户已验证 ✅（停顿正确、无 blocked 误报）。**
- 吃草冷却 25-45s ✅。
- 第四、五轮用户已复测：**行进中转圈 ✅（垂面跳点）、跳崖 ✅（速度缩放探测 + FailBMBMove 急刹）、游荡停顿 6-14s ✅**。
  - 第四轮：单段游荡 `WanderDistanceMin/Max`（sheep 删 WanderRadius）；`MoveAlongPath` 节点推进加"越过节点垂面且距节点 <= 1.5 格则跳过"判定。
  - 第五轮：`IsMovementTargetSafe` 探测随速度放大（`SafetyProbeSpeedScale=0.45`，可传 probeDistance 覆盖）；`FailBMBMove` 杀水平动量。
- 第六轮（实测仍冻）-> **第七轮真根因（用户已验证 ✅ 贴脸 prop 不再冻住）**：`getSafeDirection` 的 `direction:LengthSqr() > 1` 把归一化单位向量全部跳过，**十方向选择从第一天起从未运行、恒返回 nil**，Flee 一直只走"朝 away 直线兜底"（侧跑没事、面朝 prop/边缘就冻的原因）；`MoveAlongDirection` 的 `<= 1` 同款拒收。两处阈值改 0.01。另：受击掉头先转身后跑 ✅（用户已验证）。
- **第八轮（用户已验证 ✅）：墙/悬崖分治**——边缘不再急停、撞 prop 会换方向。`IsMovementTargetSafe` 区分 `wall`/`cliff` 失败，墙只在贴脸 `WallStopDistance`(20u) 内算挡路；wall 失败不杀动量；每 tick 复查距离改 `min(选向档位, max(48, vel×0.45))`（`GetBMBTickSafetyProbe`）。
- **第九轮（用户已验证 ✅）：Flee 重写为 MC PanicGoal 式**（对照用户本地 MC 源码）：随机近点 dash、没路放弃、平地不跑远，全部通过。
- **第十轮（待复测）：RealBlockWorld 接通 MCSWEP**（addon 在 `D:\...\addons\mcswep-main`，`MC.SV.SetBlock` 已就位）。修掉五个对接隐藏 bug：BlockWorld 无切换机制（新增 `BMB.SelectBlockWorld` + `bmb_use_real_world` + `bmb_world` 命令）、GetBlockAt 数字 id 对不上 BMB.BlockTypes 枚举（adapter 双向映射）、吃草查成脚部空气格（改查脚下支撑格 + actor 透传）、A* 不查头部格（isPassable）、MaxStepDown 34<36 下不来一格地板（改 40）。已知缺口：一格台阶自动跳未实现。详见 findings.md 与 docs/STATE.md。
- **第十一轮（最新，待复测）：修一格宽走廊"出得来、进不去"**。Fable 诊断成立：A* 路径被跟随层二次否决，`IsMovementTargetSafe` 的 `WallStopDistance=20` 会误伤 36u 走廊入口；carrot 也会在直角入口切角。本轮 `MoveAlongPath` 删除 Source 安全复查，carrot 改 pure pursuit（投影到路径折线后沿折线前推），再用网格视线检查把不可直视的 carrot 缩回最后可见点。裸方向移动仍保留安全探测。坑里 Flee 盲采放弃是下一步独立问题。
- **第十二轮（最新，待复测）：方块通行按 mob hull**。第十一轮后仍会从一格高洞/方块角穿过，且 Tool Gun 右键只闪一下 `debug_move`。本轮把 `isPassable` / 随机候选 / carrot 视线从"中心点 foot+head cell"升级为实体 hull 占格：`IsBMBHullClearAtPosition` 按水平半径和身高检查周围 solid cell；A* 调 `FindPath(..., {mob=self})`；`GetRandomWalkablePoint` 接收 mob；`IsPathGridVisible` 每 1/4 格采样 hull clear；`bmb_sheep` hull 宽 28u->32u；Tool Gun 右键目标改走 A* path debug，点击面上抬/推出到空气格。
- **第十三/十四轮（最新，待复测）：过弯和 Source 安全回补**。第十二轮三项通过后，走廊拐弯有漂移 -> 新增 `path_corner`，提前约 2 格检测转角，缩短 carrot、降速、提高 deceleration。随后发现地图墙/跳崖回归 -> `MoveAlongPath` 加回 path 专用 `IsPathSourceTargetSafe`：Source wall hit 若对应 MC solid block 则忽略（不误伤方块走廊），若不是 MC block 则 `path_wall`；地面 probe 没地/坡陡/落差大则 `path_cliff` 急刹。
- 吃草粒子决策：选择原版手感版，不靠 MCSWEP 破坏 fx；羊后续自己补低头动画、咀嚼音效、草屑粒子。当前只修路径，不实现粒子。
- `bmb_use_source_path` 默认改 0（不用 navmesh）；`UseWanderPathFallback` 已删除。
- 下方"New Fix For Standing Twist"一节描述的直线游走方案已被上述方案**取代**，仅作历史参考。

## Current Goal

把 Minecraft 风格 mob 做成 GMod NextBot，并逐步形成一个薄 `BaseMob`、可复用行为模块、方块世界接口和调试工具链。当前切片是 `bmb_sheep`，用于验证被动生物的游荡、受击逃跑、吃草改方块、Source 安全检查和调试工具。

## Current Progress

- Phase 1 `mcgm_zombie` 手感样机已完成，作为早期追击/攻击/声音验证物。
- Phase 2 `BlockMob Base / BMB` 正在推进。
- 已建立：
  - `bmb_base_mob` NextBot 基类
  - `bmb_sheep` 原型实体
  - mock `IBlockWorld`
  - 方块网格 A*
  - Wander / Flee / EatGrass 行为模块
  - prop 高速冲击伤害和速度衰减
  - HUD、控制台命令、Tool Gun 调试工具
- 用户已验证：
  - `bmb_sheep` 可生成
  - Flee 当前可稳定触发，逃跑时间随机 `3.5-6.0` 秒
  - prop 砸中/砸死后不会再反向高速弹飞
  - 速度锯齿/移动丢帧问题已解决
  - Tool Gun 调试面板不再刷 `Tried to look up command ... as if it were a variable`

## File Structure And Responsibilities

### Addon Root

- `gmod_addon/addon.json`
  - GMod addon 元数据。

### Autorun

- `gmod_addon/lua/autorun/bmb_autorun.lua`
  - BMB 主加载入口。
  - 客户端加载 HUD debug。
  - 服务端加载 block world、pathfinder、behaviors、debug tools。
  - 注册 `bmb_sheep` 到 NPC 列表。

- `gmod_addon/lua/autorun/mcgm_autorun.lua`
  - 早期 `mcgm_zombie` 样机加载入口，属于旧切片保留物。

### Entities

- `gmod_addon/lua/entities/bmb_base_mob.lua`
  - BMB NextBot 基类。
  - 管生命值、受伤、死亡、移动 primitive、转向、脚步、Source 安全 trace、台阶/下落检查、prop 冲击伤害。
  - 现有移动后端：
    - Source `Path("Follow")` 可选路径
    - BMB A* `MoveAlongPath` carrot-point 跟随
    - `MoveAlongDirection` 连续方向巡航
    - `MoveDirectFallback`
    - debug target/direction move
  - 现有 debug NW 字段：
    - `BMBState`
    - `BMBHealth`
    - `BMBDesiredSpeed`
    - `BMBMoveMode`
    - `BMBDistToGoal`
    - `BMBPathNode`
    - `BMBPathAdvance`

- `gmod_addon/lua/entities/bmb_sheep.lua`
  - 当前 BMB 验证实体。
  - 参数：血量、walk/run speed、wander radius、flee distance/duration。
  - 行为循环：debug move > flee > eat grass > wander。
  - 受击时记录 threat position snapshot，避免逃跑期间持续躲玩家当前位置。

- `gmod_addon/lua/entities/mcgm_zombie.lua`
  - 早期 Zombie 手感样机。
  - 后续会迁移到 BMB 架构或作为参考删除/归档。

### BMB Modules

- `gmod_addon/lua/bmb/sh_config.lua`
  - 共享配置。
  - 当前 `BlockSize = 36` Source units。
  - 默认 path goal tolerance。

- `gmod_addon/lua/bmb/sv_block_world_mock.lua`
  - mock 方块世界。
  - 提供 mob 侧需要的 `IBlockWorld` 风格接口。
  - 支持 grass/dirt/stone，支持 debug block visualization。

- `gmod_addon/lua/bmb/sv_block_world_real.lua`
  - MCSWEP/BMB 真实方块世界 adapter 草案。
  - 当前只保留接口方向，真实 server authoritative write 还缺朋友那边的完整 API。

- `gmod_addon/lua/bmb/sv_pathfinder.lua`
  - 方块网格 A*。
  - 基于 `BMB.BlockWorld` 查询 walkable point/path。

- `gmod_addon/lua/bmb/sv_behaviors.lua`
  - 行为模块：
    - `Wander`
    - `Flee`
    - `EatGrass`
  - Wander/Flee 使用连续方向移动，避免短段移动造成停顿。

- `gmod_addon/lua/bmb/cl_debug.lua`
  - 客户端 HUD 和 mock block 渲染。
  - HUD 显示 class、hp、state、mode、actual/desired velocity、dist_to_goal、path node、advance count。

- `gmod_addon/lua/bmb/sv_debug_tools.lua`
  - 服务端控制台 debug 命令：
    - `bmb_debug_info`
    - `bmb_debug_health`
    - `bmb_debug_speed`
    - `bmb_debug_move`
    - `bmb_debug_stop`
    - `bmb_debug_flee`

### Tool Gun

- `gmod_addon/lua/weapons/gmod_tool/stools/bmb_debug.lua`
  - GMod Tool Gun STool：`BlockMob Base -> BMB Debug`
  - Left click：选择 BMB mob
  - Right click：移动选中的 mob 到目标点
  - Reload：停止 debug movement
  - 面板提供 HUD、move speed/duration、health、walk/run/accel/decel、force flee。
  - Tool client convars 使用 `bmb_debug_move_*` 和 `bmb_debug_edit_*`，避免和控制台命令 `bmb_debug_health` / `bmb_debug_speed` 撞名。

### Docs And Planning

- `docs/roadmap.md`
  - 总路线和 VJ Base vs 自研 NextBot 判断。

- `.planning/mcgm-main/task_plan.md`
  - 长期任务拆分。

- `.planning/mcgm-main/progress.md`
  - 已做事项流水。

- `.planning/mcgm-main/findings.md`
  - 调研和行为/接口结论。

- `.planning/mcgm-main/status_summary_2026-06-10.md`
  - 本文件，用于新窗口快速续上上下文。

## Velocity Sawtooth Bug Status

### Phenomenon

- 羊移动时看起来像丢帧，一抽一抽。
- HUD/截图中 `vel` 会从期望速度附近骤降，再恢复，形成锯齿。
- 用户测试 `bmb_use_source_path 1` 和 `0` 都会抽，说明问题不只是 Source `Path("Follow")` 或手写 fallback 的单一选择。

### HUD Investigation

- 加入 HUD 字段：
  - `vel: actual/desired`
  - `mode`
  - `dist`
  - `node`
  - `adv`
- 目标是确认 `loco:Approach()` 实际目标距离是否长期贴近一个方块距离。
- 如果 `dist_to_goal <= 36` 长期出现，NextBot 很容易在每个小目标前减速。

### Carrot Point Hypothesis

- Fable 提出的假设成立：
  - `loco` 接近 goal 时会自动 decelerate。
  - BMB A* waypoint 间距是一个方块，即 36 units。
  - 如果每次 `Approach` 只喂下一个 36u waypoint，羊会不断进入减速区：提速 -> 刹车 -> 切点 -> 提速 -> 刹车。
- 另一个已排除/修正的问题：
  - `bmb_base_mob:Think()` 曾经用 `NextThink(CurTime() + 0.08)`，可能把行为协程实际更新频率压低到约 12.5Hz，也会制造移动补油门感。

### What Changed

- `Think` 改为 `NextThink(CurTime())`，物理 prop impact 仍通过 `PhysicsImpactInterval` 内部限频。
- `MoveToWorldPosition` 不再逐个 `MoveToWaypoint`。
- 新增 `MoveAlongPath`：
  - waypoint index 仍按距离推进
  - `loco:Approach` 接收沿路径前方投影的 carrot point
  - carrot 距离按速度约束在 `72-150` units
  - 每 tick 维持 desired speed
- `MoveAlongDirection` 和 debug movement 每 tick 更新 desired speed 和 debug dist。
- HUD 显示 `dist_to_goal` 和 node advance count。

### Verified

- 用户已验证移动丢帧/vel 锯齿完美解决。
- Tool Gun 面板也已验证修好。

### Not Fully Verified Yet

- 新增 no-progress watchdog 对“原地扭身”的实际效果还没进 GMod 复测。
- `source_path` 长距离模式在复杂 navmesh 上还没有单独复测。
- 多只 mob 同时移动时，HUD NW 更新频率和性能还没有压测。
- 真实 MCSWEP/BMB block write API 未接入，mock `IBlockWorld` 仍是主验证路径。

## New Fix For Standing Twist

### Symptom

- 当前新问题：NPC 有时会停在原地，身体/朝向扭动，但不继续走。
- 用户后续截图显示：`state=wander`、`mode=path_carrot`、`vel=0.0/70.0`。这说明问题不是单纯 idle 动画残留，而是普通 wander 掉进 A* carrot path 后，移动控制仍在运行但 loco 没产生速度。

### Likely Causes

- 移动 primitive 已经进入 `FaceTarget + Approach`，但实际速度/位移没有起来，导致它持续原地朝目标修正角度。
- 等待/空闲阶段可能仍残留 walk/run activity，看起来像原地动作没有收住。
- `MoveAlongDirection` 是短距离连续 steering，走 Source PathFollower 反而可能出现短目标 path valid 但实际原地转的情况。

### Changes Made

- 新增 no-progress watchdog：
  - `MoveNoProgressGrace = 0.75`
  - `MoveNoProgressTimeout = 0.45`
  - `MoveNoProgressDistance = 3`
  - `MoveNoProgressSpeed = 8`
- Debug/source/path/direct/direction/legacy waypoint 移动循环都会检测：
  - 如果持续没有速度也没有实际位移，标记对应 `*_blocked` 或 `*_stuck` 并返回失败，让行为层重新选方向。
- `mode=idle` 时切回 `ACT_IDLE`。
- `InterruptibleWait` 开始时也切回 idle，避免等待时残留 walk/run 活动。
- `MoveAlongDirection` 默认不再使用 Source PathFollower；只有显式传 `useSourcePath = true` 才走 SourcePath。长距离 `MoveToWorldPosition` 仍保留 SourcePath 可选。
- 普通 `Wander` 默认不再使用 A* path fallback；随机游荡优先使用 direct steering，只有实体显式设置 `UseWanderPathFallback` 时才允许 Wander 调 `MoveToWorldPosition`。
- no-progress watchdog 调硬：
  - grace 从 `0.75` 降到 `0.35`
  - timeout 从 `0.45` 降到 `0.25`
  - progress distance 从 `3` 提到 `8`
  - progress speed 从 `8` 提到 `16`
- watchdog 现在复制位置向量，避免位置引用或微小漂移影响判定。
- `path_carrot` 额外要求朝最终目标取得进展；如果约 `0.9` 秒内最终目标距离没有下降至少 `10` units，会失败为 `path_no_goal_progress`。

## Next Checklist

1. 重启 GMod，生成 `bmb_sheep`，开 `bmb_debug_hud 1`。
2. 优先复测一格宽走廊、低顶、方块角、Tool Gun 右键 path debug、拐弯 `path_corner`、地图墙/平台边缘 `path_wall`/`path_cliff`。失败时记录 HUD：
   - `mode`
   - `vel actual/desired`
   - `dist`
   - `node` / `adv`
   - 是否显示 `*_blocked` / `*_stuck`
3. 复测 Flee：
   - 枪击触发
   - prop 砸中触发/死亡
   - 逃跑期间不再躲玩家正面绕位
4. 下一步优先：Flee 在坑/封闭结构中从"盲采世界点"改成"枚举可站立格 -> 随机抽 -> A* 验证"。
5. 下一步工具建议：
   - BMB movement inspector：显示 path nodes、carrot、safety trace hit
   - life/speed editor：当前 Tool 已有初版，后续可做得更像 VJ Base 面板
   - block probe tool：查看脚下 mock/real block coord 和 walkable 判断
6. 等朋友补完完整 interface 后：
   - 更新 `sv_block_world_real.lua`
   - 把 mock/real adapter 做成可切换
   - 验证非玩家 server authoritative block write
7. Sheep 稳定后：
   - 把 Zombie 迁移到 BMB base
   - 建 hostile behavior 分支
   - 开始模型/动画管线验证

## 2026-06-11 Latest Status

- 第十一到十四轮移动问题已由用户确认通过：一格宽走廊进/出、低顶、方块角、拐弯漂移、地图墙和平台边缘保护都不再复现。
- 第十五轮（A* 3D 邻接 + BlockHop/drop）用户实测报三个 bug → **第十六轮（最新，待复测）**：
  - hop 贴墙不跳 = `hopStartedAt` 一次性 + 空中弱转向落地后仍接管并刷 watchdog 的死锁；修为落地重跳（≤3 次，`path_hop_fail` 交还行为层）+ 起跳朝目标水平分量补足到行走速度 + 空中转向只在离地时接管。
  - 右键高处/非 MC 地面"卡一下且不动" = 不可达目标 A* 泛洪（同层 walk 边无支撑要求 + drop 不认 Source 地皮 + 每格 hull 扫描无缓存）；修为 `IBlockWorld.HasSupport`（MC 实心或 Source 刷子地面，prop 不算）+ walk/hop/drop 落点统一要求可站立 + 目标悬空下吸 ≤12 格 + per-call 缓存 + f 预算（hStart*2+24）+ 每 64 迭代 yield。
  - 新增部分路径（中止返回最近已展开点，标 `partial`）：>3 格纯垂直落差从"卡顿拒动"变"走到崖边停住"（仍按 MC 规则拒跳，要改调 `MaxPathDropCells`）；Flee 显式 `allowPartial=false` 保住"被围住会放弃"。
- 本轮 lint 已通过，已同步 D 盘。
- **第十六轮用户复测结果**：卡顿全消 ✅、不跳楼 ✅、下落正常 ✅；另确认旧清单三项（枪击 Flee、prop 冲击衰减、真方块世界全链路+mock 回退）通过。新报三个问题 → **第十七轮（最新，待复测）**：
  - 迷宫绕路中途 `path_no_goal_progress` 放弃 = 直线距离 watchdog 误杀合法绕路；修为节点推进刷新 watchdog + timeout 0.9→1.2。
  - flatgrass 围墙窗台等窄 Source 路完全走不了 = HasSupport 只采格子中心的回归；修为中心悬空时补 ±12u 轴向偏移采样。
  - `path_hop` 状态有但不起跳 = 起跳 tick 在地面走了 Approach 把 SetVelocity 竖直速度冲掉的回归；修为 `BlockHopLaunchWindow=0.15s` 起跳保护窗强制空中转向。
- **第十七轮用户复测**：绕路 ✅、窄沿 ✅；hop 仍不起跳（截图证实整砖 hop 从未离地、半砖"成功"是 StepHeight 走上去的）→ **第十八轮（已复测，继续第十九轮）**：
  - hop 真根因 = NextBot 落地态地面解算把 `loco:SetVelocity` 直写的竖直速度当帧压回（SetVelocity 单独起跳从未生效过）。修：`loco:SetJumpHeight(45)` + `loco:Jump()` 切跳跃态后再 SetVelocity 覆盖弹道。
  - 删 0.15s 保护窗 → 查 `loco:IsClimbingOrJumping()`（起跳当帧强制真）；重跳延时挂 `OnLandOnGround`（`BMBLastLandTime`），不轮询。
  - 新增**物理枪持握一等状态 `BMBHeld`**：抓羊抽搐/陷地 vs 安静悬挂 = 被抓瞬间 loco 醒/睡。持握中 loco 每 tick 缴械、行为挂起（state=held）、移动入口拒新；拾起 Interrupt 掐掉 move 协程（hop 计数随局部状态销毁，held×hop 握手）；松手 `SetVelocity(0,0,-10)` 踹醒睡眠 loco。
  - 查证 MCSWEP：半砖 `BlockIsFullCube=false` → A* 当空气，混半砖地形会跳整格（观感问题，待 `MC.BlockBoxes` 细化）。
- **第十八轮用户复测**：hop 有抬脚/离地动作，但呈现"一陷一陷"的小跳节奏，最终仍上不去；物理枪抽动明显改善但还有轻微弹簧感 → **第十九轮（已复测，继续第二十轮）**：
  - BlockHop 改用 NextBot 原生 `loco:JumpAcrossGap(landingGoal, landingForward)`，落点给目标 foot cell 的地表点（`target.z - halfBlock`），`SetJumpHeight` 抬到至少 58u。原生 hop 期间只 FaceTowards + 刷 watchdog，不再 `SetVelocity` 空中弱控；老引擎缺接口才 fallback 到 `Jump()+SetVelocity`。
  - 物理枪 held 每 tick 缴械升级为 `SetVelocity(vector_origin)` + `SetGravity(0)` + `SetDesiredSpeed(0)`；pickup 保存原 gravity，drop 恢复后向下踹醒。
  - 若仍不上台，下轮先打 0.5s 逐 tick 日志（`IsClimbingOrJumping`、`IsOnGround`、`vel.z`、`pos.z`）区分 jump height/API、过早落地判定、hull 碰撞三类问题。
- **第十九轮用户复测**：物理枪上下抽完全修好 ✅；hop 仍低弧、擦模、概率性上台（反复 debug 点击某方向才偶尔成功），其他地形显示 `path_hop` 但上不去 → **第二十轮（已复测，继续第二十一轮）**：
  - BlockHop 增加起跳准入：距离窗口约 0.85~1.4 格，朝目标速度 ≥0.6×pathSpeed；太近/太慢先退到 1.15 格助跑点再进跳。
  - `JumpAcrossGap` 落点改成上层格中心、z=台面+2u；JumpHeight 默认 `1.6*BlockSize`（约 58u），保留配置覆盖。
  - HUD 第三行显示 `hop# native/manual d face v apex result`；`bmb_debug_hop_log 1` 可打印控制台日志。下一轮先看 `d/v/apex`，再决定是否切到底线方案（`Jump()` 后下一 tick `SetVelocity` 覆盖弹道）或查 A* hop 候选拒绝。
- **第二十轮用户复测**：debug 有助跑能上；wander 自己慢速靠近时大多上不去；日志显示 native 成功样本 `dist≈47/face≈29/speed≈73/apex≈36`，失败多为 `dist≈36/face≈18/speed≈50/apex=0`；另发现 wander 不主动下 2 格高台（debug 可下）→ **第二十一轮（已复测，继续第二十二轮）**：
  - BlockHop 默认改成错帧手写弹道：`Jump()` 打开跳跃态，下一 tick `SetVelocity`；竖直顶点 `1.6*BlockSize`，水平速度按距离/飞行时间计算并 clamp，防止助跑跳很远。
  - 写入手写速度后短时间强制空中 steering，避免同一轮 path loop 仍判地面并让 `Approach` 抢回控制。
  - 起跳准入取消已有速度硬门槛，只保留距离窗口；wander 慢速靠近也应该能跳。
  - MC 源码确认普通 mob 寻路最大下落 3 格，BMB `MaxPathDropCells=3` 不改；real Wander 随机候选增加下层偏置（前 14 次优先抽 1~3 格下层），让它更容易主动选到台下目标走 `path_drop`。
- **第二十一轮用户复测**：wander 主动下 3 格内已实现 ✅；hop 仍未成功，日志显示 manual `vz≈339` 已写入但 `apex=0~12`，说明速度被碰撞/地面解算吃掉 → **第二十二轮（已复测，一格成功）**：
  - BlockHop 改两段式 manual lift：下一 tick 先只给竖直速度，短 lift 窗口内仍判 onGround 就重复 `Jump()`；抬到约 `0.8*BlockSize` 或 lift 超时后再加水平速度落到上层。
  - 保留水平速度 flight-time clamp 和 debug HUD；成功/失败/中断清理 active/pending hop 状态。
- **第二十二轮用户复测**：NPC 已能跳上一格台阶 ✅；成功样本 apex 约 54~65。保留待调优：弧线偏高、偶发误上两格（A* 不主动规划两格）、debug move 长路径超时偏短、跳后动作保持偏久 → **第二十三轮（已复测通过）**：
  - hop 期间临时 `StepHeight=18`，结束/失败/中断恢复默认 28，切断 apex + 自动登阶误上两格的组合；不削一格可靠性需要的 apex。
  - path timeout 改为路径长度 / speed × scale + base；debug 右键 path move 不再把面板 duration 当硬截断，卡死仍由 no-progress watchdog 判断。
  - activity 改为 Think/落地状态驱动：held/airborne/ground speed 选择 idle/walk/run/jump，落地重置 `CurrentMoveActivity`，防跳姿残留。
- **第二十三轮用户复测**：当前未发现 bug ✅；一格 hop、误上两格、debug 远点早停、跳后动作残留均暂未复现。

## Current Next Checklist

1. **第二十四轮代码已完成，待用户游戏回归**：MCSWEP 已切 `MC.BS=36.5`，BMB 改为 `BMB.GetBlockSize()` / `BMB.BS` 单一尺寸入口，mock fallback 36.5。先在控制台确认 `MC.BS` 与 `BMB.BS` 都为 36.5。
2. **36.5 必测**：hop 一格稳定、两格不上；半砖/楼梯靠普通 `StepHeight=28` 走上去；36.5 走廊 hull 32 双向通行；drop 3 格（109.5u）主动下、4 格拒绝；吃草链路和坐标往返正常；`bmb_world mock` 尺度一致。
3. **继续回归观察**：hop/StepHeight、debug timeout、activity reset 在更多地形和套皮后继续留意。
4. **下一功能短板**：Flee 坑/封闭结构采样，改为枚举可站立格（复用 `HasSupport`）-> 随机抽 -> A* 验证。
5. **表现收尾**：吃草原版粒子/动画/音效。
6. **后续地形细化**：半砖/栅栏 `MC.BlockBoxes`，以及 Zombie 迁移验证 base 抽象。
