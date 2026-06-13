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

-- 可通行/支撑都带 per-FindPath 缓存：A* 里同一个格子会被反复当作 walk 邻居、hop 目标、
-- drop 落柱检查，而每次判断都是一轮 hull 占格扫描（每格十几次 GetBlock）。无缓存时
-- 目标不可达扫满迭代上限会放大成几十万次方块查询，全落在一帧里 = 肉眼可见的卡顿

-- 可通行默认 = 脚部格和头部格都不是实心；有 mob 上下文时交给实体按自身 hull
-- 做水平宽度/高度占格检查，避免成年羊从一格高洞或方块角落挤过去。
local function isPassable(blockWorld, cell, options)
    local cache = options and options.passableCache
    local cellKey = cache and coordKey(cell)

    if cache and cache[cellKey] ~= nil then return cache[cellKey] end

    local passable
    local mob = options and options.mob

    if IsValid(mob) and mob.IsBMBPathCellPassable then
        passable = mob:IsBMBPathCellPassable(cell) and true or false
    elseif blockWorld.IsSolid(cell) then
        passable = false
    else
        passable = not blockWorld.IsSolid({ x = cell.x, y = cell.y, z = (cell.z or 0) + 1 })
    end

    if cache then cache[cellKey] = passable end

    return passable
end

-- 支撑 = 脚下有 MC 实心方块；实现若提供 HasSupport（real 用 Source 刷子地面兜底），
-- flatgrass 地皮等非 MC 地面也算可站立，mob 才能在"方块结构 ↔ Source 地面"间寻路衔接
local function hasSupport(blockWorld, cell, options)
    local cache = options and options.supportCache
    local cellKey = cache and coordKey(cell)

    if cache and cache[cellKey] ~= nil then return cache[cellKey] end

    local supported
    if blockWorld.HasSupport then
        supported = blockWorld.HasSupport(cell) and true or false
    else
        supported = blockWorld.IsSolid({ x = cell.x, y = cell.y, z = (cell.z or 0) - 1 })
    end

    if cache then cache[cellKey] = supported end

    return supported
end

local function isStandable(blockWorld, cell, options)
    return isPassable(blockWorld, cell, options) and hasSupport(blockWorld, cell, options)
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

        if not allowVertical then
            -- mock 平面世界：只看可通行，不引入 z 轴语义（CLAUDE.md）
            if isPassable(blockWorld, sameLevel, options) then
                addNeighbor(found, copyCoord(sameLevel), "walk", 1)
            end
        else
            -- 同层 walk 边必须有支撑：否则目标不可达时搜索会顺着悬空格把整片空域
            -- 淹一遍直到迭代上限（= 右键不可达点时的整帧卡顿），路径本身也可能悬空
            if isStandable(blockWorld, sameLevel, options) then
                addNeighbor(found, copyCoord(sameLevel), "walk", 1)
            else
                -- StrandedRecovery 专用：实体已经被物理托在一个 BMB 语义非法的位置
                -- （例如玻璃板/脚下支撑失效），允许它沿 passable 但无支撑的表面逃向最近合法格。
                -- 普通寻路不走这里，因此不会主动把玻璃板等窄碰撞规划为目标路线。
                if options and options.allowUnsupportedWalk and isPassable(blockWorld, sameLevel, options) then
                    addNeighbor(found, copyCoord(sameLevel), "stranded", 1.05)
                end

                local dropTarget, dropCells = findDropNeighbor(blockWorld, coord, sameLevel, options)

                if dropTarget then
                    addNeighbor(found, copyCoord(dropTarget), "drop", 1 + dropCells * 0.12)
                end
            end

            local hopTarget = {
                x = sameLevel.x,
                y = sameLevel.y,
                z = (coord.z or 0) + 1
            }

            if isStandable(blockWorld, hopTarget, options) then
                addNeighbor(found, copyCoord(hopTarget), "hop", 1.25)
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

local function buildWaypoints(blockWorld, cameFrom, cameAction, endCoord)
    local coords = reconstruct(cameFrom, cameAction, endCoord)
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

