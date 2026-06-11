项目：GMod (Lua) 双人协作，把 Minecraft 搬进 GMod。
两个系统（不同命名空间，各自独立 addon）：
朋友的 MCSWEP（命名空间 MC）：方块/世界系统，已基本完成。自定义 IMesh 渲染 + greedy 碰撞，290 万方块不卡，方块是数据不是 entity，支持运行时增删。方块大小 36 Source units。已提供 MC.* 接口文档。
我的 BMB / BlockMob Base（命名空间 BMB）：mob 系统，刚起步。目标做 MC 全部 mob（计划到 26.1 全 roster），自己写 base，不依赖 VJ/DrGBase 那些现成的（动作僵硬、行为对不上原版）。
架构决策（已定）：
薄 BaseMob（Nextbot 实体）+ 可组合行为模块（Wander/Flee/SeekTarget/Chase/各种 Attack）+ 每类怪一个状态机。不是敌对/中立/友好三条平行继承链。中立 = 友好打底 + 受激惹切敌对。贴 MC 的 Goal 系统思路。
实体基类用 Nextbot（loco + 协程 think）。
寻路自己写 A*，跑在方块网格上。navmesh 盖不住动态体素，碰撞≠寻路。
方块接口：mob 是调用方，由我定接口、先对 mock 开发，再写 RealBlockWorld adapter 套在 MC.* 上。mock 和 adapter 满足同一接口，mob 代码不用动。
当前进度：
agent 写了 zombie 基础（攻击/寻路/血量），但没架构，待重构进上面那套结构。
我写了羊的吃草逻辑（草→土），没测试。
朋友刚把真接口（interface-usage.md）和维护文档发我，确认命名空间 MC、方块 36 单位。
已产出两份文档（我手上有）：
gmod_mc_mob_spec.md (v2)：架构 + 任务 + 第一个里程碑。
bmb_mcswep_对接补充.md：把 mock 接口映射到真 MC.*，含 adapter 方式和下面那个缺口。
当前唯一阻塞点：
朋友的改方块接口 MC.SV.Place/Break 是面向玩家的（要 ply、做 reach/冷却/管理员校验），mob 自主改方块套不进去；SetBlockRaw 又不做同步和碰撞重建，联机会 desync。需要他加一个非玩家的服务端写入入口（如 MC.SV.SetBlock(bx,by,bz,id,orient)）。在那之前，吃草的"改方块"那步先 stub，其余照常对 mock+flatgrass 做。
接口映射速查：
WorldToCell / CellWorldCenter 做坐标换算
MC.GetBlock(bx,by,bz) 取方块（返回数字 id）
IsSolid 要组合：GetBlock + GetBlockOrient + BlockIsFullCube
方块类型用 MC.ResolveBlock("grass_block").id
下一步：
找朋友要非玩家 SetBlock 入口（最优先）。
agent 重构 zombie 进薄 base + 行为模块 + 状态机。
写第二个怪（被动羊）验证 base 抽象。
自写 A* 对 mock 开发；羊在 flatgrass 上游荡，mock 方块画成调试框。
里程碑：羊游荡(A*) → 受击逃跑(状态机) → 吃草(接缝，改方块那步先 stub)。