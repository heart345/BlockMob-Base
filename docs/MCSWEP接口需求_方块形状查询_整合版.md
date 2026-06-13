# BMB 对 MCSWEP 的接口需求：方块形状查询（整合版）

> 给 MCSWEP 维护者。  
> 这份是 BMB 侧整理后的最终需求，可直接替代 `接口需求_GetBlockExtent.md` 发给朋友。  
> 结论先说：朋友这边已经有 `MC.BlockBoxes(id, orient)`，所以 BMB 真正需要的不是一套新形状系统，而是确认 `BlockBoxes` 的热路径契约，并最好加一个从它派生的便宜封装 `MC.GetBlockExtent(id, orient)`。

---

## 1. 最终请求

### P0：确认/稳定 `MC.BlockBoxes(id, orient)` 的接口契约

你们文档里已经有：

```lua
local boxes = MC.BlockBoxes(id, orient)
```

每个 box 是：

```lua
{ x0, y0, z0, x1, y1, z1 }
```

坐标是单个方块内 `0..1` 局部值，而且文档说 `MC.BlockBoxes()` 已经处理 slab、stairs、model、axis/facing 旋转和 fence gate 覆盖。

BMB 希望确认下面几点：

- 服务端可调用。
- 纯查询：只依赖 `id + orient`，不查世界，不走网络。
- `orient` 已经在 MCSWEP 内部消化，返回的是最终朝向下的 box。
- 返回值是方块碰撞实际使用的同一份形状数据，不能是另一套手写近似。
- 如果返回内部缓存 table，BMB 只读、不修改；如果每次都会新建 table，也请告诉我，BMB 会在自己 adapter 里按 `id+orient` 缓存。

这条是最关键的，因为完整 box 数据才能判断玻璃板/栅栏这类窄碰撞、楼梯这种同格多高度形状。

### P1：建议新增 `MC.GetBlockExtent(id, orient)`

如果方便，请加一个从 `MC.BlockBoxes(id, orient)` 派生的高频封装：

```lua
-- 返回该方块碰撞盒在方块本地坐标中的竖直包络 [lo, hi]
-- 0 = 方块底面，1 = 方块顶面，与 MC.BlockBoxes 的局部坐标一致
local lo, hi = MC.GetBlockExtent(id, orient)
```

推荐约定：

- 返回多返回值，不返回 table：`local lo, hi = ...`
- 单位用 `0..1` 归一化坐标，不返回 Source units。
- 空气/无碰撞方块返回 `nil, nil`。
- 纯函数，只依赖 `id + orient`。
- 内部可以按 `id+orient` 缓存，保证热路径无重复计算、无每次调用分配。

如果你更喜欢 `0, 0` 表示无碰撞，或函数名想叫 `MC.BlockExtent(id, orient)`，BMB 都能适配；只是请把约定定死。

### P2：方块变化通知（不阻塞第一版）

BMB 会缓存世界格子的支撑/通行结果。如果已有方块变化事件或 hook 能拿到 `bx, by, bz`，请告诉我们应该挂哪里。  
理想情况是：放置、破坏、`mc_set` 同步落地时，BMB 能收到变化 cell，失效该 cell 附近缓存。

这条不阻塞 `GetBlockExtent` 第一版；没有也可以先全局短缓存/按需过期。

---

## 2. 为什么 BMB 需要形状，而不是只要 full cube

BMB 的 A* 现在只能粗略用：

```lua
MC.BlockIsFullCube(id, orient)
```

这会把世界压成“整格实心 / 空气”二值，问题是：

- 半砖、雪层、地毯、耕地、灵魂沙等非整格平顶方块会被当成空气或非支撑。
- 楼梯/台阶不是简单 full cube，走上去的高度取决于形状。
- 玻璃板、栅栏、铁栏杆等窄碰撞有碰撞，但顶面不适合 mob 当合法寻路节点。
- top slab 和 full cube 顶面都在 `1.0`，但它们对下方净空完全不同。

BMB A* 需要按真实形状计算：

- 脚下有没有支撑，以及支撑面的高度。
- 当前格/头顶格有没有碰撞压到 mob hull。
- 相邻格高度差是 walk、hop 还是 drop。
- 窄顶碰撞是否不能作为普通寻路目标。

这些语义应该由 BMB 决定；MCSWEP 只需要提供权威碰撞形状。

---

## 3. 重要修正：`GetBlockExtent` 很有用，但不能单独替代 `BlockBoxes`

4.8 原稿里把 `GetBlockExtent` 的作用说得很强。这里补一个工程修正：  
**竖直区间 `[lo, hi]` 是高频快速查询，不是完整形状接口。**

原因：

