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

local function neighbors(coord)
    return {
        { x = coord.x + 1, y = coord.y, z = coord.z },
        { x = coord.x - 1, y = coord.y, z = coord.z },
        { x = coord.x, y = coord.y + 1, z = coord.z },
        { x = coord.x, y = coord.y - 1, z = coord.z }
    }
end

-- 可通行 = 脚部格和头部格都不是实心（mob 高 44 < 2 格）。
-- mock 是 z=0 平面世界、z=1 恒为空，行为不变；real 世界（3D）必须查头顶
local function isPassable(blockWorld, cell)
    if blockWorld.IsSolid(cell) then return false end

    return not blockWorld.IsSolid({ x = cell.x, y = cell.y, z = (cell.z or 0) + 1 })
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

local function reconstruct(cameFrom, current)
    local path = { copyCoord(current) }
    local currentKey = coordKey(current)

    while cameFrom[currentKey] do
        current = cameFrom[currentKey]
        path[#path + 1] = copyCoord(current)
        currentKey = coordKey(current)
    end

    local reversed = {}
    for i = #path, 1, -1 do
        reversed[#reversed + 1] = path[i]
    end

    return reversed
end

function pathfinder.FindPath(startPos, goalPos)
    local blockWorld = BMB.BlockWorld
    blockWorld.EnsureInitialized(startPos)

    local startCoord = blockWorld.WorldToBlock(startPos)
    local goalCoord = blockWorld.WorldToBlock(goalPos)
    local goalKey = coordKey(goalCoord)

    local open = { startCoord }
    local openSet = { [coordKey(startCoord)] = true }
    local closedSet = {}
    local cameFrom = {}
    local gScore = { [coordKey(startCoord)] = 0 }
    local fScore = { [coordKey(startCoord)] = heuristic(startCoord, goalCoord) }

    for _ = 1, BMB.Config.MaxPathIterations do
        if #open == 0 then break end

        local current = lowest(open, fScore)
        local currentKey = coordKey(current)
        openSet[currentKey] = nil

        if currentKey == goalKey then
            local coords = reconstruct(cameFrom, current)
            local waypoints = {}

            for i = 1, #coords do
                waypoints[#waypoints + 1] = blockWorld.BlockToWorld(coords[i])
            end

            return waypoints
        end

        closedSet[currentKey] = true

        for _, nextCoord in ipairs(neighbors(current)) do
            local nextKey = coordKey(nextCoord)

            if not closedSet[nextKey] and isPassable(blockWorld, nextCoord) then
                local tentative = (gScore[currentKey] or math.huge) + 1

                if tentative < (gScore[nextKey] or math.huge) then
                    cameFrom[nextKey] = copyCoord(current)
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
