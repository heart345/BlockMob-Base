BMB = BMB or {}

-- IBlockWorld 的 MCSWEP adapter：内部用 MC.* 实现。
-- 接口文档：D:\SteamLibrary\...\addons\mcswep-main\docs\interface-usage.md
-- 业务代码（行为/寻路/状态机）一律走 BMB.BlockWorld，禁止直接调 MC.*（CLAUDE.md 铁律）
BMB.RealBlockWorld = BMB.RealBlockWorld or {}

local real = BMB.RealBlockWorld
real.BlockIds = real.BlockIds or {}
real.SupportsVerticalPath = true

local function coord(x, y, z)
    return { x = x, y = y, z = z or 0 }
end

local function blockSize()
    return BMB.GetBlockSize and BMB.GetBlockSize() or (BMB.BS or 36.5)
end

local function hasMC()
    return istable(MC)
        and isfunction(MC.WorldToCell)
        and isfunction(MC.CellWorldCenter)
        and isfunction(MC.GetBlock)
end

-- 方块类型 id 不硬编码：首次用到时 MC.ResolveBlock 解析并缓存（CLAUDE.md）
local function cacheBlockId(key, ...)
    if real.BlockIds[key] then return real.BlockIds[key] end
    if not hasMC() or not isfunction(MC.ResolveBlock) then return nil end

    for _, name in ipairs({ ... }) do
        local resolved = MC.ResolveBlock(name)
        if resolved and resolved.id then
            real.BlockIds[key] = resolved.id
            return resolved.id
        end
    end
end

local function blockTypeToId(blockType)
    if isnumber(blockType) then return blockType end
    if blockType == nil then return 0 end

    if blockType == BMB.BlockTypes.Grass then
        return cacheBlockId("grass", "grass_block", "minecraft:grass_block")
    elseif blockType == BMB.BlockTypes.Dirt then
        return cacheBlockId("dirt", "dirt", "minecraft:dirt")
    elseif blockType == BMB.BlockTypes.Stone then
        return cacheBlockId("stone", "stone", "minecraft:stone")
    end
end

-- 对外返回 BMB.BlockTypes 枚举（行为层只认这套，不感知 MC 数字 id）；
-- BMB 没建模的方块原样返回数字 id，行为层把它当"其他方块"处理
local function idToBlockType(id)
    if not id or id == 0 then return nil end

    if id == blockTypeToId(BMB.BlockTypes.Grass) then return BMB.BlockTypes.Grass end
    if id == blockTypeToId(BMB.BlockTypes.Dirt) then return BMB.BlockTypes.Dirt end
    if id == blockTypeToId(BMB.BlockTypes.Stone) then return BMB.BlockTypes.Stone end

    return id
end

function real.Available()
    return hasMC()
end

function real.EnsureInitialized(_)
    -- 真实方块世界由 MCSWEP 维护；mock 的同名函数用于生成测试地块，这里无事可做
end

function real.WorldToBlock(pos)
    local bx, by, bz = MC.WorldToCell(pos)
    return coord(bx, by, bz)
end

function real.BlockToWorld(blockCoord)
    return MC.CellWorldCenter(blockCoord.x, blockCoord.y, blockCoord.z)
end

function real.GetBlockAt(blockCoord)
    if not real.Available() then return nil end
    return idToBlockType(MC.GetBlock(blockCoord.x, blockCoord.y, blockCoord.z))
end

function real.IsSolid(blockCoord)
    if not real.Available() then return false end

    local id = MC.GetBlock(blockCoord.x, blockCoord.y, blockCoord.z)
    if not id or id == 0 then return false end

    local orient = 0
    if isfunction(MC.GetBlockOrient) then
        orient = MC.GetBlockOrient(blockCoord.x, blockCoord.y, blockCoord.z) or 0
    end

    -- 粗略版：只把完整方块当寻路障碍。半砖/楼梯/栅栏按"可通过"处理，实际撞不撞
    -- 由移动层的 Source 安全探测和 loco 碰撞兜住；需要细化时入口是 MC.BlockBoxes(id, orient)
    if isfunction(MC.BlockIsFullCube) then
        return MC.BlockIsFullCube(id, orient)
    end

    return true
