# Task Plan: Minecraft Mobs in Garry's Mod

## Goal

把 Minecraft 26.1 系列生物做成 Garry's Mod NPC，并优先做到移动、声音和行为节奏接近原版 Minecraft。

## Current Phase

Phase 2

## Phases

### Phase 1: Zombie 手感样机

- [x] 创建 GMod addon 骨架
- [x] 创建可生成的 NextBot Zombie
- [x] 修复 `FaceTowards` 不存在导致的运行错误
- [x] 加入基础追击、游荡、攻击、脚步和叫声
- [x] 加入可测试的动态 prop 避障
- [x] 在 GMod 中验证控制台无报错
- **Status:** complete

### Phase 2: 架构重整与方块寻路切片

- [x] 初步收窄 Zombie 攻击距离
- [x] 将 Zombie 每次命中伤害调为 10 HP
- [x] 加入玩家受击音效和轻微击退
- [x] 初步调整攻击命中延迟和更强击退
- [x] 接收 `gmod_mc_mob_spec(2).md` 架构规格
- [x] 建立薄 `BaseMob` NextBot 基类
- [x] 建立第一批行为模块：Wander / Flee / EatGrass
- [x] 建立 mock `IBlockWorld`
- [x] 接收 MCSWEP 真实接口文档
- [x] 将 BMB 方块大小改为 36 Source units
- [x] 建立 `BMB.RealBlockWorld` adapter 草案
- [x] 建立方块网格 A* 寻路
- [x] 做 Sheep 最小切片代码：Wander、受击 Flee、吃草改方块
- [x] 在 GMod 中验证 `bmb_sheep` 无控制台报错
- [ ] 验证 Sheep 在 mock 方块世界中能绕 mock stone 障碍游荡
- [ ] 验证 Sheep 受击后 Flee 稳定触发
- [x] 验证 Sheep 吃草时 mock `SetBlockAt(coord, DIRT)`
- [x] 加入 `bmb_mock_show` 调试命令显示 mock 方块
- [x] 加入 Source hull 和地面安全检查，避免撞墙/跳崖
- [x] 将 mock 方块显示改为客户端渲染
- [x] 验证 Source 小台阶上/下可走且不跳崖
- [x] 加入高速物理 prop 冲击伤害和速度衰减反馈
- [ ] 复测 Sheep 枪击受伤后 Flee 是否稳定触发
- [ ] 复测高速 prop 砸中/砸死 Sheep 后是否沿原方向衰减而不是反向弹飞
- [x] 修"走一会停一下换方向"：Wander 改回 A* 完整路径 + 到站停顿（Fable 2026-06-10，用户已验证）
- [x] 修原地扭动真根因：goalTolerance 12->18 消减速区死区；FaceTarget 改 loco:FaceTowards（用户已验证）
- [x] 修面朝前方倒退：SteerTowards 先原地转身再走（用户已验证）
- [x] 吃草频率调低：吃完冷却 25-45s（用户已验证）
- [x] 复测 MC 式游荡节奏：到站停顿 4-10s 生效，无 `path_blocked`/`path_no_goal_progress`（用户已验证）
- [x] 复测游荡微调：停顿 6-14s OK；单段距离用户要求上调，2-5 格 -> 3-8 格（WanderDistanceMin/Max 108/288，待复测）
- [x] 复测行进中"莫名转圈"修复：垂面跳点判定生效（用户已验证）
- [x] 复测跳崖修复：速度缩放安全探测 + FailBMBMove 急刹生效（用户已验证）
- [x] 复测 Flee 冻住第七轮真根因修复：getSafeDirection / MoveAlongDirection 的单位向量 LengthSqr 阈值 bug（1 -> 0.01）——用户已验证贴脸 prop 不再冻住
- [x] 复测第八轮墙/悬崖分治：离 prop/边缘不再远距离犹豫掉速——用户已验证边缘不急停、撞 prop 换方向
- [x] 复测第九轮 MC PanicGoal 式 Flee：受击随机近点 dash（不朝反方向）、平地跑 1-2 段就停、被围住冲几下放弃站住（用户已验证，Flee 整体 ✅）
- [x] 复测 Flee 受击掉头先转身后跑、无倒退（用户已验证）
- [x] 接通 `BMB.RealBlockWorld`：MC.SV.SetBlock 写入、id↔BMB.BlockTypes 映射、吃草改查脚下格、A* 头部格检查、MaxStepDown 40、mock/real 切换（bmb_use_real_world / bmb_world 命令）
- [ ] 真方块世界全链路复测：游荡（含从一格地板走下来）→ 受击逃 → 吃草 grass_block→dirt（同步/音效/存档）；`bmb_world mock` 回退正常
- [ ] 羊一格台阶自动跳（StepHeight 28 < 36 缺口）+ A* 3D 邻接
- **Status:** in_progress

