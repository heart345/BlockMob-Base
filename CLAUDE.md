# BMB / BlockMob Base

GMod (Lua) addon：为 MCSWEP 方块世界做 Minecraft mob 系统。双人协作项目——本仓库只负责 mob，方块/世界系统是另一个独立 addon（MCSWEP，命名空间 `MC`，朋友维护，对本项目是只读依赖）。

**每次开工先读 `docs/STATE.md`**（当前进度、未解 bug、下一步），本文件只放不随进度变化的约定。

## 系统边界

- 本仓库命名空间：`BMB`。不要向 `MC` 命名空间写入任何东西。
- MCSWEP 接口文档（权威、随朋友更新）：`D:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\mcswep-main\docs\interface-usage.md`，朋友的源码也在该 addon 目录可直接查证签名。改对接相关代码前先读它。
- 方块大小只从 **`BMB.GetBlockSize()` / `BMB.BS`** 取，规则是 `(MC and MC.BS) or 36.5`；当前 MCSWEP 已切 `MC.BS = 36.5`，mock fallback 也必须对齐。不要在业务代码写裸 `36/18/40/72/108` 这类尺寸派生常量；用 `BMB.BS * scale` 或"格数/cell 数"表达。坐标两层：world `Vector` ↔ cell 整数坐标 `bx,by,bz`。chunk 是 MCSWEP 内部概念，BMB 代码不感知。

## 架构铁律

- **薄 BaseMob（Nextbot 实体）+ 可组合行为模块 + 每类怪一个状态机。** 不做敌对/中立/友好三条平行继承链。中立怪 = 友好行为打底 + 受激惹切换敌对状态。思路对齐 Minecraft 的 Goal 系统。
- 行为模块（Wander / Flee / SeekTarget / Chase / 各类 Attack）必须可复用、无怪物特化逻辑；怪物差异全部表达在各自的状态机和参数里。
- 实体基于 Nextbot：移动走 `loco`，行为走协程 Think。

## 行为设计约定

