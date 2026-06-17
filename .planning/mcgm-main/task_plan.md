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
- [x] 第二十五轮：StrandedRecovery（非法起点恢复）——当前脚部 cell 非 standable 但物理上 onGround 时，本地 8 方向 bail-out；优先走到邻近合法 standable 点，否则侧向离开窄支撑并下落；普通 A* 仍不把玻璃板顶当合法目标
- [ ] 复测第二十五轮：物理枪/工具把羊放玻璃板顶或挖掉脚下支撑后，`state=stranded` 后应进入 `mode=stranded_bail`，必要时 `stranded_fall`，不卡顿、不沿玻璃板网络当路走，落到合法地面后恢复 wander；普通 wander 不主动规划到玻璃板顶；旧 hop/drop/走廊/物理枪不回归
- [x] 第二十五轮 prop 支撑补丁：站在 GMod prop / `func_physbox` 等 Source 实体支撑上不触发 `stranded_no_escape`；A* 仍不把 prop 当支撑，当前步只用 `prop_direct` + `IsMovementTargetSafe` 兜底，边缘继续按 Source `cliff` 拦
- [ ] 复测 prop 支撑补丁：把 sheep/zombie 直接放到 `prop_physics` 顶面，应不进入 `state=stranded` / `mode=stranded_no_escape`；debug/wander/chase 可短距离移动，走到 prop 边缘应被 cliff safety 拦住或按允许落差下去；玻璃板/栅栏 StrandedRecovery 不回归
- [x] 第二十六轮：移动/性能收口——Stranded bail-out 撞障碍后记录失败方向并 `stranded_bail_retry` 换方向；drop 空中保持朝向不回头；BlockHop 起跳前按 lateral tolerance 对齐 launch/backoff；非 held Think 维护节流；新增 `scripts/check_movement_recovery_and_scaling.ps1`
- [x] 复测第二十六轮：用户确认玻璃板撞障碍不再永久卡住 ✅；高处 drop 不空中回头 ✅；复杂台阶 hop 先对准再跳 ✅；遗留 drop 水平惯性、debug partial/hop 早停、新出生立刻 wander、20+ sheep FPS 低
- [x] 第二十七轮：drop 空中水平速度钳制但不反向 steering；debug path 在到达/过期前持续 replan，partial/dead-end 进入 `debug_repath`；sheep 新生成 idle 4~9s；A* yield budget、wander attempts/failure pause、Think/physics impact 间隔和错峰做多 mob 峰值优化；新增 `scripts/check_drop_debug_spawn_perf.ps1`
- [x] 复测第二十七轮：用户确认 drop 不回头 ✅、debug 右键寻路 ✅、新 sheep 先 idle ✅、优化有效 ✅；发现回归：NPC 走路一卡一卡
- [x] 第二十八轮：修一卡一卡回归——恢复 `Think` 每 tick `NextThink(CurTime())`，禁止节流整个 NextBot entity Think；性能优化保留在 physics impact 内部间隔/错峰、A* yield、Wander attempts/failure pause、spawn idle；更新检查脚本防 `NextThink(CurTime()+self.ThinkInterval)` 回归
- [x] 复测第二十八轮：用户确认 NPC 不再卡、玩家也不卡 ✅；发现新问题：hop 多次贴脸失败、debug 复杂路径跑到一半回 wander、debug/path 会跨过一格空
- [x] 第二十九轮：BlockHop 增加 faceDistance 起跳准入（`face_close` 先退到更远 launch 点）；debug target 默认 120s 命令寿命并在路径推进/靠近目标时续命；carrot 视线检查增加沿线 standable 采样，防止抄近路跨一格空；新增 `scripts/check_hop_debug_gap_regressions.ps1`
- [ ] 复测第二十九轮：hop 不再 `face≈16~20` 贴脸硬跳多次；debug 不再半路过期回 wander；一格空洞不再被 carrot 跨过去；平滑移动和性能不回归（用户已确认 path 跨一格空没问题，debug gap 假死转入第三十轮）
- [x] 第三十轮：debug gap/dead-end 无进展时不再假死到 120s，新增 `DebugPathNoProgressTimeout` + `debug_no_progress`；碰撞第一版曾尝试 player-like collision group + 软分离，后续撤销
- [x] 复测第三十轮：debug 右键目标隔着一格空/死路时短暂 repath 后退出 debug，不假死 ✅；碰撞第一版失败，玩家仍能站在 sheep bbox 上
- [x] 第三十一轮：禁用 player/BMB 硬碰撞试验失败（物理枪抓不起、子弹不掉血、prop 物理伤害链路受影响）；回滚全部碰撞计划，恢复 `SetCollisionGroup(COLLISION_GROUP_NPC)`，删除 `SetCustomCollisionCheck`/`ShouldCollide`/软分离；脚本改为防止碰撞计划回归
- [ ] 复测第三十一轮回滚：物理枪恢复可抓；子弹/枪击恢复掉血；prop 物理伤害不受影响；debug gap 不回归；玩家踩/挤 mob 保留 GMod 手感
- [x] 第三十二轮：Flee 速度/动作意图稳定化——Base 新增 `BMBActivitySpeed`，把 animation/activity intent 与瞬时 `BMBDesiredSpeed` 分离；Flee 传 `moveIntentSpeed=RunSpeed` 并用 `minPathSpeed` 把 path_corner 降速夹在 run 阈值以上；新增 `scripts/check_flee_speed_stability.ps1`
- [ ] 复测第三十二轮：受击 Flee 期间目标速度/ACT_RUN 不再在 run/walk 阈值上下抖；path_corner 可以轻微降速但不切走路动作；Flee 围住放弃、悬崖/撞墙、hop/drop/debug gap 不回归
- [x] 第三十三轮：MC 式受击反馈第一版——受击红闪（`hurtTime = 10 ticks` / 0.5s）、有效伤害冷却（源码 `invulnerableTime=20` 但 `>10` 前半段才挡同等/更低伤害，BMB 取 0.5s）、非冷却窗口才触发击退；击退是一等状态，优先级 held 之后、debug/stranded/flee 之前；`DMG_CRUSH` 物理砸击不叠 BMB 击退；Flee 中受击只刷新恐慌窗口/威胁来源，不额外打断当前 flee 段；新增 `scripts/check_damage_iframes_knockback.ps1`
- [ ] 复测第三十三轮：普通攻击扣血红闪并远离攻击者击退；无敌帧内连击不扣血、不击退、不刷新 flee；爆炸从爆心径向击退；prop 物理伤害链路不回归；击退落地到非法格后 StrandedRecovery 能接住；Flee 中连击不再原地反复重选方向
- [x] 第三十四轮：修第三十三轮实测回归——受击红闪正常但 HUD `vel` 第二项变 0、NPC 停住且无击退。根因是 `RunBMBKnockback()` 用 `MaintainBMBMoveSpeed(0)` 把 `BMBDesiredSpeed` 发布成 0，同时可能吞掉 `loco:SetVelocity` 击退。改为保存 `BMBKnockbackDesiredSpeed` / `BMBKnockbackActivitySpeed`，公开速度意图保持非 0；内部单独给 loco 击退速度预算并启动当帧写入水平击退；检查脚本禁止红闪碰 movement/loco、禁止 knockback 写 `DesiredSpeed=0`
- [ ] 复测第三十四轮：受击红闪时 HUD 不再 `70/0`，普通移动/flee 能继续接管；非无敌帧命中能看见水平击退；无敌帧连击仍不扣血/不击退；prop 物理伤害、物理枪、debug gap 不回归
- [x] 第三十五轮：MC 击退手感收口——`DamageInvulnerabilityTime` 改 0.5；`KnockbackDuration` 缩到 0.12，避免长时间压住 flee；地面受击 `loco:Jump()` 后给竖直上抬（`KnockbackVerticalSpeedScale=6`，clamp 170~240u/s），第一下也立即写水平+竖直冲量；Flee 在空中恢复时传 `allowStrandedStart=airborneStart` 继续尝试逃跑
- [x] 复测第三十五轮：第一下生成后受击也有击退；受击有一点离地上抬；击退后不再长时间停住，空中/落地都会继续 flee；冷却约 0.5s；旧红闪、prop 伤害、物理枪、debug gap 不回归
- [x] 第三十五轮后 hotfix：Sheep Flee 目标速度满速化——`RunSpeed=100`、`FleeKeepFullSpeed=true`、恐慌窗口 `3.5-5.0s`；共享 Flee 支持 `FleeKeepFullSpeed`，避免 sheep 在 `path_corner` 时 HUD 目标速度从 100 掉到跑步阈值
- [ ] 复测 Sheep Flee 满速热修：受击后 HUD 目标速度应稳定显示 100，不再出现 81/90 式切换；Flee 应比旧 2s 更久但仍会在 3.5-5.0s 窗口后恢复普通行为；围住放弃、悬崖/撞墙、hop/drop/debug gap 不回归
- [ ] Fall damage / 摔伤：后续单独实现掉血来源，不和受击击退共用状态；摔伤不应触发击退
- [ ] 半砖/楼梯/MC 台阶表面高度寻路：等待 MCSWEP shape/floor height 接口（`MC.BlockBoxes` 或等价 API）；A* 从二值 solid/air 升级为 surface-height walk/hop/drop
- [ ] 玻璃板/栅栏 shape 接口接入后：PARTIAL/窄顶碰撞按"有碰撞但不可站立"，普通 A* 不规划其顶面；StrandedRecovery 负责已站上去的逃生
- **Status:** in_progress

