BMB = BMB or {}
BMB.Debug = BMB.Debug or {}

local function isBMBMob(ent)
    return IsValid(ent) and string.sub(ent:GetClass() or "", 1, 4) == "bmb_"
end

local function canUseDebug(ply)
    if not IsValid(ply) then return true end
    return ply:IsAdmin()
end

local function reply(ply, message)
    message = "[BMB] " .. message

    if IsValid(ply) then
        ply:ChatPrint(message)
    else
        print(message)
    end
end

local function getTargetMob(ply, radius)
    radius = radius or 768

    if IsValid(ply) then
        local trace = ply:GetEyeTrace()
        if isBMBMob(trace.Entity) then return trace.Entity end

        local best
        local bestDist = radius * radius

        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), radius)) do
            if isBMBMob(ent) then
                local dist = ent:GetPos():DistToSqr(ply:GetPos())
                if dist < bestDist then
                    best = ent
                    bestDist = dist
                end
            end
        end

        return best
    end

    for _, ent in ipairs(ents.GetAll()) do
        if isBMBMob(ent) then return ent end
    end

    return nil
end

local function requireTarget(ply)
    local radius = 768
    local mob = getTargetMob(ply, radius)

    if not IsValid(mob) then
        reply(ply, "No BMB mob found. Aim at one or stand within " .. radius .. " units.")
        return nil
    end

    return mob
end

function BMB.Debug.DescribeMob(mob)
    local velocity = mob:GetVelocity():Length2D()

    return string.format(
        "%s hp=%d/%d state=%s mode=%s vel2d=%.1f desired=%.1f dist=%.1f pos=%s source_path=%s",
        mob:GetClass(),
        mob:Health(),
        mob.StartHealth or 0,
        mob.State or "?",
        mob:GetNWString("BMBMoveMode", "?"),
        velocity,
        mob:GetNWFloat("BMBDesiredSpeed", 0),
        mob:GetNWFloat("BMBDistToGoal", 0),
        tostring(mob:GetPos()),
        tostring(mob.ShouldUseSourcePath and mob:ShouldUseSourcePath() or false)
    )
end

concommand.Add("bmb_debug_info", function(ply, _, args)
    if not canUseDebug(ply) then return end

    local mob = requireTarget(ply)
    if not IsValid(mob) then return end

    reply(ply, BMB.Debug.DescribeMob(mob))
end)

concommand.Add("bmb_debug_health", function(ply, _, args)
    if not canUseDebug(ply) then return end

    local mob = requireTarget(ply)
    if not IsValid(mob) then return end

    local value = tonumber(args[1])
    if value then
        mob:SetHealth(value)
        mob:SetNWInt("BMBHealth", mob:Health())
    end

    reply(ply, BMB.Debug.DescribeMob(mob))
end)

concommand.Add("bmb_debug_speed", function(ply, _, args)
    if not canUseDebug(ply) then return end

    local mob = requireTarget(ply)
    if not IsValid(mob) then return end

    local walk = tonumber(args[1])
    local run = tonumber(args[2])
    local accel = tonumber(args[3])
    local decel = tonumber(args[4])

    if walk then mob.WalkSpeed = walk end
    if run then mob.RunSpeed = run end
    if accel then
        mob.Acceleration = accel
        mob.loco:SetAcceleration(accel)
    end
    if decel then
        mob.Deceleration = decel
        mob.loco:SetDeceleration(decel)
    end

    reply(ply, string.format(
        "%s walk=%.1f run=%.1f accel=%.1f decel=%.1f",
        mob:GetClass(),
        mob.WalkSpeed or 0,
        mob.RunSpeed or 0,
        mob.Acceleration or 0,
        mob.Deceleration or 0
    ))
end)

concommand.Add("bmb_debug_move", function(ply, _, args)
    if not canUseDebug(ply) then return end

    local mob = requireTarget(ply)
    if not IsValid(mob) then return end

    local duration = tonumber(args[1]) or 5
    local speed = tonumber(args[2]) or mob.RunSpeed or 120
    local direction = IsValid(ply) and ply:GetAimVector() or mob:GetForward()
    direction.z = 0

    if direction:LengthSqr() <= 1 then
        direction = mob:GetForward()
        direction.z = 0
    end

    direction:Normalize()

    mob.BMBDebugMoveDirection = direction
    mob.BMBDebugMoveTarget = nil
    mob.BMBDebugMoveSpeed = speed
    mob.BMBDebugMoveUntil = CurTime() + duration
    mob.BMBDebugMoveLookAhead = math.max(speed * 1.2, 140)
    mob.FleeUntil = 0
    mob.BMBMoveInterrupt = true

    reply(ply, string.format("Debug moving %s for %.1fs at %.1f speed.", mob:GetClass(), duration, speed))
end)

concommand.Add("bmb_debug_stop", function(ply, _, args)
    if not canUseDebug(ply) then return end

    local mob = requireTarget(ply)
    if not IsValid(mob) then return end

    mob.BMBDebugMoveUntil = 0
    mob.BMBDebugMoveDirection = nil
    mob.BMBDebugMoveTarget = nil
    mob.FleeUntil = 0
    mob.FleeThreat = nil
    mob.FleeThreatPosition = nil
    mob:InterruptBMBMovement()

    reply(ply, "Stopped " .. mob:GetClass() .. ".")
end)

concommand.Add("bmb_debug_flee", function(ply, _, args)
    if not canUseDebug(ply) then return end

    local mob = requireTarget(ply)
    if not IsValid(mob) then return end

    local duration = tonumber(args[1]) or math.Rand(mob.FleeDurationMin or 3.5, mob.FleeDurationMax or 6)
    local threatPos = IsValid(ply) and ply:GetPos() or (mob:GetPos() - mob:GetForward() * 120)

    mob.FleeThreat = nil
    mob.FleeThreatPosition = threatPos
    mob.FleeUntil = CurTime() + duration
    mob:InterruptBMBMovement()

    reply(ply, string.format("Forced flee for %.1fs.", duration))
end)