end

-- 窄 Source 几何比 36u 格子窄时，MC 网格中心可能悬在沿外侧：中心采样没命中
-- 再用这四个轴向偏移兜一次（HasSupport 用），偏移量约 1/3 格。
local supportSampleOffsetFractions = {
    { x = 1 / 3, y = 0 },
    { x = -1 / 3, y = 0 },
    { x = 0, y = 1 / 3 },
    { x = 0, y = -1 / 3 }
}

-- 寻路"支撑"语义：脚下有 MC 实心方块，或这一格内有 Source 刷子地面（flatgrass 地皮、
-- 地图静态几何）。prop 不算支撑——A* 不感知 prop，交给移动层 Source safety 兜。
-- 有了它，mob 才能在"方块结构 ↔ Source 地面"之间寻路衔接（drop 落回地皮、目标点
-- 落在非 MC 地面上也可达）
function real.HasSupport(blockCoord)
    if not real.Available() then return false end

    local below = coord(blockCoord.x, blockCoord.y, (blockCoord.z or 0) - 1)
    if real.IsSolid(below) then return true end

    local center = real.BlockToWorld(blockCoord)
    local half = blockSize() * 0.5
    local top = center.z + half - 1
    local bottom = center.z - half - 6

    -- 从格顶探到格底下方一点：命中 = 地面落在这一格内（可站立）；
    -- 中心 StartSolid = 整格埋在地面以下，不可站立——挡掉"往地里钻"的 drop/walk 候选
    local centerTrace = util.TraceLine({
        start = Vector(center.x, center.y, top),
        endpos = Vector(center.x, center.y, bottom),
        mask = MASK_SOLID_BRUSHONLY
    })

    if centerTrace.StartSolid then return false end
    if centerTrace.Hit then return true end

    -- 窄 Source 几何（围墙窗台、薄沿）比 36u 格子窄，MC 网格中心可能正好悬在沿外侧、
    -- 但格子大半压在沿上：偏移采样任一命中就算支撑。StartSolid 的样本（戳进旁边墙体）
    -- 跳过，不代表这格不可站
    local sampleScale = blockSize()
    for _, offset in ipairs(supportSampleOffsetFractions) do
        local offsetX = offset.x * sampleScale
        local offsetY = offset.y * sampleScale
        local trace = util.TraceLine({
            start = Vector(center.x + offsetX, center.y + offsetY, top),
            endpos = Vector(center.x + offsetX, center.y + offsetY, bottom),
            mask = MASK_SOLID_BRUSHONLY
        })

        if trace.Hit and not trace.StartSolid then return true end
    end

    return false
end

function real.GetBlocksInRadius(pos, radius)
    if not real.Available() then return {} end

    local center = real.WorldToBlock(pos)
    local size = blockSize()
    local blockRadius = math.ceil(radius / size)
    local found = {}

    for bx = center.x - blockRadius, center.x + blockRadius do
        for by = center.y - blockRadius, center.y + blockRadius do
            for bz = center.z - blockRadius, center.z + blockRadius do
                local id = MC.GetBlock(bx, by, bz)
                if id and id ~= 0 then
                    found[#found + 1] = {
                        coord = coord(bx, by, bz),
                        type = idToBlockType(id)
                    }
                end
            end
        end
    end

    return found
end