### Phase 3: Zombie 迁移回新架构

- [x] 第三十六轮：新增 `bmb_zombie.lua`，继承 `bmb_base_mob`；旧 `mcgm_zombie.lua` 保留为 legacy 对照，不再作为新架构实现参考
- [x] 第三十六轮：新增共享 hostile 行为模块 `SeekTarget` / `Chase` / `MeleeAttack`，Zombie 状态机只负责参数、声音、目标和优先级调度
- [x] 第三十六轮：迁移当前 Zombie 手感参数第一版（20 HP、追击速度 115、索敌 900、攻击距离 38、伤害 10、cooldown 1.05、hit delay 0.38）
- [x] 第三十六轮：Spawn menu 注册 `BMB Prototype Zombie`，保留 `MCGM Prototype Zombie` 旧样机
- [x] 第三十六轮：新增 `scripts/check_zombie_phase1.ps1`，防止新 Zombie 回退到 navmesh/legacy 架构
- [x] 第三十七轮：修 Zombie 首轮实测问题——Base 红闪改为固定红 0.5s；Base activity 增加 per-mob 映射；Zombie `RunActivity=ACT_WALK` 防 Classic 模型追击腿不动；`MeleeAttack` 增加独立垂直范围，Zombie 攻击距离 52u、垂直范围 28u；`ChaseSegmentTimeout=1.0` 避免远处 chase 还没推进就重置
- [x] 第三十八轮：修 Zombie 二轮实测问题——近战不再 `BMBMeleeLockUntil`/速度 0，攻击期间保留 `AttackMoveSpeed=92` 前压；攻击 cooldown/hit delay 调快到 0.8/0.28；追击失败但目标有效时保持 target 进入 `chase_repath`；Base hop/drop final 和节点推进改用 `IsBMBVerticalPathNodeReached`，防止 final hop 2D 贴近但没跳就 idle
- [x] 第三十九轮：修 Zombie 三轮实测问题——`ChaseSegmentTimeout=2.0`、`ChaseFailureRepathDelay=0.05`、`TurnInPlaceAngle=170` 降低远距离追击停顿；`chase_repath` 期间继续 `SteerTowards`/`BodyMoveXY`；Base 增加 `BlockHopAllowCloseLaunch`，Zombie 开启贴脸 `close_lift` hop 兜底
- [x] 第四十轮：修 Zombie 追击策略——看得到目标且前方安全时优先 `chase_direct` 直盯玩家推进；墙/悬崖/迷宫/视线断开时回到 BMB A*；A* 失败且玩家近处高处不可达时进入 `chase_stalk` 贴底等待，保持 target 不清空、不对零向量 chase_repath
- [ ] 复测第四十轮：开阔地 HUD 主要显示 `chase_direct` 且不再远距离走走停停/平地乱拐；迷宫/绕墙仍能 `path_carrot/path_hop/path_drop` 绕路；高两格近处不可达显示 `chase_stalk`，不清目标长 idle
- [x] 第四十轮后 hotfix：修 Sheep 一格 hop 后 `path_hop` / `debug_repath` 来回切——`IsBMBVerticalPathNodeReached` 不再依赖 `WorldToBlock` z equality，改为落地后实际脚底 z 接近目标 foot z；`bmb_debug_hop_log 1` 增加 setup/velocity/reach 日志，用于确认一格空间是否退不到理想 face/backoff
- [x] 第四十轮后 hotfix 2：用户日志确认一格狭窄空间失败在 `reason=face_close face≈20-22 < minFace≈27.4` 且 backoff hull 不通；Base 新增受保护 `blocked_close_lift`（横向对准、`face>=0.52*BS`、backoff blocked 时才近距起跳），并让 drop completion 使用非对称高度容差
- [x] 第四十轮后 hotfix 3：用户确认普通一格 hop 通过，但低顶多级台阶里理想 backoff 点能站却会撞头；Base 新增 hop launch ceiling clearance 检查，`ready/close_lift/blocked_close_lift` 需 `currentLiftClear=true`，`backoffLift=false` 也算 backoff blocked，并优先用较近 lift-clear launch 点
- [x] 第四十轮后 hotfix 4：修低顶 hop 在 `face_close/lift_blocked` 间来回摆——`backoffLift=false` 时有效近距起跳门槛降到 `0.48*BS` 并记录 `effClose`；hop grounded 且水平贴近节点时允许约一格向上 overshoot 算进展，避免 debug_repath
- [ ] 复测 hop hotfix 4：低顶台阶 `face≈18.x currentLift=true` 应直接 `blocked_close_lift` 起跳，不再转几圈；落到目标上方一格应推进路径；一格狭窄/开阔 backoff/过贴脸拒跳/两格 hop/debug gap/carrot 防跨洞不回归
- [x] Zombie Phase 2：攻击进入范围立即同帧命中（`AttackHitDelay=0`），攻击间隔改为 `AttackCooldown=1.0`；命中玩家播放受伤音效，并给较克制水平击退（`AttackKnockback=240`）+ 竖直击飞；地面玩家先 `SetGroundEntity(NULL)` 并用 `AttackGroundedVerticalKnockback=190` 跨过 Source ground movement 阈值；ambient 叫声按 MC `Mob#getAmbientSoundInterval()=80 tick` + `random.nextInt(1000) < ambientSoundTime++` 模型，Base `Think` 任意状态检查
- [x] Zombie Phase 2 断崖 hotfix：`chase_direct` / `attack_ready` / `chase_repath` 统一走 `Chase.ApplySafePressure`，直线压迫前对实际 steering target 跑 `IsMovementTargetSafe`，遇到 cliff 发布 `*_cliff` 并压掉水平速度，避免无视 Source 断崖掉下去
- [x] Zombie Phase 2 hotfix 2：近身重叠命中缓存 chase/attack 方向，击退下一 tick 只补缺失水平/竖直速度；`IsMovementTargetSafe` 在 Source trace 后增加 MC 方块 standable 采样，只在 MC 支撑附近启用，避免直追绕过 A* 从 MCSWEP 方块边缘掉下去，同时不把 prop 顶面当 BMB 地形
- [x] Zombie Phase 2 hotfix 3：玩家受击改为 3 tick/0.03s 多 tick 缺口补偿，避免 Source 地面/重叠偶尔吞掉水平击退和 z 击飞；实际命中玩家加轻微 `ViewPunch` / screen shake
- [x] Zombie Phase 2 hotfix 4：玩家深贴 Zombie hull 时先做 trace 保护的 6u separation nudge，再写击退；新增 `bmb_debug_melee_knockback` 可选日志；screen shake / view punch 小幅上调
- [x] Zombie Phase 2 hotfix 5：MC 方块直追安全采样改用 lifted foot sample（约 `0.12*BS` 且至少 4u），避免完整方块顶面/边界被 `WorldToBlock` 量化到 solid cell 后误报 `chase_repath_cliff`
- [x] Zombie Phase 2 hotfix 6：玩家击飞改为确定速度写入（先 `SetGroundEntity(NULL)`，再 `SetVelocity(-velocityBefore)` 抵消残留，最后一次性写水平+z），删除旧 correction/nudge；新增 `bmb_melee_knockback_debug 1/0` 日志开关
- [x] Zombie Phase 2 hotfix 7：修 `ApplyTargetKnockback` 把 normalized 单位方向 `LengthSqr()==1` 当无效方向早退；方向验证统一改 epsilon，并记录 `direction_nil/direction_invalid`
- [x] Zombie Phase 2 hotfix 8：手感细调——Zombie 索敌范围扩到 `TargetRange=1350` / `TargetLoseRange=1725`，同层攻击距离调到 `AttackRange=60`，水平击退降到 `AttackKnockback=210`；共享 `MeleeAttack` 新增可选窄竖直重叠命中，Zombie 用 `AttackVerticalOverlapRange=86` + `AttackVerticalOverlapFlatRange=24` 解决玩家踩头不挨打，同时保持普通 `AttackVerticalRange=28` 防止高一格平台误攻击
- [x] Zombie Phase 2 hotfix 9：击退距离继续收敛——用户复测 210 水平击退配合 190z 滞空会推出约 4-5 格，目标是 2-3 格；Zombie `AttackKnockback` 改为 150，竖直击飞保持 155 / grounded 190
- [x] Zombie Phase 2 hotfix 10：Zombie 在 MC 方块顶面追击玩家时被打偶发触发跳跃——Base 新增 `KnockbackUseJump`，Zombie 关闭受击 `loco:Jump()` 并把受击竖直速度置 0；Zombie 攻击玩家的玩家击飞仍走独立 MeleeAttack 参数
- [x] Zombie MC 音效接入：复制并注册 `mob/zombie` 的 `death/hurt/say/step` 和 `damage/hit1-3`，统一重采样到 44100Hz；Zombie ambient/非致死受击/死亡/命中玩家/脚步都改用模组内 MC OGG，致死受击只播 death 不叠 hurt，脚步和程序化腿摆同源距离驱动，禁用 base 0.5s Source 脚步占位
- [ ] 复测 Zombie Phase 2：约 1350u 内应能发现玩家；同层约 60u 第一时间扣血；连续攻击约 1.0s 一次；命中有玩家受伤音效、轻微屏幕晃动、击退和小击飞，站地面/跳起两种情况都能体现 z 击飞，水平击退约 2-3 格且不再时好时坏；玩家直接踩头会被打，但站高一格平台/隔块目标仍走 chase/path；held/debug/stranded/chase/wander 中都能偶尔叫；高台边缘/窄桥桥头不再直线追玩家掉下去；完整 MCSWEP 方块平地/平台中间追击不应显示 `*_cliff` 停住；旧追击、hop、stranded、受击不回归
- [ ] 重新设计低顶/头顶方块坏 hop：A* hop-edge clearance 方案已撤回（会导致正常 hop 不触发），后续改用更局部的失败记忆/绕路目标或精确分诊
- [x] 参考本地 Minecraft 源码中的 Zombie AI 做第二轮参数校准（本轮确认 Zombie ambient 走通用 `Mob` 80 tick 递增概率；攻击节奏按用户 Phase 2 手感最终取 1.0s）
- [ ] 加入日光燃烧、门/障碍交互策略
- **Status:** in_progress

