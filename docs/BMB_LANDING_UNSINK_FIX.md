# BMB Landing Unsink Fix

日期：2026-06-25  
状态：用户游戏内复测已确认修好  
改动文件：`gmod_addon/lua/entities/bmb_base_mob.lua`

## 症状

- 所有 BMB mob 被击退/击飞后，在平地会短暂陷进地面，再回弹出来。
- 普通蜘蛛在一格高空间/一格顶下被击退击飞后，会下陷并卡住，HUD 可进入 `state=stranded mode=stranded_no_escape`。
- 洞穴蜘蛛也会下陷，但因为体型/回弹表现不同，通常能弹出来，不像普通蜘蛛那样稳定卡死。
- `bmb_ground_unsink 1` 第一版打开后，和 `0` 对比没有明显区别。

## 失败尝试

第一版只在 `OnLandOnGround` 里做落地 unsink：

- 增加 `bmb_ground_unsink` / `bmb_ground_unsink_eps`。
- 落地回调里向下 trace，发现脚底低于地面时向上 `SetPos`。

游戏实测无效。原因是这条 NextBot 击退/击飞路径里，真实“下陷后回地面”的时机经常不稳定地落在击退窗口之后，不能只依赖 `OnLandOnGround`。另外，MCSWEP 方块顶面不一定能被普通 Source hull trace 稳定当成地表返回。

## 最终方案

最终修在 Base，作为所有 BMB mob 的通用落地维护：

- 新增 `TryBMBGroundUnsink(reason)`。
- server `Think` 的 grounded 维护阶段每 tick 尝试一次轻量 unsink。
- `ShouldRunBMBStrandedRecovery()` 进入 stranded 判定前先尝试 unsink；如果同 XY 能拔回合法地表，就不进入 stranded。
- `FindBMBStrandedEscapePoint()` 增加同 XY 垂直拔回最近地表的候选，避免已经下陷时只做水平逃逸。
- `GetBMBGroundSurfaceZ(pos)` 同时看 Source hull trace 和 block-world fallback。
- `GetBMBBlockWorldGroundSurfaceZ(pos)` 用 `BMB.BlockWorld` + `BMB.Pathfinder.IsStandablePosition` 在当前位置附近扫描可站立 cell，换算出方块表面 `surfaceZ`。
- 只在 `surfaceZ - pos.z > bmb_ground_unsink_eps` 且上拔距离不超过 `GetBMBGroundUnsinkMaxLift()` 时向上修正。
- 修正前必须通过 `IsBMBHullClearAtPosition(target)`，避免把实体塞进低顶或实体碰撞里。
- 修正后清掉残留 z velocity，并清 `BMBStrandedCell`。

关键限制：

- 只向上拔，不向下吸附。
- 不是通用寻路 teleport，只处理“脚已经低于最近可站地表”的小范围修正。
- 默认最大上拔为 `max(StepHeight, BS * GroundUnsinkMaxLiftScale)`，当前 `GroundUnsinkMaxLiftScale = 0.75`。
- 不改 `IsMovementTargetSafe`。上一轮一格高 passage/wall-probe 是另一类问题。
- 不混入 `BMBSpiderClimbFloorZ`。蜘蛛爬墙 floor/climb 逻辑仍由 Spider Phase 3 自己维护。
- 不改 hop/drop/A* 的语义；成功 hop/drop 不应被这套逻辑硬拔回原层。

## 运行开关

- `bmb_ground_unsink 1`：默认打开。
- `bmb_ground_unsink 0`：关闭这套落地修正，方便回归对比。
- `bmb_ground_unsink_eps 2`：脚低于地表超过该值才修正，避免微小浮点抖动。

## 已验证

用户游戏内确认：

- 平地击退/击飞不再明显下陷再回弹。
- 普通蜘蛛在一格顶下被击退击飞后不再卡进地里/卡成 `stranded_no_escape`。
- 洞穴蜘蛛仍能正常回到地表。

已跑过的静态/脚本检查：

- `H:\工作视频\20251115毕业\glualint.exe lint gmod_addon/lua/entities/bmb_base_mob.lua`
- `scripts/check_stranded_recovery.ps1`
- `scripts/check_hop_debug_gap_regressions.ps1`
- `scripts/check_spider_phase3.ps1`
- `scripts/check_movement_recovery_and_scaling.ps1`
- `scripts/check_block_shape_pathing.ps1`

已同步到 live addon：

- `D:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\gmod_addon\lua\entities\bmb_base_mob.lua`

热刷新命令：

- `lua_refresh_file lua/entities/bmb_base_mob.lua`

## 后续回归重点

- 羊、狼、僵尸、骷髅、普通蜘蛛、洞穴蜘蛛都要作为回归对象，不要只看蜘蛛。
- 场景至少覆盖平地、一格顶/低顶、台阶边、MCSWEP 方块顶面、Source 地面。
- 如果以后又出现击飞后卡 `stranded_no_escape`，先看 `TryBMBGroundUnsink()` 是否找到 surface、是否被 max lift 或 hull clear 拒绝。
- 如果以后出现“被拔得太高”，优先检查 block-world surface fallback 的 standable 判定和 `GroundUnsinkMaxLiftScale`，不要先改 hop/drop/A*。
