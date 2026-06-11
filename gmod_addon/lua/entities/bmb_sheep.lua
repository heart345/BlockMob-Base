AddCSLuaFile()

ENT.Base = "bmb_base_mob"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Prototype Sheep"
ENT.Author = "BMB"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/kleiner.mdl"
ENT.StartHealth = 20
ENT.WalkSpeed = 70
-- MC PanicGoal 速度倍率：羊/猪 1.25×走速（牛 2.0×、兔 2.2×，做新怪时参考源码各自的 addGoal）
ENT.RunSpeed = 90
ENT.Acceleration = 240
ENT.Deceleration = 260
ENT.WanderDistanceMin = 108  -- 单段游荡 3~8 格
ENT.WanderDistanceMax = 288
ENT.WanderPauseMin = 6.0     -- 到站站立 6~14s，站立是常态
ENT.WanderPauseMax = 14.0
-- MC 恐慌窗口 = lastDamageSource 有效期 40 tick（2s），每次受击刷新；窗口内一段接一段跑，
-- 窗口过了跑完当前段就停，所以原版友好生物受击后跑不远
ENT.FleeDurationMin = 2.0
ENT.FleeDurationMax = 2.5
ENT.FleePanicRadius = 180        -- 恐慌单段目标 ±5 格（MC DefaultRandomPos.getPos(mob, 5, 4)）
ENT.FleePanicMinDistance = 36
ENT.FleeGiveUpFailures = 4       -- 连续 4 次选不出点/起步即被挡 → 认定无路可逃，放弃恐慌
ENT.CollisionMins = Vector(-14, -14, 0)
ENT.CollisionMaxs = Vector(14, 14, 44)

function ENT:Initialize()
    if CLIENT then return end

    self:BaseInitialize()
    self:SetBMBState("wander")
    self.FleeThreat = nil
    self.FleeThreatPosition = nil
    self.FleeUntil = 0
    self.NextEatGrassTime = CurTime() + math.Rand(8.0, 20.0)
end

function ENT:RunBehaviour()
    while true do
        local fleeThreat = IsValid(self.FleeThreat) and self.FleeThreat or self.FleeThreatPosition

        if self.RunBMBDebugMove and self:RunBMBDebugMove() then
            self.BMBDebugMoveActive = true
        elseif CurTime() < self.FleeUntil and fleeThreat then
            self:SetBMBState("flee")
            BMB.Behaviors.Flee.Run(self, fleeThreat)
        elseif BMB.Behaviors.EatGrass.Try(self) then
            self:SetBMBState("eat_grass")
        else
            self:SetBMBState("wander")
            BMB.Behaviors.Wander.Run(self)
        end

        coroutine.yield()
    end
end

function ENT:OnBMBInjured(damageInfo)
    local attacker = damageInfo:GetAttacker()
    local damagePosition = damageInfo:GetDamagePosition()
    local damageForce = damageInfo:GetDamageForce()

    if IsValid(attacker) then
        self.FleeThreat = nil
        self.FleeThreatPosition = attacker:GetPos()
    elseif damagePosition and damagePosition:LengthSqr() > 1 then
        self.FleeThreat = nil
        self.FleeThreatPosition = damagePosition
    elseif damageForce and damageForce:LengthSqr() > 1 then
        damageForce:Normalize()
        self.FleeThreat = nil
        self.FleeThreatPosition = self:GetPos() - damageForce * 128
    end

    if self.FleeThreatPosition then
        self.FleeUntil = CurTime() + math.Rand(self.FleeDurationMin or 3.5, self.FleeDurationMax or 6.0)
    end

    if self.InterruptBMBMovement then
        self:InterruptBMBMovement()
    else
        self.BMBMoveInterrupt = true
    end

    self:EmitSound("npc/headcrab/pain1.wav", 70, math.random(98, 108), 0.55)
end