### Phase 4: 共享 MCGM Base 固化

- [ ] 从 Zombie 中抽出共享 NextBot base
- [ ] 抽出声音、脚步、索敌、避障、攻击冷却模块
- [ ] 为不同生物提供配置表
- **Status:** pending

### Phase 5: 模型和动画管线

- [ ] 确定 Blockbench/Crowbar/StudioMDL 流程
- [x] BMB 侧 sequence adapter：BaseMob 新增 opt-in `AnimationSequences`，按逻辑动作映射到模型 `$sequence` 别名；缺序列回退 idle；walk/run playback rate 按当前速度缩放；新增 `scripts/check_sequence_animation_adapter.ps1`
- [x] Sheep sequence 接线临时撤回：`AnimationSequences` / `AnimationReferenceSpeeds` 先注释，等转换器 pivot 和低速 playback/cycle 稳定后再打开；客户端保留 Base 连续 limb swing，并恢复程序化腿摆，头部 overlay 仅保留吃草/preview/后续看向接管
- [x] 模型接入后第一轮调整：程序化腿摆从二元摆幅（`speed>8?1:0`）改为随速度连续缩放，上提到 base 通用 `UpdateBMBLimbSwing(speed2D)`（连续相位 + 连续摆幅强度，牛/猪复用），频率仍随速度区分走/跑；sheep 改调 helper，删自维护 `BMBSheepLimbSwing*`；`check_sequence_animation_adapter.ps1` 护栏迁到 base 并加“禁止二元 `and 1 or 0`”断言（待用户游戏回归）
- [x] Sheep 吃草低头改俯仰轴（羊专属，不进 base）：`eat_grass` head 关键帧从 roll 改 pitch（`Angle(X,0,0)`）下俯够地，0.42s 到最低点、1.05s 收回；pitch 符号/度数依模型骨骼朝向，待用 `bmb_sheep_pose_preview` 游戏实测确认（可能翻号）
- [x] 模型接入实测迭代：腿摆走/跑都偏小 → sheep `legSwingMax 7→9` + `LimbSwingMinAmount=0.25`；吃草实测纠正——俯仰是 **roll 轴负值**（上轮误判 pitch 已回退），`eat_grass` 改为 preview 实测值的三段动画（`pos Y` 下探到 -12 → `roll -55` 够地 → `roll -55↔-40` 咀嚼两回 → rot+pos 一起收回，`duration 1.8`/`biteDelay 0.45`）
- [x] 模型接入实测迭代 2：sheep `legSwingMax=25.0`；`LimbSwingPhaseScale=0.13`，走/跑腿频率都降低；普通移动头部 swing 关闭，退出吃草/preview 后只清一次旧 head pose，不每帧锁死 head 骨；check 锁值同步到 25/0.13（待用户复测）
- [x] 模型接入实测迭代 3：腿频率再降 `LimbSwingPhaseScale 0.13→0.09`（走/跑都更慢）；修“头部 swing 关了但游戏仍晃”——根因是 live addon(D 盘)漏同步、游戏读到旧 `walkHead/idleHead`，本轮 robocopy 全量同步并验证 D 盘已是新代码；check phase-scale 锁值同步 0.09（待用户复测）
- [x] 死亡序列重做：脚本化骨骼倾倒（root 0→90° lerp 0.8s，整只翻、方向固定，关物理尸体）+ 停留 1.9s + Java poof 粒子（`vtf.py` 多帧 VTF、`generic_0..7`→`mc_poof.vtf/vmt`、effect 20 粒子 8 帧轮播 0.6s 淡出）；侧倒轴 roll 待实测（待用户复测）
- [x] Base 通用 LookAtPlayerGoal + 随机环视：看玩家只 NW 同步 EntIndex/timeout（首轮 15% 太频繁，本轮降到 6%、2-4s），客户端按玩家位置算方向；没看玩家时慢走/静止每 1-3s 低频同步随机 yaw ±60 / pitch ±15 或正前，快跑回正；head rot Z 上限 35→24；sheep normal 分支接入，吃草/死亡分支抑制（待用户复测调参）
- [x] Sheep sound 收尾：接入 MC `say1-3`、`step1-5`、`dig/grass1-4`；ambient/受击用 say；吃草咬草用 grass dig；脚步改客户端距离驱动（`speed * FrameTime()` 累积，阈值 35u）对齐腿摆，不再用计时器（待用户复测）
- [x] 做第一只 Minecraft 风格 Zombie 模型（转换器烘 `mcgm/zombie/zombie.mdl`；确认双足 body 不转；手臂改垂下、不烘 attack rest pose）
- [x] 僵尸动画走程序化（不烘序列）：base 泛化关键帧采样器 + 双足 locomotion；zombie 换模型、去 `ACT_WALK`、客户端 `UpdateBMBVisualBones`（双足腿臂摆 + lookat + 死亡侧倒 + 攻击前挥关键帧）；摆轴/前伸/攻击/侧倒初值待游戏迭代
- [x] 让脚步声和动画帧同步（当前 sheep/zombie 都走客户端 `speed * FrameTime()` 距离累积，阈值按腿摆半波长调；后续新 mob 继续按各自步态参数接）
- **Status:** pending

