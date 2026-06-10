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
ENT.RunSpeed = 145
ENT.Acceleration = 240
ENT.Deceleration = 260
ENT.WanderRadius = 420
ENT.FleeDistance = 520
ENT.FleeDirectDistance = 220
ENT.FleeDirectDuration = 0.85
ENT.FleeDurationMin = 3.5
ENT.FleeDurationMax = 6.0
ENT.CollisionMins = Vector(-14, -14, 0)
ENT.CollisionMaxs = Vector(14, 14, 44)

function ENT:Initialize()
    if CLIENT then return end

    self:BaseInitialize()
    self:SetBMBState("wander")
    self.FleeThreat = nil
    self.FleeThreatPosition = nil
    self.FleeUntil = 0
    self.NextEatGrassTime = CurTime() + math.Rand(1.0, 3.0)
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