-- 目标格悬空时（debug 工具点高处墙面/空中、目标点被抬出后落在空气里）向下吸附到
-- 第一个可站立格：目的地合法性属于目标产出方，但"悬空格"永远不合法，吸附到正下方
-- 地表是规范化而非运动层兜底；同时让不可达目标快速失败，不再扫满迭代上限
local function snapGoalToStandable(blockWorld, goalCoord, options)
    if isStandable(blockWorld, goalCoord, options) then return goalCoord end

    local cell = copyCoord(goalCoord)
    local maxScan = (options and options.goalSnapDownCells) or 12

    for _ = 1, maxScan do
        cell = { x = cell.x, y = cell.y, z = cell.z - 1 }

        if not isPassable(blockWorld, cell, options) then return nil end
        if hasSupport(blockWorld, cell, options) then return cell end
    end

    return nil
end

local function prepareQueryOptions(options)
    options = options or {}
    options.passableCache = options.passableCache or {}
    options.supportCache = options.supportCache or {}
    return options
end

local function searchOffsetAt(index, radius, downCells)
    local width = radius * 2 + 1
    local layerSize = width * width
    local zeroIndex = index - 1
    local layer = math.floor(zeroIndex / layerSize)
    local layerIndex = zeroIndex - layer * layerSize

    return (layerIndex % width) - radius,
        math.floor(layerIndex / width) - radius,
        layer - downCells
end

local function scoreStandableCandidate(blockWorld, origin, center, dx, dy, dz, options)
    if dx == 0 and dy == 0 and dz == 0 then return nil end
    if options and options.minHorizontalCells
        and math.max(math.abs(dx), math.abs(dy)) < options.minHorizontalCells then
        return nil
    end

    local cell = {
        x = center.x + dx,
        y = center.y + dy,
        z = (center.z or 0) + dz
    }

    if not isStandable(blockWorld, cell, options) then return nil end

    local pos = blockWorld.BlockToWorld(cell)
    local flatCost = math.sqrt(dx * dx + dy * dy)
    local verticalCost = math.abs(dz) * 1.25

    return flatCost + verticalCost + origin:DistToSqr(pos) * 0.0001, pos, cell
end

function pathfinder.IsStandablePosition(pos, options)
    if not BMB or not BMB.BlockWorld then return true end

    local blockWorld = BMB.BlockWorld
    if not blockWorld.WorldToBlock or not blockWorld.EnsureInitialized then return true end

    options = prepareQueryOptions(options)
    blockWorld.EnsureInitialized(pos)

    local cell = blockWorld.WorldToBlock(pos)
    return isStandable(blockWorld, cell, options), copyCoord(cell)
end

function pathfinder.FindNearestStandable(origin, options)
    if not BMB or not BMB.BlockWorld then return nil end

    local blockWorld = BMB.BlockWorld
    if not blockWorld.WorldToBlock or not blockWorld.BlockToWorld or not blockWorld.EnsureInitialized then return nil end

    options = prepareQueryOptions(options)
    blockWorld.EnsureInitialized(origin)

    local center = blockWorld.WorldToBlock(origin)
    local allowVertical = blockWorld.SupportsVerticalPath ~= false
    local radius = math.max(1, math.floor(options.searchRadiusCells or 6))
    local downCells = allowVertical and math.max(0, math.floor(options.searchDownCells or options.maxDropCells or 3)) or 0
    local upCells = allowVertical and math.max(0, math.floor(options.searchUpCells or 1)) or 0
    local bestCell
    local bestPos
    local bestScore = math.huge
    local searchWidth = radius * 2 + 1
    local searchCount = searchWidth * searchWidth * (downCells + upCells + 1)

    for i = 1, searchCount do
        local dx, dy, dz = searchOffsetAt(i, radius, downCells)
        local score, pos, cell = scoreStandableCandidate(blockWorld, origin, center, dx, dy, dz, options)

        if score and score < bestScore then
            bestScore = score
            bestCell = copyCoord(cell)
            bestPos = pos
        end
    end

    return bestPos, bestCell
