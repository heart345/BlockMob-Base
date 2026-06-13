# BMB 当前状态

> 每次开工先读这份（CLAUDE.md 指定入口）。历史流水/早期调试记录归档在 `.planning/mcgm-main/`（status_summary、findings、progress），只读参考，不再更新。

## 当前进度（2026-06-13）

- `bmb_sheep` 切片（mock 世界）：生成 ✅、Flee ✅（**第九轮 MC PanicGoal 式重写，用户已实测通过**：随机近点 dash、没路放弃、平地不跑远）、prop 物理伤害 ✅、速度锯齿 ✅、倒退 ✅、吃草频率 ✅、MC 游荡节奏 ✅、转圈 ✅、跳崖 ✅、贴 prop 冻住 ✅、障碍犹豫掉速 ✅。
- **第十轮（待复测）：RealBlockWorld 接通 MCSWEP，mock 首次切真环境**。朋友的 `MC.SV.SetBlock` 已就位（addon 在 `D:\...\addons\mcswep-main`，接口文档在其 `docs/interface-usage.md`，签名已对照源码 `mc/sv_world.lua:392` 验证）。目标：羊在真方块世界跑通"游荡 → 受击逃 → 吃草 grass_block→dirt"全链路。
- **第十一轮（用户已验证）：修"一格宽走廊出得来、进不去"**。根因在路径跟随层，不是 A*：`MoveAlongPath` 对 A* 路径每 tick 又跑 `IsMovementTargetSafe`，36u 走廊入口会被 `WallStopDistance=20` 的 Source hull 探测误判成墙；carrot 也可能从当前位置直线瞄向前方节点/终点外投，直角入口切角撞墙。修法：A* 路径跟随不再用 Source 安全探测二次否决；`GetPathCarrot` 改成 pure pursuit（先投影到当前路径折线，再沿折线前推）；再用 `IBlockWorld.IsSolid` 做网格视线检查，直线到 carrot 被方块挡住时二分缩短到最后可见的折线点。裸方向移动/legacy/debug direct 仍保留 `IsMovementTargetSafe`。
- **第十二轮（用户已验证）：修 debug 目标秒退 + 羊从一格高洞/方块角穿过**。上一轮仍按"中心点所在格"判断通行，没按成年羊宽高占格，所以会从 1 格高天花板下钻、从方块角擦过去；Tool Gun 右键也仍走 direct debug move，不是 A*。修法：`bmb_base_mob` 新增 `IsBMBHullClearAtPosition`，按实体水平半径和身高检查周围实心格；A*、随机候选、carrot 网格视线统一用 mob hull 通行；`bmb_sheep` hull 调到 32u 宽（MC 成年羊 0.9 格约 32.4u）；Tool Gun 右键目标改走 `MoveToWorldPosition` A*，点击面会略抬/推出到可站立空气格。
- **第十三轮（用户已验证）：修拐弯漂移/打滑**。用户确认第十二轮三项通过后，反馈方块走廊拐弯有惯性滑出去再反复矫正。修法：`MoveAlongPath` 新增 `path_corner` 过弯控制，提前约 2 格检测折线急转，靠近转角时动态降低目标速度、缩短 carrot 到约一格内，并临时提高 `loco` deceleration；直线段恢复 `path_carrot`。
- **第十四轮（用户已验证）：修 Source 地图墙/跳崖回归**。退役 path 里的 Source 安全复查后，A* 只知道 MC 方块，不知道 gm_flatgrass 地图墙和平台边缘，导致羊会沿 `path_carrot` 往地图墙/悬崖走。修法：`MoveAlongPath` 加回 path 专用 Source safety：前向 hull 命中若对应 `IBlockWorld` solid 方块则忽略（不误伤一格方块走廊），若不是方块 solid（地图墙/prop）则 `path_wall`；前向地面探测没地/坡太陡/落差 > `MaxStepDown` 则 `path_cliff` 并急刹。
- **第十五轮（用户已实测，发现三个 bug → 第十六轮）：A* 3D 邻接 + BlockHop / drop 边**。`sv_pathfinder` 在 real 方块世界生成 `walk` / `hop` / `drop` waypoint：+1 格高差标 `hop`，向下 ≤3 格有支撑落点标 `drop`；mock 仍固定平面。`MoveAlongPath` 新增 `path_hop` / `path_drop`，hop 用 45u 顶点的 `loco:SetVelocity` 弹道，空中弱控水平速度；drop 不跳，故意走出边缘让重力落下。hop/drop 消费期间豁免 `path_wall` / `path_cliff`，避免台阶被当墙、下落边被当跳崖；终点判定补上"垂直边必须落地且脚部 cell 到目标层"。real `GetRandomWalkablePoint` 开始抽当前层附近的可支撑候选，让 Wander 有机会自然跨上/跨下真实起伏地形。
- **第十六轮（用户已实测：不卡了、不跳楼了、下落正常 ✅；遗留三个新问题 → 第十七轮）：修 hop 贴墙不跳、右键高处/非 MC 地面整帧卡顿且不动**。
  - **hop 贴墙卡死**：根因是 `MoveAlongPath` 每个 hop 节点只跳一次（`hopStartedAt` 永不复位），第一跳撞方块面落回后永远走空中弱转向把羊往方块上蹭，且该分支每 tick 续 no-progress watchdog，连兜底失败都进不去；加上起跳"只保留水平速度"，贴墙时水平≈0，跳起来直上直下必然失败。修法：落地未推进节点超过 `BlockHopRetryDelay`(0.25s，必须 < watchdog grace 0.35) 复位重跳，连续 `BlockHopMaxAttempts`(3) 次失败按 `path_hop_fail` 交还行为层；`StartBMBBlockHop` 朝目标方向的水平分量不足行走速度时补足（已有横向速度照旧保留）；空中转向只在真离地时接管。
  - **A* 不可达泛洪 = 卡顿根因**：同层 walk 边过去只要求"可通行"不要求脚下有支撑，目标格悬空（点高处墙面被推出的空中格）或落在非 MC 地面（drop 边过去要求落点下方必须是 MC 实心，flatgrass 地皮不算）时目标永远不可达，搜索顺着空中格淹整片空域扫满 900 次迭代，每格又是十几次 `MC.GetBlock` 的 hull 扫描且无缓存——全在一帧 = 卡一下，然后返回 nil = 不动。修法五件套：① `IBlockWorld.HasSupport`（real：先查 MC 实心纯表查询，无实心才兜底一次 `MASK_SOLID_BRUSHONLY` TraceLine 认 Source 刷子地面，StartSolid=整格埋地不算；prop 不算支撑）；② 同层 walk 边要求 `isStandable`（passable+support），搜索空间锁死在真实可走表面，路径也不再可能悬空；③ 目标格悬空向下吸附 ≤12 格到第一个可站立格（点高墙面 = 走到墙根），吸不到快速失败；④ passable/support 进 per-FindPath 缓存（同格同次搜索只算一次）；⑤ 搜索预算 `f = g+h ≤ hStart*2+24`（椭圆界，"无路"结论不再扫满上限）+ 每 64 次迭代 `coroutine.yield()` 时间切片（大搜索摊到多 tick，单帧不卡）。预算和 yield 互补：预算管总开销，yield 管单帧。
  - **部分路径**：搜索中止时返回离目标最近已展开节点的路径（标 `waypoints.partial = true`，至少要比起点更接近目标才返回）。行为观感从"卡顿后拒动"变成"走到崖边/尽头停住"（原版手感）；高于 3 格的垂直落差仍按 MC 规则拒跳（要改上限调 `MaxPathDropCells`）。**Flee 显式 `allowPartial=false`**：partial 会把"撞墙"洗成"成功冲刺"，失败计数永远清零，破坏第九轮已验证的"被围住冲几下放弃"。
  - real `GetRandomWalkablePoint` 候选支撑判断统一走 `HasSupport`：站在高台上抽到平台外的同层悬空格在源头就被拒，不再依赖 A* 失败兜底。
