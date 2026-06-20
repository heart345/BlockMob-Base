# Findings

## Zombie 双足程序化动画 + 转换器手臂垂下（2026-06-17）

- **确认僵尸没被当四足**：`reference.smd` 的 `body` bind rotation 是 0（直立），不像羊/牛的 `body -90° stand`；`root` 的 90°X 是所有 MC 模型通用的 Y-up→Z-up（羊也有），不是四足特征。判断"有没有被当四足"看 `body`/子骨骼 bind，不是 root。
- **僵尸手臂前伸是 attack 动画被烘成 rest pose**：`geo.py` 把 `animation.zombie.attack_bare_hand` 当 rest pose 烘进 arm bind（前伸标志姿态）。用户要程序化手臂（从垂下基线，避免在前伸 bind 上叠欧拉旋转踩 gimbal/合成坑），故从 `REST_POSE_ANIMATION_*` 移除 zombie 攻击条目；僵尸家族手臂垂下。改实现就同步改 golden（`test_*raised_arm` 拆 skeleton/zombie-family）。
- **关键帧采样器泛化进 base**：羊吃草的 `sampleSheepAnimation`/`applyPose`/`lerp` 提取为 `BMB.SampleKeyframeAnimation` + `ENT:ApplyBMBKeyframePose`（base client 块），僵尸攻击前挥复用同一套；双足 locomotion `ENT:ApplyBMBBipedLocomotion`（腿反相 + 手臂前伸 + 反相摆）。死亡侧倒/lookat/step/poof/缴械全复用 base，僵尸实体只配参数 + 写 `UpdateBMBVisualBones`。
- **僵尸摆轴/角度沿用羊的实测策略（初值待游戏调）**：双足摆轴先用 roll（对齐羊腿），手臂前伸/攻击/死亡侧倒（yaw）都给初值，按游戏表现迭代——骨骼局部轴语义只能实测，不从骨骼名/bind 猜。

## Base LookAtPlayerGoal：偶发注视是并行控制器，不是行为状态（2026-06-16）

- **MC LookAtPlayerGoal 的观感重点是“偶尔看一眼”**：服务端只在未看目标时低频轮询（当前 0.5s），首轮 15% 实测太频繁，默认已降到 6%，一次持续 2-4s；目标在范围内也不能每 tick 续期，否则会变成“玩家靠近就一直盯”。BMB 用 `BMBLookAtTarget` + `BMBLookAtUntil` NW 同步“看谁/看到何时”，超时、离开范围、吃草或死亡就清掉。
- **LookAt 不应进移动/行为状态机**：它和 Wander/Flee/Chase 并行，只控制头骨，不打断 locomotion，不抢 `RunBehaviour`。Base `Think` 里独立运行服务端控制器，客户端由每只 mob 的 `UpdateBMBVisualBones` 在普通 pose 分支调用 `UpdateBMBLookAtHeadPose(headBone)`。
- **轴向以 sheep 实测为准，别按骨骼名字猜**：当前通用映射采用 sheep preview 实测结果：head rot X 正=向左、负=向右；head rot Z 正=向上、负=向下；Y 不参与 LookAt。计算上先把目标转到 mob 本地空间，yaw 来自 local Y/X，pitch 来自 local Z/horizontal，然后分别钳制 `±70/±24` 并 Lerp 平滑；首轮 `±35` 实测 Z 太高。
- **头骨所有权要分支明确**：死亡和吃草 pose 提前 return，完全压过 LookAt；普通移动不再每帧锁死头骨，只在 LookAt active 时写头角度，目标消失后平滑回正再交回“清一次旧 pose”的逻辑。这样后续牛/猪只需要配头骨名、范围、概率、时长和 clamp。
- **随机环视也只同步低频目标，不同步每帧姿态**：看玩家已经只同步 EntIndex/timeout，客户端用玩家位置实时算方向；随机环视同理，服务端只在慢走/静止时每 1-3s 写一次 `BMBLookAroundYaw/Pitch/Until`，客户端复用 LookAt 的 Lerp。快跑时服务端清环视，客户端回正，避免 Flee/跑动时头乱扫。

## Sheep sound：脚步跟距离走，别跟计时器走（2026-06-16）

- **脚步应该挂在视觉步态的同一个距离源上**：当前程序化腿摆是 `phase += speed * FrameTime() * LimbSwingPhaseScale`，半个步态波长对应距离约 `pi / 0.09 = 34.9u`。Sheep 脚步因此用 `BMBSheepStepDistance += speed * FrameTime()`，阈值先取 `StepSoundDistance=35`，跨阈值播放并减掉阈值。走/跑只改变距离增长速度，脚步自然变密，不需要单独定时器。
- **Base 的旧 `MaybePlayStep` 是占位计时器，不适合 sheep**：base 仍有 `NextStepSoundTime` + zombie foot placeholder 给旧路径调用兜底；sheep 必须 override 成 no-op，由客户端视觉分支自己播脚步，否则会出现服务端固定 0.5s 脚步和视觉腿摆不同步。
- **声音来源先落到 MC 原始 OGG，方块 step 后续再接**：本轮基础版用 sheep 自己的 `step1-5.ogg`，吃草用 `dig/grass1-4.ogg`。后续接脚下方块 step 时，只换“迈步时播放哪个 sound list”，不要改步态时机；BMB 只决定迈步时机，block 系统决定材质声音。

## 死亡序列重做：骨骼倾倒 + 多帧 VTF poof（2026-06-16）

- **整只翻必须转 root，不能转 body**：SMD 骨骼层级是 `root → body → leg0-3` 且 `head → root`。转 body 只带动 body+腿，head 留原地（用户担心的"只身子倒"）；转 root 才整只翻。这类"哪根骨骼是共同祖先"先读 `reference.smd` 的 nodes 块，不要猜。
- **脚本化倾倒 > 物理尸体**：旧 `prop_physics` + 施力倒地方向随机、不稳。改成客户端按 `CurTime()-BMBStateStartedAt` lerp root 角度，方向固定、可控、可复现；死亡时刻用 `SetBMBState("dead")` 已网络同步的 `BMBStateStartedAt`，客户端直接读。
- **多帧动画 VTF 的最简布局**：`vtf.py` 加 `write_animated_bgra8888_vtf`——单 mip（`mipCount=1`）+ `numFrames=N` + NOMIP/NOLOD，data = lowres DXT1 + 各帧全尺寸顺序拼接，避免多 mip × 多帧的嵌套布局。8×8×4×8 帧 + header + lowres = 2160 bytes。粒子帧动画用逐粒子 `IMaterial:SetInt("$frame", n)` + `DrawQuadEasy`（待游戏确认不被批处理定格）。
- **MC poof 精确参数**（对照 `D:\BMBTools\mc26_1_poof_particle_behavior.md` / `ExplodeParticle`；凭记忆的“0.6s / 纯白 / 均匀大小 / 有渐隐”都是错的）：20 个；速度 `gaussian*0.02 + 扰动±0.05` block/tick；出生 bbox 内随机 `- vel*10`；尺寸 `0.1*(rand*rand*6+1)` block（多小少大）；寿命 `16/(rand*0.8+0.2)+2` tick（0.9~4.1s）；灰白 0.7~1.0；friction 0.9/tick + gravity -0.1（上飘 0.004/tick）；帧 generic_7→0；OPAQUE 无 alpha 渐隐（靠帧 + 到寿命移除消散）。素材 `LA` 8×8。**教训**：这类有源码/文档的行为，照文档逐参数复刻，别凭印象。
- **侧倒轴实测结果**：root 的 roll(第三分量)=后仰、**yaw(第二分量)=侧躺**（游戏实测确认，左右用 `EntIndex` 随机）。又一次印证骨骼局部轴语义只能靠游戏实测，不能从别的骨骼/绑定姿态推。

## 协作教训：改完必须同步 D 盘，否则游戏测的是旧代码（2026-06-15）

- 现象：sheep 头部 locomotion swing 在代码层（C 盘 `bmb_sheep.lua` + check 脚本）早已关闭，但用户游戏里头还在晃，“不知道为什么”。
- 根因：live addon（`D:\...\addons\gmod_addon`）没全量同步——D 盘 `bmb_sheep.lua` 还是旧代码（`walkHead`/`idleHead` 头摆还在），而游戏读的是 D 盘。**C 盘改对了不等于游戏生效**。本轮还发现 D 盘是“半同步”状态（`legSwingMax=25` 同步了，但关 head swing / 调频率那轮没同步）。
- 教训：每轮改完**必须** robocopy 整个 `gmod_addon` 到 D 盘，并对关键文件抽查 D 盘内容（grep 确认旧代码已消失），不能只 lint C 盘就以为完事。多 agent 协作时尤其容易只改 C 盘 / 只更新日志而漏同步 D 盘。

## 模型动画接入：腿摆 25° / 低频率 / 头部不随动（2026-06-15）

- **腿幅和腿频要分开调**：`legSwingMax` 只决定最大角度，`LimbSwingPhaseScale` 决定相位推进速度。当前 sheep 用 `legSwingMax=25.0` 放大腿摆，同时把 `LimbSwingPhaseScale` 从 Base 默认 0.18 降到 0.13，让走路和跑步频率都慢下来，不需要改 Base helper。
- **原版羊头不随身体 bob**：locomotion 层不再算 `walkHead/idleHead`，普通移动不写 head swing。为了不把后续看向系统挡住，normal 分支只在退出吃草/preview 后清一次旧 head angle/pos，不每帧 `setBoneAngle(head, zero)` 锁死头骨。
- **护栏跟随手感参数**：`check_sequence_animation_adapter.ps1` 现在同时锁定 `legSwingMax=25.0`、`LimbSwingPhaseScale=0.13`，并禁止 `UpdateBMBVisualBones` 重新出现 `walkHead/idleHead/headWalkSwing`。

## 模型动画接入：腿摆连续缩放进 base + 吃草低头轴向（2026-06-15）

- **腿摆“频率连续但幅度二元”的割裂**：sheep 程序化腿摆 `targetSwingAmount = speed > 8 and 1 or 0` 把摆幅做成开关——走和跑都满 7°，只有相位推进（频率 = `speed * frameTime * scale`）随速度变。观感上走路腿摆又大又慢、和跑步只有快慢之别。改法是把摆幅也连续化：摆幅强度 = `Clamp((speed-minSpeed)/(fullSpeed-minSpeed), 0, 1)`（再 Lerp 到 `MinAmount` 下限），走=小幅低频、跑=大幅高频、全程连续。
- **这套数学是通用的，上提到 base**：`UpdateBMBLimbSwing(speed2D)` 只产出连续的 phase 和 amount 并维护持久状态（`BMBLimbSwingPhase/Amount`），不碰具体骨骼；各 mob（牛/猪/羊）在自己的 `UpdateBMBVisualBones` 里决定摆几条腿、什么轴、最大角度。符合“驱动可复用、怪物差异在参数里”，且不干扰 sequence 动画路（sequence 路频率本就由 `SetPlaybackRate(speed/refSpeed)` 连续缩放，幅度由模型动画决定）。
- **吃草“抬头不低头”根因是符号反、不是轴错**：上轮推断“roll 不是俯仰、低头应是 pitch”是**错的**——游戏内 preview 实测证明 sheep head 骨骼的**俯仰/低头就是 roll 轴（`Angle(0,0,X)`）**，只是符号反了：正 roll（原 +66）=抬头，负 roll=低头，够地姿势 `roll=-55` + `posY=-12`。改 pitch 那版已回退。教训：MC→Source 转换 + bind_pose 旋转后，骨骼局部轴语义不能从“走路摇头用 roll”反推“低头一定不是 roll”；有 `bmb_sheep_pose_preview` + `bmb_sheep_pose_print_keyframe` 这套游戏内调姿工具时，直接实测取值，不要凭轴名推理。吃草最终做成有先后顺序的三段动画（pos 下探 → roll 低头够地 → roll -55↔-40 咀嚼两回 → rot+pos 一起收回）。
- **改实现就同步迁护栏，不削弱**：`check_sequence_animation_adapter.ps1` 原本断言 sheep 内含 `BMBSheepLimbSwingAmount` 等（编码了“摆幅逻辑在 sheep”的旧假设）；本轮把逻辑搬到 base，护栏相应迁到 base 并**加强**——新增“`UpdateBMBLimbSwing` 内禁止 `and 1 or 0`”防止退回二元。不是删护栏盲过测试。

