# Findings

## Latest physics and flee notes

- BMB mobs are NextBots, not normal rigid-body props. Physics-kill style impacts need explicit detection in `bmb_base_mob`.
- Fast movable physics props now cause `DMG_CRUSH` through periodic nearby velocity checks plus `OnContact` / `StartTouch` fallback hooks.
- Reverse bounce feedback was too strong and visually wrong: props flew backward after killing a mob.
- Current fix keeps prop motion in its original direction and applies velocity damping:
  - `PhysicsPropImpactDamping = 0.45`
  - `PhysicsPropKillDamping = 0.68`
- Sheep flee reliability issue had two causes:
  - Wander/EatGrass could be inside `coroutine.wait`, making hit reaction look delayed or absent.
  - Flee only accepted a valid attacker entity, so some damage sources did not produce a usable flee source.
- Current fix:
  - `InterruptibleWait` lets injury interrupt behavior waits.
  - Sheep stores `FleeThreatPosition` from attacker position, damage position, or damage force.
  - Flee accepts either an entity threat or a vector threat position.

## GMod NextBot 与 prop

- NextBot 路径跟随主要依赖地图 navmesh。
- 玩家在游戏内后放置的 prop 不会自动写进 navmesh。
- 因此“绕开动态 prop”不能只靠 `nav_generate`。
- 需要在 NPC 移动循环中加动态感知，例如 `util.TraceHull` 检测前方实体，再临时选择左/右避让点。
- 初版测试结果：复杂 prop 场景中可以最终追到玩家，但路线会绕来绕去，不是最优路径。
- 后续优化方向：记忆最近失败方向、按目标方向评分左右避让点、被卡住时后退重试或临时扩大侧移距离。

## Zombie 战斗参数

- 用户反馈旧攻击距离 `55` 太远。
- 当前调整：
  - 攻击距离：`38`
  - 每次伤害：`10`
  - 命中玩家时播放痛声
  - 命中玩家时施加更强水平击退和上抛
- 当前击退参数：
  - 水平击退：`330`
  - 垂直上抛：`155`
- 当前 Source 僵尸占位模型的攻击动画和命中时机不完全同步；后续套 Minecraft 僵尸模型时，应将伤害触发绑定到攻击动画关键帧，而不是固定猜时间。

## Refresh Command

- 正确命令是：

```text
lua_refresh_file <path/to/file.lua>
```

- 对当前 addon，可尝试：

```text
lua_refresh_file addons/gmod_addon/lua/entities/mcgm_zombie.lua
```

- 如果实体状态没有完全刷新，重进地图或重启 GMod 更稳。

## Minecraft 源码

- 本地路径：`C:\Users\ADMIN\Downloads\Compressed\我的世界源码`
- 当前看到的包名和时间更像较老版本源码，不是 26.1 系列。
- 仍可参考 Zombie 的基础 AI：
  - `EntityZombie.java`
  - `EntityAIZombieAttack.java`
- 新版本生物和新机制需要另建 26.1 系列清单，不能只依赖这份源码。

## gmod_mc_mob_spec(2).md 架构结论

- 规格文档路径：`H:\工作视频\20251115毕业\gmod_mc_mob_spec(2).md`
- 已锁定方向：
  - 实体基类仍用 NextBot。
  - 不走 VJ Base。
  - 不依赖 GMod navmesh 解决 MC 方块地形。
  - 对 MC 方块世界自写 A*，输入是方块坐标和 `IsSolid(coord)`。
  - mob 侧先定义 `IBlockWorld` 接口，并用 mock 实现开发。
- 关键判断：
  - 对方的方块系统有碰撞，不等于有寻路。
  - 方块不是 entity，而是对方数据结构里的运行时 mesh 数据。
  - 因此 NextBot 内置 `Path` 和地图 navmesh 只能保留给普通 GMod 地图/临时实验，不能作为最终 MC 地形寻路核心。
- 架构方向：
  - 薄 `BaseMob`。
  - 行为模块组合：Wander、Flee、SeekTarget、Chase、MeleeAttack、RangedAttack、ExplodeAttack。
  - 具体 mob = 类别状态机模板 + 行为模块 + 模型/声音/参数。