- 另：用户已确认旧清单三项通过 ✅：枪击受伤 Flee 稳定触发；高速 prop 砸中/砸死沿原方向衰减不反弹；真方块世界全链路（游荡含走下一格地板 → 受击逃 → 吃草 grass_block→dirt 同步/音效/存档；`bmb_world mock` 回退正常）。
- **第十七轮（用户已实测：绕路不再误杀 ✅、窄沿恢复可走 ✅；hop 仍不起跳 → 第十八轮）：修第十六轮实测的三个新问题**。
  - **`path_no_goal_progress` 误杀绕路**（迷宫里走到一半、前面明明有路却放弃）：该 watchdog 要求每 0.9s 离终点直线距离至少近 10u，但绕墙的合法路径必然有"越走离终点越远"的段。修法：沿路径推进节点视为实打实进展，节点推进时刷新 watchdog（baseline 距离 + deadline）；watchdog 保留原本"防原地绕圈"用途（绕圈不会持续推进节点）。`PathGoalProgressTimeout` 0.9→1.2 给过弯减速段留余量。
  - **窄 Source 路完全走不了**（flatgrass 围墙窗台，上一轮还能走）：第十六轮回归——walk 边要求支撑后，`HasSupport` 的 Source 兜底只在格子中心打一条线，窄沿比 36u 格子窄、MC 网格中心可能正好悬在沿外侧 → 整条沿被判无支撑。修法：中心 StartSolid 仍判埋地不可站；中心悬空没命中时补 4 个轴向 ±12u 偏移采样，任一命中（非 StartSolid）算支撑。
  - **`path_hop` 状态有了但人不起跳，试几次放弃**：第十六轮回归——起跳那个 tick 还在地面，改成走 `SteerTowards`→`loco:Approach` 后，把 `SetVelocity` 直写的竖直速度在物理生效前冲掉了（第十五轮起跳 tick 走的是空中分支所以至少跳得起来）。修法：新增 `BlockHopLaunchWindow`(0.15s，必须 < RetryDelay 0.25)，起跳保护窗内强制走空中转向不许 Approach；窗口过后落地贴墙仍交回 SteerTowards + watchdog（保留第十六轮的防卡死语义）。