## 一格宽走廊"出得来、进不去"（第十一轮，2026-06-11）

- **不对称现象本身就是诊断线索**：从走廊里能出来，说明 A* 和基本通行判定大概率没坏；从外面进不去，问题更像路径跟随层在入口处把一条已规划路径误判为不可走。
- 根因 1：`MoveAlongPath` 对 A* 路径每 tick 又调用 `IsMovementTargetSafe(safetyTarget)`。一格宽走廊 = 36u，羊在中线时离两侧墙各约 18u；旧的 `WallStopDistance=20` 会把入口侧壁当"贴脸墙"拦住。**A* 验证过的路径不应再被 Source hull 安全探测二次否决**；这套探测只适合裸方向移动、debug direct、legacy fallback。
- 根因 2：carrot 如果从当前位置直线追前方节点/终点外投，会在直角入口切角。正确做法是 **pure pursuit 沿路径折线取 carrot**：先把当前位置投影到路径折线，再沿折线量出前瞻距离；之后用廉价网格视线检查（逐格 `IsSolid`）判断 mob 到 carrot 的直线是否穿墙，穿墙就缩短到最后可见的折线点。
- 本轮实现要点：
  - `GetClosestPathCursor` 只在当前节点附近几段内找最近投影，避免 U 形路径误跳到后半段。
  - `GetPathPointAhead` 沿折线前推，终点外投沿最后一段方向且最多一个 goalTolerance。
  - `IsPathGridVisible` 逐半格采样 `IBlockWorld.WorldToBlock`，脚部格和头部格都非实心才算直视可达。
  - `MoveAlongPath` 删除 Source 安全复查；真正撞墙/卡住仍由 `loco:IsStuck` 和 no-progress watchdog 失败重选兜底。
- 风险/后续：当前 A* passable 只检查脚+头是否空，不检查脚下支撑；此前路径层 Source ground probe 会挡悬崖。退役路径安全探测后，目标选择层需要补"可站立格"枚举/过滤，尤其是 Flee 坑内采样和未来 3D A*。
- 吃草粒子决策已定：走**原版手感版**，不把 `MC.SV.SetBlock` 的破坏 fx 当吃草效果；羊自己补低头吃草动画、咀嚼音效、草屑粒子。

## 方块通行必须按 mob hull，不是中心点（第十二轮，2026-06-11）

- 用户复测第十一轮后发现：Tool Gun 右键目标只闪一下 `debug_move` 就回 wander；Wander/Flee 仍会从一格高方块下面钻过去，且方块角落能擦穿。
- 根因：
  1. Debug Tool 右键仍走 `BMBDebugMoveTarget` 的直线 direct steering，不走 `MoveToWorldPosition` / A*，所以在复杂方块结构里会被 direct 安全层秒退。
  2. `isPassable` / `IsPathGridVisible` 只查"中心点所在 foot cell + head cell"，没有考虑成年羊水平宽度；中心线可以贴着方块角过，但实体 hull 已经重叠方块。MC 成年羊宽 0.9 格（约 32.4u），不能像点一样从一格高洞和角落挤过去。
- 修法：
  - `bmb_base_mob` 新增 `IsBMBHullClearAtPosition`：用实体碰撞盒半径检查周围 solid block 的 XY AABB，Z 方向按实体高度覆盖的方块层检查。`IsBMBPathCellPassable` = 该 cell 中心位置 hull clear。
  - `BMB.Pathfinder.FindPath(start, goal, { mob = self })`：A* 邻居和目标格都调用 mob 的 hull passable。
  - mock/real `GetRandomWalkablePoint(origin, radius, mob)`：有 mob 时先用 hull clear 过滤候选，Wander/Flee 传入 mob。
  - `IsPathGridVisible` 改为沿直线每 1/4 格采样 exact position 的 hull clear，防止 carrot 从角上切过去。
  - Tool Gun 右键目标改为 path debug move：点击上表面时目标点上抬 4u，点击侧面时推出半格；`RunBMBDebugMove` 对 path target 调 `MoveToWorldPosition`。
  - `bmb_sheep` 碰撞宽度 28u -> 32u，接近 MC 成年羊，同时仍小于 36u 一格走廊。
- 风险/后续：hull clear 仍不判断脚下是否有 MC 支撑方块，保留 Source 地面可支撑的开发便利；可站立枚举/BlockHop/3D A* 时要明确支撑规则。

## A* 只懂 MC 方块，Source 地图安全层不能全退役（第十四轮，2026-06-11）

- 用户确认第十二轮三项通过后，发现两个回归：羊会沿 `path_carrot` 往 gm_flatgrass 地图砖墙走；平台边缘又会"跳崖"。截图 HUD 都是 `state=wander mode=path_carrot`，说明 A* 路径跟随正在正常执行，但没有 Source 地图安全兜底。
- 根因：第十一轮为了不误伤一格方块走廊，把 `MoveAlongPath` 里的 `IsMovementTargetSafe` 完全删除。这样 MC 方块走廊没被 Source hull 误杀，但 A* 只看 `IBlockWorld`，它不知道 Source 地图墙、地图平台边缘、玩家 prop。
- 正确边界：
  - **MC 方块通行**：由 A* + mob hull 占格判断决定，Source hull 命中 MC chunk 碰撞不能二次否决。
  - **Source 地图/prop/悬崖安全**：仍由移动层前向 trace/ground probe 兜底，因为这些不在 `IBlockWorld`。
- 修法：新增 path 专用 `IsPathSourceTargetSafe`：
  - 前向 hull 命中墙时，用 `IsSourceHitBMBBlock(hitPos, hitNormal)` 采样命中面两侧/半格内的 `IBlockWorld` cell；若命中来自 MC solid block，则忽略墙命中并只把地面 probe 截到墙前；若不是 MC solid，则返回 `false, "wall"`（HUD mode `path_wall`）。
  - 地面 probe 没命中、坡太陡、落差 > `MaxStepDown` 一律返回 `false, "cliff"`（HUD mode `path_cliff`，`FailBMBMove` 急刹）。
- 这比老的 `IsMovementTargetSafe` 更窄：不会用 `WallStopDistance` 否决 A* 方块路径，只负责 Source 世界没有被 A* 建模的危险。

## mock 切真环境炸出的对接坑（第十轮，2026-06-11）

- **接口的"隐式约定"在 mock 里看不出来，切真环境才炸**，这批都是接 RealBlockWorld 时发现的：
  1. `GetBlockAt` 返回值类型：mock 存的是 `BMB.BlockTypes` 字符串，real 拿到的是 MC 数字 id——行为层 `blockType ~= BMB.BlockTypes.Grass` 在 real 下恒真。**adapter 必须把 id 映射回 BMB 枚举**，行为层永远只见 BMB 类型（架构铁律的具体化）。
  2. "mob 所在方块"的歧义：mock 是 2D 平面（z 恒 0），`WorldToBlock(GetPos())` 怎么写都对；real 里 mob 原点在脚底、落在**脚部空气格**，吃草要查的是**脚下的支撑方块**——`GetPos() - Vector(0,0,4)` 再换算。凡"mob 站的格子"语义都要想清楚是脚部格还是支撑格。
  3. 2D mock 让 A* 的 3D 缺陷隐形：头部格检查（mob 高 44 < 2 格）在 z=0 世界恒通过，real 必须显式查 `z+1`。
  4. 参数和世界几何的耦合：`MaxStepDown 34` 在 Source 地图上没问题，但方块世界台阶就是 36 一格——**所有距离类参数都要按 36 的倍数想一遍**（StepHeight 28 上不去一格，是下一个要补的：MC 自动跳）。
- **加载顺序**：addons 按字母序加载，`gmod_addon` < `mcswep-main`，BMB include 时 `MC` 不存在。依赖 MC 的初始化（实现选择、ResolveBlock 缓存）都要懒执行（生成 mob 时/首次用到时），不能在文件作用域做。
- `MC.SV.SetBlock` 实测签名（`mc/sv_world.lua:392`）：`(bx, by, bz, id, orient, options)`，options 可直接传实体（等价 `{actor=ent}`）；返回 `ok, err`，`err == "unchanged"` 不算真失败（同类型覆写）。`MC.GetBlock` 空格返回 **0** 不是 nil。

## MC 官方源码可直接对照（2026-06-10 起）

- 用户本地有最新版 MC 反编译源码：`C:\Users\ADMIN\Downloads\Compressed\mcswep-main\out`（包结构 `net/minecraft/...`）。**做行为前先读对应 Goal 的真实实现，不要凭记忆猜**。
- 已确认的关键事实（第九轮 Flee 重写依据）：
  - `PanicGoal`（羊/猪/牛受击恐慌）**不看受击方向**：`DefaultRandomPos.getPos(mob, 5, 4)` 在 ±5 格随机选点，10 次候选过寻路校验取权重最优；全失败 → `canUse` false → 不恐慌（站住）。"朝反方向跑"是 `AvoidEntityGoal`（怕人生物：猫/兔）才有的，用 `getPosAway` 限制背离方向 ±90°。
  - 恐慌持续 = `lastDamageSource` 有效期 **40 tick（2s）**（`LivingEntity` 1420 行附近），每次受击刷新；当前段跑完才停（`canContinueToUse = !navigation.isDone()`）。所以原版友好生物受击后跑不远。
  - PanicGoal 速度倍率：羊 1.25、猪 1.25、牛 2.0、兔 2.2（各生物 `registerGoals` 里 `addGoal(1, new PanicGoal(this, x))`）。
  - BMB 对应：候选点可达性校验用前向 `IsMovementTargetSafe` 预检代替 MC 的寻路 malus（BMB 方块 A* 看不到 prop 和 Source 平台边缘）；"确认无路可逃"用**连续 N 次失败计数**（选不出点或 dash 起步即被挡）代替 MC 的纯选点失败——因为撞 prop 只有跑过去才知道。

## 移动手感根因三连（Fable, 2026-06-10）

- **NextBot `loco:Approach` 的减速区会和 watchdog 互相打架**：Approach 接近目标点时自动减速。两个后果：
  1. `goalTolerance(12) < nodeTolerance(18)` 时，离终点 12-18 units 是死区——节点推不进、到达判不过、carrot=终点在减速区，速度归零原地修正朝向 = 当初的"原地扭动"。到达阈值必须 >= waypoint 容差（现在都是 18 = 0.5 方块）。
  2. 终点减速把速度拖到 no-progress watchdog 阈值以下，正常到站被误判"卡住"返回失败，行为层以为没走成。解法：`GetPathCarrot` 在路径尾部把 carrot 投到终点**之外**，mob 全速跨过到达圈再停；watchdog 失败时距终点 <= 2x tolerance 按成功兜底。
