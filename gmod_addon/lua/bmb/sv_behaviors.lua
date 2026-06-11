BMB = BMB or {}
BMB.Behaviors = BMB.Behaviors or {}

BMB.Behaviors.Wander = BMB.Behaviors.Wander or {}
BMB.Behaviors.Flee = BMB.Behaviors.Flee or {}
BMB.Behaviors.EatGrass = BMB.Behaviors.EatGrass or {}

-- 游荡 = 选一个随机可走点，沿 A* 路径完整走到，到达后按 MC 节奏停顿一下再选下一个。
-- 不要在途中按固定时长切段：那会变成"走一会-刹停-换向"的节奏（已踩过坑）。
-- 途中的转向全部由 MoveAlongPath 的 carrot point 平滑完成。
function BMB.Behaviors.Wander.Run(mob)
    -- 单段行程的距离范围：MC 式短途散步（2~5 格），不跨半张地图
    local minDistance = mob.WanderDistanceMin or BMB.Config.BlockSize * 2
    local maxDistance = mob.WanderDistanceMax or mob.WanderRadius or BMB.Config.BlockSize * 5

    for _ = 1, 8 do
        if mob.BMBMoveInterrupt then return end

        local destination = BMB.BlockWorld.GetRandomWalkablePoint(mob:GetPos(), maxDistance, mob)
        local direction = destination - mob:GetPos()
        direction.z = 0

        local distance = direction:Length2D()

        if distance >= minDistance and distance <= maxDistance then
            if mob:MoveToWorldPosition(destination, mob.WalkSpeed, { skipSourcePath = true }) then
                -- 原版 MC 游荡是"站很久、偶尔走一段"：到站后长停顿，站立才是常态
                mob:InterruptibleWait(math.Rand(mob.WanderPauseMin or 6.0, mob.WanderPauseMax or 14.0))
                return
            end

            -- 走不通（路径失败/被挡）直接换个目标点重试，不插入停顿，保持移动连贯
            if mob.BMBMoveInterrupt then return end
        end
    end

    -- 候选点全部失败，歇一拍避免空转刷路径
    mob:InterruptibleWait(math.Rand(1.0, 2.0))
end

-- Flee = MC 的 PanicGoal（参考 net/minecraft/world/entity/ai/goal/PanicGoal.java +
-- ai/util/DefaultRandomPos.java / RandomPos.java，源码在用户本地）：
-- 恐慌**不是**朝伤害反方向跑，而是反复"随机选一个可达的近点（±5 格）→ 全速跑过去"，
-- 跑完一段还在恐慌窗口内就再选下一段——大平地的观感就是随机乱跑、且跑不远。
-- 候选点全部不可达（MC：10 次全过不了寻路校验 → canUse false）= 没地方跑，站住不恐慌。

local function pickPanicDestination(mob)
    -- MC DefaultRandomPos.getPos(mob, 5, 4)：水平 ±5 格随机；RANDOM_POS_ATTEMPTS = 10
    local radius = mob.FleePanicRadius or BMB.Config.BlockSize * 5
    local minDistance = mob.FleePanicMinDistance or BMB.Config.BlockSize

    for _ = 1, 10 do
        local candidate = BMB.BlockWorld.GetRandomWalkablePoint(mob:GetPos(), radius, mob)
        local offset = candidate - mob:GetPos()
        offset.z = 0

        local distance = offset:Length2D()

        if distance >= minDistance and distance <= radius then
            offset:Normalize()

            -- MC 用寻路 malus 校验候选点可达；BMB 的方块 A* 看不到 prop 和 Source 平台边缘，
            -- 改用前向安全探测代替：朝候选点的第一段必须能走（挡掉悬崖外、prop 正后方的点）
            local probe = math.min(distance, 110)
            local probeTarget = mob:GetPos() + offset * probe
            probeTarget.z = mob:GetPos().z

            if not mob.IsMovementTargetSafe or mob:IsMovementTargetSafe(probeTarget, probe) then
                return candidate
            end
        end
    end

    return nil
end

function BMB.Behaviors.Flee.Run(mob)
    -- 连续失败（选不出候选点 / 起步即被挡）达到上限 = 确认无路可逃，提前结束恐慌。
    -- 对齐 MC 实测：被围在小台子上的友好生物冲几下就站住，不会无限乱撞绕圈
    local failures = 0
    local giveUpAfter = mob.FleeGiveUpFailures or 4

    while CurTime() < (mob.FleeUntil or 0) do
        if mob.ClearBMBMovementInterrupt then
            mob:ClearBMBMovementInterrupt()
        else
            mob.BMBMoveInterrupt = false
        end

        local destination = pickPanicDestination(mob)
        local moved = false

        if destination then
            moved = mob:MoveToWorldPosition(destination, mob.RunSpeed, { skipSourcePath = true })
        end

        if mob.BMBMoveInterrupt then
            -- 跑动中再次受击：FleeUntil 已被刷新，不算逃跑失败，直接进下一段
            if mob.ClearBMBMovementInterrupt then
                mob:ClearBMBMovementInterrupt()
            else
                mob.BMBMoveInterrupt = false
            end
        elseif moved then
            failures = 0
        else
            failures = failures + 1

            if failures >= giveUpAfter then
                mob.FleeUntil = 0
                return
            end

            coroutine.yield()
        end
    end
end

function BMB.Behaviors.EatGrass.Try(mob)
    if CurTime() < (mob.NextEatGrassTime or 0) then return false end

    -- 吃的是脚下踩着的那个方块：mob 原点在脚底，往下偏一点再换算才落进支撑方块
    -- （real 世界里 GetPos 所在格是脚部的空气格；mock 的 WorldToBlock 忽略 z，行为不变）
    local blockCoord = BMB.BlockWorld.WorldToBlock(mob:GetPos() - Vector(0, 0, 4))
    local blockType = BMB.BlockWorld.GetBlockAt(blockCoord)

    if blockType ~= BMB.BlockTypes.Grass then
        mob.NextEatGrassTime = CurTime() + math.Rand(2.0, 4.0)
        return false
    end

    -- mob 作为 actor 传给方块世界（real 实现会带进 MCSWEP 的 OnPlace/OnBreak）
    BMB.BlockWorld.SetBlockAt(blockCoord, BMB.BlockTypes.Dirt, mob)
    mob:EmitSound("npc/barnacle/barnacle_crunch2.wav", 65, math.random(95, 105), 0.45)
    -- MC 里成年羊吃草是低频行为，吃完要隔较长时间才会再吃
    mob.NextEatGrassTime = CurTime() + math.Rand(mob.EatGrassCooldownMin or 25, mob.EatGrassCooldownMax or 45)

    if mob.PlayBMBAnimation then
        mob:PlayBMBAnimation("eat")
    end

    if mob.InterruptibleWait then
        if not mob:InterruptibleWait(0.65) then return false end
    else
        coroutine.wait(0.65)
    end

    return true
end