- **第十八轮（用户已实测：hop 有抬脚/离地但一陷一陷仍上不去；物理枪好很多但仍轻微弹簧抽动 → 第十九轮）：hop 真根因第一版——落地态 `loco:SetVelocity` 写竖直速度无效**。用户四张截图证实：整块方块的 hop 从未真正离地（hop2/3 有状态无动作）；半砖两次"跳跃成功"其实是 `StepHeight=28 > 半砖18` **走**上去的（hop4：明明能走上去却显示跳跃失败、人却已在上面）。NextBot 落地态的地面解算会把直写的竖直速度当帧压回地面，保护窗（第十七轮）治标没治到本。修法：`StartBMBBlockHop` 先 `loco:SetJumpHeight(apex)` + `loco:Jump()` 把 locomotion 切进跳跃态，再 `SetVelocity` 覆盖成固定弹道（45u 顶点 + 朝目标补足的水平分量）。CLAUDE.md 的 BlockHop 约定同步改。另查证 MCSWEP 源码：`BlockIsFullCube` 对半砖返回 false → BMB 把半砖当空气，A* 看不见半砖，混半砖地形会选择跳整格而不是走半砖台阶——观感问题，遇到再用 `MC.BlockBoxes` 细化。
  - 顺手拔掉两根刺（另一 Fable 建议）：① 0.15s 起跳保护窗删除——`loco:Jump()` 同步置跳跃态，空中分支直接查 `loco:IsClimbingOrJumping()`（起跳当帧强制视为真，防引擎标志晚一帧），不再留"窗口与真实物理不一致谁说了算"的隐患；② 重跳延时改以 `OnLandOnGround` 回调时刻为基准（`BMBLastLandTime`），不靠 `IsOnGround` 轮询猜时序。
  - **新增物理枪持握一等状态 `BMBHeld`**（用户反馈：抓起来的羊有的上下抽搐/陷地、有的安静悬挂——取决于被抓瞬间 loco 醒/睡，醒的会和物理枪持握点拉扯）。`PhysgunPickup`/`PhysgunDrop` 钩子 → `OnBMBPhysgunPickup/Drop`：持握期间 base Think 每 tick `loco:SetVelocity(vector_origin)` 缴械、羊行为循环挂起（state=held）、`MoveToWorldPosition`/`MoveAlongDirection` 拒新请求；拾起时 `InterruptBMBMovement` 掐掉当前 move（hop 重跳计数等局部状态随协程销毁，不会后台数失败）；松手 `SetVelocity(0,0,-10)` 踹醒睡眠 loco，挂半空的正常下落。