- **不要用 `SetAngles` 做平滑转向**：每 tick SetAngles 打断客户端插值，视觉抽搐（CLAUDE.md 已立铁律）。正确做法 `loco:FaceTowards(target)` 每 tick 调 + `loco:SetMaxYawRate` 控转速。
- **`loco:Approach` 不顾朝向**：目标在身后会直接倒着走。`ENT:SteerTowards` 统一入口：夹角 > `TurnInPlaceAngle`(110°) 只转身不前进，转身期间要刷新 no-progress watchdog 的 deadline（原地速度 0 是预期，不是卡住）。
- **A* 路径头部是出发格中心**，可能在 mob 身后 ~20 units，起步前要跳过，否则开局回头拐一下。
- **Wander 不能按固定时长切段**：codex 之前"直线走 1.0-1.8s 就返回"的方案每段必刹停换向。正确节奏 = 选点 -> A* 完整走到 -> 到站长停顿。
- **原版 MC 游荡是"站很久、偶尔走一段"**：stroll goal 低概率触发，站立是常态。当前到站停顿 6-14s（`WanderPauseMin/Max`），单段行程 2-5 格（`WanderDistanceMin/Max`）。吃草同理是低频行为：吃完冷却 25-45s（`EatGrassCooldownMin/Max`）。
- **carrot 跟随的节点推进不能只看距离**：切弯时 mob 会从 waypoint 旁边掠过（横向 > nodeTolerance），距离判定推进不了，`GetPathCarrot` 从当前位置折回身后的漏过节点再前投，carrot 落在身后 → mob 掉头追 → 推进后又转回来 = 行进中"莫名转圈"。修法：距节点 <= 1.5 格且已越过"该节点 -> 下一节点"的垂面（dot > 0）就视为通过。垂面跳点要配距离上限，否则 U 形路径会提前抄近路。
- **安全探测必须跑赢刹车距离，失败后必须急刹**（平台边缘冻住/跳崖，2026-06-10）：
  1. 固定 48u 前向探测在 Flee 145u/s（刹车距离约 40u）下没有余量，探到悬崖时动量已经把 mob 带下去。探测距离要随速度放大：`max(ForwardSafetyDistance, vel2D x SafetyProbeSpeedScale(0.45))`。
  2. 安全检查失败只 return 不刹车，loco 残留速度照样滑下边缘。`FailBMBMove` 现在主动杀水平动量（x0.1，z 保留）。`loco:SetVelocity` 急停兜底不算"驱动移动"，CLAUDE.md 禁的是 SetPos/SetAngles 驱动位移/转向。
  3. 选方向（getSafeDirection）和移动中校验用的探测距离必须一致或前者更长：选方向短探测会放行"再跑几步就是悬崖"的方向，起跑后每个 slice 都在边缘失败，反复选向-失败空转 = Flee 在边缘冻住。现在选方向用 `min(lookAhead, 110)`。
- **`LengthSqr()` 阈值绝不能拿 1 当"是否有效向量"判据**（Flee 冻住真根因，2026-06-10 第七轮）：归一化单位向量的 LengthSqr ≈ 1.0，`> 1` 恒 false、`<= 1` 恒 true。`getSafeDirection` 因此从第一天起恒返回 nil（十方向选择从未运行，Flee 永远在走"朝 away 直线兜底"），`MoveAlongDirection` 也会拒收归一化方向。零向量守卫一律用 `> 0.01` / `< 0.01` 这种量级。调试教训：HUD mode 一直显示 `direct_blocked`（兜底分支）而非 `direction_blocked`（主分支），早该据此发现主分支根本没被执行，而不是反复调主分支的参数。
- **二元"安全/不安全"判定需要 StartSolid 例外和降级阶梯**（Flee 冻住第二轮根修，2026-06-10）：
  1. mob 贴住/被挤进 prop（尤其斜放 prop）时，安全 hull trace 从重叠开始（`StartSolid`），所有方向都判 Hit，抬高复查也在 prop 内 → 十个方向全灭 → Flee 冻住（HUD 卡 `direct_blocked`、vel 0）。StartSolid 时不能按墙处理：放行，撞不动的方向交给 loco 碰撞 + no-progress watchdog 换向。
  2. 单一探测距离（110）在围栏圈/石坡上会全方向失败（110 外落差超 MaxStepDown、坡度超标都是距离放大出来的假悬崖）。要做探测阶梯（110 → 48 → 24）：长档全失败就降档，让 mob 至少贴着障碍挪动。
  3. 阶梯选出的方向必须用**同档**距离在移动循环里复查（`options.safetyProbe`），否则短档选中、长档复查 = 选中即失败。短档的悬崖风险由"每 tick 复查 + FailBMBMove 急刹"兜住。
- **墙和悬崖必须分治，不能共用一个"危险距离"**（Flee 犹豫掉速根修，2026-06-10 第八轮）：撞墙无害——loco 碰撞自己就能挡住，提前避让墙只会让 mob 在离 prop 一个探测距离（110u）外就急刹-重选-再加速地"犹豫"，三面围起来时更是全方向被毙、压根不敢靠近；悬崖才需要跑赢刹车距离的前瞻。修法三件套：
  1. 安全检查区分失败原因（`false, "wall"` / `false, "cliff"`）；墙只在贴脸 `WallStopDistance`（20u）内算挡路，更远的墙放行但把地面探测截到墙跟前（探测点落进墙体/墙顶会误报悬崖）。
  2. 急刹（杀水平动量）只给 cliff 失败；wall 失败保留动量顺势转向（`FailBMBMove(mode, keepMomentum)`）。
  3. 每 tick 复查距离 = `min(选向档位, max(48, vel×0.45))`（`GetBMBTickSafetyProbe`）：悬崖前瞻随速度缩放即可，固定长档复查会把"减速点"推到危险还很远的地方。
- 行为节奏参数全部放 ENT 字段（每怪可调），行为模块只取默认值——符合"行为模块无怪物特化"的架构铁律。

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

## 2026-06-11: A* 3D 邻接 / BlockHop / drop

- Fable 的关键提醒成立：hop/drop 不能复用普通 `path_wall` / `path_cliff` 判定。+1 hop 冲向台阶时，Source hull 会把前方方块看成墙；drop 主动走下台阶时，地面探测会把目标看成悬崖。因此垂直边必须由 A* 标 action，并在移动层显式进入 `path_hop` / `path_drop` 豁免普通 path safety。
- waypoint table 采用兼容结构：`{ x, y, z, coord, action }`。旧 carrot/corner/flatDistance 继续读 `x/y/z`；只有新垂直逻辑读 `action/coord`。
- mock 世界保留 `SupportsVerticalPath=false` 很重要。mock 的 `WorldToBlock` 固定返回 z=0，如果强行开 3D，会生成没有视觉支撑的垂直边，反而污染平面调试。
- real `GetRandomWalkablePoint` 如果继续只抽当前 z，A* 虽然会跳台阶，但 Wander 很少自然选到上下层目标。现在 real 随机点会少量抽当前层附近；跨层候选必须有 MC solid 支撑，当前层仍允许 Source flatgrass 支撑。
- 风险/待实测：
  - `BlockHopTriggerDistance=42`、空中弱控 `0.08` 是首版手感值；如果台阶前跳早/跳晚，优先调这两个。
  - `IsBMBPathActionAtTargetLevel` 依赖 `WorldToBlock(GetPos()).z` 判断落到目标层；如果 MCSWEP cell 边界和 NextBot 落地 z 有偏差，可能需要加小范围 z 容忍。
  - hop/drop 豁免 Source safety 是必要的，但也意味着 malformed vertical path 不能靠 Source 墙/悬崖层兜底；后续若出现贴地图墙的垂直边，需要在 A* 候选或目标选择层过滤。

## 2026-06-11: hop 卡死与 A* 不可达泛洪（第十六轮）

- **"贴着方块不跳"不是触发距离问题，是状态机死锁**：hop 一旦尝试过（`hopStartedAt` 置位）就永远走空中弱转向分支，而该分支每 tick 刷新 no-progress watchdog——两个兜底互相抵消，mob 永久贴墙。教训：任何"豁免 watchdog"的分支必须有明确的退出条件（这里 = 真在空中）。
- **"右键卡一下"的本质是不可达目标的 A* 泛洪**：图搜索的最坏情况发生在"无解"时——有解时 A* 被启发函数拉着走，无解时它会展开整个连通分量。所以挡泛洪要三层：搜索空间约束（walk 边要求支撑 → 空域根本不进图）、预算（f 椭圆界 → 无解结论花费有上限）、时间切片（yield → 哪怕扫满也不卡帧）。yield 治症状，预算治成本，空间约束治根。
- **支撑语义必须包含 Source 刷子地面**：BMB 跑在混合世界（MC 方块 + gm_flatgrass），纯"MC 实心才算支撑"会把 Source 地皮判成虚空——drop 永远落不回地面、落在地皮上的目标永远不可达。`HasSupport` 顺序：先 MC 实心（表查询，零成本），无实心才 TraceLine 兜底（贵一个数量级，必须配 per-call 缓存）；StartSolid（整格埋地）不算支撑，挡掉"往地里钻"的候选。prop 故意不算支撑（A* 不感知 prop，交给移动层 Source safety）。
- **partial path 是把双刃剑**：对"走向不可达点"它给出原版手感（走到崖边停住），但对 Flee 它会把"撞墙失败"洗成"成功冲刺"，使"被围住冲几下放弃"的失败计数永远清不上去。结论：partial 默认开、Flee 显式关——任何依赖"失败信号"驱动状态切换的行为都要关 partial。
- **MCSWEP 网格与 flatgrass 地面的相对偏移是潜在变数**：`HasSupport` 的 trace 区间（格顶 → 格底下 6u）假设地面大致落在格子内部；若两者错位到边界附近，站立层判定可能漂移一格。复测时若寻路选层怪异，先查这里。

## 2026-06-11: 第十七轮三个回归/误杀的教训

- **直线距离不是路径进度**：`path_no_goal_progress` 用"离终点直线距离必须持续下降"度量进度，在带内墙的地形上是错误度量——合法绕路必然存在距离上升段。正确度量是"沿路径推进"（节点推进事件）；直线距离 watchdog 只该兜"原地绕圈"这种节点不推进的病态。
- **格子语义的采样点要配得上格子的物理含义**：HasSupport 第一版只采格子中心，隐含假设"支撑面 ≥ 格子宽"。Source 几何不按 36u 网格长——窄沿、窗台都比格子窄。凡是"格子 → 世界几何"的判定，单点采样都要慎重；中心 + 轴向偏移是最低配置。
- **NextBot 的 SetVelocity 跳跃必须保护起跳窗**：`loco:SetVelocity` 写入的竖直速度要等物理 tick 才把实体抬离地面；这期间任何 `loco:Approach`（地面驱动）都会把它冲掉。规则：起跳后到确认离地前（这里 0.15s 窗口），移动驱动必须走"空中"分支（只弱调水平、不 Approach）。第十六轮把"空中分支只在 not onGround 时进"写得太干净，反而干掉了第十五轮顺带提供的起跳保护——修 watchdog 豁免 bug 时把另一个隐性依赖一起删了，典型的回归形态。

## 2026-06-11: NextBot 起跳与物理枪持握（第十八轮）

- **落地态 `loco:SetVelocity` 写竖直速度无效**：NextBot 地面解算每帧把实体钉回地面，竖直分量当帧被吃。起跳必须 `loco:Jump()`（同步切跳跃态）后再 SetVelocity 覆盖弹道。诊断关键证据是"半砖成功、整砖失败"——半砖 18u < StepHeight 28u，所谓跳跃成功是走上去的；一旦发现"成功案例"全部 ≤ 步高、"失败案例"全部 > 步高，就该怀疑跳跃从未发生。
- **状态查询永远优于时间窗**：保护窗（0.15s）是在没有状态可查时用时间猜物理；`IsClimbingOrJumping` 是引擎真值。两者并存时"不一致谁说了算"就是隐患，有真值就删掉魔法数。同理重跳计时挂 `OnLandOnGround` 回调而非轮询 IsOnGround。
- **物理枪 vs loco 的拉扯**：抓起的 nextbot 抽不抽取决于被抓瞬间 loco 醒/睡（醒 = 重力下拽 + 出固体上顶 + 物理枪回拉的循环；睡 = 物理更新短路、安静悬挂连掉都不掉）。修法不是逐 bug 补，而是"被持握"升一等状态：loco 每 tick 缴械 + 行为挂起 + 移动入口拒新 + 松手向下踹一脚唤醒。GMod 沙盒里物理枪抓 mob 是高频操作，所有 mob 都从 base 免费继承这套。
- **held 与移动状态必须握手**：拾起时 Interrupt 掐掉 move 协程，hop 重跳计数这类局部状态随协程销毁——任何"挂起类"状态切换都要问一句：正在跑的状态机还有什么会在后台继续计数/计时？

