# BMB ↔ MCSWEP 对接补充（配合朋友的 interface-usage.md 一起看）

> 真接口到了。方块系统命名空间是 `MC`（addon 叫 MCSWEP），不是之前占位用的 `MinecraftBase`。spec v2 第 4 节那套占位接口（`IBlockWorld.*`）现在落地成下面这样。先把朋友的 `interface-usage.md` 当权威读完，这份只讲怎么接到 BMB 上。

## 1. 确定的常量
- **方块大小 = 36 Source units**（`MC.BS`）。spec 里 `BLOCK_SIZE` 的 TODO 用这个值。
- chunk：水平 16×16，section 高 32。chunk 是他内部的事，BMB 只按 cell 坐标 `bx, by, bz` 操作。
- 坐标三层：world `Vector` ↔ cell `bx,by,bz` ↔ chunk。BMB 只跟前两层打交道。

## 2. 不要"一行换 mock"，改成写一个 adapter
真 API 的形状跟我们 mock 的接口**不是 1:1**（没有现成的 `IsSolid(coord)`；改方块要传 `ply`）。所以：保持 BMB 内部那套 `IBlockWorld` 接口不动，**额外写一个 `RealBlockWorld` 适配层**，用 `MC.*` 去实现 BMB 期望的那些函数。Mock 和 adapter 都满足同一个接口，BMB 的寻路/行为代码一个字不用改——切换还是切一个变量，只是真实现是适配层不是裸 `MC.*`。

## 3. 接口映射

| BMB 期望（mock 接口） | 真实现（`MC.*`） | 备注 |
|---|---|---|
| `WorldToBlock(vec)` | `MC.WorldToCell(vec) -> bx,by,bz` | 直接对应 |
| `BlockToWorld(coord)`（中心） | `MC.CellWorldCenter(bx,by,bz)` | 角点用 `MC.CellWorldMin` |
| `GetBlockAt(coord)` | `MC.GetBlock(bx,by,bz) -> id` | 返回**数字 id**，不是字符串；空气大概是 0/nil，**agent 实测确认空值** |
| `IsSolid(coord)` | **没有直接函数，组合出来** | `id = MC.GetBlock(...)`；非空再取 `orient = MC.GetBlockOrient(...)`，判 `MC.BlockIsFullCube(id, orient)`。adapter 里封成一个 helper |
| `GetBlocksInRadius(pos,r)` | 自己实现 | 半径内采样 cell（`MC.GetBlock` 扫一圈），或用 `MC.ForEachBlock` 遍历附近 chunk 再过滤 |
| 方块类型常量（GRASS/DIRT…） | `MC.ResolveBlock("grass_block").id` | 类型是数字 id，名字→id 用 `ResolveBlock`；init 时把 grass/dirt 等解析好缓存成常量 |

> `IsSolid` 用"完整方块=实心"只是粗略版。半砖、楼梯是能站但不满格的，寻路要精确处理得后面再细化；第一只羊在平地上用粗略版够了。

## 4. ⚠️ 改方块有个真缺口，需要你朋友拍板（agent 解决不了）

他的改世界接口是**面向玩家**的：

```lua
MC.SV.Place( ply, bx,by,bz, id, orient )
MC.SV.Break( ply, bx,by,bz )
```

带 `ply`，内部做 cooldown / 管理员限制 / reach 校验 / 防卡入——全是**玩家动作**的假设。但羊吃草、蠹虫钻石头是 **mob 自主行为，没有玩家**，套不进去（传 mob 实体当 ply 大概率报错，传 nil 行为不可控）。

低级的 `MC.SetBlockRaw()` 他文档里又明确写了：不做网络同步、碰撞重建、handler、保存。**你们是联机玩的**，用它客户端看不到变化、碰撞不更新，会 desync。

所以联动"改方块"这一步，需要他提供一个**服务端权威、非玩家的写入入口**——类似 `MC.SV.SetBlock(bx,by,bz, id, orient)`，照样走 sync + 碰撞 dirty + handler + save，只是跳过玩家相关校验。这是接口设计问题，得他来加。

**在他给这个之前**：adapter 里的 `SetBlock` 先 stub 住（只打日志 / 改 mock 网格），其余全部照常——寻路、感知、状态机、动画对着 mock + flatgrass 全做完。这条**只阻塞最后落地那一下，不阻塞主线**。

## 5. 顺带
- 吃草本质是 grass_block → dirt，即"替换该 cell 的方块"，等第 4 节那个写入入口定了再接上。
- 蠹虫的"虫蚀方块"将来可以用 `MC.RegisterBlock` 注册一个自定义块（参考他 doc 里 id 60010+ 的例子）。
- mob 的移动/跳跃/上台阶尽量跟**玩家的 hull/jump/step 对齐**（他 `sh_player.lua` 那套），否则寻路算得通、实际走不上去、或客户端服务端拉扯。
- `maintenance-update-guide.md` 基本是他**内部维护**用的（生成管线、文件分工、build 脚本）。BMB 这边除了上面摘出来的常量和纪律，不用照它做。
