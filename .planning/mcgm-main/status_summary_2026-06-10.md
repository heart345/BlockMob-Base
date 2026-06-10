# BMB Status Summary - 2026-06-10

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
2. 观察原地扭身是否消失。
3. 如果还出现，记录 HUD：
   - `mode`
   - `vel actual/desired`
   - `dist`
   - 是否显示 `*_blocked` / `*_stuck`
4. 复测 Flee：
   - 枪击触发
   - prop 砸中触发/死亡
   - 逃跑期间不再躲玩家正面绕位
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