## 2026-06-11: JumpAcrossGap 与 held gravity（第十九轮）

- **脚离地但一陷一陷 = 自定义跳跃仍在和引擎解算抢控制权**：`Jump()+SetVelocity` 比纯 SetVelocity 前进了一步，但用户看到的周期性小跳说明竖直速度仍可能只活 1-2 tick 就被地面/locomotion 状态吃掉。遇到这种"半成功"时，优先换成引擎为此设计的原子接口，而不是继续叠时间窗。
- **`loco:JumpAcrossGap(landingGoal, landingForward)` 是更合适的 BlockHop primitive**：它自己算水平/竖直速度、进跳跃态、处理落地。BMB 只给 A* 授权的 hop 落点和朝向；原生 hop 期间不能再 `SetVelocity` 弱控，否则等于又把方向盘抢回来。老引擎缺接口时才保留 `Jump()+SetVelocity` fallback。
- **落点 z 要按实体脚底语义给**：BMB waypoint 的 `target.z` 是 foot cell 中心，不是地表；NextBot landing goal 按实体 origin/脚底位置理解，所以给 `target.z - blockSize * 0.5`，即上层空气格底面/支撑方块顶面。
- **物理枪 held 的缴械要包含目标速度和重力**：只清 velocity 能压掉大抽动，但 loco 仍可能保留 desired speed 或重力求解，表现成轻微弹簧。held 每 tick 应同时 `SetVelocity(0)`、`SetGravity(0)`、`SetDesiredSpeed(0)`；drop 必须恢复原 gravity。
- **下一轮诊断签名**：若 JumpAcrossGap 仍不上台，先记录 0.5 秒逐 tick：`IsClimbingOrJumping`、`IsOnGround`、`vel.z`、`pos.z`。`vel.z` 起步低看 jump height/API；起步正常但瞬间归零看落地判定；`vel.z` 正常而 `pos.z` 不涨看 hull/碰撞。

## 2026-06-11: BlockHop 概率上台的变量化（第二十轮）

- **`path_hop` 触发不等于起跳条件合格**：只看"离目标中心足够近"会让太近、太慢、横向速度偏离的个体硬跳。表现就是 debug 反复点有时靠运气上台，有时低弧擦边。hop 需要准入窗口：距离、朝目标速度、落点都合格再交给 `JumpAcrossGap`。
- **Source 里 MC 视觉顶点需要余量**：MC 视觉上 45u 顶点够，但 Source hull 会和方块面/碰撞解算打架。默认 jump height 用 `1.6 * BlockSize`，落点给台面 +2u，观感变化小，但能避免"目标点在台沿/台面正好高度"造成擦边弧线。
- **先 backoff 再跳比重试硬跳便宜**：如果当前距离小于 0.85 格或速度不足，直接重跳只是在重复坏起点；退到约 1.15 格的助跑点，再带速度进入 0.85~1.4 格窗口，能把概率事件变成确定前置条件。
- **HUD 诊断比猜测更值钱**：每次 hop 记录 `d/face/v/apex/result`。下一轮如果失败，先看 HUD：`d/v` 不合格就是准入/助跑；`d/v` 合格但 apex 低就是 native jump 弧线问题；apex 足够但不上台才看 hull/collision 或目标层判定。

## 2026-06-11: Native Hop 失败签名与 MC Drop 高度（第二十一轮）

- **`JumpAcrossGap` 的失败签名已经明确**：成功样本 `dist≈47/face≈29/speed≈73/apex≈36`，失败样本 `dist≈36/face≈18/speed≈50/apex=0`。也就是说 native hop 在近距离爬台时不是弧低，而是根本没给实体上升位移。继续调 landing/jumpheight 收益低，默认应切到错帧手写弹道。
- **错帧手写弹道避开同 tick 顺序问题**：第十八轮 `Jump()+SetVelocity` 同 tick 仍可能被内部冲量/地面解算覆盖；第二十一轮改为先 `Jump()`，下一 tick 再 `SetVelocity`。如果这仍 apex=0，下一步就再延后一 tick 或等 `IsClimbingOrJumping` 真值稳定后写速度。
- **错帧后仍要防 path loop 抢回地面控制**：下一 tick 写入手写速度后，当前循环可能还没离地、`IsOnGround` 仍为真；如果马上交回 `Approach`，等于又把上抛压回。写速度后给一个极短空中控制窗口，只做 hop steering，不改普通落地重试语义。
- **手写水平速度要按飞行时间算**：不能简单保留 debug 助跑速度，否则会出现用户看到的“跳很远”。公式是水平距离 / 弹道飞行时间，再 clamp 到合理移动速度区间。
- **MC 默认主动下落高度是 3 格**：源码链路是 `WalkNodeEvaluator.tryFindFirstGroundNodeBelow` 用 `mob.getMaxFallDistance()`；`Entity` 默认 3，`LivingEntity#getComfortableFallDistance(0)=3`，`Mob` 无目标时返回 comfortable fall distance，羊无覆写。所以 BMB 的 A* drop 上限 3 是对的；主动性问题在 Wander 目标采样，而不是 A* drop 高度。

## 2026-06-12: Manual Hop 两段式 lift（第二十二轮）

- **`vz` 写入不代表实体真的获得 apex**：用户日志里 `hop velocity ... vz≈339` 已打印，但 `apex=0~12`，说明计算值没错，问题在后续碰撞/地面解算。以后看到这种签名，不要继续调 jump height；要看写入后是否被台阶侧面或 ground state 磨掉。
- **斜上速度会把 hull 推进台阶侧面**：一格爬升不是跨沟，贴台阶时水平分量过早生效会让 Source bbox 顶住垂直面，竖直位移也可能被碰撞解算吞掉。manual hop 改成两段：先竖直 lift，离开侧面后再水平落点。
- **短窗口内重复 `Jump()` 是针对落地解算的局部补丁**：只在 lift 阶段仍判 onGround 时踢，不恢复旧版无限保护窗；落地未到目标层仍按 `OnLandOnGround` + retry/fail 交还行为层。
- **第二十二轮实测成功但弧线偏高**：一格台阶已能上，成功样本 apex 约 54~65；但偶发能误上两格。下一步是调低 lift/jump 余量，而不是撤掉两段式。A* 仍只规划 +1 hop，不主动跳两格。
- **debug move timeout 是独立可用性问题**：长路径明明在路上却被 debug 指令放弃，后续按路径长度放宽 debug timeout / goal-progress watchdog；不要和 hop 成败混在一起。

## 2026-06-12: StepHeight / timeout / activity 收口（第二十三轮）

- **误上两格是 hop apex 与 StepHeight 合成，不是 A* 允许两格**：两格高差 72u，apex 54~65 本身够不到；但空中脚部高度超过 `72 - StepHeight(28) = 44` 后，Source 落地/step 解算可能把实体抬上两格。正确修法是 hop 期间临时压 `StepHeight=18`，不是把 apex 削到 <44（那会破坏一格可靠性）。MC 里跳跃和自动登阶不叠加。
- **debug path timeout 必须按路径预算**：右键远点的固定 duration 只适合裸方向 debug，不适合 A* path target。路径模式应按路径长度 / speed × scale + base 算总预算；还在移动/推进节点不因时间放弃，真卡住交给 no-progress watchdog。
- **跳后动作残留要靠状态驱动收口**：落地回调里重置 `CurrentMoveActivity` 并根据 locomotion 状态重选 idle/walk/run；Think 每帧也兜底选择 held/airborne/ground activity。以后套 MC 模型时只替换状态到动作的映射。

## 2026-06-12: 36.5 / BS 参数化（第二十四轮）

- **方块尺寸必须是运行时数据，不是常量**：BMB 的唯一入口是 `BMB.GetBlockSize()` / `BMB.BS`，规则为 `(MC and MC.BS) or 36.5`。`BMB.Config.BlockSize` 只保留兼容别名，新业务代码不直接读。MCSWEP 比 BMB 后加载时，每次取 size 都会刷新，避免文件加载阶段把 fallback 永久烙进参数。
- **mock 和 real 必须同尺寸**：mock 的 `WorldToBlock/BlockToWorld` 如果还用旧 36，而 real 走 36.5，所有 hop/走廊/drop 调参都会失真。第二十四轮已把 mock fallback 改 36.5，并让 mock/real/debug 全走同一尺寸入口。
- **尺寸派生值用 scale 或 cell 数表达**：goal/node tolerance = `0.5*BS`，carrot/corner/drop/hop 等用 scale；sheep wander/flee 用 cell 数（3~8 格、panic 5 格、min 1 格）。这样以后 MC.BS 再变，只改 `MC.BS` 或 fallback。
- **StepHeight 拆成两个语义**：普通 `StepHeight=28` 是 Source locomotion 绝对值，不是 `BS` 派生；它必须保持 > 半砖（36.5 半砖 18.25）且 < 整格。hop 期间临时 StepHeight 才是方块尺寸派生，必须是 `< 0.5*BS`，当前 `0.49*BS`，防止 apex + auto-step 误上两格。
- **apex 目标随 BS 而不是固定 54/65**：一格 hop 的默认 jumpheight/apex 目标改为约 `1.5*BS`，36.5 下约 54.75，留足 Source hull 余量；两格不上靠 hop 期间低 StepHeight 保证，不靠把 apex 削到危险低值。
- **裸数字复查清单**：grep `36 / 45 / 18 / 40 / 72 / 108 / 28 / 54 / 65` 时，尺寸派生必须参数化；保留项要能解释为非尺寸（声音 pitch、时间、调试 HUD z 偏移、旧 zombie 样机、Source locomotion 绝对值等）。新增 `scripts/check_block_size_parameterization.ps1` 专查高风险回归点。

## 2026-06-12: StrandedRecovery 与半砖分层（第二十五轮）

- **半砖/MC 台阶是表面高度问题，不是 path_cliff 调参问题**：locomotion 能走上半砖（StepHeight 28 > 18.25），但 A* 只有 solid/air 二值。半砖算 solid 会变 wall，算 air 会变 no-support/cliff。正确修法是等 MCSWEP 暴露 shape/floor height 后，把 support 与邻接改成按真实表面高度差判断；不要在 `path_cliff` 里塞半砖特判。
- **玻璃板顶不是合法寻路目标**：顶面比 mob hull 窄的 PARTIAL/窄碰撞应当"有碰撞但不可站立"，普通 A* 不应主动规划上去。这和 MC 原版怪物不会把玻璃板顶当路一致。
- **但已经站上非法节点时必须能脱困**：物理枪、外力、脚下支撑失效都可能把 mob 放到 BMB 语义非法的位置。此时普通 A* 的"只扩展 standable 表面"原则会让行为层空转。StrandedRecovery 是一个独立入口：只在当前 `IsOnGround` 且当前 cell 非 standable 时触发，目标不是寻一条路，而是尽快离开非法当前位置。
- **大范围搜索 + 远点 direct 是错误兜底**：用户直接在玻璃板上生成时出现卡顿，并沿玻璃板结构走下去。原因是 real world 的大范围 support/passable 查询成本高；同时远点 steering 会把玻璃板的真实碰撞当连续可走路线。修正为本地 bail-out：只采样周围短距离点，能走到邻近合法地面就走，否则侧向离开窄支撑并下落。
- **非法节点恢复不是寻路**：StrandedRecovery 的职责是尽快离开不合法当前位置，而不是规划到一个远处合法目标。它可以让实体掉落，因为触发前提已经是"实体被放到了普通 A* 不会选择的非法节点"；这和普通 path_cliff 防跳崖不冲突。