- 中立生物不应成为第三条平行继承链；它更像“友好基础 + 被激惹后进入敌对分支”。
- 第一架构里程碑应从 Sheep 开始：
  - mock 方块世界上 A* 游荡。
  - 受击切 Flee。
  - 检测草方块并 `SetBlockAt(coord, DIRT)`。

## 当前 Zombie 与新规格的关系

- 当前 Zombie 仍有价值，但定位要调整：
  - 它是战斗手感和动态 prop 避障试验台。
  - 不应继续把所有功能堆在单文件里。
  - 等 `BaseMob`、行为模块、mock 方块世界跑通后，再把 Zombie 迁移回新架构。
- 动态 prop 避障仍应保留为局部避障层，因为自写方块 A* 只解决 MC 方块世界，不自动解决玩家后放置的 GMod prop。

## BMB 初版实现

- 命名：
  - 对外名：BlockMob Base
  - 内部前缀：BMB
  - 实体前缀：`bmb_`
- 已创建：
  - `lua/autorun/bmb_autorun.lua`
  - `lua/bmb/sh_config.lua`
  - `lua/bmb/sv_block_world_mock.lua`
  - `lua/bmb/sv_pathfinder.lua`
  - `lua/bmb/sv_behaviors.lua`
  - `lua/entities/bmb_base_mob.lua`
  - `lua/entities/bmb_sheep.lua`
- 当前 Sheep 使用 `models/kleiner.mdl` 占位，不代表最终外观。
- 当前 A* 是 2D 方块网格版本，只验证接口和状态机接缝；高度差、跳跃、落差规则后续再加。
- 当前行为模块包括 Wander、Flee、EatGrass；SeekTarget/Chase/MeleeAttack 后续随 Zombie 迁移添加。

## Sheep v1 测试反馈

- `bmb_sheep` 能生成，控制台无报错。
- 第一版问题：
  - Sheep 只会原地转圈。
  - 受击后不会明显逃跑。
  - mock 草方块不可见。
- 第一轮修复：
  - Waypoint 目标 Z 贴合实体当前 Z，避免朝地面目标点转圈。
  - Waypoint 到达判断改为 2D 距离。
  - 受击时设置 `BMBMoveInterrupt`，打断当前游荡路径。
  - BMB base 增加显式 `OnTakeDamage`，保证扣血和 `OnInjured` 触发。
  - Sheep 测试血量从 `8` 提到 `20`，避免测试时太容易死亡。
  - 增加 `bmb_mock_show [radius] [duration]` 显示 mock 草/泥/石方块。
- 第二轮测试问题：
  - Sheep 仍会撞 Source 墙体。
  - Sheep 会从平台边缘走下去。
  - `debugoverlay` 方式显示 mock 方块不可靠，且离 mock 初始化区域远时会显示 0。
- 第二轮修复：
  - `bmb_base_mob` 在移动 waypoint 前做 Source `TraceHull`，前方有墙/prop 就放弃当前路径。
  - `bmb_base_mob` 在目标点下方做地面探测，没地面或坡度过陡就放弃当前路径。
  - `bmb_mock_show` 改为 server 发送 mock block 列表，client 用 `render.DrawWireframeBox` / `render.DrawBox` 绘制。
  - `bmb_mock_show all 12` 可显示所有 mock 方块，不受玩家当前位置影响。
- 第三轮测试问题：
  - Source 安全层检查整条 waypoint 过于保守，两侧近距离 prop 会让 Sheep 不动。
  - mock debug 方块仍不可见，疑似绘制在平台/地面下方或客户端材质状态不对。
- 第三轮修复：
  - Source 安全层改为只检查前方 `48` Source units。
  - 安全 hull 缩小为碰撞盒的 `0.65`，减少侧面 prop 误判。
  - mock world 初始化时记录地面 Z，`BlockToWorld` 用该 Z 绘制。
  - 客户端绘制前调用 `render.SetColorMaterial()`。
  - 新增 `bmb_mock_reset`：在玩家附近重建 mock world 并立即显示。
- 第四轮测试问题：
  - Sheep 会把玩家当作安全障碍，玩家站在面前时直接转 180 度离开。
