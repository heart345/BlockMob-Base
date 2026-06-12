BMB = BMB or {}

BMB.Config = BMB.Config or {}
BMB.DefaultBlockSize = 36.5

function BMB.GetBlockSize()
    local mcBlockSize = MC and MC.BS and tonumber(MC.BS) or nil
    local blockSize = mcBlockSize or BMB.DefaultBlockSize

    BMB.BS = blockSize
    -- Compatibility alias for older call sites and debug panels. New code should use BMB.GetBlockSize().
    BMB.Config.BlockSize = blockSize
    BMB.Config.DefaultGoalTolerance = blockSize * (BMB.Config.DefaultGoalToleranceScale or 0.5)

    return blockSize
end

BMB.Config.DefaultGoalToleranceScale = 0.5
BMB.GetBlockSize()
BMB.Config.MaxPathIterations = 900
-- MC 普通 LivingEntity/Mob 的 getMaxFallDistance 默认 3；羊未覆写。
BMB.Config.MaxPathDropCells = 3
-- 到达阈值 = 0.5 个方块（CLAUDE.md），必须 >= PathNodeTolerance，
-- 否则离终点 [goal, node] 区间时节点推进不了、到达也判不过，mob 会在减速区原地扭

BMB.BlockTypes = {
    Grass = "GRASS",
    Dirt = "DIRT",
    Stone = "STONE"
}