## 2026-06-13: 移动恢复/Drop/Hop/性能（第二十六轮）

- **StrandedRecovery 失败方向要有记忆**：本地 bail-out 如果方向顺序固定，撞障碍后会每轮选同一个点，表现为 `stranded_bail_blocked` 永久不动。恢复逻辑需要把失败方向短暂拉黑并旋转游标，才像“脱困”而不是“撞同一堵墙”。
- **drop 空中不是 hop 空中**：hop 需要空中弱控落到目标格；drop 是走出边缘后自然落下。把两者共用 `SteerBMBInAir` 会让 carrot 在身后时回头转向，产生用户看到的空中反向速度。drop 空中应保持朝向/水平速度，只刷新 watchdog。
- **hop 触发要先对齐 launch line**：只看距离会导致 mob 从侧面、墙角、台阶面前“试跳”，失败后看起来像不会找能跳的位置。起跳准入要包含 lateral offset；横向偏离或距离过远时先走 backoff/launch 点。
- **多 mob 性能先砍维护频率**：50 只 idle mob 掉帧时，首要嫌疑是每 tick 的通用维护，而不是单只移动控制。非 held 的 `Think` 可降到 0.1s；移动协程仍逐帧，held 仍每 tick 缴械。后续若 50 只同时寻路仍卡，再做 A* 全局分帧/预算队列。

## 2026-06-13: Drop 惯性、debug replan、spawn idle、峰值性能（第二十七轮）

- **移除空中回头后还要处理 Source 空中惯性**：drop 不再追 carrot 后，朝向问题解决了，但离边瞬间仍带完整 `pathSpeed` 水平速度。Source 空中摩擦小，mob 会被甩远。正确补丁不是恢复反向 steering，而是只按原方向钳制水平速度大小。
- **debug 目标不能把一次移动结果当命令结果**：`MoveToWorldPosition` 失败可能只是当前 partial/hop/dead-end 段失败，不代表玩家右键目标取消。debug path 应在 target/timeout 这一层持有命令，移动层一次失败只进入 `debug_repath` 并重算。
- **新生成 mob 的 idle 也是性能优化**：MC 观感上动物不是生成后一帧就集体散步；工程上这还把大量同帧出生的 wander/A* 起点错开。spawn idle 不能压过 debug/flee/stranded，否则会妨碍测试和受击反应。
- **A* yield 的单位要看“全场总量”**：单只 mob 每 64 iteration yield 看着不大，20 只同帧寻路就是 1280 iteration/帧。把 yield budget 下放到 `BMB.Config.PathfinderYieldEvery`，先降低默认单帧展开量，后续若仍卡再上全局 path 队列。
- **Wander 不应一轮连刷多条完整路径**：旧逻辑一轮最多 8 个候选，每个候选可能跑一次 A*；这对“单只羊努力找路”合理，但对 20+ 羊同步运行会形成尖峰。普通 wander 失败后随机退避比连续重试更接近 MC 的低频随机散步。
- **周期性实体球查找必须错峰**：`ents.FindInSphere` 这类全局查询即使有 interval，如果所有实体初始时间相同，仍会在同一帧一起爆发。生成时给 `NextPhysicsImpactCheck` 一个随机 offset，平均成本不变但峰值低很多。

## 2026-06-13: NextBot entity Think 不能作为性能阀门（第二十八轮）

- **一卡一卡的根因是 whole Think 被降频**：第 27 轮把 `NextThink(CurTime())` 改成 `NextThink(CurTime()+0.2)`，相当于把 NextBot 实体级更新降到 5Hz。移动协程和 path following 还在逻辑上推进，但身体/locomotion/客户端插值的外层节奏被拖慢，表现就是走路一顿一顿。
- **优化边界要分清**：可以节流 A* 展开、Wander 选点次数、physics impact 球查找、吃草/行为决策；不能节流整个实体 Think。NextBot 的 per-tick Think 是 locomotion 平滑度的一部分。
- **旧坑复现**：早前 `NextThink(CurTime()+0.08)` 已经制造过移动补油门感；这次 `0.2` 只是更明显。以后看到“性能优化后移动一卡一卡”，第一时间 grep `NextThink(CurTime()+...)`。
- **防回归规则**：检查脚本必须要求 `NextThink(CurTime())` 并禁止 `NextThink(CurTime()+self.ThinkInterval)`。如果 50 只仍不够，下一步是全局 path/AI queue，不是再次降 entity Think。

## 2026-06-13: hop face-distance 与 carrot 防跨洞（第二十九轮）

- **hop 准入要看“离方块面”不是只看“离目标中心”**：中心距 `dist≈34~38` 看似在旧窗口内，但减去半格后 `face≈16~20`，已经接近羊 hull 半径，等于贴在方块侧面起跳。日志证明这类跳 apex 经常为 0；成功样本在 `face≈31`。结论：BlockHop 需要 face-distance gate，贴脸先 backoff。
- **不要靠削 apex 修贴脸失败**：成功样本 apex≈50，失败样本 apex=0/36，说明弹道可以工作；问题是 launch 点太坏。调低高度只会损伤可靠一格 hop，不能解决 hull 顶侧面。
- **debug 目标是长命令，移动段是短尝试**：Tool 右键的初始直线预算不等于复杂路径预算。debug path 应在命令层持有 target，移动段只报告一次尝试结果；只要推进节点或靠近目标，就续命。否则复杂路径会“明明在走”但到时间回 wander。
- **carrot 可见性必须包含支撑**：只检查 solid 会允许直线穿过空气洞，因为洞里没有墙；Source safety 只探 carrot 位置又会漏掉中间 gap。pure pursuit 的“可见”在方块世界里应当是 hull clear + standable，每个采样点都用 A* 同一 standable 语义。
- **性能注意**：沿线 standable 采样会增加查询量，必须在单次 visibility 检查中复用 passable/support cache；若后续复杂路径掉帧，再优化采样步长或按 segment 缓存，不能删掉支撑语义。

## 2026-06-13: debug gap no-progress 与软碰撞（第三十轮）

- **长命令和不可达出口必须成对出现**：第二十九轮把 debug target 寿命拉到 120s 解决“还在路上却过期”，但也让不可达 gap/dead-end 的反复失败显得像死机。规则：推进节点/靠近目标才续命；连续无推进就 `debug_no_progress` 退出。不能用“缩短 debug 总寿命”修，否则长路径 bug 会回归。
- **`moved == true` 不等于命令有进展**：`MoveToWorldPosition` 在 partial/acceptPartial 语义下可能返回成功，但对最终 debug target 没有真正靠近。debug 命令层要看 path node advance 和最终目标距离，而不是只看一次移动调用的 bool。
- **MC 式实体碰撞先调碰撞组，再软分离**：默认改为 player-like collision group 是最轻的一步；如果玩家/羊仍重叠，软分离只负责水平错开，不应该重新变成 rigid support。
- **软分离是速度仲裁的末尾层**：它不能写进 steering、stranded、hop/drop、knockback 的内部逻辑，否则会互相吃速度或抖动。当前放在 Think 尾部，对当前 velocity 叠加水平分量并保留 z。
- **近邻扫描必须错峰**：玩家/羊推挤需要持续运行，但不能 O(n²)。用 `ents.FindInSphere` + `NextSoftSeparationAt` 随机 offset；后续如果 50+ 仍卡，先调 interval/空间查询频率，不要节流 whole Think。

## 2026-06-13: player/BMB hard support（第三十一轮）

- **collision group 不是 pair collision policy**：`COLLISION_GROUP_PLAYER` 在当前 GMod/NextBot 组合里仍允许玩家被 BMB bbox 垂直支撑。它可以作为默认组保留，但不能当成“玩家不会站在 mob 上”的保证。
- **软分离不能修仍存在的硬支撑**：如果 engine 仍在 player↔mob 这对实体上做硬碰撞解算，玩家先被托住，水平软推只是在托住之后尝试挪 mob，不能变成 MC 式穿插/滑开。必须先在 `ShouldCollide` 返回 `false` 关闭硬 pair，再让软分离接手水平错开。
- **禁用范围要窄**：只对 player↔BMB mob、BMB mob↔BMB mob 返回 false；prop/世界/其它实体不动。这样保留走路撞墙、prop 物理伤害、工具/子弹命中的余地。若后续发现 trace 选择受影响，再单独处理 trace，不退回硬支撑。

## 2026-06-13: MC-like collision rollback

- **上面的第三十一轮 hard-support 修法已撤销**：实测 `ShouldCollide=false` 让物理枪抓不起 mob，子弹不掉血，还和 prop 物理伤害链路冲突。这个结果说明当前 GMod/NextBot 实体碰撞、trace、physgun、damage 并没有被干净分层。
- **默认 GMod 手感优先级高于 MC 式穿插**：玩家能踩/挤到 mob 先接受；比起这点观感，物理枪、子弹、prop 伤害是核心调试/玩法链路，不能牺牲。
- **防回归规则**：不要再顺手加 `COLLISION_GROUP_PLAYER`、`SetCustomCollisionCheck`、`ShouldCollide`、软分离 velocity overlay。除非将来单独设计并验证“玩家移动碰撞”和“trace/physgun/damage”完全分层，否则保持 `COLLISION_GROUP_NPC`。

## 2026-06-13: Flee speed/activity stability

- **`BMBDesiredSpeed` 不能同时承担 loco 命令和动画意图**：path follower 会因 `path_corner`、drop、local safety 临时改变命令速度。如果 activity 用这个瞬时值，Flee/Panic 这类“行为上正在跑”的状态会在拐角被误判成 walk。
- **Base 需要稳定的行为意图速度**：新增 `BMBActivitySpeed` 后，动画/套皮看的是行为意图，loco 仍可按路径控制短暂降速。以后 Chase、Avoid、Attack windup 等也应按这个模式传 `moveIntentSpeed`。
- **Flee 的 corner slow 有下限**：panic 可以为了转弯略降速，但不能降到 run/walk 阈值以下。对 sheep，`RunSpeed=90`、阈值约 80；旧 `PathCornerSpeedScale=0.55` 会掉到 49.5，这是速度抖动和动作切换的根因。

## 2026-06-13: MC hurt feedback / iframes / knockback

- **MC 受击有两个不同计时器，且 `invulnerableTime=20` 不能直译成 1s 完全无敌**：本地 `LivingEntity.java` 中完整受伤分支设置 `invulnerableTime = 20`，同时 `hurtDuration = 10; hurtTime = hurtDuration`。但伤害冷却分支只有 `invulnerableTime > 10` 时挡同等/更低伤害；有效冷却是前 10 ticks = 0.5s。BMB 映射为伤害冷却 0.5s、红闪 0.5s。
- **无敌帧内重复命中不应刷新行为**：如果忽略的命中还刷新 `FleeUntil`、重选威胁或重启击退，连续攻击会让羊停在原地“思考”而不是跑。`OnTakeDamage` 的 invulnerable return 必须发生在扣血、`OnInjured`、flee refresh 和 knockback 之前。
- **击退是一等状态，不是一次 SetVelocity**：如果只在伤害事件里写速度，正在跑的 `MoveAlongPath`/Flee 会在下一 tick 用 steering 把速度抢回来。正确位置是行为调度：held 之后立刻进入 knockback，窗口结束后再交给 debug/stranded/flee/wander。
- **击退速度要重置而不是累加**：连续可接受命中应按新来源方向重置 capped 水平速度；否则连射或高伤害来源会把 mob 越推越快。第一版只做水平，保留 z 轴当前速度，避免打断下落/落地恢复。
- **来源方向不能用“面朝反方向”偷懒**：枪击/近战优先攻击者→mob；爆炸优先爆心/伤害位置→mob；fallback 才看 damage force。物理砸击 `DMG_CRUSH` 当前保留原 GMod/prop 伤害链路，不叠 BMB 击退。
- **Flee 中受击要刷新窗口但不重复打断段落**：`OnBMBInjured` 需要知道受击前是否已经在 flee。已在 flee 时只更新威胁和 `FleeUntil`，不再额外 `InterruptBMBMovement`，否则连续受击会把当前 move 段反复取消。
- **摔伤后做且独立处理**：摔伤和普通受击只共享“扣血”结果，不共享击退方向/状态；否则从高处掉落可能被错误地水平击退，污染 drop/stranded 手感。

