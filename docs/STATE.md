# BMB 当前状态

> 每次开工先读这份（CLAUDE.md 指定入口）。历史流水/早期调试记录归档在 `.planning/mcgm-main/`（status_summary、findings、progress），只读参考，不再更新。

## 当前进度（2026-06-11）

- `bmb_sheep` 切片（mock 世界）：生成 ✅、Flee ✅（**第九轮 MC PanicGoal 式重写，用户已实测通过**：随机近点 dash、没路放弃、平地不跑远）、prop 物理伤害 ✅、速度锯齿 ✅、倒退 ✅、吃草频率 ✅、MC 游荡节奏 ✅、转圈 ✅、跳崖 ✅、贴 prop 冻住 ✅、障碍犹豫掉速 ✅。
- **第十轮（待复测）：RealBlockWorld 接通 MCSWEP，mock 首次切真环境**。朋友的 `MC.SV.SetBlock` 已就位（addon 在 `D:\...\addons\mcswep-main`，接口文档在其 `docs/interface-usage.md`，签名已对照源码 `mc/sv_world.lua:392` 验证）。目标：羊在真方块世界跑通"游荡 → 受击逃 → 吃草 grass_block→dirt"全链路。
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

## 复测清单（第十轮：真方块世界全链路）

1. flatgrass，确认 MCSWEP 已加载，生成 `bmb_sheep`，控制台应打 `[BMB] Block world -> real (MCSWEP)`（或用 `bmb_world` 查询当前实现）。
2. 用 MCSWEP 铺一片 `grass_block` 地板（如 `mc_fill` 或 SWEP 手铺），把羊引上去或在上面生成。
3. **游荡**：羊在方块地板上正常游荡；能从一格高地板走下来（MaxStepDown 40 生效）；不会试图穿过 1 格高的方块墙（A* 绕行）。
4. **受击逃**：在方块世界里 Flee 行为与 mock 一致（随机 dash、被方块围住会放弃）。
5. **吃草**：站在 grass_block 上等吃草触发 → 方块变 dirt、有破坏/放置音效粒子、所有客户端可见（网络同步）、`mc_save` 后不丢。站在 Source 地皮上不应误触发。
6. **回退**：`bmb_world mock` 切回 mock 一切照旧（调试框、bmb_mock_show）。
7. mock 验证过的行为（游荡节奏、Flee、跳崖、吃草频率）在 real 下不回归。

## 未解 bug / 风险

- **羊上不去一格台阶**（StepHeight 28 < 36）：MC 生物会自动跳一格，BMB 还没把跳跃接进寻路/移动。真世界铺高低差地形时会绕路或被挡，这是下一个补的能力（loco jump height 58 已设，缺触发逻辑）。
- A* 只在同 z 层扩展（4 邻接）：跨层路径（上下台阶）规划不了，目前靠"目标点取脚部层 + Source 安全探测"凑合。做跳跃时一起升级成 3D 邻接。
- `IsSolid` 粗略版：栅栏/半砖被当可通过，A* 可能穿栅栏规划，移动层会撞住然后靠 watchdog/Flee 失败计数兜底——观感是"撞一下换路"。需要更好的话用 `MC.BlockBoxes` 细化。
- 性能：A* 每节点 2 次 `MC.GetBlock`（脚+头），`MaxPathIterations` 900——大量羊同时寻路时注意；MCSWEP 的 GetBlock 是纯表查询，预计没问题。
- `MaxStepDown` 40 也放宽了 Source 环境的判定（之前 34），理论上无副作用（跳崖判定主要靠落差>40 失败），复测时顺带留意平台边缘。
- `mcgm_zombie.lua` 仍是旧样机（自带 SetAngles 转向），待迁移，不要参考它写新代码。

## 下一步

1. 复测上面清单（第一次真环境联调，预期会炸出新问题，炸了截图 + `bmb_debug_hud 1`）。
2. 羊的一格跳跃（对齐 MC 自动跳），A* 升级 3D 邻接。
3. Sheep 稳定后迁移 Zombie 验证 base 抽象；怕人生物做 `Avoid` 行为模块（参考 `AvoidEntityGoal.java`）。
