# BMB 当前状态

> 每次开工先读这份（CLAUDE.md 指定入口）。历史流水/早期调试记录归档在 `.planning/mcgm-main/`（status_summary、findings、progress），只读参考，不再更新。

## 当前进度（2026-06-11）

- `bmb_sheep` 切片（mock 世界）：生成 ✅、Flee ✅（**第九轮 MC PanicGoal 式重写，用户已实测通过**：随机近点 dash、没路放弃、平地不跑远）、prop 物理伤害 ✅、速度锯齿 ✅、倒退 ✅、吃草频率 ✅、MC 游荡节奏 ✅、转圈 ✅、跳崖 ✅、贴 prop 冻住 ✅、障碍犹豫掉速 ✅。
- **第十轮（待复测）：RealBlockWorld 接通 MCSWEP，mock 首次切真环境**。朋友的 `MC.SV.SetBlock` 已就位（addon 在 `D:\...\addons\mcswep-main`，接口文档在其 `docs/interface-usage.md`，签名已对照源码 `mc/sv_world.lua:392` 验证）。目标：羊在真方块世界跑通"游荡 → 受击逃 → 吃草 grass_block→dirt"全链路。
- **第十一轮（用户已验证）：修"一格宽走廊出得来、进不去"**。根因在路径跟随层，不是 A*：`MoveAlongPath` 对 A* 路径每 tick 又跑 `IsMovementTargetSafe`，36u 走廊入口会被 `WallStopDistance=20` 的 Source hull 探测误判成墙；carrot 也可能从当前位置直线瞄向前方节点/终点外投，直角入口切角撞墙。修法：A* 路径跟随不再用 Source 安全探测二次否决；`GetPathCarrot` 改成 pure pursuit（先投影到当前路径折线，再沿折线前推）；再用 `IBlockWorld.IsSolid` 做网格视线检查，直线到 carrot 被方块挡住时二分缩短到最后可见的折线点。裸方向移动/legacy/debug direct 仍保留 `IsMovementTargetSafe`。
- **第十二轮（用户已验证）：修 debug 目标秒退 + 羊从一格高洞/方块角穿过**。上一轮仍按"中心点所在格"判断通行，没按成年羊宽高占格，所以会从 1 格高天花板下钻、从方块角擦过去；Tool Gun 右键也仍走 direct debug move，不是 A*。修法：`bmb_base_mob` 新增 `IsBMBHullClearAtPosition`，按实体水平半径和身高检查周围实心格；A*、随机候选、carrot 网格视线统一用 mob hull 通行；`bmb_sheep` hull 调到 32u 宽（MC 成年羊 0.9 格约 32.4u）；Tool Gun 右键目标改走 `MoveToWorldPosition` A*，点击面会略抬/推出到可站立空气格。
- **第十三轮（用户已验证）：修拐弯漂移/打滑**。用户确认第十二轮三项通过后，反馈方块走廊拐弯有惯性滑出去再反复矫正。修法：`MoveAlongPath` 新增 `path_corner` 过弯控制，提前约 2 格检测折线急转，靠近转角时动态降低目标速度、缩短 carrot 到约一格内，并临时提高 `loco` deceleration；直线段恢复 `path_carrot`。
- **第十四轮（用户已验证）：修 Source 地图墙/跳崖回归**。退役 path 里的 Source 安全复查后，A* 只知道 MC 方块，不知道 gm_flatgrass 地图墙和平台边缘，导致羊会沿 `path_carrot` 往地图墙/悬崖走。修法：`MoveAlongPath` 加回 path 专用 Source safety：前向 hull 命中若对应 `IBlockWorld` solid 方块则忽略（不误伤一格方块走廊），若不是方块 solid（地图墙/prop）则 `path_wall`；前向地面探测没地/坡太陡/落差 > `MaxStepDown` 则 `path_cliff` 并急刹。
- **第十五轮（待复测）：A* 3D 邻接 + BlockHop / drop 边**。`sv_pathfinder` 在 real 方块世界生成 `walk` / `hop` / `drop` waypoint：+1 格高差标 `hop`，向下 ≤3 格有支撑落点标 `drop`；mock 仍固定平面。`MoveAlongPath` 新增 `path_hop` / `path_drop`，hop 用 45u 顶点的 `loco:SetVelocity` 弹道，空中弱控水平速度；drop 不跳，故意走出边缘让重力落下。hop/drop 消费期间豁免 `path_wall` / `path_cliff`，避免台阶被当墙、下落边被当跳崖；终点判定补上"垂直边必须落地且脚部 cell 到目标层"。real `GetRandomWalkablePoint` 开始抽当前层附近的可支撑候选，让 Wander 有机会自然跨上/跨下真实起伏地形。
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

## 复测清单（当前：真方块世界 + 第十五轮 BlockHop/drop）