- 第四轮修复：
  - `ShouldSafetyTraceHit` 默认忽略玩家、NPC、NextBot。
  - BMB base 默认只把 Source 世界几何和 prop 当硬避障。
  - 友好生物和玩家的交互后续应由 LookAtPlayer、碰撞推挤、短暂停留等行为处理，而不是安全层躲避。
- 第五轮测试问题：
  - 低矮、理论上能直接走上去的 prop/平台边缘会被 Sheep 顶住。
  - 原因是安全层把前方 hull 命中一律当墙，先于 `loco:SetStepHeight` 拦住了移动。
- 第五轮修复：
  - `StepHeight` 从 `18` 提到 `28`。
  - 增加 `MaxStepDown = 34`，允许小下台阶但拒绝大落差。
  - 前方 hull 命中时调用 `CanStepPastTrace`。
  - 如果上方通路 clear、落点有地、落点高度没有超过 step 高度，就允许继续走。
  - 这只是 Source 低台阶上/下处理；Minecraft 方块上 1 格、跳跃、落差规则后续在方块 A* 高度规则中实现。
- 第六轮测试结果：
  - Source 小台阶上/下通过。
  - 吃草变土通过。
  - mock 方块显示通过。
  - Flee 偶发不动。
- 第六轮修复：
  - Flee 入口清掉旧的 `BMBMoveInterrupt`。
  - Flee 候选方向从 6 个扩到 10 个。
  - 后半候选使用较短逃跑距离，降低目标点不安全概率。
  - `MoveToWorldPosition` 支持 `allowDirectFallback`。
  - 如果 A* 失败或 waypoint 失败，Flee 会短距离 direct fallback，保证受击后有明显移动反应。
- 第七轮测试问题：
  - BMB mob 与物理 prop 之间没有明显作用力。
  - 重力枪拿 prop 砸到 mob 时，prop 会穿过，mob 不会被“物理杀”。
- 第七轮修复：
  - BMB base 设置 `COLLISION_GROUP_NPC`。
  - BMB base 每 `0.08s` 扫描自身附近可移动物理实体。
  - 速度超过 `PhysicsImpactMinSpeed = 260` 的 prop 会造成 `DMG_CRUSH`。
  - 伤害按速度和质量缩放，单次上限 `80`。
  - 命中后给 prop 反向速度和力反馈，降低穿过去的感觉。
  - 同时实现 `OnContact` / `StartTouch` 兜底触发。

## MCSWEP 真实接口

- 文档：
  - `H:\工作视频\20251115毕业\interface-usage.md`
  - `H:\工作视频\20251115毕业\bmb_mcswep_对接补充.md`
- 命名空间：`MC`
- 方块大小：`MC.BS = 36`
- BMB 内部仍保留 `IBlockWorld` 形状，真实系统通过 `BMB.RealBlockWorld` adapter 接入。
- 已知映射：
  - `WorldToBlock(vec)` -> `MC.WorldToCell(vec)`
  - `BlockToWorld(coord)` -> `MC.CellWorldCenter(bx, by, bz)`
  - `GetBlockAt(coord)` -> `MC.GetBlock(bx, by, bz)`
  - `IsSolid(coord)` -> `MC.GetBlock` + `MC.GetBlockOrient` + `MC.BlockIsFullCube`
  - 方块类型 -> `MC.ResolveBlock("grass_block").id` 等数字 id
- `GetBlockAt` 返回数字 id；空气可能是 `0` 或 `nil`，需要实测确认。
- 当前 `IsSolid` 用 full cube 粗略判断，slab/stairs/fence 这类非完整方块后续要用 `MC.BlockBoxes` 细化。
- 当前最大缺口：
  - `MC.SV.Place(ply, ...)` 和 `MC.SV.Break(ply, ...)` 是玩家动作接口。
  - 羊吃草/蠹虫钻石头需要 mob 自主改方块，不能可靠传 `nil` 或 mob 当 `ply`。
  - 需要朋友提供类似 `MC.SV.SetBlock(bx, by, bz, id, orient)` 的服务端权威写入入口，走同步、碰撞 dirty、handler、save，但跳过玩家 reach/cooldown/admin 校验。
- 在这个入口完成前，`BMB.RealBlockWorld.SetBlockAt` 保持 stub；mock 不受影响。