- full cube、玻璃板、栅栏的 z 包络都可能是 `[0, 1]`，但 full cube 可当墙/支撑，玻璃板/栅栏是窄碰撞，普通 A* 不应把顶面当合法目标。
- 楼梯的 box 可能包含下半块 + 上半块，整体 z 包络也是 `[0, 1]`，但真实可走表面不是“整格高方块”这么简单。
- `GetBlockExtent` 可以区分 bottom slab `[0, 0.5]`、top slab `[0.5, 1]`、full cube `[0, 1]`，这很有价值；但遇到多 box / 窄 box 形状时，BMB 仍需要完整 `BlockBoxes` 判断水平覆盖和 mob hull。

所以 BMB 的接入策略会是：

- `GetBlockExtent`：热路径快速判断“这个方块大致有没有碰撞、竖直范围在哪”，尤其适合半砖/雪层/地毯/净空这类纵向问题。
- `BlockBoxes`：精确判断 support footprint、headroom、窄碰撞、楼梯、多 box 形状。

这样既利用便宜封装，也不丢形状信息。

---

## 4. `GetBlockExtent` 为什么仍然值得加

即使 BMB 会消费完整 `BlockBoxes`，`GetBlockExtent` 仍然有价值：

- A* 会频繁做“有没有碰撞/竖直区间”查询；z 包络是最常用的快路径。
- `GetBlockExtent` 从 `BlockBoxes` 派生，天然同源，不会和物理碰撞打架。
- 多返回值避免每次查询建 table，适合寻路热路径。
- BMB adapter 代码会更简单，也减少我们这边重复扫描 boxes 的次数。

参考实现：

```lua
local extentCache = {}

function MC.GetBlockExtent(id, orient)
    if not id or id == 0 then return nil, nil end

    local key = id * 65536 + (orient or 0)
    local cached = extentCache[key]
    if cached then
        if cached.empty then return nil, nil end
        return cached.lo, cached.hi
    end

    local boxes = MC.BlockBoxes(id, orient)
    if not boxes or #boxes == 0 then
        extentCache[key] = { empty = true }
        return nil, nil
    end

    local lo, hi = math.huge, -math.huge
    for i = 1, #boxes do
        local b = boxes[i]
        if b[3] < lo then lo = b[3] end
        if b[6] > hi then hi = b[6] end
    end

    extentCache[key] = { lo = lo, hi = hi }
    return lo, hi
end
```

这只是示意，按你们代码风格改即可。关键点是：数据源必须是 `MC.BlockBoxes(id, orient)`。

---

## 5. BMB 这边会怎么用

BMB 的 `IBlockWorld` adapter 会扩成类似：

```lua
GetBlockBoxes(cell) -> boxes
GetSolidExtent(cell) -> lo, hi
```

Real adapter：

```lua
local id = MC.GetBlock(bx, by, bz)
local orient = MC.GetBlockOrient(bx, by, bz)
local lo, hi = MC.GetBlockExtent(id, orient)
local boxes = MC.BlockBoxes(id, orient)
```

BMB 侧再根据 mob hull 自己算：

- 支撑面高度。
- StepHeight 内的普通 walk。
- 超过 StepHeight 但 ≤ 1 格的 hop。
- 允许 ≤3 格的 drop。
- 头顶净空。
- 玻璃板/栅栏这类窄顶碰撞不作为普通 A* standable 节点。
- 已经被放到非法节点上时，仍走现有 StrandedRecovery 兜底。

MCSWEP 不需要知道 mob 尺寸、寻路规则或 MC 生物 AI，这些都留在 BMB。

---

## 6. 非目标

这次不要求 MCSWEP 做：

- mob 寻路。
- mob hull / standable 语义。
- “这个方块怪物能不能站”的表。
- 新网络消息。
- 新世界查询路径。

只要形状查询同源、稳定、服务端可用即可。

---

## 7. 希望朋友拍板的几个小问题

1. `MC.BlockBoxes(id, orient)` 是否可以作为服务端热路径查询使用？它返回的是内部静态表还是每次新建表？
2. `MC.GetBlockExtent(id, orient)` 你愿意加吗？函数名用这个还是更贴近现有风格的 `MC.BlockExtent(id, orient)`？
3. 无碰撞方块返回 `nil, nil` 可以吗？如果你更想返回 `0, 0`，BMB 也能适配。
4. `lo, hi` 是否保持 `0..1` 归一化？BMB 推荐这样，因为和 `BlockBoxes` 一致，也不和 `MC.BS` 耦合。
5. 现有方块变化链路里，BMB 应该挂哪个 hook/事件来拿 `bx, by, bz` 做缓存失效？

---

## 8. 一句话总结

`MC.BlockBoxes(id, orient)` 是完整权威形状源；BMB 需要确认它能稳定服务端调用。  
`MC.GetBlockExtent(id, orient)` 是从 `BlockBoxes` 取 z 包络的便宜封装，推荐加，能让半砖/净空等高频判断更轻。  
但玻璃板、栅栏、楼梯这类形状不能只靠 z 区间判断，BMB 会继续使用完整 `BlockBoxes` 做精确支撑和 hull 判断。
