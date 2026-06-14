AddCSLuaFile()

ENT.Base = "bmb_base_mob"
ENT.Type = "nextbot"
ENT.PrintName = "BMB Prototype Zombie"
ENT.Author = "BMB"
ENT.Category = "BlockMob Base"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/Zombie/Classic.mdl"
ENT.StartHealth = 20
ENT.WalkSpeed = 92
ENT.RunSpeed = 115
ENT.Acceleration = 420
ENT.Deceleration = 650
ENT.TargetRange = 900
ENT.TargetLoseRange = 1150
ENT.TargetScanInterval = 0.35
ENT.TargetRequireLineOfSight = false
ENT.ChaseRepathInterval = 0.5
ENT.ChaseSegmentTimeout = 2.0
ENT.ChaseFailureRepathDelay = 0.05
ENT.ChasePreferDirect = true
ENT.ChaseDirectDuration = 0.28
ENT.ChaseDirectProbeCells = 4
ENT.ChaseHighTargetHoldCells = 1.65
ENT.ChaseHighTargetStalkDelay = 0.12
ENT.WanderDistanceMinCells = 2
ENT.WanderDistanceMaxCells = 5
ENT.WanderPauseMin = 0.5
ENT.WanderPauseMax = 1.8
ENT.WanderPathAttempts = 1
ENT.WanderFailurePauseMin = 0.35
ENT.WanderFailurePauseMax = 0.8
ENT.AttackRange = 52
ENT.AttackVerticalRange = 28
ENT.AttackDamage = 10
ENT.AttackCooldown = 1.0
ENT.AttackHitDelay = 0
ENT.AttackMoveSpeed = 92
ENT.AttackHitSlop = 16
ENT.AttackKnockback = 240
ENT.AttackVerticalKnockback = 155
ENT.AttackGroundedVerticalKnockback = 190
ENT.AttackKnockbackCorrectionTicks = 3
ENT.AttackKnockbackCorrectionInterval = 0.03
ENT.AttackKnockbackSeparationDistance = 6
ENT.AttackKnockbackSeparationUp = 2
ENT.HitViewPunchPitch = -0.85
ENT.HitViewPunchYaw = 0.38
ENT.HitScreenShakeAmplitude = 0.85
ENT.HitScreenShakeFrequency = 12
ENT.HitScreenShakeDuration = 0.11
ENT.HitScreenShakeRadius = 96
ENT.AmbientSoundIntervalTicks = 80
ENT.AmbientSoundChanceDenominator = 1000
ENT.AmbientSoundTickRate = 20
ENT.AmbientSoundMaxCatchupTicks = 4
ENT.CollisionMins = Vector(-11, -11, 0)
ENT.CollisionMaxs = Vector(11, 11, 72)
-- Classic zombie model has a reliable walk sequence; ACT_RUN can freeze its legs on some installs.
ENT.RunActivity = ACT_WALK
ENT.TurnInPlaceAngle = 170
ENT.BlockHopAllowCloseLaunch = true

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
    Hit = {
        "player/pl_pain5.wav",
        "player/pl_pain6.wav",
        "player/pl_pain7.wav"
    }
}