- **目的地合法性在目标选择层保证，不在运动层兜底。** 任何移动类行为产出的目标都必须是验证过的可达格（可站立过滤 + A\* 验证），运动层只负责跟路径。不要再给运动层加刹车/探测类补丁来掩盖非法目的地。
- **Flee 按 MC PanicGoal 实现**：受击触发，在半径约 5 格（垂直 ±4）内采样随机可达点——与攻击者方向**无关**；采样顺序是先用 `IBlockWorld` 枚举可站立格、再从中随机抽、最后 A\* 验证，限制每次尝试次数（约 8~10），全部失败则本次不触发 flee（原地，符合原版）。到点后仍在惊慌窗内则再选下一个点；速度带 panic 倍率（羊约 1.25×）。
- **敌对基础切片 = SeekTarget + Chase + MeleeAttack + 怪物薄状态机**。`SeekTarget` 只做目标选择/保持，`Chase` 采用“视线直追优先、BMB A\* 兜底”的两层追击：看得到目标且前方短探测安全时用 `chase_direct` 每 tick 面向并直压目标，手感接近 MC；视线断开、前方墙/悬崖、迷宫/绕路、hop/drop 时才走短时间片 BMB A\* 重规划；目标在近处高处且 A\* 暂不可达时保持 target 进入 `chase_stalk` 贴底等待/短周期重查，不能清目标 idle，也不能对零水平向量假追。`MeleeAttack` 只做 attack range、vertical attack range、windup、cooldown、`DamageInfo` 和命中反馈。Zombie 等怪物实体只放参数、声音、目标类型和调度优先级；不要把追击/近战逻辑写回单个怪物里，也不要回退到旧 `mcgm_zombie` 的 navmesh/`Path("Follow")` 样机。攻击准备不能只看水平距离：高一整格/隔层目标应继续 chase/path，而不是在台阶下进入 `attack_ready`。近战挥击不是硬直：攻击 windup/cooldown 期间不能把 `BMBDesiredSpeed` 写成 0，也不能用长锁定窗口压住追击；MC 式敌对生物应边挥手边继续贴近目标。
- **Zombie Phase 2 近战/声音**：Zombie 进攻击范围且冷却结束时应同帧结算命中（`AttackHitDelay=0`），随后只受 `AttackCooldown=1.0s` 间隔限制；共享 `MeleeAttack` 仍要保留非零 windup 能力给未来生物。命中玩家后要用真实 `DamageInfo`、水平击退 + 少量竖直击飞、玩家受伤音效、轻微 `ViewPunch` / screen shake；水平击退当前取 `AttackKnockback=150`，目标是击退+击飞合计约 2-3 格，绝不要回到 330/240/210 的强拉扯。Zombie 发现范围当前是 `TargetRange=1350`（旧 900 的 1.5 倍），同层攻击距离是 `AttackRange=60`；正常 `AttackVerticalRange=28` 不能为了踩头被拉高，否则高一格平台会重新误进 `attack_ready`，玩家直接站在 Zombie 头上只走窄的 `AttackVerticalOverlapRange=86` + `AttackVerticalOverlapFlatRange=24` 特例。贴脸重叠时 `target - mob` 会退化成零向量，所以 chase/attack 过程中必须缓存最近一次有效的水平目标方向，命中时优先用缓存方向。玩家 `SetVelocity` 是叠加不是设置，击飞必须先 `SetGroundEntity(NULL)`，再 `SetVelocity(-target:GetVelocity())` 抵消残留速度，最后一次性 `SetVelocity(direction * horizontal + Vector(0,0,launchZ))`；不要再用多 tick correction 或 `SetPos` nudge 跟玩家 movement 抢帧。若要看诊断，控制台用 `bmb_melee_knockback_debug 1`（或直接设 `bmb_debug_melee_knockback 1`）；日志必须覆盖 `try` / `resolve` / `knockback apply` 三层，不能只在真正击飞时才打印。Zombie ambient 叫声按 MC 源码 `Mob#getAmbientSoundInterval() = 80 tick` 和 `random.nextInt(1000) < ambientSoundTime++` 的递增概率模型；Zombie 只提供 `SoundEvents.ZOMBIE_AMBIENT` 等音源。BMB 中 ambient 检查必须挂在 Base `Think` 的可选钩子上，不能只放行为协程顶部，否则 debug/held/stranded/长 chase 时会停叫。`chase_direct`、`attack_ready`、`chase_repath` 这类不走 A* 的直压入口必须走 `Chase.ApplySafePressure`，每 tick 用 `IsMovementTargetSafe` 复查实际 steering target；遇到断崖发布 `*_cliff` 并压掉水平速度，不能绕过 `path_cliff` 安全层。
- **Avoid（躲特定实体，如猫/兔躲玩家）是独立模块**，方向感知（找远离目标实体的可达点），不要和 Panic 合并。
- **Look 类模块（如 LookAtPlayer）是非独占的**，与移动类模块并行：移动时身体朝向归移动管，look 只控制头部；静止时头先转（骨骼操纵，clamp yaw ±75°/pitch ±40°），头到极限才由 `loco:FaceTowards` 带动身体跟转。状态机调度需支持"一个移动模块 + 一个注视模块"同时活跃。
- **物理枪持握（`BMBHeld`）是一等状态**：持握期间 loco 每 tick 缴械（`SetVelocity(vector_origin)` + `SetGravity(0)` + `SetDesiredSpeed(0)`，否则 loco 醒着会和物理枪拉扯成上下抽搐/陷地）、行为协程整体挂起、移动入口拒绝新请求；松手恢复原 gravity 并踹一脚向下速度唤醒可能睡眠的 loco（挂半空的个体才会正常下落）。held 必须与移动状态握手：拾起时 `InterruptBMBMovement` 掐掉当前 move（hop 重跳计数等局部状态随之销毁），不许后台继续计数。
- **受击反馈按 MC LivingEntity 语义收口**：红闪窗口对应 `hurtTime = 10 ticks`（0.5s），且应是命中后立刻固定红，持续到窗口结束，不做淡入/淡出曲线；伤害冷却按 MC 的有效窗口取 10 ticks（0.5s）——源码会把 `invulnerableTime` 设为 20，但只有 `invulnerableTime > 10` 的前半段挡同等/更低伤害，不能直译成 1 秒完全无敌。只有非冷却窗口内接受的伤害才扣血、红闪、触发 flee 和击退；冷却内重复命中直接忽略，不刷新 flee 方向。击退是短促冲量状态，优先级在 held 之后、debug/stranded/flee 之前，但只用很短窗口防 steering 吞掉冲量；窗口结束后即使还在空中也要让 flee 继续尝试移动。击退方向按来源取：爆炸优先爆心/伤害位置，枪击/近战优先攻击者→mob，必要时才用 damage force；地面受击带一点竖直上抬（`loco:Jump()` 打开跳跃态后再 `SetVelocity`），空中受击保留当前 z 速度；`DMG_CRUSH` 物理砸击保留 GMod/prop 伤害手感，不叠 BMB 击退。Flee 中受击只刷新恐慌时间/威胁来源，不额外打断当前 flee 段，避免连击时反复重选方向。摔伤先不要和击退绑在一起，后续作为单独伤害来源实现。
- 击退/硬直类状态不能把公开移动意图写成 0：`BMBDesiredSpeed` / `BMBActivitySpeed` 是 HUD、动画和后续行为接管的语义字段。击退窗口内要让 steering 让位，靠状态优先级和移动入口拒绝新命令；需要给 `loco:SetVelocity` 留速度预算时，只在内部设置 loco desired speed，并保留 NW desired/activity 原值。否则 HUD 会出现 `70/0`，击退速度也可能被 desired speed 0 吃掉，窗口结束后还会把正常移动拖死。