function real.GetRandomWalkablePoint(origin, radius, mob)
    if not real.Available() then return origin end

    local center = real.WorldToBlock(origin)
    local size = blockSize()
    local blockRadius = math.max(1, math.floor(radius / size))
    local maxDropCells = (IsValid(mob) and mob.MaxPathDropCells) or BMB.Config.MaxPathDropCells or 3

    for attempt = 1, 36 do
        local bx = center.x + math.random(-blockRadius, blockRadius)
        local by = center.y + math.random(-blockRadius, blockRadius)
        local bz = center.z

        -- MC 普通 mob 的 getMaxFallDistance() 默认是 3。高台上游荡时要主动抽
        -- 下层候选，否则 A* 会走 drop，但 Wander 很少把目标选到台下。
        if attempt <= 14 and maxDropCells > 0 then
            bz = center.z - math.random(1, maxDropCells)
        elseif math.random() < 0.55 then
            bz = center.z + math.random(-maxDropCells, 1)
        end

        -- 候选点取 mob 脚部所在层：脚部格和头部格都要是空的（mob 高 44 < 2 格）。
        -- 支撑判断统一走 HasSupport（MC 实心或 Source 地皮都算），同层悬空候选
        -- （站在高台上抽到平台外的空中格）在这里就被挡掉，不再依赖 A* 失败兜底
        if real.HasSupport(coord(bx, by, bz)) then
            local candidate = real.BlockToWorld(coord(bx, by, bz))

            if IsValid(mob) and mob.IsBMBHullClearAtPosition then
                if mob:IsBMBHullClearAtPosition(candidate) then return candidate end
            elseif not real.IsSolid(coord(bx, by, bz)) and not real.IsSolid(coord(bx, by, bz + 1)) then
                return candidate
            end
        end
    end

    return origin
end

function real.SetBlockAt(blockCoord, blockType, actor)
    local id = blockTypeToId(blockType)
    if not id then return false end

    if not istable(MC) or not istable(MC.SV) or not isfunction(MC.SV.SetBlock) then
        print("[BMB] RealBlockWorld.SetBlockAt: MC.SV.SetBlock unavailable")
        return false
    end

    local orient = 0
    if isfunction(MC.DefaultOrient) then
        orient = MC.DefaultOrient(id) or 0
    end

    -- actor（mob 实体）直接当 options 传 = { actor = ent }，MCSWEP 会带进 OnPlace/OnBreak、
    -- 并处理网络同步/碰撞 dirty/声音粒子/保存（接口文档"非玩家写入"一节）
    local ok, err = MC.SV.SetBlock(blockCoord.x, blockCoord.y, blockCoord.z, id, orient, actor)

    if not ok and err ~= "unchanged" then
        print("[BMB] RealBlockWorld.SetBlockAt failed: " .. tostring(err))
    end

    return ok or false
end

function real.RemoveBlockAt(blockCoord, actor)
    if not istable(MC) or not istable(MC.SV) or not isfunction(MC.SV.SetBlock) then
        print("[BMB] RealBlockWorld.RemoveBlockAt: MC.SV.SetBlock unavailable")
        return false
    end

    local ok = MC.SV.SetBlock(blockCoord.x, blockCoord.y, blockCoord.z, 0, 0, actor)
    return ok or false
end

-- ------------------------------------------------------------------ 实现选择
-- IBlockWorld 双实现切换（CLAUDE.md：切换只改一个变量 = BMB.BlockWorld 指向谁）。
-- MCSWEP 在 BMB 之后加载（addons 字母序 g < m），include 时 MC 还不存在，
-- 所以除了启动时选一次，生成 mob 时（BaseInitialize）会再选一次
CreateConVar("bmb_use_real_world", "1", FCVAR_ARCHIVE, "Use MCSWEP real block world when available; falls back to mock.")

function BMB.SelectBlockWorld()
    local target = BMB.MockBlockWorld

    if GetConVar("bmb_use_real_world"):GetBool() and real.Available() then
        target = real
    end

    if BMB.BlockWorld ~= target then
        BMB.BlockWorld = target
        print("[BMB] Block world -> " .. (target == real and "real (MCSWEP)" or "mock"))
    end

    return target
end

BMB.SelectBlockWorld()

cvars.AddChangeCallback("bmb_use_real_world", function()
    BMB.SelectBlockWorld()
end, "bmb_select_block_world")

concommand.Add("bmb_world", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end

    local mode = string.lower(args[1] or "")
    if mode == "mock" or mode == "real" then
        GetConVar("bmb_use_real_world"):SetBool(mode == "real")
    end

    local active = BMB.SelectBlockWorld()
    local name = active == real and "real (MCSWEP)" or "mock"

    if mode == "real" and active ~= real then
        name = name .. " (MCSWEP not loaded, fell back to mock)"
    end

    print("[BMB] Block world = " .. name)
    if IsValid(ply) then ply:ChatPrint("[BMB] Block world = " .. name) end
end)