local function randomSound(list)
    return list[math.random(#list)]
end

local function validTarget(target)
    if not IsValid(target) then return false end

    if target:IsPlayer() then
        return target:Alive()
    end

    return false
end

function ENT:Initialize()
    if CLIENT then return end

    self:BaseInitialize()
    self:SetBMBState("idle")
    self.TargetEntity = nil
    self.NextTargetScanTime = 0
    self.NextMeleeAttackTime = 0
    self:ResetBMBAmbientSoundTime()
    self.BMBNextAmbientSoundTickAt = CurTime() + math.Rand(0, 1 / (self.AmbientSoundTickRate or 20))
end

function ENT:RunBehaviour()
    while true do
        if self.BMBHeld then
            self:SetBMBState("held")
            coroutine.wait(0.2)
        elseif self.RunBMBKnockback and self:RunBMBKnockback() then
            self.BMBDebugMoveActive = false
        elseif self.RunBMBDebugMove and self:RunBMBDebugMove() then
            self.BMBDebugMoveActive = true
        elseif self.RunBMBStrandedRecovery and self:RunBMBStrandedRecovery() then
            self.BMBDebugMoveActive = false
        else
            self.BMBDebugMoveActive = false
            self:RunBMBZombieAI()
        end

        coroutine.yield()
    end
end

function ENT:RunBMBZombieAI()
    self.TargetEntity = BMB.Behaviors.SeekTarget.Find(self, self.TargetEntity)

    if not IsValid(self.TargetEntity) then
        self:SetBMBState("wander")
        BMB.Behaviors.Wander.Run(self)
        return
    end

    if BMB.Behaviors.MeleeAttack.Try(self, self.TargetEntity) then
        coroutine.wait(0.05)
        return
    end

    self:SetBMBState("chase")
    if not BMB.Behaviors.Chase.Run(self, self.TargetEntity) then
        if BMB.Behaviors.SeekTarget.IsValid(self, self.TargetEntity, self.TargetLoseRange or self.TargetRange) then
            if BMB.Behaviors.Chase.StalkHighTarget(self, self.TargetEntity) then return end

            self:SetBMBState("chase")
            self:SetBMBMoveMode("chase_repath")
            if BMB.Behaviors.Chase.ApplySafePressure then
                BMB.Behaviors.Chase.ApplySafePressure(
                    self,
                    self.TargetEntity,
                    self.RunSpeed,
                    "chase_repath",
                    self.ChaseRepathProbeDistance or self:GetBMBBlockSize() * 1.5
                )
            else
                self:MaintainBMBMoveSpeed(self.RunSpeed, self.RunSpeed)
                self:FaceTarget(self.TargetEntity:GetPos())
            end
            coroutine.wait(self.ChaseFailureRepathDelay or 0.08)
        else
            self.TargetEntity = nil
            self:InterruptibleWait(math.Rand(0.25, 0.55))
        end
    end
end

function ENT:CanBMBTarget(target)
    return validTarget(target)
end

function ENT:PlayBMBMeleeGesture(_)
    self:RestartGesture(ACT_MELEE_ATTACK1)
end

function ENT:ApplyBMBPlayerHitFeedback(target)
    if not IsValid(target) or not target:IsPlayer() then return end

    if target.ViewPunch then
        local pitch = self.HitViewPunchPitch or -0.55
        local yaw = self.HitViewPunchYaw or 0.28
        target:ViewPunch(Angle(pitch, math.Rand(-yaw, yaw), 0))
    end

    local shakeAmplitude = self.HitScreenShakeAmplitude or 0
    if shakeAmplitude > 0 and util and util.ScreenShake then
        util.ScreenShake(
            target:GetPos(),
            shakeAmplitude,
            self.HitScreenShakeFrequency or 10,
            self.HitScreenShakeDuration or 0.08,
            self.HitScreenShakeRadius or 96,
            true
        )
    end
end

function ENT:OnBMBMeleeHit(target, _)
    if not IsValid(target) then return end

    if self.Sounds and self.Sounds.Hit then
        target:EmitSound(randomSound(self.Sounds.Hit), 74, math.random(96, 104), 0.75)
    end

    self:ApplyBMBPlayerHitFeedback(target)
end

function ENT:OnBMBInjured(damageInfo, _)
    local attacker = damageInfo:GetAttacker()

    if self:CanBMBTarget(attacker) then
        self.TargetEntity = attacker
        self.NextTargetScanTime = 0
    end

    if self.Sounds and self.Sounds.Hurt then
        self:EmitSound(randomSound(self.Sounds.Hurt), 72, math.random(95, 105), 0.8)
    end
end

function ENT:OnKilled(damageInfo)
    if CLIENT then return end

    if self.Sounds and self.Sounds.Death then
        self:EmitSound(randomSound(self.Sounds.Death), 76, math.random(95, 105), 0.9)
    end

    hook.Run("OnNPCKilled", self, damageInfo:GetAttacker(), damageInfo:GetInflictor())
    self:BecomeRagdoll(damageInfo)
end

function ENT:ResetBMBAmbientSoundTime()
    self.BMBAmbientSoundTime = -(self.AmbientSoundIntervalTicks or 80)
end

function ENT:MaybePlayIdleSound()
    if not self.Sounds or not self.Sounds.Idle then return end

    local now = CurTime()
    local tickRate = self.AmbientSoundTickRate or 20
    local tickInterval = 1 / tickRate
    local nextTick = self.BMBNextAmbientSoundTickAt or now

    if now < nextTick then return end

    local ticks = math.floor((now - nextTick) / tickInterval) + 1
    ticks = math.Clamp(ticks, 1, self.AmbientSoundMaxCatchupTicks or 4)

    for _ = 1, ticks do
        local soundTime = self.BMBAmbientSoundTime
        if soundTime == nil then
            soundTime = -(self.AmbientSoundIntervalTicks or 80)
        end

        if math.random(0, (self.AmbientSoundChanceDenominator or 1000) - 1) < soundTime then
            self:EmitSound(randomSound(self.Sounds.Idle), 72, math.random(92, 108), 0.65)
            self:ResetBMBAmbientSoundTime()
            break
        end

        self.BMBAmbientSoundTime = soundTime + 1
    end

    self.BMBNextAmbientSoundTickAt = nextTick + ticks * tickInterval
    if self.BMBNextAmbientSoundTickAt < now - tickInterval then
        self.BMBNextAmbientSoundTickAt = now + tickInterval
    end
end