### Phase 3: Zombie 迁移回新架构

- [ ] 将当前 Zombie 参数迁移到 BaseMob + 敌对状态机
- [ ] 参考本地 Minecraft 源码中的 Zombie AI
- [ ] 建立 Zombie 行为参数表
- [ ] 调整移动速度、攻击距离、攻击 tick、索敌范围
- [ ] 加入日光燃烧、门/障碍交互策略
- **Status:** pending

### Phase 4: 共享 MCGM Base 固化

- [ ] 从 Zombie 中抽出共享 NextBot base
- [ ] 抽出声音、脚步、索敌、避障、攻击冷却模块
- [ ] 为不同生物提供配置表
- **Status:** pending

### Phase 5: 模型和动画管线

- [ ] 确定 Blockbench/Crowbar/StudioMDL 流程
- [ ] 做第一只 Minecraft 风格 Zombie 模型
- [ ] 做 idle/walk/attack/hurt/death 动画
- [ ] 让脚步声和动画帧同步
- **Status:** pending

### Phase 6: 生物扩展

- [ ] 被动生物：Pig 或 Cow
- [ ] 远程敌对：Skeleton
- [ ] 特殊行为：Enderman
- [ ] 飞行/水生生物
- [ ] 26.1 系列完整生物清单
- **Status:** pending

## Key Questions

1. 动态 prop 能否通过短距离 hull trace + 临时绕行点解决？
2. Minecraft 原版速度和攻击 tick 映射到 Source 单位后是否需要手感修正？
3. 公开发布时模型、贴图和声音的授权路径如何处理？

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| 先做 Zombie 纵向切片 | Zombie 覆盖索敌、追击、近战、声音和基础移动，是最好的手感样机 |
| 先自研 NextBot 原型 | VJ Base 提供通用 SNPC 能力，但不能直接解决 Minecraft 风格移动 |
| 使用文件计划保存长期上下文 | 项目很长，聊天上下文会丢失，计划和进度必须落盘 |
| 动态 prop 用局部避障处理 | 玩家生成的 prop 不在地图 navmesh 中，不能只靠 `nav_generate` |
| 采用薄 Base + 组合行为模块 | 中立生物不是独立继承链，而是友好行为和敌对分支的组合 |
| 方块寻路自写 A* | 对方方块系统是运行时 IMesh 数据，GMod navmesh 不能覆盖动态方块 |
| 先做 mock IBlockWorld | 不等待方块系统真实接口，先固定 mob 侧需要的函数签名 |
| Sheep 作为架构切片 | 羊能同时验证 Wander、Flee、方块感知和 SetBlockAt 联动 |
| Base 命名为 BlockMob Base / BMB | 名字突出方块世界 mob base，内部前缀短且稳定 |

## Errors Encountered

| Error | Attempt | Resolution |
|-------|---------|------------|
| `attempt to call method 'FaceTowards' (a nil value)` | 1 | 用自定义 `FaceTarget` 替代不存在的 NextBot 方法 |
| 误写 `lua_refreshents` | 1 | 改为使用 `lua_refresh_file <path/to/file.lua>` |

## Notes

- GMod addon 实装路径：`D:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\gmod_addon`
- 工作区源码路径：`C:\Users\ADMIN\Documents\MC MOB IN GMOD`
- 本地 Minecraft 源码路径：`C:\Users\ADMIN\Downloads\Compressed\我的世界源码`
- planning-with-files-master 参考路径：`C:\Users\ADMIN\Documents\New project 2\planning-with-files-master`
- Opus 规格文档路径：`H:\工作视频\20251115毕业\gmod_mc_mob_spec(2).md`
- MCSWEP 接口文档：`H:\工作视频\20251115毕业\interface-usage.md`
- BMB/MCSWEP 对接补充：`H:\工作视频\20251115毕业\bmb_mcswep_对接补充.md`
