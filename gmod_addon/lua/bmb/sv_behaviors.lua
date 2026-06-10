BMB = BMB or {}
BMB.Behaviors = BMB.Behaviors or {}

BMB.Behaviors.Wander = BMB.Behaviors.Wander or {}
BMB.Behaviors.Flee = BMB.Behaviors.Flee or {}
BMB.Behaviors.EatGrass = BMB.Behaviors.EatGrass or {}

local function rotate2D(vec, radians)
    return Vector(
        vec.x * math.cos(radians) - vec.y * math.sin(radians),
        vec.x * math.sin(radians) + vec.y * math.cos(radians),
        0
    )
end

local function getSafeDirection(mob, baseDirection, lookAhead)
    local angleOffsets = { 0, 30, -30, 60, -60, 90, -90, 135, -135, 180 }

    for _, degrees in ipairs(angleOffsets) do
        local direction = rotate2D(baseDirection, math.rad(degrees))

        if direction:LengthSqr() > 1 then
            direction:Normalize()

            local target = mob:GetPos() + direction * lookAhead
            target.z = mob:GetPos().z

            if not mob.IsMovementTargetSafe or mob:IsMovementTargetSafe(target) then
                return direction
            end
        end
    end

    return nil
end

function BMB.Behaviors.Wander.Run(mob)
    if mob.InterruptibleWait then
        if not mob:InterruptibleWait(math.Rand(0.05, 0.18)) then return end
    else
        coroutine.wait(math.Rand(0.05, 0.18))
    end

    for _ = 1, 8 do
        local destination = BMB.BlockWorld.GetRandomWalkablePoint(mob:GetPos(), mob.WanderRadius or 360)
        local direction = destination - mob:GetPos()
        direction.z = 0

        if direction:LengthSqr() > 1 then
            direction:Normalize()

            local safeDirection = getSafeDirection(mob, direction, 110)
            if safeDirection and mob.MoveAlongDirection then
                if mob:MoveAlongDirection(safeDirection, mob.WalkSpeed, {
                    duration = math.Rand(1.0, 1.8),
                    lookAhead = 110
                }) then return end
            elseif mob.UseWanderPathFallback and mob.MoveToWorldPosition and mob:MoveToWorldPosition(destination, mob.WalkSpeed, {
                allowDirectFallback = true,
                duration = math.Rand(0.65, 1.0)
            }) then
                return
            end

            if mob.BMBMoveInterrupt then return end
        end
    end

    if mob.SetBMBMoveMode then
        mob:SetBMBMoveMode("idle")
    end
end

function BMB.Behaviors.Flee.GetThreatPosition(threat)
    if IsValid(threat) then return threat:GetPos() end
    if (isvector and isvector(threat)) or type(threat) == "Vector" then return threat end

    return nil
end

function BMB.Behaviors.Flee.Run(mob, threat)
    local activeThreat = mob.FleeThreatPosition or (IsValid(mob.FleeThreat) and mob.FleeThreat) or threat
    local threatPos = BMB.Behaviors.Flee.GetThreatPosition(activeThreat)
    if not threatPos then return end

    if mob.ClearBMBMovementInterrupt then
        mob:ClearBMBMovementInterrupt()
    else
        mob.BMBMoveInterrupt = false
    end

    local away = mob:GetPos() - threatPos
    away.z = 0

    if away:LengthSqr() <= 1 then
        away = VectorRand()
        away.z = 0
    end

    away:Normalize()

    while CurTime() < (mob.FleeUntil or 0) do
        activeThreat = mob.FleeThreatPosition or (IsValid(mob.FleeThreat) and mob.FleeThreat) or threat
        threatPos = BMB.Behaviors.Flee.GetThreatPosition(activeThreat)
        if not threatPos then return end

        away = mob:GetPos() - threatPos
        away.z = 0

        if away:LengthSqr() <= 1 then
            away = VectorRand()
            away.z = 0
        end

        away:Normalize()

        local safeDirection = getSafeDirection(mob, away, mob.FleeDirectDistance or 180)
        local moved = false

        if safeDirection and mob.MoveAlongDirection then
            moved = mob:MoveAlongDirection(safeDirection, mob.RunSpeed, {
                duration = mob.FleeDirectDuration or 0.22,
                lookAhead = mob.FleeDirectDistance or 180
            })
        else
            local fallback = mob:GetPos() + away * 120
            moved = mob:MoveDirectFallback(fallback, mob.RunSpeed, { duration = 0.16 })
        end

        if mob.BMBMoveInterrupt then
            if mob.ClearBMBMovementInterrupt then
                mob:ClearBMBMovementInterrupt()
            else
                mob.BMBMoveInterrupt = false
            end
        end

        if not moved then coroutine.yield() end
    end
end

function BMB.Behaviors.EatGrass.Try(mob)
    if CurTime() < (mob.NextEatGrassTime or 0) then return false end

    local blockCoord = BMB.BlockWorld.WorldToBlock(mob:GetPos())
    local blockType = BMB.BlockWorld.GetBlockAt(blockCoord)

    if blockType ~= BMB.BlockTypes.Grass then
        mob.NextEatGrassTime = CurTime() + math.Rand(1.0, 2.2)
        return false
    end

    BMB.BlockWorld.SetBlockAt(blockCoord, BMB.BlockTypes.Dirt)
    mob:EmitSound("npc/barnacle/barnacle_crunch2.wav", 65, math.random(95, 105), 0.45)
    mob.NextEatGrassTime = CurTime() + math.Rand(5.0, 9.0)

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
