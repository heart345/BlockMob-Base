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

## 行为设计约定

- **目的地合法性在目标选择层保证，不在运动层兜底。** 任何移动类行为产出的目标都必须是验证过的可达格（可站立过滤 + A\* 验证），运动层只负责跟路径。不要再给运动层加刹车/探测类补丁来掩盖非法目的地。
- **Flee 按 MC PanicGoal 实现**：受击触发，在半径约 5 格（垂直 ±4）内采样随机可达点——与攻击者方向**无关**；采样顺序是先用 `IBlockWorld` 枚举可站立格、再从中随机抽、最后 A\* 验证，限制每次尝试次数（约 8~10），全部失败则本次不触发 flee（原地，符合原版）。到点后仍在惊慌窗内则再选下一个点；速度带 panic 倍率（羊约 1.25×）。
- **Avoid（躲特定实体，如猫/兔躲玩家）是独立模块**，方向感知（找远离目标实体的可达点），不要和 Panic 合并。
- **Look 类模块（如 LookAtPlayer）是非独占的**，与移动类模块并行：移动时身体朝向归移动管，look 只控制头部；静止时头先转（骨骼操纵，clamp yaw ±75°/pitch ±40°），头到极限才由 `loco:FaceTowards` 带动身体跟转。状态机调度需支持"一个移动模块 + 一个注视模块"同时活跃。
- **物理枪持握（`BMBHeld`）是一等状态**：持握期间 loco 每 tick 缴械（`SetVelocity(vector_origin)`，否则 loco 醒着会和物理枪拉扯成上下抽搐/陷地）、行为协程整体挂起、移动入口拒绝新请求；松手踹一脚向下速度唤醒可能睡眠的 loco（挂半空的个体才会正常下落）。held 必须与移动状态握手：拾起时 `InterruptBMBMovement` 掐掉当前 move（hop 重跳计数等局部状态随之销毁），不许后台继续计数。

## 方块访问纪律（最重要的一条）

- **所有方块读写只走 `IBlockWorld` 接口。** 行为模块、寻路、状态机一律不许直接调用 `MC.*`。
- `IBlockWorld` 有两个实现：`MockBlockWorld`（开发/测试用）和 `RealBlockWorld`（adapter，内部用 `MC.*` 实现）。两者满足同一接口，切换只改一个变量。
- adapter 实现备忘：
  - `WorldToBlock` → `MC.WorldToCell`；`BlockToWorld`（中心）→ `MC.CellWorldCenter`
  - `GetBlockAt` → `MC.GetBlock(bx,by,bz)` 拿数字 id，再**映射回 `BMB.BlockTypes` 枚举**返回（行为层只认这套枚举；未建模的 id 原样透传当"其他方块"）
  - `IsSolid` 无现成函数：`GetBlock` 非空 → `GetBlockOrient` → `MC.BlockIsFullCube(id, orient)`。粗略版（半砖/楼梯按需细化，入口留 `MC.BlockBoxes`）
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