1. flatgrass，确认 MCSWEP 已加载，生成 `bmb_sheep`，控制台应打 `[BMB] Block world -> real (MCSWEP)`（或用 `bmb_world` 查询当前实现）。
2. 用 MCSWEP 铺一片 `grass_block` 地板（如 `mc_fill` 或 SWEP 手铺），把羊引上去或在上面生成。
3. **BlockHop**：Tool Gun 右键点高一格平台，HUD 应显示 `path_hop`，羊应跳上去，不应在台阶前 `path_wall` / 点刹。
4. **Drop**：Tool Gun 右键点低 1-3 格落点，HUD 应显示 `path_drop`，羊应主动走下去，不应 `path_cliff`。
5. **游荡**：羊在方块地板和起伏地形上正常游荡；不会试图穿过 1 格高的方块墙（A* 绕行）。
6. **一格宽走廊**：从走廊外随机游荡/Tool 目标进入走廊内某格，HUD 应保持 `mode=path_carrot` 前进，不应在入口 `path_blocked`；从走廊内走出仍正常。
7. **低顶/角落**：成年羊不应从 1 格高天花板下面钻过去；绕方块角时不应穿过石头/木头角。1 格宽直走廊仍应能通过。
8. **Tool Gun 右键**：选中羊后右键走廊内地面，应进入 `debug_move`/`path_carrot` 并沿 A* 前往，不应只闪一下 `debug_move` 就回 wander。
9. **拐弯手感**：走廊 90 度转弯附近 HUD 可短暂显示 `path_corner`；羊应明显减小漂移，不应滑出一截后反复左右矫正。
10. **地图墙/平台边缘**：羊不应沿 `path_carrot` 往 gm_flatgrass 砖墙或平台外走；被拦时 HUD 应短暂显示 `path_wall` 或 `path_cliff` 后重选目标。
11. **受击逃**：在方块世界里 Flee 行为与 mock 一致（随机 dash、被方块围住会放弃）。
12. **吃草**：站在 grass_block 上等吃草触发 → 方块变 dirt、所有客户端可见（网络同步）、`mc_save` 后不丢。站在 Source 地皮上不应误触发。粒子/动画见下方待办，当前先不算本轮阻塞。
13. **回退**：`bmb_world mock` 切回 mock 一切照旧（调试框、bmb_mock_show）。
14. mock 验证过的行为（游荡节奏、Flee、跳崖、吃草频率）在 real 下不回归。

## 未解 bug / 风险

- **BlockHop/drop 待实机调参**：代码已接通 3D A*、`path_hop`、`path_drop`，但 45u 弹道在 GMod 里还需要看实际落点、速度和动画观感；若羊在台阶前跳早/跳晚，优先调 `BlockHopTriggerDistance` 和 `BlockHopAirSteerStrength`。
- 坑/封闭结构里的 Flee 仍是旧采样：当前 `pickPanicDestination` 还是随机世界点再验证，虽然已接入 mob hull 过滤，但坑里命中可站立出口的概率仍低，可能直接放弃。下一步应按 CLAUDE.md 改成：先用 `IBlockWorld` 枚举半径内可站立格，再随机抽样，最后 A* 验证。
- `IsBMBHullClearAtPosition` 当前只管身体与实心方块重叠，不统一判断"脚下是否有 MC 支撑方块"；flatgrass/Source 地面仍可作为支撑。hop/drop 和 real 跨层随机候选已要求目标脚下有 MC 支撑，后续 Flee 可站立枚举也应复用这条语义。
- path Source safety 会尝试用 hit position 判断 Source wall 是否来自 MC 方块；若 MCSWEP chunk 碰撞命中点正好落在边界，可能仍需调 `IsSourceHitBMBBlock` 的采样偏移。
- 吃草粒子/动画选择**原版手感版**：保持行为语义上 `fx=false`/非破坏写入的方向，羊自己补低头吃草动画、草屑粒子和咀嚼音效；不要靠 MCSWEP 的破坏 fx 冒充吃草。本轮只记录决策，未实现。
- `IsSolid` 粗略版：栅栏/半砖被当可通过，A* 可能穿栅栏规划，移动层会撞住然后靠 watchdog/Flee 失败计数兜底——观感是"撞一下换路"。需要更好的话用 `MC.BlockBoxes` 细化。
- 性能：A* 每节点 2 次 `MC.GetBlock`（脚+头），`MaxPathIterations` 900——大量羊同时寻路时注意；MCSWEP 的 GetBlock 是纯表查询，预计没问题。
- `MaxStepDown` 40 也放宽了 Source 环境的判定（之前 34），理论上无副作用（跳崖判定主要靠落差>40 失败），复测时顺带留意平台边缘。
- `mcgm_zombie.lua` 仍是旧样机（自带 SetAngles 转向），待迁移，不要参考它写新代码。

## 下一步

1. 复测 BlockHop/drop：Tool Gun 右键点高一格平台，HUD 应显示 `path_hop` 并跳上去；从高台点低 1-3 格落点，HUD 应显示 `path_drop` 并主动走下去；这两类动作不应在边缘显示 `path_wall` / `path_cliff`。
2. 回归复测旧移动修复：一格宽走廊进/出、低顶、方块角、拐弯 `path_corner`、地图墙/平台边缘 `path_wall`/`path_cliff`。
3. 坑/走廊场景的 Flee 采样改为枚举可站立格后随机抽样。
4. 吃草原版粒子/动画/音效。
5. Sheep 稳定后迁移 Zombie 验证 base 抽象；怕人生物做 `Avoid` 行为模块（参考 `AvoidEntityGoal.java`）。