- **第十九轮（用户已实测：物理枪上下抽完全修好 ✅；hop 仍低弧/概率上台/擦模 → 第二十轮）：BlockHop 改用 `loco:JumpAcrossGap` + 物理枪 held gravity/desired speed 归零**。第十八轮 `Jump()+SetVelocity` 让脚离地但表现为节律性小陷跳，符合"竖直速度起效一两 tick 又被 locomotion/地面解算压回"的签名。修法：`StartBMBBlockHop` 优先调用 NextBot 原生 `loco:JumpAcrossGap(landingGoal, landingForward)`，落点给上层脚部格的地表点（foot cell center z - 半格），`SetJumpHeight` 抬到至少 58u；原生 hop 期间只转向/刷新 watchdog，不再 `SetVelocity` 弱控水平，避免和原生跳跃解算抢方向盘。没有 `JumpAcrossGap` 的旧引擎才 fallback 到 `Jump()+SetVelocity`。物理枪 held 进一步每 tick `SetGravity(0)` + `SetDesiredSpeed(0)`，松手恢复原 gravity，压掉残留弹簧感。
- **第二十轮（用户已实测：debug 有助跑能上；wander 靠近常上不去；native 近距离多次 `apex=0`，偶发成功 `apex=36` → 第二十一轮）：BlockHop 起跳准入 + 落点/高度余量 + 分类 HUD**。用户截图显示失败处已进入 `path_hop`，且成功需要反复 debug 点击、弧线很低并会擦进模型，说明主要问题在跟随层触发点/速度/落点，不是 A* 完全没标 hop。修法：① `JumpHeight` 写成 `1.6 * BlockSize`（约 58u）；② `JumpAcrossGap` 落点改为上层格中心、z = 台面 +2u；③ 起跳准入窗口：2D 距离约 `0.85~1.4` 格，朝目标速度 ≥ `0.6 * pathSpeed`，太近/太慢先退到约 `1.15` 格的 backoff/助跑点再跳；④ Debug HUD 增加 `hop# native/manual d face v apex result`，并提供 `bmb_debug_hop_log 1` 控制台日志，把"概率"拆成起跳距离、速度、实际顶点和成败。
- **第二十一轮（用户已实测：drop 主动下 3 格内 ✅；hop 仍全部失败 → 第二十二轮）：BlockHop 改错帧手写弹道 + Wander 主动下层采样**。第二十轮 HUD/日志结论：`JumpAcrossGap` 在 `dist≈36/face≈18/speed≈50` 的近距离爬台多次 `apex=0`，只有 `dist≈47/face≈29/speed≈73` 的助跑样本成功且 `apex≈36`，所以 native jump 对一格爬升不可靠。修法：默认不再调用 `JumpAcrossGap`；先 `loco:Jump()` 打开跳跃态，下一 tick 按弹道公式 `SetVelocity`（竖直顶点 `1.6*BlockSize`，水平速度 = 距离/飞行时间并 clamp 到 `32..1.1*pathSpeed`），速度写入后给一个极短空中控制窗口，避免同一轮 path loop 又把它交回 `Approach` 压掉上抛；同时取消“必须已有 0.6×pathSpeed”的起跳硬门槛，wander 慢速靠近也能跳。实测日志显示 `hop velocity ... vz≈339` 已写入，但 `apex=0~12`，说明问题不是速度数值，而是水平过早顶住方块侧面/地面解算把上抛磨掉。另查 MC 源码：`Entity#getMaxFallDistance()` 默认 3，`LivingEntity#getComfortableFallDistance(0)=3`，`Mob` 无目标时用 3，羊未覆写；BMB 的 `MaxPathDropCells=3` 保持不变，real `GetRandomWalkablePoint` 下层偏置已让 Wander 主动下落生效。
- **第二十二轮（用户已实测：一格高 BlockHop 成功 ✅）：BlockHop 两段式 manual hop**。`ApplyBMBPendingBlockHop` 不再立刻给水平速度，而是建立 `BMBActiveBlockHop`：第一段 lift 只给竖直速度，短窗口内如果仍在地面就重复 `loco:Jump()`；达到约 `0.8*BlockSize` 抬升或超过 lift 时间后，第二段再加水平速度/弱转向落到上层格。实测日志 `apex≈54~65`，NPC 已能跳上一格台阶。保留问题：弧线偏高，偶发能误上两格（A* 不会主动规划两格 hop）；跳完动作会多保持一段时间，套皮后要复查观感。
- **第二十三轮（用户已实测：当前未发现 bug ✅）：StepHeight / timeout / activity 收口**。按 Fable 诊断，误上两格是 apex≈55 与空中 `StepHeight=28` 叠加：脚部高度超过 `72-28=44` 后落地解算会 step 上两格台沿。因此不削掉一格 hop 需要的 apex，而是在 hop 状态临时把 `loco:SetStepHeight(18)`，成功/失败/中断/路径结束恢复默认 28。debug 右键长路径不再把面板 duration 当硬截断：路径 timeout 改为路径长度 / 速度 × 系数 + base，仍由 no-progress watchdog 判断真卡住。跳后动作残留改为 Think/落地的状态驱动 activity 选择，落地后按速度回 idle/walk/run。用户复测：一格 hop、误上两格、debug 长路径、跳后动作均未再暴露问题。
- **第二十四轮（代码已切：36.5 / BS 参数化，待用户游戏回归）：MCSWEP 已把 `MC.Config.BlockSize` 切到 36.5，BMB 同步收口到单一尺寸入口**。`BMB.GetBlockSize()` 每次优先读 `(MC and MC.BS)`，mock fallback 改 36.5，并同步 `BMB.BS` / 兼容字段 `BMB.Config.BlockSize`；业务代码不再直接读 `BMB.Config.BlockSize`。BaseMob 的尺寸派生默认改为 scale/cell：goal/node tolerance = `0.5*BS`，carrot min/max = `2*BS` / `25/6*BS`，corner slow = `2*BS`，hop apex/jumpheight = `1.5*BS`，manual lift = `0.8*BS`，hop 临时 StepHeight = `0.49*BS`（36.5 时约 17.9 < 半砖 18.25），`MaxStepDown = 1.1*BS`；默认 StepHeight=28 保留为 Source locomotion 绝对值（仍 > 半砖、< 整格）。Sheep 的 wander/flee 半径改用 cell 数（3~8 格、panic 5 格、min 1 格）。Real/Mock block world、debug HUD/tool、HasSupport 轴向偏移也改为跟随 BS。新增 `scripts/check_block_size_parameterization.ps1` 防止旧尺寸 fallback 回归。已从朋友源码确认 `D:\...\mcswep-main\lua\mc\sh_config.lua` 中 `MC.Config.BlockSize = 36.5`。
- **第二十五轮（代码已切：StrandedRecovery，待用户游戏回归）：半砖/MC 台阶走不上是表面高度接口缺失，不在本轮硬修；先解决玻璃板/脚下支撑失效导致的非法起点冻结**。新增 `BMB.Pathfinder.IsStandablePosition` / `FindNearestStandable`，BaseMob 在 `IsOnGround` 且当前脚部 cell 非 standable 时进入 `stranded` 状态。复测发现两版问题：① 只检测不够会卡在 `stranded_no_target`；② 大半径搜索 + 远点 direct 会卡顿，并让实体沿玻璃板网络走下去。现改为本地 bail-out：采样周围 8 个短距离点，优先走到邻近合法 standable 点；否则选择没有物理支撑的一侧轻推下去，进入 `stranded_fall` 后靠重力落回合法地面。普通 Wander/Flee A* 仍不会主动把玻璃板顶、栅栏顶等窄碰撞规划为合法节点。新增 `scripts/check_stranded_recovery.ps1` 防止调度/bail-out 语义回退。
- **第二十六轮（用户已实测核心移动通过）：StrandedRecovery 卡障碍、drop 空中回头、hop 起跳对齐、多 mob 性能首轮优化**。玻璃板上撞障碍后不再永久 `stranded_bail_blocked`：记录失败方向短冷却，HUD 进入 `stranded_bail_retry`，下一轮换方向。`path_drop` 离边后改用 `MaintainBMBDropAir`，不再 FaceTowards/air-steer 追 carrot，避免高处下来空中回头转一圈。BlockHop 起跳新增横向对齐窗口，横向偏离或距离过远时先走 backoff/launch 点，不直接冲方块面“试一下”。用户确认玻璃板撞障碍、高处 drop 回头、复杂台阶 hop 对齐均通过；遗留 drop 水平惯性和性能。
- **第二十七轮（用户已实测功能通过，发现移动一卡一卡 → 第二十八轮）：drop 水平惯性、debug partial/hop 早停、新出生 idle、多 mob 峰值优化**。`MaintainBMBDropAir` 保持不转身，但把空中水平速度钳到目标速度的一小段，避免从高处掉下时被完整行走惯性带太远。debug 右键 path 不再一次 `MoveToWorldPosition` 后无论成败都清空命令：到达目标或过期前持续 replan，partial/dead-end/hop 失败只进入 `debug_repath` 短暂停顿。新生成 sheep 默认 `idle` 4~9s，debug/stranded/flee 仍优先。性能分摊保留：physics impact 周期查找 `0.3s` 且生成时错峰，A* `PathfinderYieldEvery=24`，Wander 单轮最多 2 次完整路径尝试并对失败随机退避。
- **第二十八轮（代码已切，待用户游戏回归）：恢复 NextBot entity Think 每 tick，修第二十七轮一卡一卡回归**。根因：把整个 `Think()` 调度改成 `NextThink(CurTime()+0.2)` 等于把 NextBot 实体更新降到 5Hz，loco/身体插值表现为走路一顿一顿。修法：`Think` 末尾恢复 `NextThink(CurTime())`；性能优化不再节流实体 Think，只保留内部贵操作的节流/错峰（physics impact、A* yield、Wander attempts/failure pause、spawn idle）。`scripts/check_drop_debug_spawn_perf.ps1` 和 `scripts/check_movement_recovery_and_scaling.ps1` 已改为禁止 `NextThink(CurTime()+self.ThinkInterval)` 回归。
- **第二十九轮（代码已切，待用户游戏回归）：hop 贴脸反复失败、debug 半路过期、carrot 跨一格空**。用户日志显示失败 hop 多为 `face≈16~20/speed≈0/apex=0`，成功样本为 `face≈31/speed≈111/apex≈50`，根因是起跳准入只看中心距，允许 hull 已贴近方块面时硬跳；现新增 `BlockHopLaunchMinFaceDistanceScale=0.75` / `IdealFaceDistanceScale=0.85`，`face_close` 时先退到更远 launch 点再跳。debug 右键目标默认命令寿命改为约 120s，并在推进节点/靠近目标时用 `DebugPathProgressGrace` 续命，避免复杂路径跑一半过期回 wander。carrot 直线可见从“没有 solid 挡住”升级为“沿线 hull clear 且每个采样点 standable”，防止路径跟随为抄近路跨一格空洞；新增 `scripts/check_hop_debug_gap_regressions.ps1`。
- **第三十轮（debug 已验证通过；碰撞计划后续撤销）：debug gap 假死 + MC 式碰撞试验第一版**。用户确认普通 path 已不会跨一格空，但 debug 期间走到空洞/死路前会卡在 `debug_repath`。根因是第二十九轮把 debug 命令寿命放长后，缺少命令级“无进展”出口：一段段失败会持续到 120s。现保留 `DebugPathNoProgressTimeout=3.5`，debug path 只把“推进节点/明显靠近目标”算进展并续命；连续无进展则 `debug_no_progress` 急停并清掉命令，回到普通行为。碰撞方面曾尝试 `COLLISION_GROUP_PLAYER` + 软分离，但后续实测会继续引出硬支撑/物理交互问题，已撤销。
- **第三十一轮（已撤销）：禁用 player/BMB mob 硬碰撞试验失败**。用户复测确认第三十轮 debug gap 修好 ✅，但碰撞试验导致物理枪抓不起、子弹不掉血，并和 prop 物理伤害链路冲突。结论：不继续做 MC 式实体穿插，保留 GMod/NextBot 默认手感。代码恢复 `SetCollisionGroup(COLLISION_GROUP_NPC)`，删除 player-like collision group、`SetCustomCollisionCheck`/`ShouldCollide` hook、软分离函数与 Think 调用；`scripts/check_debug_gap_and_collision.ps1` 改为防止碰撞试验代码回归，同时继续保护 debug gap 修复。
- **第三十二轮（代码已切，待用户游戏回归）：Flee 速度/动作意图稳定化**。用户反馈 flee 状态速度不稳定，后续套皮会导致羊动作异常，也会污染 Base。根因是 Flee 虽然以 `RunSpeed` 调 `MoveToWorldPosition`，但通用 `path_corner` 会把瞬时 path speed 降到 `RunSpeed*0.55`（sheep 约 49.5），低于 walk/run 阈值（约 80），导致 HUD 目标速度和 activity 在跑/走之间波动。现 Base 新增 `BMBActivitySpeed`：`BMBDesiredSpeed` 继续表示 loco 当前命令速度，`BMBActivitySpeed` 表示行为/动画意图速度；activity 选择改用意图速度。Flee 传 `moveIntentSpeed=RunSpeed`，并用 `minPathSpeed` 把过弯临时降速夹到 run 阈值以上，既保留 corner 控制，又不让 panic/run 动画抖。新增 `scripts/check_flee_speed_stability.ps1`。
- **第三十三轮（代码已切，待用户游戏回归）：受击红闪 / 伤害冷却 / 水平击退 + Flee 连击不重选方向**。MC 源码确认 `hurtTime = 10 ticks`；`invulnerableTime` 字段会设为 20，但 `LivingEntity` 只有 `invulnerableTime > 10` 时挡同等/更低伤害，所以 BMB 对应红闪 0.5s、有效伤害冷却 0.5s。`OnTakeDamage` 只有在非冷却窗口内才扣血、开启客户端红色调制、触发 flee 和击退；冷却内重复命中 `return 0`，不刷新 flee。击退是一等状态：sheep 调度顺序为 held → knockback → debug/stranded/flee，击退窗口内普通 path/steering 拒绝新移动，水平速度按来源方向重置并 capped，不和旧速度累加；`DMG_CRUSH` 物理砸击保留原 GMod/prop 伤害链路，不叠 BMB 击退。Flee 中受击会刷新恐慌窗口/威胁来源，但不再额外 `InterruptBMBMovement` 当前 flee 段，避免连续受击时反复重选目标方向导致原地犹豫。新增 `scripts/check_damage_iframes_knockback.ps1`。摔伤仍是待办，本轮不实现。
- **第三十四轮（代码已切，待用户游戏回归）：修受击后 `vel:70/0` 和击退不生效**。用户实测红闪/无敌帧正常，但每次闪红都会让羊静止，HUD 显示当前速度/目标速度如 `70/0`，且看不到击退。根因不是红闪渲染越界：`StartBMBHurtFlash()` 只写红闪 NWFloat；真正把第二个数写 0 的是 `RunBMBKnockback()` 中的 `MaintainBMBMoveSpeed(0)`。这既把 HUD/行为意图速度变成 0，也可能让 `loco:SetVelocity` 的水平击退被 desired speed 0 吞掉。修法：击退状态不再发布 `BMBDesiredSpeed=0`，而是保存受击前的 `BMBKnockbackDesiredSpeed` / `BMBKnockbackActivitySpeed` 供 HUD/动画继续显示原意图；内部单独给 loco 一个 `BMBKnockbackLocoSpeed` 预算以允许水平 `SetVelocity` 生效，并在击退启动当帧立即写一次水平速度。新增检查确保红闪函数不碰 movement/loco，且 knockback runner 不再写 `MaintainBMBMoveSpeed(0)` / `SetDesiredSpeed(0)`。
- **第三十五轮（代码已切，待用户游戏回归）：击退手感对齐 MC：0.5s 冷却、短窗口、竖直上抬、空中继续 flee**。用户复测确认 `vel` 不再变 0，但受击后仍有停顿；MC 26.1.2 实测/源码显示有效无敌约 0.5s，受击会有上抬离地，且空中仍尝试逃跑。修法：`DamageInvulnerabilityTime` 改 0.5；`KnockbackDuration` 从 0.35 缩到 0.12，只保留防 steering 吞冲量的短仲裁窗口；新增 `GetBMBKnockbackVerticalVelocity()`，地面受击用 `loco:Jump()` 开跳跃态后给约 `6*BS`、clamp 到 170~240u/s 的竖直速度，空中受击保留当前 z；Flee 在 knockback 结束后若仍在空中，传 `allowStrandedStart = airborneStart`，让 A* 从 unsupported/airborne 起点继续尝试逃跑，而不是原地等落地。
- 本轮修掉的对接隐藏 bug（接 real 之前就存在）：
  1. **mock 占死 `BMB.BlockWorld` 名字、无切换机制** → mock 改名 `BMB.MockBlockWorld`；新增 `BMB.SelectBlockWorld()` + convar `bmb_use_real_world`（默认 1，MCSWEP 不在场回退 mock）+ 控制台 `bmb_world mock|real`。MCSWEP 比 BMB 后加载（addons 字母序），所以 `BaseInitialize` 生成 mob 时会再选一次（幂等）。
  2. **类型枚举对不上**：real `GetBlockAt` 原来返回数字 id，行为层比较的是 `BMB.BlockTypes.Grass` 字符串，永远不相等 → adapter 现在做 id↔枚举双向映射（`blockTypeToId`/`idToBlockType`），未建模的 id 原样透传。
  3. **吃草坐标差一格**：real 世界里 `WorldToBlock(GetPos())` 是脚部所在的**空气格**，不是脚下的草方块 → EatGrass 改为 `GetPos() - Vector(0,0,4)` 再换算（mock 忽略 z，行为不变）；并把 mob 作为 actor 传入 `SetBlockAt`（real 转成 MCSWEP 的 `{actor=ent}`，带进 OnPlace/OnBreak 和声音粒子）。
  4. **寻路没查头部格**：A* 新增 `isPassable` = 脚部格 + 头部格都非实心（mock z=1 恒空，行为不变）。
  5. **`MaxStepDown` 34 < 36**：站在一格高方块地板上会把"走下来"判成悬崖永远不下来 → 先改 40；第二十四轮参数化为 `1.1 * BMB.BS`（36.5 时 40.15，>1 格且 <2 格）。
