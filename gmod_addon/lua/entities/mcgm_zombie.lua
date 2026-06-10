AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.Type = "nextbot"
ENT.PrintName = "MCGM Prototype Zombie"
ENT.Author = "MCGM"
ENT.Category = "Minecraft in GMod"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/Zombie/Classic.mdl"
ENT.StartHealth = 20
ENT.WalkSpeed = 92
ENT.RunSpeed = 115
ENT.Acceleration = 420
ENT.Deceleration = 650
ENT.TargetRange = 900
ENT.AttackRange = 38
ENT.AttackDamage = 10
ENT.AttackCooldown = 1.05
ENT.AttackHitDelay = 0.38
ENT.AttackKnockback = 330
ENT.AttackVerticalKnockback = 155
ENT.StepInterval = 0.48
ENT.RepathInterval = 0.35
ENT.DynamicObstacleAvoidDistance = 95
ENT.DynamicObstacleSideDistance = 95
ENT.DynamicObstacleForwardDistance = 80
ENT.DynamicObstacleAvoidDuration = 0.55

ENT.Sounds = {
    Idle = {
        "npc/zombie/zombie_voice_idle1.wav",
        "npc/zombie/zombie_voice_idle2.wav",
        "npc/zombie/zombie_voice_idle3.wav"
    },
    Hurt = {
        "npc/zombie/zombie_pain1.wav",
        "npc/zombie/zombie_pain2.wav",
        "npc/zombie/zombie_pain3.wav"
    },
    Death = {
        "npc/zombie/zombie_die1.wav",
        "npc/zombie/zombie_die2.wav",
        "npc/zombie/zombie_die3.wav"
    },
    Step = {
        "npc/zombie/foot1.wav",
        "npc/zombie/foot2.wav",
        "npc/zombie/foot3.wav"
    },
    PlayerHit = {
        "player/pl_pain5.wav",
        "player/pl_pain6.wav",
        "player/pl_pain7.wav"
    }
}

