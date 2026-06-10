BMB = BMB or {}
BMB.RealBlockWorld = BMB.RealBlockWorld or {}

local real = BMB.RealBlockWorld
real.BlockIds = real.BlockIds or {}

local function coord(x, y, z)
    return { x = x, y = y, z = z or 0 }
end

local function hasMC()
    return istable(MC)
        and isfunction(MC.WorldToCell)
        and isfunction(MC.CellWorldCenter)
        and isfunction(MC.GetBlock)
end

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

local function resolveBlockType(blockType)
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

function real.Available()
    return hasMC()
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
    return MC.GetBlock(blockCoord.x, blockCoord.y, blockCoord.z)
end

function real.IsSolid(blockCoord)
    if not real.Available() then return false end

    local id = MC.GetBlock(blockCoord.x, blockCoord.y, blockCoord.z)
    if not id or id == 0 then return false end

    local orient = 0
    if isfunction(MC.GetBlockOrient) then
        orient = MC.GetBlockOrient(blockCoord.x, blockCoord.y, blockCoord.z) or 0
    end

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
                        type = id
                    }
                end
            end
        end
    end

    return found
end

function real.SetBlockAt(blockCoord, blockType)
    local id = resolveBlockType(blockType)
    if not id then return false end

    if not MC or not MC.SV or not isfunction(MC.SV.SetBlock) then
        print("[BMB] RealBlockWorld SetBlockAt needs MC.SV.SetBlock; stubbed for now.")
        return false
    end

    local orient = 0
    if isfunction(MC.DefaultOrient) then
        orient = MC.DefaultOrient(id) or 0
    end

    return MC.SV.SetBlock(blockCoord.x, blockCoord.y, blockCoord.z, id, orient)
end

function real.RemoveBlockAt(blockCoord)
    if not MC or not MC.SV or not isfunction(MC.SV.SetBlock) then
        print("[BMB] RealBlockWorld RemoveBlockAt needs MC.SV.SetBlock; stubbed for now.")
        return false
    end

    return MC.SV.SetBlock(blockCoord.x, blockCoord.y, blockCoord.z, 0, 0)
end