## 2026-06-13: Knockback speed budget vs public movement intent

- **HUD `70/0` 的第二项是 `BMBDesiredSpeed`**：不是 Source maxspeed，也不是红闪材质状态。看到这个签名时，先 grep 谁写了 `BMBDesiredSpeed` / `MaintainBMBMoveSpeed(0)`。
- **红闪必须纯视觉，但这轮红闪本身是干净的**：`StartBMBHurtFlash()` 只写 `BMBHurtFlashUntil` / duration。实际冻结来自同一次受击启动的 knockback runner。
- **不要用 `BMBDesiredSpeed=0` 表达“steering 让位”**：这会污染 HUD、动画意图和后续行为接管，还可能让 `loco:SetVelocity` 的直接击退被 desired speed 0 吞掉。让位应由状态优先级 + 移动入口拒绝新命令实现。
- **击退需要两套速度语义**：公开的 `BMBDesiredSpeed/BMBActivitySpeed` 继续表达受击前的移动/动画意图；内部的 loco desired speed 只作为击退预算，保证水平 `SetVelocity` 能推动实体。第三十四轮用 `BMBKnockbackDesiredSpeed` / `BMBKnockbackActivitySpeed` / `BMBKnockbackLocoSpeed` 分开这三件事。
- **启动当帧先给一次速度**：伤害事件和行为协程之间可能隔一轮 scheduler。`StartBMBKnockback` 立即写一次水平 `loco:SetVelocity`，后续 `RunBMBKnockback` 再衰减维护，视觉上更像“被打的一瞬间弹开”。

## 2026-06-13: MC knockback lift and airborne flee

- **击退状态窗口不能承担“硬直”语义**：MC 生物受击后会被打出冲量，但 AI 仍会继续尝试跑，尤其被击飞在空中也不会完全停思考。BMB 的 knockback window 只负责防止 steering 吃掉初始冲量，窗口应短（当前 0.12s），而不是 0.35s 这种可见停顿。
- **地面击退需要一点 z 速度**：MC `knockback` grounded 分支会给 `min(0.4, y/2 + power)` 的竖直速度；BMB 不能只水平推，否则看起来像被平移。第三十五轮用 `loco:Jump()` 先打开跳跃态，再给 170~240u/s 的竖直速度；空中受击保留当前 z，不二次弹高。
- **第一下没击退常见原因是行为协程还没接上**：刚生成/initial idle 时，伤害事件可能早于下一轮行为调度。击退必须在 `StartBMBKnockback` 伤害 tick 当场写入 velocity，不能等 `RunBMBKnockback` 下一轮才开始。
- **空中 flee 需要放宽起点合法性**：被击飞后脚下 cell 不是 standable，普通 A* 从严格合法起点出发会失败或等落地。Flee 在 airborne start 时传 `allowStrandedStart`，只放宽起点，不放宽目标/路径节点合法性，保持“空中也在尝试跑”的观感。

## 2026-06-13: Zombie Phase 1 hostile slice

- **第二只怪要验证 Base，而不是复制一份 Base**：Zombie 的价值在于覆盖索敌、追击、近战、声音、受击和移动优先级。如果加 Zombie 需要改出一套平行移动/攻击架构，说明 Base 抽象失败。本轮把敌对差异压到薄状态机和参数里。
- **旧 `mcgm_zombie.lua` 是 legacy 对照，不是迁移模板**：它依赖 Source navmesh / `Path("Follow")` / 自己的避障和手动角度控制，和 BMB 方块 A*、hop/drop、held、knockback、stranded 管线不是同一套世界模型。新 `bmb_zombie.lua` 必须继承 `bmb_base_mob`。
- **Hostile 行为拆三层**：`SeekTarget` 只决定目标；`Chase` 只做短时间片 BMB A* 追目标当前位置；`MeleeAttack` 只处理 range、windup、cooldown、DamageInfo。这样以后 Skeleton 复用 target/chase，Creeper 复用 target/chase 但换 attack，Avoid/Neutral 也能组合。
- **追移动目标要短时间片重规划**：`MoveToWorldPosition` 是阻塞式路径执行，如果一次性追玩家旧位置，玩家移动后会拖到旧终点才重算。Chase 用约 0.35s timeout + `acceptPartial=true`，每段消费已有 BMB path，一小段后自然重查目标位置。
- **攻击停顿是 attack lock，不是全局硬直**：MeleeAttack 用 `BMBMeleeLockUntil` 让挥击 windup 时短暂停步/面向目标，但不改 Base 的 knockback/held/debug 优先级。受击、物理枪、debug 仍能打断或优先接管。
- **第一版目标只锁玩家**：这是最小可测切片。后续村民、铁傀儡、其它 mob、仇恨/中立规则应扩 `CanBMBTarget` 或 target module 配置，不要把特殊 case 写死进 `SeekTarget`。
- **外部 spec 未读风险**：`specV3_zombie_phase1.md` 在 H 盘，读取被审批工具故障挡住。本轮实现的是 repo 内 Phase 3 约定的最小纵向切片；若 spec 有额外硬要求，下一轮按差异补。

## 2026-06-13: Zombie first retest fixes

- **`attack_ready + vel 0/0 + 高低差` 不是寻路没路，是攻击准备抢跑**：旧 `Chase.Run` 只看水平距离，玩家在一格高平台边缘时水平很近，于是 Zombie 进入 `attack_ready` 停住，而没有机会继续 A* / hop。近战 range 必须拆成 horizontal range 与 vertical range。
- **攻击距离加长不能顺手加高差攻击**：把 `AttackRange` 从 38 提到 52 会让同层不再贴脸才挨打；但如果 vertical 也跟着 range 变大，就会继续从台阶下打空气。Zombie 现在单独设 `AttackVerticalRange=28`，小于一个完整 36.5u 方块。
- **追移动目标的时间片不能太短**：0.35s 同时承担“重规划频率”和“本段移动 timeout”时，远距离目标容易刚算完路/刚起步就返回。拆出 `ChaseSegmentTimeout=1.0`，重规划仍频繁，但给移动段足够推进时间。
- **占位模型 activity 要按模型能力映射**：Classic zombie 模型在部分环境下 `ACT_RUN` 腿部不动，`ACT_WALK` 稳定。Base 需要 per-mob `WalkActivity/RunActivity/JumpActivity` 映射，后续换 MC 模型只改映射表。
- **MC 红闪不是曲线**：BMB 之前用 remaining time 做颜色强度，表现成渐变。用户对照 MC 后要求命中后立刻红，持续 hurt/invulnerability window 后恢复。Base 改为固定红 0.5s，脚本禁止再把 Draw 写成 fade curve。

## 2026-06-13: Zombie attack pressure and final-hop completion

- **近战 windup 不是硬直**：第一版为了看清攻击，把 `BMBMeleeLockUntil` 和 `MaintainBMBMoveSpeed(0)` 塞进 MeleeAttack/Zombie。实测表现为 HUD 速度 0、攻击时停住，和 MC Zombie 边挥手边贴近不一致。正确做法是只启动 gesture/timer/cooldown，移动通道继续由 Chase/attack_ready 前压。
- **攻击期间的速度语义也不能写 0**：这和前面击退 `70/0` 是同类坑。`BMBDesiredSpeed=0` 会污染 HUD、动画和后续追击。Zombie 现在用 `AttackMoveSpeed=92`，attack_ready 继续 `SteerTowards(target)`。
- **追击失败不能立即丢目标**：高两格或暂时不可达时，`Chase.Run` 失败不代表目标消失。旧状态机会 `TargetEntity=nil` + 等待，造成“走几步停一下/回 idle”。现在目标仍有效就保留，短暂 `chase_repath` 后重算。
- **final hop 不能只靠 2D 到达**：复杂台阶截图显示 `path_hop dist≈5.6` 后直接 `idle dist:0`，说明最终节点被 2D/格语义提前消费。新增 `IsBMBVerticalPathNodeReached`，要求 onGround、目标 cell level、实际脚底高度达到目标脚底高度附近，才推进 hop/drop 或判 final reached。

## 2026-06-13: Zombie chase smoothing and close-lift hop

- **chase 的时间片也会变成肉眼节奏**：1s 一段的 `MoveToWorldPosition` 在远距离追击中仍会看到“走一会停一下”，尤其每段重新算路/转向时。Zombie 追击段拉到 2s，失败重算 delay 降到 0.05s，减少分段感。
- **羊的 TurnInPlace 规则对敌对追击偏保守**：Base 为了羊不倒着走，yaw 差大时会原地转。Zombie 追击时 path carrot/目标移动导致角度变化更频繁，原地转会像停顿。Zombie 单独把 `TurnInPlaceAngle` 放宽到 170。
- **贴脸 hop 需要和羊区分**：羊之前 face-distance gate 是为了避免无助跑贴墙反复失败；Zombie 在狭槽/台阶下追击玩家时，backoff 点常不可用，导致 `path_hop` 与 `chase_repath` 来回切。给 Zombie 开 `BlockHopAllowCloseLaunch`，只在 lateral 对齐且距离不远时允许 `close_lift`，仍走两段式先竖直抬升再水平前压。
- **高处贴脸仍可能需要 target offset**：如果玩家在 Zombie 正上方，水平向量接近 0，`SteerTowards(target)` 没有方向。若第三十九轮后仍看到高两格贴脸不动，下一步不是再调 hop，而是给 chase_repath/target selection 增加“不可达高处目标的邻近可走 offset 点”。

## 2026-06-13: Zombie MC-style direct chase

- **开阔地追击不应该全程依赖 path carrot**：A* 擅长迷宫和方块高低差，但在玩家可见的平地上，持续追“当前玩家位置”的直线 steering 更像 MC，也避免每段路径重算带来的停顿/拐弯感。结论：敌对 Chase 应先判断能否直追，不能直追再交给 BMB A*。
- **直追不是绕过安全层**：`chase_direct` 必须同时满足 line of sight 和短距离 `IsMovementTargetSafe`，否则会把“看得到玩家”误写成“可以冲下悬崖/撞墙”。安全探测失败、视线断开、迷宫转弯时，立即回到 `MoveToWorldPosition`。
- **旧 `mcgm_zombie` 的手感可参考，架构不能复用**：它直盯玩家的追击观感是对的，但 `Path("Follow")` / navmesh / 旧避障不适合动态方块世界。BMB 的版本只借“视线段直压”这个策略，不借实现。
- **高处不可达目标要保持仇恨，不要伪移动**：玩家在正上方时水平向量接近 0，`SteerTowards(target)` 没有实际方向；反复 `chase_repath` 会在 HUD 上像追击，实际不动。A* 失败且目标近处高于攻击范围时用 `chase_stalk`：保留 target、面向玩家、短周期重查，表现为贴底等待。

## 2026-06-14: Hop completion should trust foot height, not cell equality

