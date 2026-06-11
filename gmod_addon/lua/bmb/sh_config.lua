BMB = BMB or {}

BMB.Config = BMB.Config or {}
BMB.Config.BlockSize = 36
BMB.Config.MaxPathIterations = 900
-- MC 普通 LivingEntity/Mob 的 getMaxFallDistance 默认 3；羊未覆写。
BMB.Config.MaxPathDropCells = 3
-- 到达阈值 = 0.5 个方块（CLAUDE.md），必须 >= PathNodeTolerance，
-- 否则离终点 [goal, node] 区间时节点推进不了、到达也判不过，mob 会在减速区原地扭
BMB.Config.DefaultGoalTolerance = 18

BMB.BlockTypes = {
    Grass = "GRASS",
    Dirt = "DIRT",
    Stone = "STONE"
}
