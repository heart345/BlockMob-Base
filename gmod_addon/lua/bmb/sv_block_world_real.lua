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

function real.GetBlocksInRadius(pos, radius)
    if not real.Available() then return {} end

    local center = real.WorldToBlock(pos)
    local blockSize = MC.BS or BMB.Config.BlockSize
    local blockRadius = math.ceil(radius / blockSize)
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
    local blockSize = MC.BS or BMB.Config.BlockSize
    local blockRadius = math.max(1, math.floor(radius / blockSize))
    local maxDropCells = (IsValid(mob) and mob.MaxPathDropCells) or BMB.Config.MaxPathDropCells or 3

    for _ = 1, 24 do
        local bx = center.x + math.random(-blockRadius, blockRadius)
        local by = center.y + math.random(-blockRadius, blockRadius)
        local bz = center.z

        if math.random() < 0.45 then
            bz = center.z + math.random(-maxDropCells, 1)
        end

        -- 候选点取 mob 脚部所在层：脚部格和头部格都要是空的（mob 高 44 < 2 格）。
        -- 当前层不要求脚下有 MC 方块（flatgrass 地皮可支撑）；跨层候选必须有 MC 支撑。
        local hasSupport = real.IsSolid(coord(bx, by, bz - 1))
        if bz == center.z or hasSupport then
            local candidate = MC.CellWorldCenter(bx, by, bz)

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