end

function pathfinder.FindPath(startPos, goalPos, options)
    options = options or {}
    options.passableCache = {}
    options.supportCache = {}

    local blockWorld = BMB.BlockWorld
    blockWorld.EnsureInitialized(startPos)

    local allowVertical = blockWorld.SupportsVerticalPath ~= false
    local startCoord = blockWorld.WorldToBlock(startPos)
    local goalCoord = blockWorld.WorldToBlock(goalPos)

    if not isPassable(blockWorld, goalCoord, options) then return nil end

    if allowVertical then
        goalCoord = snapGoalToStandable(blockWorld, goalCoord, options)
        if not goalCoord then return nil end
    end

    local goalKey = coordKey(goalCoord)
    local startKey = coordKey(startCoord)
    local hStart = heuristic(startCoord, goalCoord)

    -- 搜索预算：f = g + h 超过它的节点不展开（椭圆界）。yield 只把卡顿摊开，
    -- 总开销没变；预算才是把"无路"结论的代价从扫满迭代上限压到起点-目标走廊一圈
    local fLimit = options.searchBudget or (hStart * 2 + 24)

    local open = { startCoord }
    local openSet = { [startKey] = true }
    local closedSet = {}
    local cameFrom = {}
    local cameAction = {}
    local gScore = { [startKey] = 0 }
    local fScore = { [startKey] = hStart }

    -- 部分路径：记录已展开节点里离目标最近的那个。搜索中止（预算/迭代耗尽、无路）
    -- 时返回到它的路径——行为观感从"卡顿后拒动"变成"走到崖边/尽头停住"（原版手感）
    local bestKey = startKey
    local bestCoord = startCoord
    local bestH = hStart

    -- 时间切片：FindPath 只在 nextbot 行为协程里调用，定期 yield 把大搜索摊到多个
    -- tick 上（mob 停半拍"想路"），不可达目标也不会再把单帧卡住
    local yieldEvery = math.max(8, options.yieldEvery or BMB.Config.PathfinderYieldEvery or 64)

    for iteration = 1, BMB.Config.MaxPathIterations do
        if #open == 0 then break end

        local current = lowest(open, fScore)
        local currentKey = coordKey(current)
        openSet[currentKey] = nil

        if currentKey == goalKey then
            return buildWaypoints(blockWorld, cameFrom, cameAction, current)
        end

        closedSet[currentKey] = true

        local currentH = heuristic(current, goalCoord)
        if currentH < bestH then
            bestH = currentH
            bestKey = currentKey
            bestCoord = current
        end

        for _, neighbor in ipairs(neighbors(current, blockWorld, options)) do
            local nextCoord = neighbor.coord
            local nextKey = coordKey(nextCoord)

            if not closedSet[nextKey] then
                local tentative = (gScore[currentKey] or math.huge) + (neighbor.cost or 1)
                local h = heuristic(nextCoord, goalCoord)

                if tentative + h <= fLimit and tentative < (gScore[nextKey] or math.huge) then
                    cameFrom[nextKey] = copyCoord(current)
                    cameAction[nextKey] = neighbor.action
                    gScore[nextKey] = tentative
                    fScore[nextKey] = tentative + h

                    if not openSet[nextKey] then
                        open[#open + 1] = copyCoord(nextCoord)
                        openSet[nextKey] = true
                    end
                end
            end
        end

        if iteration % yieldEvery == 0 and coroutine.running() then
            coroutine.yield()
        end
    end

    -- 走到这 = 无完整路径。能比起点更接近目标就交部分路径（标记 partial），
    -- 一步都凑不近才算彻底失败
    if options.allowPartial ~= false and bestKey ~= startKey and bestH < hStart then
        local waypoints = buildWaypoints(blockWorld, cameFrom, cameAction, bestCoord)
        waypoints.partial = true
        return waypoints
    end

    return nil
end
