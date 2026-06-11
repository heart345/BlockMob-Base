# BMB / BlockMob Base

GMod (Lua) addon：为 MCSWEP 方块世界做 Minecraft mob 系统。双人协作项目——本仓库只负责 mob，方块/世界系统是另一个独立 addon（MCSWEP，命名空间 `MC`，朋友维护，对本项目是只读依赖）。

**每次开工先读 `docs/STATE.md`**（当前进度、未解 bug、下一步），本文件只放不随进度变化的约定。

## 系统边界

- 本仓库命名空间：`BMB`。不要向 `MC` 命名空间写入任何东西。
- MCSWEP 接口文档（权威、随朋友更新）：`D:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\mcswep-main\docs\interface-usage.md`，朋友的源码也在该 addon 目录可直接查证签名。改对接相关代码前先读它。
- 方块大小 = **36 Source units**（`MC.BS`）。坐标两层：world `Vector` ↔ cell 整数坐标 `bx,by,bz`。chunk 是 MCSWEP 内部概念，BMB 代码不感知。

## 架构铁律

- **薄 BaseMob（Nextbot 实体）+ 可组合行为模块 + 每类怪一个状态机。** 不做敌对/中立/友好三条平行继承链。中立怪 = 友好行为打底 + 受激惹切换敌对状态。思路对齐 Minecraft 的 Goal 系统。
- 行为模块（Wander / Flee / SeekTarget / Chase / 各类 Attack）必须可复用、无怪物特化逻辑；怪物差异全部表达在各自的状态机和参数里。
- 实体基于 Nextbot：移动走 `loco`，行为走协程 Think。

## 方块访问纪律（最重要的一条）

- **所有方块读写只走 `IBlockWorld` 接口。** 行为模块、寻路、状态机一律不许直接调用 `MC.*`。
- `IBlockWorld` 有两个实现：`MockBlockWorld`（开发/测试用）和 `RealBlockWorld`（adapter，内部用 `MC.*` 实现）。两者满足同一接口，切换只改一个变量。
- adapter 实现备忘：
  - `WorldToBlock` → `MC.WorldToCell`；`BlockToWorld`（中心）→ `MC.CellWorldCenter`
  - `GetBlockAt` → `MC.GetBlock(bx,by,bz)` 拿数字 id，再**映射回 `BMB.BlockTypes` 枚举**返回（行为层只认这套枚举；未建模的 id 原样透传当"其他方块"）
  - `IsSolid` 无现成函数：`GetBlock` 非空 → `GetBlockOrient` → `MC.BlockIsFullCube(id, orient)`。粗略版（半砖/楼梯按需细化，入口留 `MC.BlockBoxes`）
  - 方块类型 id 首次用到时 `MC.ResolveBlock("grass_block").id` 解析并缓存，不要硬编码数字
  - 写入走 `MC.SV.SetBlock(bx,by,bz,id,orient,options)`（2026-06-11 起已就位），mob 实体直接当 options 传（= `{ actor = ent }`）；它会处理网络同步、碰撞 dirty、声音粒子、OnPlace/OnBreak、保存
  - 实现切换：`BMB.BlockWorld` 指向 `BMB.MockBlockWorld` 或 `BMB.RealBlockWorld`，由 `BMB.SelectBlockWorld()` + convar `bmb_use_real_world`（默认 1，MCSWEP 不在场自动回退 mock）决定；控制台 `bmb_world mock|real` 切换。MCSWEP 比 BMB 后加载，所以生成 mob 时会再选一次
- **仍然禁止**：
  - `MC.SV.Place/Break` 是玩家工具接口（cooldown/reach/权限校验），要传 `ply`——**禁止**传 nil 或 mob 实体硬套，mob 写方块只用 `MC.SV.SetBlock`。
  - `MC.SetBlockRaw` 不做网络同步和碰撞重建——联机会 desync，**禁止**在游戏逻辑中使用。

## 寻路与移动

- 寻路是自写 A*，跑在方块网格上。**不用 navmesh**（盖不住动态体素）。
- A* 重算必须限频（约 0.3–0.5s）且仅在目标 cell 变化时触发；每 tick 只消费已有路径。
- 移动全部交给 `loco`（`Approach` 每 tick 持续调用 + `SetDesiredSpeed`）；**禁止**手动 `SetPos`/`SetAngles` 驱动移动或转向（打断客户端插值），转向用 `loco:FaceTowards`。
- `Approach` 的目标用前瞻点（carrot point，沿路径前投 2–4 格），不要直接瞄下一个 waypoint，否则永远在减速区内导致速度锯齿。
- waypoint 到达判定用 2D 距离（忽略 z），阈值取 hull 半径量级（约 0.5×36）。
- mob 的 hull / jump / step 参数尽量对齐 MCSWEP 玩家的设定，否则寻路可达但实际走不上去。

## 开发与测试方式

- 默认对 `MockBlockWorld` + flatgrass 开发，mock 方块用调试框渲染。
- 新行为先在 mock 上验证，最后才接 `RealBlockWorld`。
- GMod 双 realm：注意 server/client 划分，mob 逻辑在服务端，调试 HUD 在客户端。
- 调试移动问题时优先在 HUD 上打点（vel / 目标速度 / dist_to_goal / 当前状态 / 切 waypoint 事件），不要靠肉眼猜。

## 里程碑参照

羊游荡（A*）→ 受击逃跑（状态机切换）→ 吃草（grass_block → dirt，改方块步骤 stub 直到写入接口到位）。第二只怪用于验证 base 抽象是否成立——如果加新怪需要改 BaseMob 或行为模块，说明抽象有问题，先修抽象。