- **`WorldToBlock` / `MC.WorldToCell` 的 z equality 在台面边界不可靠**：Source bot 脚底落在方块顶面时，位置可能是 `top - epsilon` 或物理解算一帧内略低，`floor(pos.z / BS)` 会给低一格。用它要求 `currentCell.z == node.coord.z` 会把已落地的一格 hop 判成未到达，表现为 `path_hop` / `debug_repath` 来回切。
- **第 38 轮的“不能只看 2D”方向是对的，但 cell equality 过严**：正确的垂直动作完成条件是“已落地 + 实际脚底 z 接近目标 foot z”。没跳上去时差一整格，不会误通过；真落到上层时即使 cell floor 抖动，也能推进节点。

## 2026-06-14: Hop cramped backoff cannot be mandatory

- **`face_close` 不一定代表应该继续后退**：第 29 轮加 face-distance gate 是为了防贴脸硬跳；但新日志显示一格狭窄空间里 ideal backoff 点本身 hull 不通，实体既退不到 `minFace`，又因为没到 `minFace` 不起跳，形成 `path_hop` / `debug_repath` 循环。
- **近距离起跳必须有“退路被堵”这个前提**：不能把 `BlockHopAllowCloseLaunch` 全局开给羊/Base，否则会回到旧贴墙乱跳。Base 现在只在 `backoffBlocked=true`、横向对准、`face >= 0.52*BS` 时用 `blocked_close_lift`，保留可退就退、过贴脸不跳的约束。
- **drop 的脚底高度容差应与 hop 分开**：hop 需要严格确认上台；drop 落地时 Source 解算可能让脚底比目标 foot z 高 8u 以上但已经在地面，单一 `abs(deltaZ)<=8` 会误报未完成。drop 用稍大的上容差，不放宽 hop。

## 2026-06-14: Hop launch points need overhead lift clearance

- **standable 不是 launchable**：A* / `IsBMBHullClearAtPosition` 能证明一个点站得下，但 BlockHop 两段式弹道还要求起跳点上方有一段净空。低顶台阶里，理想 backoff 点可能 `hull=true`，但第一段竖直 lift 立刻撞头，表现为 `vz≈330` 正常、`apex≈10-15` 异常低。
- **backoffBlocked 要包含 lift clearance**：理想 backoff 点如果 `backoffLift=false`，就应该和 hull/safety blocked 一样触发近距 launch 逻辑，而不是继续把实体拉到低顶下面起跳。
- **调试日志要区分三类堵点**：`backoffHull=false` 是方块/身体空间不够；`backoffSafe=false` 是 Source safety 不安全；`backoffLift=false` 是能站但不能从这里跳。三者的修法不同，不能都混成 `face_close`。

## 2026-06-14: Low-ceiling hop needs hysteresis

- **低顶安全窗口会非常窄**：`log2` 显示 `backoffLift=false` 时，`face≈18.x` 往往 `currentLift=true`，但 `face≈21.x` 就 `currentLift=false`。如果 close threshold 正好是 19.0，实体会因为运动惯性在“没到阈值”和“撞头”之间来回摆，表现为 path_hop/debug_repath/转圈。
- **低顶场景的 close threshold 应有单独有效值**：普通 blocked close 仍需要保守的 `0.52*BS`；但 `backoffLift=false` 时，把 `effClose` 降到 `0.48*BS` 能扩大可跳窗口，且仍不放开真正贴墙（0~10u）硬跳。
- **一格 upward overshoot 是进展，不该马上重算**：低顶/复杂碰撞偶发把实体落到目标节点上方一格。只要已经 grounded 且 XY 贴近当前节点，这比“没跳上去”更接近目标，应推进路径；否则 debug 会把一次有效上升洗成失败 replan。

## 2026-06-14: Prop support is not stranded support

- **GMod prop 顶面不是 A* 支撑，但也不是 StrandedRecovery 目标**：`HasSupport` 忽略 prop 是正确的，否则 A* 会把玩家摆的 prop 当稳定地形来规划；但实体已经站在 prop 上时，`IsOnGround` 表示 Source 物理当前能托住它，不应进入玻璃板/栅栏那套非法网格逃生。
- **prop 上的边缘判断应交给 Source safety**：从 prop 顶面移动时，当前步用 `IsMovementTargetSafe` / `path_cliff` 的 hull + ground trace 判断墙和边缘，不能用 BMB standable 语义判“脚下没有 MC 支撑所以搁浅”。
- **兜底必须是当前位置局部的**：`prop_direct` 只在 A* 从 prop-supported 起点失败时短时间直线 steering，并且仍保留 cliff/wall safety；它不是把 prop 写进 `IBlockWorld.HasSupport`，也不是恢复沿玻璃板网络走远点的旧方案。

## 2026-06-14: Zombie Phase 2 instant melee and ambient sound

- **“进入攻击范围就出手”应由共享 melee 支持，不该写进 Zombie 状态机**：`AttackHitDelay=0` 是参数，`MeleeAttack.Try` 负责同帧 `ResolveHit`；非零 delay 仍保留给有 windup 的未来怪物。这样 Phase 2 Zombie 是一个参数化用例，不是分叉实现。
- **命中反馈只有实际命中后才播**：玩家受伤音效挂在 `OnBMBMeleeHit`，而不是挥手开始时；miss / cooldown / 目标离开 range 不应播受伤音。
- **贴身重叠需要击退方向兜底**：玩家和 Zombie 水平位置非常近时，`target - mob` 可能接近零向量。用 mob forward 作为 fallback 可以避免“咬到了但没有推开”的手感断层。
- **地面玩家的 z 击飞有 Source 阈值/地面状态问题**：直接 `Player:SetVelocity(Vector(0,0,z))` 在玩家站地面时可能被 ground movement 同帧吃掉，玩家跳起时才明显。近战击飞需要先 `SetGroundEntity(NULL)`，并给地面玩家单独最小 z 阈值；下一 tick 只补缺失 z，避免水平击退叠两次。
- **直追/攻击准备也是移动入口，必须做 cliff safety**：`path_cliff` 只能保护 `MoveAlongPath`。Zombie 的 `chase_direct`、`attack_ready`、`chase_repath` 直接 `SteerTowards(player)`，如果不复查实际 steering target，就会绕过 A* 和 path safety 从 Source 高台边缘走下去。所有直线压迫应先走共享 `ApplySafePressure`，不安全时停在边缘并杀水平动量。
- **MC ambient 不是固定随机区间**：源码 `Mob#getAmbientSoundInterval() = 80`，`baseTick` 用 `random.nextInt(1000) < ambientSoundTime++` 播放，播放后 `ambientSoundTime=-80`。BMB 需要模拟 20Hz tick 概率，并从 Base `Think` 驱动；只在行为协程顶部检查会被长 chase/debug/stranded 阻塞。

## 2026-06-14: Point-blank melee direction and MC block direct-cliff safety

- **近战击退方向要在接近过程中缓存，不能等命中帧现场猜**：贴脸 `dist:0.0` 时，`target:GetPos() - mob:GetPos()` 退化成零向量，mob forward 又可能被转向/碰撞扰动，表现为击退时有时无。共享 `MeleeAttack` 应在 chase/attack 阶段缓存最后一次有效的水平目标方向，命中、DamageForce、SetVelocity 共用这条方向。
- **方向缓存仍然必要，但不是击飞飘的根因**：贴脸 `dist:0.0` 会让方向退化，缓存解决水平方向不稳定；竖直击飞时好时坏另有根因，见下面的 `Player:SetVelocity` 叠加语义。
- **direct chase 的 cliff safety 有两种世界模型**：Source trace 能保护地图边缘和 prop 顶面，但 MCSWEP 方块的合法性还要看 BMB standable 语义。`IsMovementTargetSafe` 先跑 Source wall/ground，再在“当前/前方附近确实是 MC 方块支撑”时沿线采样 BMB standable；纯 Source/prop 支撑不启用这层，避免把 prop 顶面写进 A* 地形。

## 2026-06-14: MC top-face boundary is not a cliff

- **BMB standable 查询不能直接吃精确脚底点**：MCSWEP 完整方块顶面/边界上的 world 坐标可能被 `WorldToBlock` 量化到脚下 full-cube solid cell，而不是脚所在的空气 cell。把这个结果直接交给 `IsStandablePosition` 会把完整平地误判为 `not passable/not standable`，HUD 表现为 `chase_repath_cliff`。
- **运行时安全层要采“略高于脚底”的 foot sample**：直追/attack_ready 的 MC grid safety 不是 A* cell 枚举，它在连续 world 坐标上采样，所以应先把样本抬高一个很小的量（当前 `max(4u, 0.12*BS)`）再做 hull/standable 查询。这个高度远低于半砖，不会把真实边缘变成可走；边缘外的 lifted foot cell 仍然没有 support。
- **同一 helper 应覆盖 carrot 视线和 stranded 当前点**：如果 path/carrot visibility 用精确脚底点，可能把合法方块路径误判不可见；如果 current standable 用精确脚底点，可能错误进入 StrandedRecovery。Base 统一用 `GetBMBGridFootSample` 兜住这些边界。

## 2026-06-14: Player:SetVelocity is additive, so launch must cancel residual velocity first

- **玩家击飞时好时坏的根因不是 z 数值太低，而是叠加语义**：`Player:SetVelocity(v)` 会把 `v` 加到当前速度上。命中瞬间玩家被 hull/地面挤压时可能带 `vel.z=-100` 之类残留，直接加 `190z` 只剩约 `90z`；低于 Source 的 grounded-player 脱地阈值后，下一 tick 会重新着地并夹掉 z。
- **稳定写法是“抵消当前速度 → 写目标速度”**：先 `SetGroundEntity(NULL)`，记录 `velocityBefore`，再 `SetVelocity(-velocityBefore)` 抵消所有残留，最后 `SetVelocity(direction * horizontal + Vector(0,0,launchZ))`。这样叠加 API 被转换成确定速度写入，launchZ 不再被残留 z 污染。
- **旧的多 tick correction / SetPos nudge 已撤掉**：它们是在跟玩家 movement 抢帧，容易让问题更随机；一次干净的速度写入更可预测。调试入口保留为 `bmb_melee_knockback_debug 1/0`，只打印本次应用的 before/desired 信息。
- **屏幕反馈必须挂在实际命中后**：轻微 `ViewPunch` / `ScreenShake` 应在 `OnBMBMeleeHit` 里触发，miss、冷却中挥手、目标离开 hit slop 都不能晃屏。

## 2026-06-14: Head-standing melee is overlap, not general vertical reach

- **不要为“玩家踩在头上”拉高普通 `AttackVerticalRange`**：Zombie 之前把普通垂直攻击范围压到 28u，是为了让高一格平台/隔层目标继续 chase/path，而不是在脚下挠空气。如果直接把它调到 70u 以上，这个旧 bug 会回归。
- **踩头应建模成窄重叠命中**：当目标在 mob 上方、水平距离极近时，说明两个 hull 已经发生了垂直重叠/堆叠，这时可以用单独的 `AttackVerticalOverlapRange` + `AttackVerticalOverlapFlatRange` 放行。这个分支不影响普通高差目标。
- **参数仍属于怪物实体，不属于 base 特判**：共享 `MeleeAttack` 只识别可选字段；Zombie 当前用 86u vertical / 24u flat。后续体型更高/更矮的怪只改自己的参数，不写 `if zombie`。

## 2026-06-14: Melee travel distance is horizontal speed times airtime

- **z 击飞稳定后，水平击退会被滞空时间放大**：`AttackKnockback=210` 单看速度不夸张，但配合 grounded `launchZ=190` 的空中时间，实际能把玩家带出 4-5 格。
- **先调水平，不轻易动 z**：z 参数刚用于跨过 Source grounded-player 阈值，动低容易让“击飞时有时无”回归。要把总位移从 4-5 格收回 2-3 格，优先把水平值降到约 150。