## 方块访问纪律（最重要的一条）

- **所有方块读写只走 `IBlockWorld` 接口。** 行为模块、寻路、状态机一律不许直接调用 `MC.*`。
- `IBlockWorld` 有两个实现：`MockBlockWorld`（开发/测试用）和 `RealBlockWorld`（adapter，内部用 `MC.*` 实现）。两者满足同一接口，切换只改一个变量。
- adapter 实现备忘：
  - `WorldToBlock` → `MC.WorldToCell`；`BlockToWorld`（中心）→ `MC.CellWorldCenter`
  - `GetBlockAt` → `MC.GetBlock(bx,by,bz)` 拿数字 id，再**映射回 `BMB.BlockTypes` 枚举**返回（行为层只认这套枚举；未建模的 id 原样透传当"其他方块"）
  - `IsSolid` 无现成函数：`GetBlock` 非空 → `GetBlockOrient` → `MC.BlockIsFullCube(id, orient)`。粗略版（半砖/楼梯按需细化，入口留 `MC.BlockBoxes`）
  - 半砖/楼梯/台阶需要"表面高度 / shape"语义，不是 `IsSolid` 二值能解决；MCSWEP 未暴露形状接口时不要在 path_cliff/path_wall 里塞特判。接口到位后扩 `IBlockWorld:GetFloorHeight` 或 shape 查询，A* 用真实表面高度差决定 walk/hop/drop。
  - 方块类型 id 首次用到时 `MC.ResolveBlock("grass_block").id` 解析并缓存，不要硬编码数字
  - 写入走 `MC.SV.SetBlock(bx,by,bz,id,orient,options)`（2026-06-11 起已就位），mob 实体直接当 options 传（= `{ actor = ent }`）；它会处理网络同步、碰撞 dirty、声音粒子、OnPlace/OnBreak、保存
  - `fx` 按行为语义决定，作为 `IBlockWorld:SetBlock` 可选参数透传、不在 adapter 写死：破坏类行为（如爆炸）用默认 true；羊吃草选择**原版手感版**，方块写入不走破坏 fx，必须由 mob 侧自己补低头吃草动画、咀嚼音效和草屑粒子
  - 返回 `ok, err`：`unchanged` 是正常竞态（目标格已被别人改），行为直接结束、不重试、不报错；`invalid_block` 打日志
  - mob 放置方块（非原地替换）时开 `preventPlayerOverlap = true`
  - 实现切换：`BMB.BlockWorld` 指向 `BMB.MockBlockWorld` 或 `BMB.RealBlockWorld`，由 `BMB.SelectBlockWorld()` + convar `bmb_use_real_world`（默认 1，MCSWEP 不在场自动回退 mock）决定；控制台 `bmb_world mock|real` 切换。MCSWEP 比 BMB 后加载，所以生成 mob 时会再选一次
- **仍然禁止**：
  - `MC.SV.Place/Break` 是玩家工具接口（cooldown/reach/权限校验），要传 `ply`——**禁止**传 nil 或 mob 实体硬套，mob 写方块只用 `MC.SV.SetBlock`。
  - `MC.SetBlockRaw` 不做网络同步和碰撞重建——联机会 desync，**禁止**在游戏逻辑中使用。

## 寻路与移动

