# MCSWEP 接口使用介绍

这份文档只讲怎么调用现有接口。需要改结构、生成方块或导入逻辑时，先看 `docs/maintenance-update-guide.md`。

## 基本概念

坐标分三层：

```text
Source world units     Vector，GMod 世界坐标
block cell coords      bx, by, bz，整数方块坐标
chunk section coords   cx, cy, cz，16x16x32 的区块段坐标
```

常用换算：

```lua
local bx, by, bz = MC.WorldToCell( someVector )
local cx, cy, cz, li = MC.CellToChunk( bx, by, bz )
local worldMin = MC.CellWorldMin( bx, by, bz )
local worldCenter = MC.CellWorldCenter( bx, by, bz )
```

`li` 是 chunk 内 local index：`lx + ly * 16 + lz * 16 * 16`。

## 查方块

```lua
local resolved = MC.ResolveBlock( "minecraft:oak_stairs" )
if resolved then
    print( resolved.id, resolved.name, resolved.mcid )
end
```

支持：

```text
stone
minecraft:stone
3
grass_block
```

解析带状态的写法：

```lua
local id, orient, rawName, err = MC.ParseBlockSpec( "minecraft:oak_stairs[facing=north,half=bottom]" )
if not err then
    print( id, orient )
end
```

状态文本：

```lua
local state = MC.BlockStateText( id, orient )
local hint = MC.BlockStateHint( id )
```

## 读写世界

读当前方块：

```lua
local id = MC.GetBlock( bx, by, bz )
local orient = MC.GetBlockOrient( bx, by, bz )
```

低级写入：

```lua
local chunk, created, emptied, changed = MC.SetBlockRaw( bx, by, bz, id, orient )
```

`MC.SetBlockRaw()` 只改本地存储，不做权限校验、距离校验、网络同步、碰撞重建、保存 dirty、block handler。游戏逻辑里优先用服务端接口。

遍历 chunk：

```lua
local chunk = MC.GetChunkByKey( key )
if chunk then
    MC.ForEachBlock( chunk, function( bx, by, bz, lx, ly, lz, id, orient )
        print( bx, by, bz, id, orient )
    end )
end
```

## 服务端放置/破坏/使用

服务端权威接口在 `MC.SV`：

```lua
MC.SV.Place( ply, bx, by, bz, id, orient )
MC.SV.Break( ply, bx, by, bz )
MC.SV.Use( ply, bx, by, bz )
```

这些接口会处理：

- cooldown
- 管理员限制
- reach 校验
- 世界边界
- 方块数量上限
- 玩家防卡入检测
- chunk entity 创建/删除
- 碰撞 dirty
- `mc_set` 网络同步
- `OnPlace` / `OnBreak` / `OnUse`
- 保存 dirty

示例：

```lua
local resolved = MC.ResolveBlock( "minecraft:oak_planks" )
if resolved then
    local orient = MC.DefaultOrient( resolved.id )
    MC.SV.Place( ply, bx, by, bz, resolved.id, orient )
end
```

破坏：

```lua
MC.SV.Break( ply, bx, by, bz )
```

右键使用：

```lua
if MC.SV.Use( ply, bx, by, bz ) then
    return true
end
```

## 朝向和放置

方向常量：

```lua
MC.Direction.DOWN
MC.Direction.UP
MC.Direction.NORTH
MC.Direction.SOUTH
MC.Direction.WEST
MC.Direction.EAST

MC.Axis.X
MC.Axis.Y
MC.Axis.Z
```

从玩家和 trace 推导放置朝向：

```lua
local orient = MC.OrientForPlacement( ply, tr, id )
```

手动 normalize：

```lua
orient = MC.NormalizeOrient( id, orient )
```

楼梯：

```lua
local orient = MC.MakeStairOrient( MC.Direction.NORTH, "bottom" )
local facing = MC.StairOrientFacing( orient )
local half = MC.StairOrientHalf( orient )
```

## 射线和选中

方块射线不依赖 Source 物理命中，适合不完整方块选中/破坏：

```lua
local hit = MC.TraceBlockRay( startPos, dir, maxDist )
if hit then
    print( hit.bx, hit.by, hit.bz, hit.Block, hit.Orient )
end
```

玩家当前瞄准：

```lua
local hit = MC.PlayerBlockAim( ply )
if hit then
    local bx, by, bz = hit.bx, hit.by, hit.bz
end
```

预览能否放置：

```lua
if MC.CanPreviewPlace( ply, bx, by, bz ) then
    -- draw ghost
end
```

## 碰撞和形状

获取碰撞盒：

```lua
local boxes = MC.BlockBoxes( id, orient )
```

每个 box 是：

```lua
{ x0, y0, z0, x1, y1, z1 }
```