## 2026-06-14: Sheep Flee 81/90 is the run-threshold clamp

- **HUD 里的 `81/90` 不是随机速度源**：旧 sheep `WalkSpeed=70`、`RunSpeed=90`，Flee 的 `minPathSpeed` 用 run activity threshold `((walk+run)/2)+padding`，所以过弯/局部控制时会显示约 `81`，直线段显示 `90`。
- **这条下限原本是保护动画，不是速度手感**：第三十二轮把 `BMBActivitySpeed` 和 `BMBDesiredSpeed` 分开后，阈值下限主要用于避免跑步动作被 path corner 降速切成 walk。套羊模型后，用户更在意 panic HUD/实际目标速度稳定满速，因此需要一个 mob 级开关，而不是全局改 path corner。
- **`FleeKeepFullSpeed` 是 opt-in**：sheep 开 `FleeKeepFullSpeed=true` 后，Flee 的 corner min speed 直接等于 `RunSpeed`；未来其它 mob 如果还想保留 corner slow 但不掉到 walk，只要不设该字段，就继续走旧阈值语义。

## 2026-06-14: Model sequences are aliases, not ACT guesses

- **BMB 不应该猜 Source ACT 到 MC 模型动画的映射**：转换器会按 entity.json 动画别名原样导出 `$sequence`（如 `walk`），所以 BMB 侧只需要消费这些确定名字。`ACT_WALK/ACT_RUN` 仍作为旧模型 fallback。
- **每只怪自己声明逻辑动作映射**：`AnimationSequences` 是 per-mob opt-in 表，把 `idle/walk/run/jump/attack/hurt/death/eat_grass` 这类逻辑动作映射到模型 sequence 别名。比如 MC 模型只有一个移动循环时，`walk="walk", run="walk"` 即可。
- **缺序列必须温和降级**：`LookupSequence(alias) == -1` 时不能硬播无效序列；先回退 idle，idle 也没有才交回旧 Activity 层。这样模型和代码可以分步接入，不会因为少一个 attack/death sequence 把实体动画打坏。
- **移动循环用当前速度缩放 playback rate**：walk/run 的 `SetPlaybackRate` 默认按水平速度除以参考速度（默认 `WalkSpeed`）计算，让同一个 walk loop 跟随 chase/flee/path_corner 的实际速度变化，减少腿部打滑。

## 2026-06-15: Hurt lift and chase hop must be decoupled

- **`loco:Jump()` 是状态开关，不只是视觉上抬**：Base hurt knockback 为了让羊有 MC 式受击上抬，会在 grounded hit 时调用 `loco:Jump()`。这会把 NextBot locomotion 切到 jumping/climbing 语义，后续一两 tick 里 `UpdateBMBActivityFromLocomotion`、chase 和 path_hop 都会看到“刚进入跳跃态”。
- **追击态最容易暴露这个串味**：Zombie 被玩家打时通常马上保持 target 并回到 chase；如果站在 MC 方块顶面，短 knockback 后 chase/hop 管线立刻接管，受击上抬就可能被看成一次莫名跳跃。非追击状态因为没有马上接强移动，现象不明显。
- **受击上抬必须按 mob opt-in**：友好/被动生物可保留 `KnockbackUseJump=true` 的上抬手感；Zombie 这类敌对追击怪当前关闭受击 jump-state，并把普通受击竖直速度置 0，只保留水平击退。注意这不影响 Zombie 命中玩家时给玩家的竖直击飞，那是独立的 melee player knockback。

## 2026-06-15: Sheep sequence hookup is parked until the exporter is stable

- **Base 的 sequence adapter 保留，sheep 的接线先退回注释**：`AnimationSequences` 仍是正式 MC 模型的方向，但当前导出的 sheep 还存在 pivot 和低速播放速率/cycle 脱节问题，强接会表现成冻腿/滑步，容易误判为 BMB 移动 bug。
- **程序化腿摆临时恢复，但只用新平滑逻辑**：旧的 `speed > 8 then` 硬分支和 `rate` 计时摆腿不回归；当前实现走 Base `UpdateBMBLimbSwing`，sheep 只保留自己的摆轴/摆幅参数。
- **正式接入时仍不能双写腿**：等转换器 pivot 修好、低速 playback/cycle 方案确定后，再打开 sheep `AnimationSequences` / `AnimationReferenceSpeeds`，同时撤掉客户端 `leg*` 覆盖。模型 sequence 和程序化腿摆不能同时存在。
- **吃草/看向仍是上层姿态**：当前占位阶段吃草 keyframe 主要覆盖 head；后续真实模型接入时，头部/看向/吃草覆盖应继续和 locomotion sequence 分层处理。

## 2026-06-17: MC sound assets must live in the addon and match Source sample rates

- **不要只引用外部解包目录**：GMod 客户端只能可靠加载 addon 内的 `sound/...` 资源，所以 Zombie 和 sheep 一样要把 Minecraft OGG 复制进 `gmod_addon/sound/bmb/...` 并用 `resource.AddFile` 注册；外部 `D:\BMBTools\解包音频\...` 只作为导入源。
- **Source 普通 sound 路径对 OGG 采样率挑剔**：sheep 的 `grass4.ogg` 已踩过 48000Hz 报错；新导入的 Zombie/damage OGG 一律重采样为 `44100 Hz mono`，避免游戏里才暴露 `Invalid sample rate`。
- **程序化动画的脚步阈值可以从相位参数反推**：Base limb phase 是 `speed * FrameTime() * LimbSwingPhaseScale`，一次半波脚步距离约为 `pi / LimbSwingPhaseScale`。sheep `0.09 -> 35u`，Zombie `0.12 -> 26u`，比纯手猜更容易和落脚视觉对齐。
- **受击声音应挂 accepted damage 钩子，但 lethal 语义是 per-mob**：如果声音只放在 `OnBMBInjured`，致死命中会跳过；把声音入口接到 `OnBMBHurtSound`，再让 `OnBMBInjured` 只做状态/反击逻辑，可以避免非致死双播。Sheep 在 lethal 也要 say，所以无条件播；Zombie 的 death 已有独立音效，所以 `OnBMBHurtSound` 要检查当前血量和本次伤害，致死时跳过 hurt、只播 death。

## Skeleton ranged combat (2026-06-17)

- **远程怪考验 base 的点是解耦"站哪"和"何时射"**：`RangedAttack.Update` 把移动决策（chase 接近 / aim 停下，M2 strafe）和拉弓放箭计时分开。chase 复用阻塞式 `Chase.Run`，aim 走一 tick + `RunBehaviour` 的 yield/wait 提供逐 tick 节奏——不需要在 aim 里自建协程循环。
- **ranged 怪不该让 Chase.Run 的近战 in-range 决定停下点**：Chase.Run 用 `AttackRange`/MeleeAttack.IsInRange 决定"到了就 attack_ready"。骷髅要在 15 格停下 aim，由 `ResolveMovement` 每 tick 用真实距离 gate（>15 格或没稳定看见才 chase），并把 `ChaseSegmentTimeout` 调短（0.3s）减少冲过 aim 线的过冲。不要给骷髅设大 `AttackRange` 去骗 Chase（那会变成贴 15 格 attack_ready 而不是停）。
- **弹丸用纯 GMod trace、不碰体素**：`bmb_arrow` 手动积分重力 + 沿本 tick 位移 TraceLine，命中世界/生物分别处理。这样远程怪零跨系统依赖（不需要 MCSWEP 方块碰撞）。弹丸不是 NextBot，可以用 SetPos/SetAngles 驱动（CLAUDE 禁的是 NextBot loco 移动用 SetPos）。
- **MC 弹道抛物线补偿是 Z-up 改写**：`d.z += horiz*0.2`，水平用 xy、竖直用 z；别照抄 MC 的 Y-up 轴。
- **`Player:SetVelocity` 叠加语义**（已有教训）对箭击退不重要（箭伤害走 DamageInfo + DamageForce，不直接 SetVelocity 玩家）。
- **Flee threat 参数是 PanicGoal↔AvoidEntityGoal 的开关**：同一个 Flee.Run，不传 threat = 随机近点恐慌（与方向无关），传 threat = 只收离威胁更远的候选。逃威胁优先级高于攻击且 return、不清 target。
- **占位模型先行解耦风险**（用户强调）：远程逻辑先挂僵尸占位模型验证，模型重烘（双足 rotate 0 + 手臂中性化）是独立轨；两轨都好了再 swap `ENT.Model`。M1 测试只判对错，不判 strafe 风筝手感。

## 2026-06-20: Direct shortcut failures need memory

- **绕路中反复 `chase_direct_cliff` 不一定是 A* 坏**：如果 A* 已能绕开悬崖，而 hostile 每隔一小段又直扑同一条 cliff，问题是 direct shortcut 没记住“这条线刚试过是死的”。
- **记忆应挂在 shortcut 层，不要改 A*/cliff 检测**：`chase_direct` 经 `ApplySafePressure` 确认 cliff 后缓存目标 EntIndex、mob 位置、target 位置、冷却和过期；`CanDirect` 先查缓存，位置没明显变化就让 A* 继续走。
- **远距离不要过早丢开 A***：`chase_direct` 适合近距离视线压迫；复杂结构里远距离 direct 会太早无视 A* 的绕路意图。用 per-mob `ChaseDirectMaxDistanceCells` 收紧入口，Zombie 先定 6 格。
- **不要把非 shortcut 压迫混进来**：`attack_ready` / `chase_repath` 仍可用 `ApplySafePressure` 防掉崖，但不写 direct shortcut memory，避免攻击贴边和 A* 失败兜底被同一块缓存意外压住。

## 2026-06-20: Retaliation is a base target override

- **“被谁打就打谁”应该写在 Base，不该拆成 Zombie 打 Skeleton / Skeleton 打 Zombie 两套**：伤害入口拿 `damageInfo:GetAttacker()`，通过当前 mob 的 `CanBMBTarget`，然后写共享 `TargetEntity`，两边互殴自然出现。
- **箭必须 credit shooter**：`bmb_arrow` 的 attacker 是 `BMBArrowOwner`，否则被射中的 mob 会追一支马上消失的箭。
- **主动扫描和还击是两件事**：`SeekTarget.Find` 仍只主动扫描玩家；mob 目标只来自受击还击。这样不会让敌怪无缘无故互相找架，但流弹/近战命中会改目标。
- **粘性复用现有目标有效性**：还击目标保持到死亡、失效或超出 `TargetLoseRange`，不额外加短计时器抢回玩家。

## 2026-06-20: Screenshot controls must be BMB-native

- **Source `notarget` 只写玩家 flag，BMB 必须自己读**：Lua NextBot 不走 CAI NPC 选敌，所以 `SeekTarget.IsValid` 要显式跳过 `FL_NOTARGET` 玩家；base combat target 也要跳过，避免受击还击重新锁。
- **`ai_disabled` 不管 BMB 行为协程**：摆拍应使用 BMB 自己的 `bmb_freeze`，在 base Think 和各 RunBehaviour 顶部同时拦，既归零速度又停掉行为推进。

## 2026-06-20: MC lighting for models is draw-time modulation

- **MC 方块光影是 mesh vertexcolor，模型不会自动继承**：朋友的光影在 `MC.SampleLighting` 里给方块 mesh 顶点 brightness；BMB mob 是 Source model，只能在 Draw 时采样当前格并 `render.SetColorModulation`。
- **不要改模型材质/转换器来适配光影**：base Draw 统一乘 brightness，`mc_light_enable 0` 时 `SampleLighting` 返回 1，外观自然回原样。
- **附属 clientside model 也要乘同一 brightness**：Skeleton 手上的弓不是 mob 主模型，必须通过同一个 helper 画，否则洞穴里会亮得穿帮。