### Phase 6: 生物扩展

- [ ] 被动生物：Pig 或 Cow
- [~] 远程敌对：Skeleton
  - [x] M1 轨1：`bmb_arrow` SENT（trace 弹道/重力/命中/伤害，占位视觉）；`BMB.Behaviors.RangedAttack`（Update/SightMemory/ResolveMovement/DrawFire/Fire，chase 阻塞 + aim 一 tick）；`Flee.Run` 加可选 threat 参数；`bmb_skeleton.lua`（镜像僵尸链 + RunBMBSkeletonAI + 程序化手臂 + 头锁定 + ambient）；spawn 注册；M1 占位音效（待复测，只判对错）
  - [x] M1 轨2：转换器中性化骷髅手臂（geo.py 移除 skeleton_attack rest pose，62 tests OK）+ 重烘 `skeleton.mdl`（双足 rotate 0）+ swap `ENT.Model`（待复测）
  - [ ] M2：strafe 风筝 + 安全探测；弓挂手骨；逃狼实测；左撇子 5%；polish（拉弦手/真箭模型/弓弦 bodygroup/箭插表面）
  - [ ] 实测项（§10）：骷髅模型 LookAt/瞄准臂轴、箭速/伤害/散布、strafe 速度、转身速率
- [ ] 特殊行为：Enderman
- [ ] 飞行/水生生物
- [ ] 26.1 系列完整生物清单
- **Status:** in_progress

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
