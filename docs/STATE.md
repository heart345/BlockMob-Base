# BMB 当前状态

> 每次开工先读这份（CLAUDE.md 指定入口）。历史流水/早期调试记录归档在 `.planning/mcgm-main/`（status_summary、findings、progress），只读参考，不再更新。

## 当前进度（2026-06-11）

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
- **第十九轮（待复测）：BlockHop 改用 `loco:JumpAcrossGap` + 物理枪 held gravity/desired speed 归零**。第十八轮 `Jump()+SetVelocity` 让脚离地但表现为节律性小陷跳，符合"竖直速度起效一两 tick 又被 locomotion/地面解算压回"的签名。修法：`StartBMBBlockHop` 优先调用 NextBot 原生 `loco:JumpAcrossGap(landingGoal, landingForward)`，落点给上层脚部格的地表点（foot cell center z - 半格），`SetJumpHeight` 抬到至少 58u；原生 hop 期间只转向/刷新 watchdog，不再 `SetVelocity` 弱控水平，避免和原生跳跃解算抢方向盘。没有 `JumpAcrossGap` 的旧引擎才 fallback 到 `Jump()+SetVelocity`。物理枪 held 进一步每 tick `SetGravity(0)` + `SetDesiredSpeed(0)`，松手恢复原 gravity，压掉残留弹簧感。
- 本轮修掉的对接隐藏 bug（接 real 之前就存在）：
  1. **mock 占死 `BMB.BlockWorld` 名字、无切换机制** → mock 改名 `BMB.MockBlockWorld`；新增 `BMB.SelectBlockWorld()` + convar `bmb_use_real_world`（默认 1，MCSWEP 不在场回退 mock）+ 控制台 `bmb_world mock|real`。MCSWEP 比 BMB 后加载（addons 字母序），所以 `BaseInitialize` 生成 mob 时会再选一次（幂等）。
  2. **类型枚举对不上**：real `GetBlockAt` 原来返回数字 id，行为层比较的是 `BMB.BlockTypes.Grass` 字符串，永远不相等 → adapter 现在做 id↔枚举双向映射（`blockTypeToId`/`idToBlockType`），未建模的 id 原样透传。
  3. **吃草坐标差一格**：real 世界里 `WorldToBlock(GetPos())` 是脚部所在的**空气格**，不是脚下的草方块 → EatGrass 改为 `GetPos() - Vector(0,0,4)` 再换算（mock 忽略 z，行为不变）；并把 mob 作为 actor 传入 `SetBlockAt`（real 转成 MCSWEP 的 `{actor=ent}`，带进 OnPlace/OnBreak 和声音粒子）。
  4. **寻路没查头部格**：A* 新增 `isPassable` = 脚部格 + 头部格都非实心（mock z=1 恒空，行为不变）。
  5. **`MaxStepDown` 34 < 36**：站在一格高方块地板上会把"走下来"判成悬崖永远不下来 → 改 **40**（>1 格，<2 格仍算悬崖）。
- real adapter 其余实现：`EnsureInitialized` no-op；`GetRandomWalkablePoint` 在脚部层随机选"脚+头双空"的格子（不要求脚下有 MC 方块，flatgrass 地皮也算地）；`IsSolid` = `GetBlock`→`GetBlockOrient`→`BlockIsFullCube` 粗略版（半砖/楼梯/栅栏当可通过，实际碰撞由移动层 Source 探测兜住，细化入口 `MC.BlockBoxes`）；写入 `MC.SV.SetBlock`，失败打日志（`unchanged` 不算错）。
- CLAUDE.md 已同步更新（接口文档指向 mcswep-main/docs；"已知缺口"段落改为"仍然禁止"两条：Place/Break 玩家专用、SetBlockRaw 禁用）。

## 协作流程（固定，每次改完都做）

1. 改完代码跑 `H:\工作视频\20251115毕业\glualint.exe lint <改过的文件>`。
2. **同步整个 `gmod_addon/` 到 `D:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\gmod_addon\`**（用户在游戏里直接测）。
3. **更新本文件 + `.planning/mcgm-main/` 四个文件**（task_plan / progress / findings / status_summary，codex 接手要看）。

## 复测清单（当前：第十九轮 JumpAcrossGap + held gravity）

1. **BlockHop（重点）**：右键高一格平台，应由 `path_hop` 触发一次干净的 `JumpAcrossGap`，不再一陷一陷地小跳，最终落到台上；贴墙站立也能原地跳上；撞面掉回约 0.25s 重跳、3 次后 `path_hop_fail`。混半砖地形允许它选择跳（A* 看不见半砖，观感问题后续细化）。
2. **物理枪（重点）**：随便抓哪只羊（走路中/发呆中）都不应上下抽搐、陷地或像弹簧一样轻微抖动，HUD state=held 且 desired speed=0；拎着不乱蹬腿、不触发行为；松手（包括拖到半空松手、之前安静悬挂的个体）都应正常下落并恢复游荡；hop 重跳中被抓走、松手后不应立刻误报路径失败。
3. 回归：绕路不误杀、窄沿可走、不卡顿、不跳楼、正常下落、一格走廊/拐弯/地图墙、Flee 围住放弃、吃草链路、`bmb_world mock` 回退。

## 未解 bug / 风险

- **第十九轮待实机验证**：`loco:JumpAcrossGap` 在当前 NextBot/方块坐标语义下的落点和弧线；若仍一陷一陷，先打 0.5s 逐 tick 日志（`IsClimbingOrJumping`、`IsOnGround`、`vel.z`、`pos.z`）分型：`vel.z` 起步不到约 300 = native 未吃到/起跳参数低；`vel.z` 起步正常但 1-2 tick 归零 = 地面判定抢跑；`vel.z` 正常但 `pos.z` 不涨 = hull/碰撞蹭方块面。若只是弧度低，优先调高 `BlockHopJumpHeight`。
- **第十九轮物理枪持握**：若 `SetGravity(0)` + `SetDesiredSpeed(0)` 后仍有微抖，下一步再考虑 held 期间临时压 yaw/accel/decel 并在 drop 恢复；不要先动碰撞组，避免拎起时穿墙/穿方块。
- **PhysgunPickup 钩子语义**：它在"尝试抓取"时触发，若有第三方 addon 拒绝了这次拾取，BMBHeld 可能误置（下次松手钩子不来）；目前单机沙盒无此问题，联机装权限 addon 时留意。
- **半砖对 A* 不可见**（`BlockIsFullCube`=false → BMB 当空气）：混半砖地形会选择跳整格而不是走半砖台阶，且半砖不能作为 MC 支撑（目前靠 Source 不了 trace——MCSWEP 方块碰撞不是刷子，`MASK_SOLID_BRUSHONLY` 探不到）。观感问题，需要时用 `MC.BlockBoxes` 细化 IsSolid/支撑语义。
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

1. 复测第十九轮 hop（`JumpAcrossGap` 真跳上台 + 无小陷跳）和物理枪 held（无弹簧抽动）；其余项回归。
2. 坑/走廊场景的 Flee 采样改为枚举可站立格后随机抽样。
3. 吃草原版粒子/动画/音效。
4. Sheep 稳定后迁移 Zombie 验证 base 抽象；怕人生物做 `Avoid` 行为模块（参考 `AvoidEntityGoal.java`）。