- 寻路是自写 A*，跑在方块网格上。**不用 navmesh**（盖不住动态体素）。real 方块世界启用 3D 邻接：同层 `walk`、+1 格 `hop`、向下 ≤3 格 `drop`（MC 普通 `LivingEntity/Mob#getMaxFallDistance()` 默认 3；羊未覆写）；mock 仍是平面世界，避免调试地面被 z 轴语义污染。real 下 walk/hop/drop 的落点都要求**可站立**（passable + `IBlockWorld.HasSupport`：脚下 MC 实心，或 Source 刷子地面兜底——prop 不算支撑），搜索空间锁死在真实可走表面，目标格悬空时向下吸附到第一个可站立格。A* 必须带搜索预算（f = g+h 椭圆界）+ per-call passable/support 缓存 + 协程 yield 时间切片——预算管"无路"结论的总开销，yield 管单帧不卡，二者互补缺一不可。搜索中止时返回离目标最近的部分路径（标 `partial`，观感 = 走到崖边/尽头停住）；**Flee 必须 `allowPartial=false`**，否则撞墙被洗成成功冲刺、"被围住会放弃"失效。Wander 随机候选要主动偏向下层候选，否则 A* 能 drop，但游荡很少把目标选到台下。
- A* 重算必须限频（约 0.3–0.5s）且仅在目标 cell 变化时触发；每 tick 只消费已有路径。
- 路径跟随的总 timeout 不能用固定秒数猜长短；默认按剩余路径长度 / 速度 × 系数预算，是否卡死交给 no-progress watchdog。debug 右键目标尤其不能因面板 duration 到期而中止还在前进的长路径。
- debug 右键目标是人工测试命令，不能因一次 partial/dead-end/hop 失败就清空：默认给足长路径命令寿命（约 120s），到达目标或 debug 过期前持续 replan；推进节点/靠近目标时要续命，失败段只短暂停在 `debug_repath` 后重算。但若连续数秒没有推进节点、也没有明显靠近目标（例如目标在一格空洞/死路另一侧），要用 `debug_no_progress` 清掉命令并急停，不能在 `debug_repath` 假死到 120s。
- 移动全部交给 `loco`（`Approach` 每 tick 持续调用 + `SetDesiredSpeed`）；**禁止**手动 `SetPos`/`SetAngles` 驱动移动或转向（打断客户端插值），转向用 `loco:FaceTowards`。
- 速度分两层：`BMBDesiredSpeed` 是当前给 `loco` 的命令速度，可以因 `path_corner`、drop、局部安全控制短暂变化；`BMBActivitySpeed` 是行为/动画意图速度，用来决定 idle/walk/run/jump。Flee/Panic 这类“正在跑”的行为必须保持 `BMBActivitySpeed=RunSpeed`，并用 `minPathSpeed` 把过弯临时降速夹在 run 阈值上方，避免套皮后跑/走动作来回抖。
- `Approach` 的目标用前瞻点（carrot point），且 carrot 必须**沿路径折线推进**（pure pursuit）取点，不是直线瞄向前方第 N 个节点——直角处（如一格宽走廊入口）会切角撞墙。配合网格视线检查：mob 到 carrot 逐步采样，既要 hull 不撞 solid，也要沿线每个采样点按 A* 同一 standable 语义有支撑；被挡或中间是洞/悬空格，就把前瞻缩到最后可见可走点。直接瞄下一个 waypoint 也不行（永远在减速区内，速度锯齿）。
- **经 A\* 验证的路径，跟随层禁止再用 Source 射线否决 MC 方块通行**（路径上每格已保证方块 hull 可走）。但 A* 不知道 gm_flatgrass 的地图墙、平台边缘、玩家 prop，所以 `MoveAlongPath` 仍要保留 path 专用 Source safety：悬崖一律拦；墙命中若对应 `IBlockWorld` solid 方块则忽略（交给方块 hull 规则），若不是方块世界里的 solid（地图墙/prop）则拦。
- 急转弯要进入 `path_corner` 手感：提前约 2 格识别折线拐点，缩短 carrot 到约 1 格内、降低目标速度、临时提高 `loco` deceleration，避免带惯性切出走廊再来回矫正。
- waypoint 到达判定用 2D 距离（忽略 z），阈值取 hull 半径量级（约 `0.5 * BMB.BS`）。
- 方块通行必须按 **mob hull 占格** 判断，不是只查中心点所在 cell：水平按碰撞盒半径检查周围 solid cell，垂直按实体高度覆盖的 cell 检查。成年羊宽约 0.9 格（BMB 暂取 32u）能过 36.5u 走廊，但不能从一格高洞或方块角挤过去。
- `IsMovementTargetSafe` 是非 A* 直线移动/直追的安全门：Source trace 负责地图墙、prop 和普通 Source 断崖；当前或前方样本落在 MC 方块支撑附近时，还必须额外按 BMB standable 语义逐半格采样，避免 `chase_direct` / `attack_ready` 绕过 A* 从 MCSWEP 方块边缘掉下去。MC 网格安全采样必须用略高于脚底的 foot sample（约 `0.12*BS`，且至少 4u），不要把正好落在完整方块顶面边界的 `WorldToBlock` 结果当成 solid/not-standable，否则平地会误报 `*_cliff`。站在 GMod prop 上时不要启用这层 MC 网格检查，prop 仍交给 Source trace。
- **StrandedRecovery**：如果实体物理上站住（`IsOnGround`），但 BMB 方块语义认为当前脚部 cell 不是 standable（例如玻璃板/栅栏这类窄碰撞、脚下支撑失效后的非法位置），不要让 Wander/Flee 从非法起点空转，也不要把窄碰撞当成可走路线。BaseMob 只做本地 bail-out：采样周围 8 个短距离点，优先走到邻近合法 standable 点；否则选择没有物理支撑的一侧轻推下去，让重力落回合法地面。不要在 recovery 中周期性大半径扫格，也不要 direct steering 到远处合法格沿玻璃板网络走。普通 A* 仍不得主动把玻璃板顶面等窄碰撞当合法目标。
- 站在 GMod prop / `func_physbox` 等 Source 实体支撑上不触发 StrandedRecovery：这是“当前位置被物理托住，但 A* 不把 prop 当地形”的临时支撑，不是玻璃板/栅栏那类需要逃生的非法网格。A* 仍不得把 prop 写进 `HasSupport` 或规划为可走节点；若从 prop 起点找不到 BMB 路径，只允许 BaseMob 用短 `prop_direct` 兜底，并继续由 `IsMovementTargetSafe` / `path_cliff` 处理 prop 边缘和墙。
- Stranded bail-out 撞墙/卡住时不要永久停在 `stranded_bail_blocked`：记录失败方向短冷却，HUD 用 `stranded_bail_retry`，下一轮换方向重试。
- **跳一格用 BlockHop**：默认走错帧手写弹道，不再用 `JumpAcrossGap`（实测近距离一格爬升常 `apex=0` 不起弧）。流程：先 `loco:SetJumpHeight(1.5 * BMB.BS)` + `loco:Jump()` 打开跳跃态，下一 tick 进入两段式 manual hop：短时间只给竖直速度（必要时重复 `Jump()`，先让 hull 离开台阶侧面），抬到约 `0.8 * BMB.BS` 或过了 lift 窗口后再加水平速度落向上层格。hop 期间 `StepHeight` 必须临时压到 `0.49 * BMB.BS`（36.5 时约 17.9，严格小于半砖 18.25），落地/失败/中断恢复默认 28；默认 28 是 Source locomotion 绝对值，故意高于半砖、低于整格。这样避免 apex≈`1.5 * BMB.BS` 时叠加自动登阶误上两格；MC 里跳跃和自动登阶不叠加。水平速度按到上层格中心的距离 / 飞行时间计算并 clamp，避免 debug 助跑时跳很远。落点 z = 目标 foot cell 中心 z - 半格 + 2u。起跳不只看中心距，还必须看离方块面的 `faceDistance`：贴脸（约 `face < 0.75*BS`，36.5 下约 27u；日志里 `face≈16~20` 会失败）先退到 `face≈0.85*BS` 的 launch/backoff 点，成功样本通常在 `face≈31`。默认不要求已有水平速度，但不能在方块面前贴脸硬跳；唯一例外是 `blocked_close_lift`：横向已对准、目标仍在 hop 范围、且理想 backoff 点被 hull/safety/起跳净空判定不可用时，允许近距离起跳，避免一格狭窄空间既退不开也不跳。普通 blocked close 的 `face` 门槛约 `0.52*BS`；如果是 `backoffLift=false` 的低顶场景，`effClose` 可降到约 `0.48*BS`，避免实体在可跳点和撞头点之间来回摆。注意 standable/hull clear 只说明“能站”，不说明“能起跳”：两段式 hop 第一段有竖直 lift，launch 点必须 `currentLiftClear=true`；理想 backoff 如果 `backoffLift=false`（能站但会撞头），也算 backoff blocked，应改用较近的 lift-clear 点。落地却没站上目标格 = 这跳失败，以 `OnLandOnGround` 回调时刻为基准短延时（必须 < watchdog grace）后复位重跳，连续失败数次按路径失败交还行为层；但若已经落地、XY 贴近节点，且脚底高出目标 foot z 不超过约 `1.25*BS`，视作 hop 已产生进展并推进路径，避免物理解算偶发推上一层后 debug_repath。Debug HUD 会临时显示每次 hop 的起跳距离、face 距离、朝向速度、实际 apex 和结果；需要控制台日志时开 `bmb_debug_hop_log 1`，其中 `hop setup` 的 `backoffBlocked/backoffHull/backoffSafe/backoffLift/currentLift/effClose` 用来判断命中了哪类例外。
- BlockHop 起跳前必须对齐 launch line：横向偏移过大时先走 backoff/launch 点，距离过远也走 backoff，不要直接冲方块面然后“试一下”。
- **hop/drop 边是 A\* 明确授权的垂直动作**：跟随层处于 `path_hop` / `path_drop` 时必须豁免 `path_wall` / `path_cliff` Source safety（否则 hop 会被前方方块当墙点刹，drop 会被故意下落当悬崖取消）。下落边不加跳跃，只沿路径走出边缘并让重力落下；落地后再恢复普通 path safety。
- hop/drop 节点推进和最终到达必须验证实体实际脚底高度，不能只看 2D 距离或 `WorldToBlock` cell 相等；方块顶面边界会 floor 到低一格，cell equality 很容易让已落地的 hop 不被认账，表现为 `path_hop` / `debug_repath` 来回切。hop 对“没跳上去”保持严格，但允许 grounded 且 XY 贴近节点时的一格内向上 overshoot 算进展；drop 可用稍大的上容差，因为落地解算可能让脚底略高于目标 foot z，但这不代表下落边失败。
- drop 空中不要再用通用 air steer/FaceTowards 追 carrot：离边后保持朝向，只钳制过大的水平速度，不反向刹车，避免高处下来时空中回头转一圈或被完整行走惯性甩太远。
- 动画/activity 选择要状态驱动：Think/落地时根据 held、空中、落地速度选择 idle/walk/run/jump，不能只在事件里 StartActivity 后不收回。后续换 MC 模型时只改"状态→动作"映射，不让逻辑层依赖占位模型姿态。
- 碰撞手感保留 GMod/NextBot 默认：base mob 使用 `COLLISION_GROUP_NPC`。不要再加 player-like collision group、`SetCustomCollisionCheck`/`ShouldCollide` 禁硬碰撞、或玩家/mob 软分离推挤；这些方案已实测会破坏物理枪抓取、子弹伤害和 prop 物理伤害链路。玩家能踩/挤到 mob 属于当前接受的 GMod 手感。
- 性能规则：**不要节流整个 NextBot entity Think**，`Think` 必须 `NextThink(CurTime())` 保持逐 tick，否则 loco/身体插值会变成肉眼可见的一卡一卡。优化只能落在内部贵操作：A* 用全局较小 `PathfinderYieldEvery` 时间切片；Wander 单轮只做少量完整路径尝试，失败后随机退避；新生成友好生物先 idle 一小段时间并错开首次游荡；周期性 physics impact 球查找默认 0.3s 且生成时错峰，软分离默认约 0.08s 错峰，避免 20+ mob 同一帧一起想路/扫实体。移动协程仍逐帧，held 仍每 tick 缴械防物理枪抽动。
- mob 的 hull / jump / step 参数尽量对齐 MCSWEP 玩家的设定，否则寻路可达但实际走不上去。

## 开发与测试方式

- 默认对 `MockBlockWorld` + flatgrass 开发，mock 方块用调试框渲染。
- 新行为先在 mock 上验证，最后才接 `RealBlockWorld`。
- GMod 双 realm：注意 server/client 划分，mob 逻辑在服务端，调试 HUD 在客户端。
- 调试移动问题时优先在 HUD 上打点（vel / 目标速度 / dist_to_goal / 当前状态 / 切 waypoint 事件），不要靠肉眼猜。

## 里程碑参照

羊游荡（A*）→ 受击逃跑（状态机切换）→ 吃草（grass_block → dirt，经 `RealBlockWorld` → `MC.SV.SetBlock` 落地）。第二只怪用于验证 base 抽象是否成立——如果加新怪需要改 BaseMob 或行为模块，说明抽象有问题，先修抽象。