- real adapter 其余实现：`EnsureInitialized` no-op；`GetRandomWalkablePoint` 在脚部层随机选"脚+头双空"的格子（不要求脚下有 MC 方块，flatgrass 地皮也算地）；`IsSolid` = `GetBlock`→`GetBlockOrient`→`BlockIsFullCube` 粗略版（半砖/楼梯/栅栏当可通过，实际碰撞由移动层 Source 探测兜住，细化入口 `MC.BlockBoxes`）；写入 `MC.SV.SetBlock`，失败打日志（`unchanged` 不算错）。
- CLAUDE.md 已同步更新（接口文档指向 mcswep-main/docs；"已知缺口"段落改为"仍然禁止"两条：Place/Break 玩家专用、SetBlockRaw 禁用）。

## 协作流程（固定，每次改完都做）

1. 改完代码跑 `H:\工作视频\20251115毕业\glualint.exe lint <改过的文件>`。
2. **同步整个 `gmod_addon/` 到 `D:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\gmod_addon\`**（用户在游戏里直接测）。
3. **更新本文件 + `.planning/mcgm-main/` 四个文件**（task_plan / progress / findings / status_summary，codex 接手要看）。

## 复测清单（当前：第三十五轮 MC 击退手感）

1. **上一轮已通过**：一格 hop 稳定，未再发现误上两格；debug 远点未再早停；跳后动作能复位。
2. **36.5 必测**：`lua_run print(MC and MC.BS, BMB and BMB.BS)` 应输出 36.5/36.5；一格 hop apex 约 `1.4~1.5*BS` 且稳定上台；两格必须上不去；半砖/楼梯应靠 StepHeight=28 走上去而不是 hop；36.5 宽走廊 hull 32 双向通行；drop 主动下 3 格（109.5u），4 格拒绝且不卡顿；吃草链路正常；`WorldToBlock/BlockToWorld` 新尺寸下往返一致；`bmb_world mock` 与 real 行为尺度一致。
3. **StrandedRecovery 必测**：物理枪/工具把羊放到玻璃板顶或挖掉脚下支撑后，HUD 应显示 `state=stranded`，随后短暂进入 `mode=stranded_bail`；撞障碍时应进入 `stranded_bail_retry` 并换方向，不应永久不动；若旁边没有合法地面，应侧向离开窄支撑并进入 `stranded_fall`，落到合法地面后恢复 wander。不得明显卡顿，也不得沿玻璃板网络当路走；普通 wander 不应主动把目标选到玻璃板顶。
4. **第二十九轮已初测**：普通 path 不应再靠 carrot 抄近路跨一格空洞；BlockHop 不应在 `face≈16~20` 贴脸位置反复硬跳，HUD 应先显示 setup/backoff（必要时 `face_close`）再在更远位置起跳；复杂 debug 右键路径不应跑一半过期回 wander；第二十八轮的平滑移动和第二十七轮的性能/drop/debug/spawn idle 不回归。
5. **第三十轮已验证**：debug 右键目标若被一格空洞/死路隔开，已确认不再假死 ✅；这一修复必须保留。
6. **第三十一轮回滚必测**：物理枪应恢复可抓取；子弹/枪击应恢复掉血和受击反应；prop 物理伤害链路不受碰撞试验影响；玩家能踩/挤到 mob 按 GMod 手感接受；debug gap 不回归。
7. **第三十二轮必测**：受击进入 Flee 后 HUD `vel:实际/目标` 的目标速度不应在 run/walk 阈值上下大幅跳变；过弯 `path_corner` 可以略降速但不应降到走路动作；ACT_RUN 应在整个 panic 段保持稳定，直到 Flee 结束回 idle/wander。确认围住放弃、撞墙/悬崖保护、hop/drop、debug gap 不回归。
8. **第三十五轮必测**：非冷却窗口枪击/近战命中应扣血、红闪约 0.5s，并在约 0.5s 内忽略同等重复伤害；HUD 不应再出现受击后目标速度永久 `0`。普通攻击应能看见水平击退 + 一点离地上抬，第一下生成后也要有击退；击退后不应原地等很久，空中/落地都应继续进入 flee。爆炸应从爆心径向散开；冷却窗口内连击不应继续扣血、击退或刷新 flee 方向。prop `DMG_CRUSH` 仍按原物理伤害链路，不额外 BMB 击退。被击退落到非法格后应能进入 StrandedRecovery。
9. **回归仍需留意**：物理枪、子弹伤害、prop 伤害、绕路、窄沿、不卡顿、不跳楼、地图墙/拐弯、Flee 围住放弃、套皮后 activity。

## 未解 bug / 风险

- **第二十四轮剩余风险**：代码层已按 36.5 参数化并通过静态检查/lint，但实际 GMod 场景还要按复测清单确认，尤其 hop apex、两格边界、半砖/楼梯和 36.5 走廊。
- **第二十五轮剩余风险**：StrandedRecovery 的移动阶段故意绕开 A* 和 `path_cliff`，但只做短距离 bail-out；若窄碰撞四周都被其它碰撞托住，可能显示 `stranded_no_escape` 并周期重试。高空玻璃板上会选择掉落式恢复，这是"已经被放到非法节点"的兜底，不代表普通 A* 允许跳崖。
- **第二十八轮剩余风险**：恢复 whole Think 每 tick 会拿回一点维护成本，但应该保留第 27 轮主要收益（A* / Wander / physics impact 的内部节流）。若 50 只仍不够，需要全局 AI/path queue，而不是再节流 entity Think。
- **第二十九轮剩余风险**：carrot 沿线 standable 检查每 tick 多做若干支撑查询，已在单次检查内共享 cache；若复杂路径性能变差，再考虑把 standable line check 降采样或缓存到当前 segment。
- **第三十一轮结论**：MC 式实体穿插/软推挤暂不做。`COLLISION_GROUP_PLAYER`、`ShouldCollide=false`、软分离都会威胁物理枪、子弹命中、prop 伤害等 GMod 基础交互；当前选择接受 GMod 手感，后续不要沿这条线继续调，除非先设计出不会影响 trace/physgun/damage 的分层方案。
- **第三十五轮剩余风险**：红闪用客户端 `render.SetColorModulation` 做整模型 tint，后续换 MC 模型/材质后要确认不会和皮肤材质冲突。竖直击退现在用 `loco:Jump()` + 直接 z 速度；若第一下仍偶尔不上抬，下一轮打受击 tick 日志（onGround、IsClimbingOrJumping、vel.z）确认是否被地面解算吞。摔伤尚未实现，后续应作为独立伤害来源，不触发击退。
- **第二十三轮剩余风险**：用户当前未发现 bug，但 StepHeight 临时切换、状态驱动 activity、debug 长路径 timeout 仍需要后续场景持续回归，尤其是套皮后动作映射。
- **hop 候选分诊**：若失败处 HUD 根本不进 `path_hop`，不要按弹道修；要开 A* hop 候选日志看是上方净空/支撑正确拒绝，还是邻接标记漏判。
- **PhysgunPickup 钩子语义**：它在"尝试抓取"时触发，若有第三方 addon 拒绝了这次拾取，BMBHeld 可能误置（下次松手钩子不来）；目前单机沙盒无此问题，联机装权限 addon 时留意。
- **半砖/MC 台阶对 A* 不可见**（`BlockIsFullCube`=false → BMB 当空气）：混半砖地形会选择跳整格或把半砖前方判成 cliff，且半砖不能作为 MC 支撑（目前靠 Source 不了 trace——MCSWEP 方块碰撞不是刷子，`MASK_SOLID_BRUSHONLY` 探不到）。需要 MCSWEP 暴露 shape / floor height（例如 `IBlockWorld:GetFloorHeight` 或 `MC.BlockBoxes`），再把 A* 的 walk/hop/drop 从二值格子改为真实表面高度差。
- **窄沿偏移采样的副作用**：紧挨沿边的悬空格可能因偏移样本擦到沿边被判可站立，理论上增加贴边坠落风险——`path_cliff` Source safety 仍兜底。
- **`HasSupport` 的 Source trace 语义**：若 MCSWEP cell 网格与 flatgrass 地面错位较大，站立层判定可能漂移一格；遇到再调 trace 区间。
- **partial path 改变了"路径失败"语义**：Wander/debug 移动遇到不可达目标会走到最近可达点算成功（MC 手感），只有 Flee 显式关闭（`allowPartial=false`）。
- 坑/封闭结构里的 Flee 仍是旧采样（随机世界点再验证），下一步改为枚举可站立格（复用 `HasSupport`）→ 随机抽 → A* 验证。
- path Source safety 的 `IsSourceHitBMBBlock` 采样偏移在 chunk 边界可能需要再调。
- 吃草粒子/动画：原版手感版待实现。
- `IsSolid` 粗略版：栅栏/半砖当可通过，撞住靠 watchdog 兜底。
- 性能：多只 mob 同时寻路未压测。
- `mcgm_zombie.lua` 旧样机待迁移，不要参考。

## 下一步

1. 等朋友提供 shape/floor height 接口后，做半砖/楼梯/MC 台阶表面高度寻路。
2. 坑/走廊场景的 Flee 采样改为枚举可站立格后随机抽样。
3. 吃草原版粒子/动画/音效。
4. Sheep 稳定后迁移 Zombie 验证 base 抽象；怕人生物做 `Avoid` 行为模块（参考 `AvoidEntityGoal.java`）。
