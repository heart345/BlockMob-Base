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
- [x] 将 BMB 方块大小接到 `BMB.BS` / `BMB.GetBlockSize()`（当前跟随 MCSWEP `MC.BS=36.5`，mock fallback 36.5）
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
- [x] 复测 Sheep 枪击受伤后 Flee 是否稳定触发（用户已验证 ✅）
- [x] 复测高速 prop 砸中/砸死 Sheep 后是否沿原方向衰减而不是反向弹飞（用户已验证 ✅）
- [x] 修"走一会停一下换方向"：Wander 改回 A* 完整路径 + 到站停顿（Fable 2026-06-10，用户已验证）
- [x] 修原地扭动真根因：goalTolerance 12->18 消减速区死区；FaceTarget 改 loco:FaceTowards（用户已验证）
- [x] 修面朝前方倒退：SteerTowards 先原地转身再走（用户已验证）
- [x] 吃草频率调低：吃完冷却 25-45s（用户已验证）
- [x] 复测 MC 式游荡节奏：到站停顿 4-10s 生效，无 `path_blocked`/`path_no_goal_progress`（用户已验证）
- [x] 复测游荡微调：停顿 6-14s OK；单段距离用户要求上调，2-5 格 -> 3-8 格（第二十四轮改为 WanderDistanceMin/Max cell 数，随 BS 缩放）
- [x] 复测行进中"莫名转圈"修复：垂面跳点判定生效（用户已验证）
- [x] 复测跳崖修复：速度缩放安全探测 + FailBMBMove 急刹生效（用户已验证）
- [x] 复测 Flee 冻住第七轮真根因修复：getSafeDirection / MoveAlongDirection 的单位向量 LengthSqr 阈值 bug（1 -> 0.01）——用户已验证贴脸 prop 不再冻住
- [x] 复测第八轮墙/悬崖分治：离 prop/边缘不再远距离犹豫掉速——用户已验证边缘不急停、撞 prop 换方向
- [x] 复测第九轮 MC PanicGoal 式 Flee：受击随机近点 dash（不朝反方向）、平地跑 1-2 段就停、被围住冲几下放弃站住（用户已验证，Flee 整体 ✅）
- [x] 复测 Flee 受击掉头先转身后跑、无倒退（用户已验证）
- [x] 接通 `BMB.RealBlockWorld`：MC.SV.SetBlock 写入、id↔BMB.BlockTypes 映射、吃草改查脚下格、A* 头部格检查、MaxStepDown（第二十四轮为 `1.1*BMB.BS`）、mock/real 切换（bmb_use_real_world / bmb_world 命令）
- [x] 修一格宽走廊"出得来、进不去"：A* 路径跟随退役 Source 安全二次否决，carrot 改 pure pursuit + 网格视线缩短（待用户复测）
- [x] 修方块通行按中心点漏判：A*/随机候选/carrot 视线改用 mob hull 占格检查，sheep hull 调到 32u，Tool Gun 右键改走 A* debug path（待用户复测）
- [x] 修 path 退役 Source safety 过头：MoveAlongPath 加回 path 专用地图墙/悬崖复查，MC 方块命中交给 hull 规则，Source 地图墙/平台边缘仍拦截（用户已验证）
- [x] 真方块世界全链路复测：游荡（含从一格地板走下来）→ 受击逃 → 吃草 grass_block→dirt（同步/音效/存档）；`bmb_world mock` 回退正常（用户已验证 ✅）
- [ ] Flee 在坑/封闭结构中改为先枚举可站立格再随机抽样，减少"有出口但盲采失败直接放弃"
- [ ] 吃草原版手感版：羊自己补低头动画、草屑粒子和咀嚼音效（不靠破坏 fx 冒充）
- [x] 羊一格台阶自动跳（BlockHop；hop 期间 StepHeight = `0.49*BMB.BS`，普通 StepHeight 28）+ A* 3D 邻接 + ≤3 格 drop 边（待用户复测）
- [x] 第十六轮：修用户实测三 bug——hop 贴墙不跳（落地重跳 ≤3 次 + 起跳水平速度朝目标补足 + 空中转向只在离地时接管）；A* 不可达泛洪卡帧（walk 边要求可站立、`IBlockWorld.HasSupport` 认 Source 刷子地面、目标悬空下吸、per-call 缓存、f 预算 + yield 切片）；部分路径（走到崖边停住；Flee 关闭）（待用户复测）
- [x] 复测第十六轮：hop 贴墙重跳；>3 格高差右键不卡顿、有梯逐级下/纯崖走到边停；非 MC 地面右键可达；Flee 被围住仍会放弃；旧走廊/墙角/地图墙/悬崖保护不回归（用户已验证：不卡 ✅ 不跳楼 ✅ 下落正常 ✅；发现三个新问题 → 第十七轮）
- [x] 第十七轮：修绕路被 `path_no_goal_progress` 误杀（节点推进刷新 goal watchdog + timeout 0.9→1.2）；修窄 Source 沿走不了（HasSupport 中心悬空时补 ±12u 轴向偏移采样）；修 `path_hop` 不起跳（起跳保护窗 0.15s 内禁 Approach，防 SetVelocity 竖直速度被冲掉）（待用户复测）
- [x] 复测第十七轮：迷宫绕路不中途放弃；围墙窗台/窄沿恢复可走；hop 真起跳（贴墙也能上）；第十六轮成果（不卡/不跳楼/下落）不回归（用户已验证：绕路 ✅ 窄沿 ✅；hop 仍不起跳 → 第十八轮）
- [x] 第十八轮：hop 真根因 = 落地态 SetVelocity 竖直速度被地面解算压回，改 `loco:Jump()`+SetVelocity 弹道；删 0.15s 保护窗改查 `IsClimbingOrJumping`；重跳延时挂 `OnLandOnGround`；新增物理枪持握一等状态 `BMBHeld`（loco 缴械/行为挂起/移动拒新/松手踹醒，held×hop 握手）
- [x] 复测第十八轮：hop 有抬脚/离地动作但一陷一陷仍跳不上台；物理枪抽动大幅改善但仍有轻微弹簧感 → 第十九轮
- [x] 第十九轮：BlockHop 优先用 `loco:JumpAcrossGap(landingGoal, landingForward)` 原生跳到上层脚底落点，`SetJumpHeight` 至少 58u；原生 hop 期间不再 `SetVelocity` 空中弱控；物理枪 held 每 tick `SetGravity(0)` + `SetDesiredSpeed(0)`，drop 恢复 gravity
- [x] 复测第十九轮：物理枪上下抽完全修好 ✅；hop 有 `path_hop` 但低弧/概率上台/擦模，debug 反复点才偶尔成功 → 第二十轮
- [x] 第二十轮：BlockHop 起跳准入窗口（0.85~1.4 格 + 朝目标速度 ≥0.6×pathSpeed，不合格先退到 1.15 格助跑点）；JumpAcrossGap 落点改台面 +2u；JumpHeight 默认 `1.6*BlockSize`；HUD/日志记录 hop 起跳距离、face 距离、速度、实际 apex、成败（待用户复测）
- [x] 复测第二十轮：debug 有助跑能上；wander 慢速靠近多数上不去；native 近距离多次 apex=0，偶发成功样本 dist≈47/speed≈73/apex≈36；发现 wander 不主动下 2 格（debug 可下）→ 第二十一轮
- [x] 第二十一轮：BlockHop 默认改为 `Jump()` 开门 + 下一 tick 手写 `SetVelocity` 弹道（不再用 `JumpAcrossGap`），写速度后短窗口走空中 steering；取消已有速度硬门槛，仅保留距离窗口；水平速度按距离/飞行时间计算并 clamp，避免助跑跳很远；MC 源码确认普通 mob `getMaxFallDistance=3`，保持 `MaxPathDropCells=3`，real Wander 随机候选前 14 次偏向 1~3 格下层
- [x] 复测第二十一轮：wander 主动从 3 格内高处下落已实现 ✅；hop 仍全失败，manual `vz≈339` 已写入但 apex 多为 0、少数约 12 → 第二十二轮
- [x] 第二十二轮：BlockHop 改两段式 manual lift（下一 tick 先竖直抬升，仍 onGround 时短窗口重复 `Jump()`；抬到约 `0.8*BlockSize` 或 lift 超时后再加水平速度落点），避免 hull 过早顶住方块侧面吞掉上抛
- [x] 复测第二十二轮：NPC 已能跳上一格台阶 ✅；drop 主动下 3 格内 ✅；发现待调优：apex 偏高、偶发误上两格（A* 不主动规划两格）、debug move 长路径超时偏短、跳后动作保持偏久
- [x] 第二十三轮：hop 期间临时 `StepHeight=18`、结束/失败/中断恢复 28，避免 apex + 自动登阶误上两格；debug path timeout 改为路径长度/速度预算；Think/落地按 locomotion 状态重选 activity，收跳后动作残留（待用户复测）
- [x] 复测第二十三轮：用户确认当前未发现 bug ✅；一格 hop、误上两格、debug 远点早停、跳后动作残留暂未复现
- [x] 第二十四轮：MCSWEP 已切 `MC.BS=36.5`，BMB 改为单一尺寸入口 `BMB.GetBlockSize()` / `BMB.BS`；mock fallback 36.5；BaseMob 尺寸默认改 scale/cell（goal/node tolerance、carrot、corner、hop apex/lift/StepHeight、MaxStepDown），Sheep wander/flee 改 cell 数，mock/real/debug 跟随 BS；新增 `scripts/check_block_size_parameterization.ps1`
- [ ] 复测第二十四轮：控制台确认 `MC.BS` 与 `BMB.BS` 都为 36.5；hop 一格稳定、两格不上；半砖/楼梯走上去；36.5 走廊双向通行；drop 3 格主动下、4 格拒绝；吃草链路和坐标往返正常；mock/real 尺度一致
- [ ] 半砖/栅栏细化（`MC.BlockBoxes`）：A* 当前把半砖当空气，混半砖地形选择跳整格而非走半砖台阶（观感问题，hop 稳定后再做）
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
- 本地 Minecraft 源码路径（最新版）：`C:\Users\ADMIN\Downloads\Compressed\mcswep-main\out`
- planning-with-files-master 参考路径：`C:\Users\ADMIN\Documents\New project 2\planning-with-files-master`
- Opus 规格文档路径：`H:\工作视频\20251115毕业\gmod_mc_mob_spec(2).md`
- MCSWEP 接口文档：`H:\工作视频\20251115毕业\interface-usage.md`
- BMB/MCSWEP 对接补充：`H:\工作视频\20251115毕业\bmb_mcswep_对接补充.md`