- 寻路是自写 A*，跑在方块网格上。**不用 navmesh**（盖不住动态体素）。real 方块世界启用 3D 邻接：同层 `walk`、+1 格 `hop`、向下 ≤3 格 `drop`；mock 仍是平面世界，避免调试地面被 z 轴语义污染。real 下 walk/hop/drop 的落点都要求**可站立**（passable + `IBlockWorld.HasSupport`：脚下 MC 实心，或 Source 刷子地面兜底——prop 不算支撑），搜索空间锁死在真实可走表面，目标格悬空时向下吸附到第一个可站立格。A* 必须带搜索预算（f = g+h 椭圆界）+ per-call passable/support 缓存 + 协程 yield 时间切片——预算管"无路"结论的总开销，yield 管单帧不卡，二者互补缺一不可。搜索中止时返回离目标最近的部分路径（标 `partial`，观感 = 走到崖边/尽头停住）；**Flee 必须 `allowPartial=false`**，否则撞墙被洗成成功冲刺、"被围住会放弃"失效。
- A* 重算必须限频（约 0.3–0.5s）且仅在目标 cell 变化时触发；每 tick 只消费已有路径。
- 移动全部交给 `loco`（`Approach` 每 tick 持续调用 + `SetDesiredSpeed`）；**禁止**手动 `SetPos`/`SetAngles` 驱动移动或转向（打断客户端插值），转向用 `loco:FaceTowards`。
- `Approach` 的目标用前瞻点（carrot point），且 carrot 必须**沿路径折线推进**（pure pursuit）取点，不是直线瞄向前方第 N 个节点——直角处（如一格宽走廊入口）会切角撞墙。配合网格视线检查（mob 到 carrot 逐格 `IsSolid`），被挡则把前瞻缩到最后可见点。直接瞄下一个 waypoint 也不行（永远在减速区内，速度锯齿）。
- **经 A\* 验证的路径，跟随层禁止再用 Source 射线否决 MC 方块通行**（路径上每格已保证方块 hull 可走）。但 A* 不知道 gm_flatgrass 的地图墙、平台边缘、玩家 prop，所以 `MoveAlongPath` 仍要保留 path 专用 Source safety：悬崖一律拦；墙命中若对应 `IBlockWorld` solid 方块则忽略（交给方块 hull 规则），若不是方块世界里的 solid（地图墙/prop）则拦。
- 急转弯要进入 `path_corner` 手感：提前约 2 格识别折线拐点，缩短 carrot 到约 1 格内、降低目标速度、临时提高 `loco` deceleration，避免带惯性切出走廊再来回矫正。
- waypoint 到达判定用 2D 距离（忽略 z），阈值取 hull 半径量级（约 0.5×36）。
- 方块通行必须按 **mob hull 占格** 判断，不是只查中心点所在 cell：水平按碰撞盒半径检查周围 solid cell，垂直按实体高度覆盖的 cell 检查。成年羊宽约 0.9 格（BMB 暂取 32u）能过 36u 走廊，但不能从一格高洞或方块角挤过去。
- **跳一格用固定弹道 BlockHop**：顶点 = 1.25 格 = 45u。起跳必须先 `loco:SetJumpHeight(45)` + `loco:Jump()` 把 locomotion 切进跳跃态——**落地态单独 `loco:SetVelocity` 写竖直速度无效**（地面解算当帧压回地面，表现为"有状态不起跳"）；Jump 后再 `loco:SetVelocity` 覆盖成固定弹道 `vz = √(2 × loco:GetGravity() × 45)`。水平速度保留，但**朝目标方向的分量不足行走速度时补足**（贴墙起跳水平≈0，纯保留会原地直上直下永远上不去）。滞空期间 `Approach` 无效，水平速度向目标方向弱 Lerp（系数 0.05~0.1），落地恢复正常跟随；空中弱转向**只在跳跃态（`loco:IsClimbingOrJumping`，起跳当帧强制视为真）或真离地时接管**（它会刷新 no-progress watchdog，落地贴墙还用它等于关掉卡死兜底）。落地却没站上目标格 = 这跳失败，以 `OnLandOnGround` 回调时刻为基准短延时（必须 < watchdog grace）后复位重跳，连续失败数次按路径失败交还行为层。hop 边由 A\* 在"+1 高度差且上方净空"时标记，跟随层消费到 hop 边、2D 距离够近且 `IsOnGround()` 时触发。`StepHeight` 保持 <36——不要靠 step 把 mob 滑上方块，视觉不是 MC 的跳跃感。`loco:SetVelocity`/`loco:Jump` 不在"禁止手动驱动"之列（loco 层接口，不打断插值）。
- **hop/drop 边是 A\* 明确授权的垂直动作**：跟随层处于 `path_hop` / `path_drop` 时必须豁免 `path_wall` / `path_cliff` Source safety（否则 hop 会被前方方块当墙点刹，drop 会被故意下落当悬崖取消）。下落边不加跳跃，只沿路径走出边缘并让重力落下；落地后再恢复普通 path safety。
- mob 的 hull / jump / step 参数尽量对齐 MCSWEP 玩家的设定，否则寻路可达但实际走不上去。

## 开发与测试方式

- 默认对 `MockBlockWorld` + flatgrass 开发，mock 方块用调试框渲染。
- 新行为先在 mock 上验证，最后才接 `RealBlockWorld`。
- GMod 双 realm：注意 server/client 划分，mob 逻辑在服务端，调试 HUD 在客户端。
- 调试移动问题时优先在 HUD 上打点（vel / 目标速度 / dist_to_goal / 当前状态 / 切 waypoint 事件），不要靠肉眼猜。

## 里程碑参照

羊游荡（A*）→ 受击逃跑（状态机切换）→ 吃草（grass_block → dirt，经 `RealBlockWorld` → `MC.SV.SetBlock` 落地）。第二只怪用于验证 base 抽象是否成立——如果加新怪需要改 BaseMob 或行为模块，说明抽象有问题，先修抽象。
