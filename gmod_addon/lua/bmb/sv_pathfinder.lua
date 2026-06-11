BMB = BMB or {}
BMB.Pathfinder = BMB.Pathfinder or {}

local pathfinder = BMB.Pathfinder

local function coordKey(coord)
    return coord.x .. "," .. coord.y .. "," .. coord.z
end

local function copyCoord(coord)
    return { x = coord.x, y = coord.y, z = coord.z or 0 }
end

local function heuristic(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y) + math.abs((a.z or 0) - (b.z or 0))
end

local directions = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 }
}

-- 可通行默认 = 脚部格和头部格都不是实心；有 mob 上下文时交给实体按自身 hull
-- 做水平宽度/高度占格检查，避免成年羊从一格高洞或方块角落挤过去。
local function isPassable(blockWorld, cell, options)
    local mob = options and options.mob
    if IsValid(mob) and mob.IsBMBPathCellPassable then
        return mob:IsBMBPathCellPassable(cell)
    end

    if blockWorld.IsSolid(cell) then return false end

    return not blockWorld.IsSolid({ x = cell.x, y = cell.y, z = (cell.z or 0) + 1 })
end

local function hasSolidBelow(blockWorld, cell)
    return blockWorld.IsSolid({ x = cell.x, y = cell.y, z = (cell.z or 0) - 1 })
end

local function isStandable(blockWorld, cell, options)
    return isPassable(blockWorld, cell, options) and hasSolidBelow(blockWorld, cell)
end

local function isDropColumnClear(blockWorld, current, target, options)
    local topZ = current.z or 0
    local bottomZ = target.z or 0

    for z = bottomZ, topZ do
        if not isPassable(blockWorld, { x = target.x, y = target.y, z = z }, options) then
            return false
        end
    end

    return true
end

local function addNeighbor(found, coord, action, cost)
    found[#found + 1] = {
        coord = coord,
        action = action or "walk",
        cost = cost or 1
    }
end

local function findDropNeighbor(blockWorld, current, sameLevel, options)
    if not isPassable(blockWorld, sameLevel, options) then return nil end

    local mob = options and options.mob
    local maxDropCells = (options and options.maxDropCells)
        or (IsValid(mob) and mob.MaxPathDropCells)
        or BMB.Config.MaxPathDropCells
        or 3

    maxDropCells = math.max(0, math.floor(maxDropCells))

    for dropCells = 1, maxDropCells do
        local target = {
            x = sameLevel.x,
            y = sameLevel.y,
            z = (current.z or 0) - dropCells
        }

        if isStandable(blockWorld, target, options) and isDropColumnClear(blockWorld, current, target, options) then
            return target, dropCells
        end
    end
end

local function neighbors(coord, blockWorld, options)
    local found = {}
    local allowVertical = blockWorld.SupportsVerticalPath ~= false

    for _, direction in ipairs(directions) do
        local sameLevel = {
            x = coord.x + direction.x,
            y = coord.y + direction.y,
            z = coord.z
        }

        local dropTarget, dropCells
        if allowVertical then
            dropTarget, dropCells = findDropNeighbor(blockWorld, coord, sameLevel, options)
        end

        if isPassable(blockWorld, sameLevel, options) and not dropTarget then
            addNeighbor(found, copyCoord(sameLevel), "walk", 1)
        end

        if allowVertical then
            local hopTarget = {
                x = sameLevel.x,
                y = sameLevel.y,
                z = (coord.z or 0) + 1
            }

            if isStandable(blockWorld, hopTarget, options) then
                addNeighbor(found, copyCoord(hopTarget), "hop", 1.25)
            end

            if dropTarget then
                addNeighbor(found, copyCoord(dropTarget), "drop", 1 + dropCells * 0.12)
            end
        end
    end

    return found
end

local function lowest(open, fScore)
    local bestIndex = 1
    local bestScore = fScore[coordKey(open[1])] or math.huge

    for i = 2, #open do
        local score = fScore[coordKey(open[i])] or math.huge
        if score < bestScore then
            bestIndex = i
            bestScore = score
        end
    end

    local best = open[bestIndex]
    table.remove(open, bestIndex)
    return best
end

local function reconstruct(cameFrom, cameAction, current)
    local path = {
        {
            coord = copyCoord(current),
            action = cameAction[coordKey(current)]
        }
    }
    local currentKey = coordKey(current)

    while cameFrom[currentKey] do
        current = cameFrom[currentKey]
        currentKey = coordKey(current)
        path[#path + 1] = {
            coord = copyCoord(current),
            action = cameAction[currentKey]
        }
    end

    local reversed = {}
    for i = #path, 1, -1 do
        reversed[#reversed + 1] = path[i]
    end

    return reversed
end

function pathfinder.FindPath(startPos, goalPos, options)
    options = options or {}

    local blockWorld = BMB.BlockWorld
    blockWorld.EnsureInitialized(startPos)

    local startCoord = blockWorld.WorldToBlock(startPos)
    local goalCoord = blockWorld.WorldToBlock(goalPos)
    local goalKey = coordKey(goalCoord)

    if not isPassable(blockWorld, goalCoord, options) then return nil end

    local open = { startCoord }
    local openSet = { [coordKey(startCoord)] = true }
    local closedSet = {}
    local cameFrom = {}
    local cameAction = {}
    local gScore = { [coordKey(startCoord)] = 0 }
    local fScore = { [coordKey(startCoord)] = heuristic(startCoord, goalCoord) }

    for _ = 1, BMB.Config.MaxPathIterations do
        if #open == 0 then break end

        local current = lowest(open, fScore)
        local currentKey = coordKey(current)
        openSet[currentKey] = nil

        if currentKey == goalKey then
            local coords = reconstruct(cameFrom, cameAction, current)
            local waypoints = {}

            for i = 1, #coords do
                local node = coords[i]
                local pos = blockWorld.BlockToWorld(node.coord)

                waypoints[#waypoints + 1] = {
                    x = pos.x,
                    y = pos.y,
                    z = pos.z,
                    coord = copyCoord(node.coord),
                    action = node.action
                }
            end

            return waypoints
        end

        closedSet[currentKey] = true

        for _, neighbor in ipairs(neighbors(current, blockWorld, options)) do
            local nextCoord = neighbor.coord
            local nextKey = coordKey(nextCoord)

            if not closedSet[nextKey] and isPassable(blockWorld, nextCoord, options) then
                local tentative = (gScore[currentKey] or math.huge) + (neighbor.cost or 1)

                if tentative < (gScore[nextKey] or math.huge) then
                    cameFrom[nextKey] = copyCoord(current)
                    cameAction[nextKey] = neighbor.action
                    gScore[nextKey] = tentative
                    fScore[nextKey] = tentative + heuristic(nextCoord, goalCoord)

                    if not openSet[nextKey] then
                        open[#open + 1] = copyCoord(nextCoord)
                        openSet[nextKey] = true
                    end
                end
            end
        end
    end

    return nil
end