坐标是单个方块内的 `0..1` 局部值。`MC.BlockBoxes()` 已经处理 slab、stairs、model、axis/facing 旋转和 fence gate 覆盖。

判断完整方块：

```lua
if MC.BlockIsFullCube( id, orient ) then
    -- normal hidden-face culling path
end
```

## 注册自定义方块

最小例子：

```lua
MC.RegisterBlock( {
    id = 60010,
    name = "debug_block",
    mcid = "mcswep:debug_block",
    solid = true,
    transparent = false,
    textures = {
        top = "stone",
        side = "stone",
        bottom = "stone",
    },
} )
```

带朝向：

```lua
MC.RegisterBlock( {
    id = 60011,
    name = "debug_facing",
    mcid = "mcswep:debug_facing",
    stateRule = "horizontal_facing",
    placeRule = "look_opposite",
    textures = {
        top = "oak_planks",
        side = "oak_planks",
        bottom = "oak_planks",
        front = "crafting_table_front",
    },
} )
```

带自定义碰撞：

```lua
MC.RegisterBlock( {
    id = 60012,
    name = "debug_half",
    mcid = "mcswep:debug_half",
    solid = true,
    shape = "model",
    boxes = {
        { 0, 0, 0, 1, 1, 0.5 },
    },
    textures = {
        top = "oak_planks",
        side = "oak_planks",
        bottom = "oak_planks",
    },
} )
```

注意：生产方块尽量走 `_build/build_atlas.ps1` 生成，不要长期手写到 runtime。

## 方块 handler

定义 handler：

```lua
MC.BlockHandlers.my_block = {
    OnUse = function( ply, bx, by, bz, orient )
        ply:ChatPrint( "used" )
        return true
    end,
    OnPlace = function( ply, bx, by, bz, orient )
    end,
    OnBreak = function( ply, bx, by, bz, orient )
    end,
}
```

注册时引用：

```lua
MC.RegisterBlock( {
    id = 60013,
    name = "debug_handler",
    mcid = "mcswep:debug_handler",
    handler = "my_block",
    textures = { top = "stone", side = "stone", bottom = "stone" },
} )
```

已有示例：`MC.BlockHandlers.furnace`。

## 客户端 UI/渲染接口

画 tile：

```lua
MC.DrawTile( tile, x, y, w, h )
```

画方块图标：

```lua
MC.DrawBlockIcon( id, x, y, w, h )
```

打开选择窗口：

```lua
MC.OpenPalette( function( id )
    print( "selected", id )
end )
```

画预览和选中框：

```lua
MC.DrawBlockGhost( id, orient, bx, by, bz, Color( 255, 255, 255, 120 ) )
MC.DrawBlockOutline( id, orient, bx, by, bz )
```

标记 mesh/碰撞 dirty：

```lua
MC.MarkDirty( bx, by, bz )
MC.MarkChunkDirty( key )
MC.MarkChunkPhysDirty( key )
```

## 控制台命令

服务端/管理员常用：

```text
mc_fill <x1> <y1> <z1> <x2> <y2> <z2> <block[state]>
mc_import <file> [replace|append]
mc_import_probe <file>
mc_clear
mc_resync
mc_rebuild
mc_save
mc_save_diag
mc_diag
mc_block_sel <block[state]>
```

客户端：

```text
mc_debug
mc_client_diag
mc_client_collision 0/1
```

## ConVar

```text
mc_admin_only
mc_world_limit
mc_max_blocks
mc_reach
mc_fill_max
mc_import_max
mc_autosave
mc_sync_cells_per_part
mc_sync_messages_per_tick
mc_sync_reliable_budget
mc_client_collision
```

## 网络消息

由 `sh_config.lua` 注册：

```text
mc_full
mc_full_begin
mc_full_part
mc_full_end
mc_set
mc_clear
```

业务代码通常不要直接发这些消息；优先使用 `MC.SV.Place`、`MC.SV.Break`、`MC.SV.BeginSync`、`mc_import`、`mc_resync`。

## 常见写法

SWEP 左键破坏：

```lua
local hit = MC.PlayerBlockAim( owner )
if hit then
    MC.SV.Break( owner, hit.bx, hit.by, hit.bz )
end
```

SWEP 右键先使用、再放置：

```lua
local hit = MC.PlayerBlockAim( owner )
if hit and MC.SV.Use( owner, hit.bx, hit.by, hit.bz ) then return end

local tr = owner:GetEyeTrace()
local bx, by, bz = MC.WorldToCell( tr.HitPos + tr.HitNormal * MC.BS * 0.5 )
local id = owner:GetNWInt( "mc_block_id", 1 )
local orient = MC.OrientForPlacement( owner, tr, id )
MC.SV.Place( owner, bx, by, bz, id, orient )
```

导入后强制已有 chunk 重建碰撞：

```text
mc_rebuild
```