local function randomSound(list)
    return list[math.random(#list)]
end

local function validNavArea(area)
    return area and area.IsValid and area:IsValid()
end

function ENT:Initialize()
    if CLIENT then return end

    self:SetModel(self.Model)
    self:SetHealth(self.StartHealth)
    self:SetCollisionBounds(Vector(-13, -13, 0), Vector(13, 13, 72))
    self:SetSolid(SOLID_BBOX)

    self.loco:SetStepHeight(18)
    self.loco:SetJumpHeight(58)
    self.loco:SetAcceleration(self.Acceleration)
    self.loco:SetDeceleration(self.Deceleration)
    self.loco:SetDesiredSpeed(self.WalkSpeed)

    self.NextAttackTime = 0
    self.NextIdleSoundTime = CurTime() + math.Rand(4, 10)
    self.NextStepSoundTime = 0
    self.NextNavWarningTime = 0
    self.DynamicAvoidUntil = 0
    self.DynamicAvoidPoint = nil
end

function ENT:RunBehaviour()
    while true do
        local enemy = self:FindEnemy()

        if IsValid(enemy) then
            self:ChaseEnemy(enemy)
        else
            self:Wander()
        end

        coroutine.yield()
    end
end

function ENT:FindEnemy()
    local bestTarget
    local bestDistance = self.TargetRange * self.TargetRange

    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            local distance = self:GetPos():DistToSqr(ply:GetPos())
            if distance < bestDistance and self:Visible(ply) then
                bestTarget = ply
                bestDistance = distance
            end
        end
    end

    return bestTarget
end

function ENT:ChaseEnemy(enemy)
    self.loco:SetDesiredSpeed(self.RunSpeed)

    local path = Path("Follow")
    path:SetMinLookAheadDistance(130)
    path:SetGoalTolerance(self.AttackRange * 0.65)
    path:Compute(self, enemy:GetPos())

    if not path:IsValid() then
        self:WarnMissingPath()
        return
    end

    local nextRepathTime = 0
    while IsValid(enemy) and enemy:Alive() do
        if self:GetRangeTo(enemy) <= self.AttackRange then
            self:FaceTarget(enemy:GetPos())
            self:TryAttack(enemy)
            coroutine.wait(0.1)
        else
            if CurTime() >= nextRepathTime then
                path:Compute(self, enemy:GetPos())
                if not path:IsValid() then
                    self:WarnMissingPath()
                    return
                end

                nextRepathTime = CurTime() + self.RepathInterval
            end

            if not self:TryAvoidDynamicObstacle(enemy) then
                path:Update(self)
                self:BodyMoveXY()
                self:MaybePlayStep()
            end
        end

        self:MaybePlayIdleSound()

        if self.loco:IsStuck() then
            self:HandleStuck()
            return
        end

        coroutine.yield()
    end
end

function ENT:Wander()
    self.loco:SetDesiredSpeed(self.WalkSpeed)
    self:MaybePlayIdleSound()

    coroutine.wait(math.Rand(0.35, 1.4))

    local destination = self:GetWanderDestination()

    local path = Path("Follow")
    path:SetMinLookAheadDistance(80)
    path:SetGoalTolerance(35)
    path:Compute(self, destination)

    if not path:IsValid() then
        self:WarnMissingPath()
        return
    end

    local timeout = CurTime() + math.Rand(2.0, 4.0)
    while path:IsValid() and CurTime() < timeout do
        if IsValid(self:FindEnemy()) then return end

        if not self:TryAvoidDynamicObstacle() then
            path:Update(self)
            self:BodyMoveXY()
            self:MaybePlayStep()
        end

        self:MaybePlayIdleSound()

        if self.loco:IsStuck() then
            self:HandleStuck()
            return
        end

        coroutine.yield()
    end
end

function ENT:TryAttack(enemy)
    if CurTime() < self.NextAttackTime then return end

    self.NextAttackTime = CurTime() + self.AttackCooldown
    self:RestartGesture(ACT_MELEE_ATTACK1)

    timer.Simple(self.AttackHitDelay, function()
        if not IsValid(self) or not IsValid(enemy) then return end
        if self:GetRangeTo(enemy) > self.AttackRange + 12 then return end

        local damage = DamageInfo()
        damage:SetAttacker(self)
        damage:SetInflictor(self)
        damage:SetDamage(self.AttackDamage)
        damage:SetDamageType(DMG_SLASH)
        enemy:TakeDamageInfo(damage)

        self:ApplyHitFeedback(enemy)
    end)
end

function ENT:ApplyHitFeedback(enemy)
    enemy:EmitSound(randomSound(self.Sounds.PlayerHit), 72, math.random(96, 104), 0.75)

    if not enemy:IsPlayer() then return end

    local direction = enemy:GetPos() - self:GetPos()
    direction.z = 0

    if direction:LengthSqr() <= 1 then return end

    direction:Normalize()
    enemy:SetVelocity(direction * self.AttackKnockback + Vector(0, 0, self.AttackVerticalKnockback))
end

function ENT:FaceTarget(position)
    local direction = position - self:GetPos()
    direction.z = 0

    if direction:LengthSqr() <= 1 then return end

    local targetAngle = Angle(0, direction:Angle().y, 0)
    self:SetAngles(targetAngle)
end

function ENT:GetWanderDestination()
    local offset = Vector(math.Rand(-420, 420), math.Rand(-420, 420), 0)
    local fallback = self:GetPos() + offset

    if navmesh and navmesh.GetNearestNavArea then
        local area = navmesh.GetNearestNavArea(fallback, false, 700, false, true)
        if validNavArea(area) then
            return area:GetRandomPoint()
        end
    end

    return fallback
end

function ENT:TryAvoidDynamicObstacle(enemy)
    if CurTime() < self.DynamicAvoidUntil and self.DynamicAvoidPoint then
        self:MoveTowardAvoidPoint()
        return true
    end

    local velocity = self:GetVelocity()
    local forward = velocity:Length2D() > 8 and velocity:GetNormalized() or self:GetForward()
    forward.z = 0

    if forward:LengthSqr() <= 0 then return false end

    forward:Normalize()

    local startPos = self:GetPos() + Vector(0, 0, 34)
    local trace = util.TraceHull({
        start = startPos,
        endpos = startPos + forward * self.DynamicObstacleAvoidDistance,
        mins = Vector(-15, -15, -24),
        maxs = Vector(15, 15, 24),
        filter = function(ent)
            return ent ~= self and ent ~= enemy
        end,
        mask = MASK_SOLID
    })

    if not trace.Hit or not self:IsDynamicObstacle(trace.Entity) then return false end

    local right = forward:Cross(Vector(0, 0, 1))
    local leftPoint = self:GetPos() - right * self.DynamicObstacleSideDistance + forward * self.DynamicObstacleForwardDistance
    local rightPoint = self:GetPos() + right * self.DynamicObstacleSideDistance + forward * self.DynamicObstacleForwardDistance

    self.DynamicAvoidPoint = self:PickClearAvoidPoint(leftPoint, rightPoint, trace.Entity)
    if not self.DynamicAvoidPoint then return false end

    self.DynamicAvoidUntil = CurTime() + self.DynamicObstacleAvoidDuration
    self:MoveTowardAvoidPoint()
    return true
end

function ENT:IsDynamicObstacle(ent)
    if not IsValid(ent) then return false end
    if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then return false end
    if ent:GetMoveType() == MOVETYPE_NONE then return false end

    return ent:GetSolid() ~= SOLID_NONE
end

function ENT:PickClearAvoidPoint(leftPoint, rightPoint, obstacle)
    local leftClear = self:IsAvoidPointClear(leftPoint, obstacle)
    local rightClear = self:IsAvoidPointClear(rightPoint, obstacle)

    if leftClear and rightClear then
        if math.random(0, 1) == 0 then return leftPoint end
        return rightPoint
    end

    if leftClear then return leftPoint end
    if rightClear then return rightPoint end
end

function ENT:IsAvoidPointClear(point, obstacle)
    local startPos = self:GetPos() + Vector(0, 0, 34)
    local trace = util.TraceHull({
        start = startPos,
        endpos = point + Vector(0, 0, 34),
        mins = Vector(-15, -15, -24),
        maxs = Vector(15, 15, 24),
        filter = function(ent)
            return ent ~= self and ent ~= obstacle
        end,
        mask = MASK_SOLID
    })

    return not trace.Hit
end

function ENT:MoveTowardAvoidPoint()
    self:FaceTarget(self.DynamicAvoidPoint)
    self.loco:Approach(self.DynamicAvoidPoint, 1)
    self:BodyMoveXY()
    self:MaybePlayStep()

    if self:GetPos():DistToSqr(self.DynamicAvoidPoint) < 900 then
        self.DynamicAvoidUntil = 0
        self.DynamicAvoidPoint = nil
    end
end

function ENT:WarnMissingPath()
    if CurTime() < self.NextNavWarningTime then return end

    self.NextNavWarningTime = CurTime() + 5

    if navmesh and navmesh.GetNavAreaCount and navmesh.GetNavAreaCount() == 0 then
        print("[MCGM] 当前地图没有 navmesh，NextBot 不能正常绕路。请在控制台运行 nav_generate。")
    else
        print("[MCGM] 无法计算有效路径，可能是目标点不在 navmesh 上。")
    end
end

function ENT:MaybePlayIdleSound()
    if CurTime() < self.NextIdleSoundTime then return end

    self:EmitSound(randomSound(self.Sounds.Idle), 72, math.random(92, 108), 0.75)
    self.NextIdleSoundTime = CurTime() + math.Rand(5, 12)
end

function ENT:MaybePlayStep()
    if CurTime() < self.NextStepSoundTime then return end
    if self:GetVelocity():Length2D() < 20 then return end

    self:EmitSound(randomSound(self.Sounds.Step), 64, math.random(96, 104), 0.45)
    self.NextStepSoundTime = CurTime() + self.StepInterval
end

function ENT:OnInjured()
    if CLIENT then return end
    self:EmitSound(randomSound(self.Sounds.Hurt), 72, math.random(95, 105), 0.8)
end

function ENT:OnKilled(damageInfo)
    if CLIENT then return end

    self:EmitSound(randomSound(self.Sounds.Death), 76, math.random(95, 105), 0.9)
    hook.Run("OnNPCKilled", self, damageInfo:GetAttacker(), damageInfo:GetInflictor())
    self:BecomeRagdoll(damageInfo)
end
