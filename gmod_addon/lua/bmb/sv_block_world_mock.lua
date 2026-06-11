BMB = BMB or {}

-- IBlockWorld 的 mock 实现（开发/测试用：z=0 平面世界 + 调试框渲染）。
-- 运行时用哪个实现由 BMB.SelectBlockWorld()（sv_block_world_real.lua）决定，
-- 业务代码一律通过 BMB.BlockWorld 访问，不要直接引用 Mock/RealBlockWorld
BMB.MockBlockWorld = BMB.MockBlockWorld or {}
BMB.BlockWorld = BMB.BlockWorld or BMB.MockBlockWorld

local world = BMB.MockBlockWorld
world.Blocks = world.Blocks or {}
world.Initialized = world.Initialized or false
world.BaseZ = world.BaseZ or 0

util.AddNetworkString("bmb_mock_blocks")

local function key(coord)
    return coord.x .. "," .. coord.y .. "," .. coord.z
end

local function coord(x, y, z)
    return { x = x, y = y, z = z or 0 }
end

function world.WorldToBlock(pos)
    local size = BMB.Config.BlockSize

    return coord(
        math.floor(pos.x / size),
        math.floor(pos.y / size),
        0
    )
end

function world.BlockToWorld(blockCoord)
    local size = BMB.Config.BlockSize

    return Vector(
        (blockCoord.x + 0.5) * size,
        (blockCoord.y + 0.5) * size,
        world.BaseZ
    )
end

function world.FindGroundZ(origin)
    local trace = util.TraceLine({
        start = origin + Vector(0, 0, 64),
        endpos = origin - Vector(0, 0, 256),
        mask = MASK_SOLID
    })

    if trace.Hit then return trace.HitPos.z end
    return origin.z
end

function world.IsSolid(blockCoord)
    local blockType = world.Blocks[key(blockCoord)]
    return blockType == BMB.BlockTypes.Stone
end

function world.GetBlockAt(blockCoord)
    return world.Blocks[key(blockCoord)]
end

function world.SetBlockAt(blockCoord, blockType)
    world.Blocks[key(blockCoord)] = blockType
    print("[BMB] Mock SetBlockAt " .. key(blockCoord) .. " = " .. tostring(blockType))
    return true
end

function world.RemoveBlockAt(blockCoord)
    world.Blocks[key(blockCoord)] = nil
    print("[BMB] Mock RemoveBlockAt " .. key(blockCoord))
    return true
end

function world.GetBlocksInRadius(pos, radius)
    local center = world.WorldToBlock(pos)
    local blockRadius = math.ceil(radius / BMB.Config.BlockSize)
    local found = {}

    for x = center.x - blockRadius, center.x + blockRadius do
        for y = center.y - blockRadius, center.y + blockRadius do
            local blockCoord = coord(x, y, 0)
            local blockType = world.GetBlockAt(blockCoord)

            if blockType then
                found[#found + 1] = {
                    coord = blockCoord,
                    type = blockType
                }
            end
        end
    end

    return found
end

function world.GetAllBlocks()
    local found = {}

    for blockKey, blockType in pairs(world.Blocks) do
        local x, y, z = string.match(blockKey, "(-?%d+),(-?%d+),(-?%d+)")

        if x and y and z and blockType then
            found[#found + 1] = {
                coord = coord(tonumber(x), tonumber(y), tonumber(z)),
                type = blockType
            }
        end
    end

    return found
end

function world.EnsureInitialized(origin)
    if world.Initialized then return end

    world.Initialized = true
    world.BaseZ = world.FindGroundZ(origin or Vector(0, 0, 0))

    local center = world.WorldToBlock(origin or Vector(0, 0, 0))

    for x = center.x - 9, center.x + 9 do
        for y = center.y - 9, center.y + 9 do
            if math.random() < 0.28 then
                world.Blocks[key(coord(x, y, 0))] = BMB.BlockTypes.Grass
            end
        end
    end

    for y = center.y - 3, center.y + 3 do
        world.Blocks[key(coord(center.x + 3, y, 0))] = BMB.BlockTypes.Stone
    end

    world.Blocks[key(coord(center.x + 3, center.y, 0))] = nil
    print("[BMB] Mock block world initialized.")
end

function world.Reset(origin)
    world.Blocks = {}
    world.Initialized = false
    world.BaseZ = 0
    world.EnsureInitialized(origin or Vector(0, 0, 0))
end

function world.GetRandomWalkablePoint(origin, radius)
    world.EnsureInitialized(origin)

    local center = world.WorldToBlock(origin)
    local blockRadius = math.max(1, math.floor(radius / BMB.Config.BlockSize))

    for _ = 1, 24 do
        local blockCoord = coord(
            center.x + math.random(-blockRadius, blockRadius),
            center.y + math.random(-blockRadius, blockRadius),
            0
        )

        if not world.IsSolid(blockCoord) then
            return world.BlockToWorld(blockCoord)
        end
    end

    return origin
end

function world.ShowDebug(origin, radius, duration, showAll, ply)
    world.EnsureInitialized(origin)

    local blocks = showAll and world.GetAllBlocks() or world.GetBlocksInRadius(origin, radius or 520)
    local durationSeconds = duration or 8

    net.Start("bmb_mock_blocks")
    net.WriteFloat(durationSeconds)
    net.WriteUInt(math.min(#blocks, 65535), 16)
    for i, block in ipairs(blocks) do
        net.WriteVector(world.BlockToWorld(block.coord))
        net.WriteString(tostring(block.type))

        if i <= 3 then
            print("[BMB] Mock block sample " .. i .. ": " .. tostring(block.type) .. " at " .. tostring(world.BlockToWorld(block.coord)))
        end
    end

    if IsValid(ply) then
        net.Send(ply)
    else
        net.Broadcast()
    end

    print("[BMB] Showing " .. #blocks .. " mock blocks.")
end

concommand.Add("bmb_mock_show", function(ply, _, args)
    local origin = IsValid(ply) and ply:GetPos() or Vector(0, 0, 0)
    local showAll = args[1] == "all"
    local radius = showAll and 0 or (tonumber(args[1]) or 520)
    local duration = tonumber(args[showAll and 2 or 2]) or 8

    world.ShowDebug(origin, radius, duration, showAll, ply)
end)

concommand.Add("bmb_mock_reset", function(ply)
    local origin = IsValid(ply) and ply:GetPos() or Vector(0, 0, 0)
    world.Reset(origin)
    world.ShowDebug(origin, 520, 10, true, ply)
    print("[BMB] Mock world reset near " .. tostring(origin) .. ".")
end)
